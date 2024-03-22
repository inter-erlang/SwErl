//
//  EPMD.swift
//
//
//Copyright (c) 2023 Lee Barney
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//
//  Created by Lee Barney on 11/20/23.
//

//All documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation
import Network
import Logging


// MARK: type aliases
public typealias ExchangeProtocol = NWParameters



/// Defines a structure representing an Erlang node's state information for the Erlang Port Mapper Daemon (EPMD).
/// This structure encapsulates details about an Erlang node that is alive and communicating with the EPMD, including its listening port number, node type, communication protocol, supported version range, node name, and any extra data associated with the node. The `nodeName` is stored as a `SwErlAtom`, aligning with Erlang's atom data type for node names.
///
/// - Properties:
///   - portNumber: The port number on which the Erlang node is listening.
///   - nodeType: The type of the Erlang node, typically indicating whether it is a hidden node or a regular node.
///   - comProtocol: The communication protocol used by the node, such as TCP or UDP.
///   - highestVersion: The highest version of the Erlang distribution protocol that the node supports.
///   - lowestVersion: The lowest version of the Erlang distribution protocol that the node supports.
///   - nodeName: The name of the Erlang node, stored as a `String`.
///   - extra: Any extra data associated with the node, stored as a `Data` object.
///
/// - Complexity: O(1) for accessing any of the properties.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
struct NodeAlive{
    let portNumber:UInt16
    let nodeType:NodeType
    let comProtocol:ConnectionProtocol
    let highestVersion:UInt16
    let lowestVersion:UInt16
    let nodeName:String
    let extra:Data
}
/// Starts the Erlang Port Mapper Daemon (EPMD) process with the specified configurations.
/// This function initializes various subsystems for tracking node names, node aliveness, address mapping, and UUID-to-name mapping. It then listens for incoming connections on the specified port to handle Erlang node registration, unregistration, and queries. The function ensures thread safety for all operations on the tracking data structures.
/// - Parameters:
///   - conduitType: The exchange protocol used for communication, defaults to .tcp.
///   - port: The port on which the EPMD should listen for incoming connections, defaults to 4369.
///   - logger: An optional `Logger` for emitting log messages during operation.
/// - Throws: An error if any part of the initialization or network listening fails.
///
/// - Complexity: O(1) for starting the service, but actual runtime will depend on the number of operations performed by the spawned systems and the handling of incoming network connections.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

public func startEPMD(using conduitType:ExchangeProtocol = .tcp, on port:UInt16 = 4369, logger:Logger? = nil){
    do{
        //Spawn the thread-safe dictionaries used to track the data required by EPMD.
        try buildSafe(dictionary: [String:UInt32](), named: "nameCreationTracker")
        try buildSafe(dictionary: [String:NodeAlive](), named: "nameNodeAliveTracker")
        try buildSafe(dictionary: [String:String](), named: "nameAddressTracker")
        try buildSafe(dictionary: [String:String](), named: "UUIDNameTracker")
        
        //This stream produces a new creation number each time it is accessed
        try initializeCreationStream()
        
        //This listener is async.
        let connectionListener = try NWListener(using:conduitType, on: 4369)
        connectionListener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                logger?.trace("EPMD ready to accept connections.")
            case .failed(let error):
                logger?.error("EPMD failed: \(error)")
            default:
                break
            }
        }
        
        //this connection handler is async
        connectionListener.newConnectionHandler = { aConnection in
            let uuid = UUID().uuidString
            aConnection.stateUpdateHandler = { aState in
                switch aState {
                case .ready:
                    logger?.trace("Client connected. Assigned UUID \(uuid)")
                    //this part runs on a thread from the .global() dispatch queue
                    aConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, context, _, error in
                        logger?.trace("\(uuid) receiving data")
                        if let data = data, !data.isEmpty {
                            logger?.trace("\(uuid) received \(Array(data)) data")
                            guard let (requestType,responseData) = dealWithRequest(data:data, uuid: uuid, logger: logger, epmdPort: port) as? (EPMDCommand,Data) else{
                                logger?.error("\(uuid) Unable to build response.")
                                //send nothing so a timeout happens on the remote
                                return
                                
                            }
                            logger?.trace("\(uuid) sending response \(Array(responseData))")
                            aConnection.send(content: responseData, completion: NWConnection.SendCompletion.contentProcessed { error in
                                logger?.trace("\(uuid) response sent.")
                                if requestType != EPMDCommand.stopReq{//never cancel a AliveX2_Request connection as per documentation.
                                    aConnection.cancel()
                                }
                            })
                        }
                    }
                case .failed(let error):
                    logger?.trace("\(uuid) connection failed: \(error)")
                    
                case .cancelled:
                    logger?.trace("\(uuid) EPMD connection canceled")
                    //clean up node alive record if the connection
                    //is the one used to originally store the
                    //NodeAlive data.
                    guard let (_,name) = ("UUIDNameTracker" ! (SafeDictionaryCommand.get,uuid,nil as String?)) as? (SwErlPassed,String) else{
                        logger?.trace("\(uuid) connection not found in uuid-name SafeDictionaryCommand.")
                        return
                    }
                    "nameNodeAliveTracker" ! (SafeDictionaryCommand.remove, name, nil as NodeAlive?)
                default:
                    break
                }
            }
            aConnection.start(queue: .global())
        }
        connectionListener.start(queue: .global())
    }
    catch{
        logger?.error("unable to start EPMD. \(error)")
    }
}
/// Initializes the creation number generator stream for Erlang node identifiers.
/// This function sets up a system process named `creation_generator` that produces unique, sequential creation numbers starting from a random point. These numbers are used as part of the node identifier in an Erlang distributed system to ensure each node gets a unique identifier. The creation numbers are unsigned 32-bit integers, starting from a random number greater than 4, to mimic Erlang's behavior. The stream has a period of 4,294,967,291, after which it wraps around.
/// The function ensures that each generated creation number is unique across the device by checking against currently active processes and adjusts the starting point if necessary.
/// - Parameter logger: An optional `Logger` for emitting warnings in case of invalid state resets.
/// - Throws: An error if the `spawnsysf` function encounters issues while spawning the creation generator process.
///
/// - Complexity: O(1) for the initialization call, but the complexity of ensuring uniqueness during use of the process may vary depending on the number of active processes.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

func initializeCreationStream(logger:Logger? = nil) throws {
    //
    // this stream has a period of 4,294,967,291.
    //
    
    //All creation numbers must be unsigned 32 bit ints
    //greater than 4 in order to match current Erlang
    //behavior. In Erlang, each node begins the series
    //of creation numbers randomly, and then increments
    //the next creation number by 1. Thus each node
    //on the device gets a unique number.
    //SwErl adds in a check to see if the number is already
    //used.
    
    //this process returns the current state (creation number)
    //and then modifies its state for the next request.
    //it ignores any message it is sent.
    try spawnsysf(name: "creation_generator",initialState: UInt32.random(in: 4..<UInt32.max)){(PID,message,state) in
        var updatedState:UInt32 = 4
        guard let state = state as? UInt32 else{
            logger?.warning("Warning: invalid previous creation: \(state). Resetting")
            var newRoot = UInt32.random(in: 4..<UInt32.max)
            while Registrar.getProcess(forID: "\(newRoot)") != nil{
                newRoot = newRoot + 1
            }
            return ((.ok,newRoot),newRoot + 1)
        }
        if state != UInt32.max{
            updatedState = state + 1
        }
        return ((.ok,state),updatedState)
    }
}

/// Handles incoming requests for the Erlang Port Mapper Daemon (EPMD) based on the request type indicated by the data received.
/// This function decodes the request from the incoming data and routes it to the appropriate handler based on the request type indicator. Supported request types are ALIVE2_X_REQ (120), PORT_PLEASE_REQ (122), and NAMES_REQ (110). Each request handler is responsible for processing the request and generating an appropriate response.
/// - Parameters:
///   - data: The raw data received from the connection, potentially representing a request to the EPMD.
///   - uuid: A unique identifier for the connection, used for logging purposes.
///   - logger: An optional `Logger` for emitting trace and error messages.
///   - epmdPort: The port number on which the EPMD is listening, used for generating some responses where necessary.
/// - Returns: A tuple containing the request type as UInt16 and the response data as optional Data. If the request type is unrecognized or there is an error, it returns (0, nil).
///
/// - Complexity: O(n) where n is the size of the data received, primarily due to the need to parse and handle the request data.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

func dealWithRequest(data:Data?, uuid:String, logger:Logger?, epmdPort:UInt16) -> (EPMDCommand,Data?){
    var resultData:Data? = nil
    var command = EPMDCommand.error
    if let data = data, data.count >= 3 {
        logger?.trace("connection \(uuid) did receive data: \(data.bytes)")
        var remainingBytes = data.dropFirst(2)
        command = EPMDCommand(rawValue: remainingBytes.first!) ?? .error
        remainingBytes = remainingBytes.dropFirst()
        logger?.trace("connection \(uuid) did receive request type: \(command)")

        switch command {
        case .alive2Request:
            logger?.trace("connection \(uuid) doing ALIVE2_REQ")
            resultData = doAliveX(data: remainingBytes, uuid: uuid)
        case .portPlease2Request:
            logger?.trace("connection \(uuid) doing PORT_PLEASE2_REQ")
            resultData = doPortPlease(bytes: remainingBytes, id: uuid, logger:logger)
        case .namesReq:
            logger?.trace("connection \(uuid) doing NAMES_REQ")
            resultData = doNamesReq(port:UInt32(epmdPort), id: uuid,logger: logger)
        default:
            logger?.trace("connection \(uuid) got unknown command \(command)")
        }
    }//end of if got good data
    else {
        logger?.error("Remote connection \(uuid) received unknown request \(String(describing: data))")
    }
    return (command,resultData)
}




//these functions handle requests send by nodes and send appropriate
//responses


/// Constructs a response for a PORT_PLEASE_REQ request by looking up the requested node name in the `nameNodeAliveTracker`.
/// This function decodes the requested node name from the incoming bytes and queries the `nameNodeAliveTracker` system to retrieve the corresponding `NodeAlive` data. If the requested node is registered and alive, it constructs a successful response containing the node's registration details. If the node is not found or the request cannot be decoded, it returns a failure response.
/// - Parameters:
///   - bytes: The data received in the PORT_PLEASE_REQ request, expected to contain the name of the requested node.
///   - id: A unique identifier for the connection, used for logging purposes.
///   - logger: An optional `Logger` object for emitting trace and error messages.
/// - Returns: A `Data` object representing the response to the PORT_PLEASE_REQ. This response includes the status of the request and, if successful, the node's registration details.
///
/// - Complexity: O(n) where n is the length of the bytes array, due to the need to decode the requested node name and construct the response.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

func doPortPlease(bytes:Data, id:String, logger:Logger? = nil) -> Data{
    let failureResponse = Data([119,1])
    
    logger?.trace("connection \(id) building portPlease response")
    guard let requestedNodeName = String(bytes: bytes, encoding: .utf8) else{
        logger?.error("connection \(id) bad requested node name bytes \(bytes.bytes)")
        return failureResponse
    }
    logger?.trace("connection \(id) requesting port for \(requestedNodeName)")
    let (success,result) = "nameNodeAliveTracker" ! (SafeDictionaryCommand.get, requestedNodeName)
    guard success == SwErlPassed.ok, let alive = result as? NodeAlive else{
        logger?.error("\(id) NodeAlive not found for \(requestedNodeName) for port please request.")
        return failureResponse
    }
    let resultData = Data([EPMDCommand.port2Response.rawValue,Byte(0)]) ++ alive.toData()
    logger?.trace("\(id) built ALIVE response \(resultData.bytes) for \(requestedNodeName)")
    return resultData
}

/// Generates a response for a NAMES_REQ request, listing all registered nodes and their corresponding ports.
/// This function queries the `nameNodeAliveTracker` to obtain a list of all registered and alive nodes. It then formats this list into a string containing each node's name and port number, which is returned as part of the response data. The response also includes the EPMD's listening port at the beginning of the data.
/// - Parameters:
///   - port: The port number on which the EPMD is listening, included in the response to indicate where the EPMD is running.
///   - id: A unique identifier for the connection, used for logging purposes.
///   - logger: An optional `Logger` for emitting trace and error messages.
/// - Returns: A `Data` object that starts with the EPMD's listening port in Erlang interchange byte order, followed by the list of node names and their ports. If there's an error generating the list or encoding it into data, the response will only contain the EPMD's listening port.
///
/// - Complexity: O(n) where n is the number of nodes registered with the EPMD, due to the need to compile and format the list of nodes.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

func doNamesReq(port:UInt32, id:String, logger:Logger?) -> Data{
    let portData = Data(port.toErlangInterchangeByteOrder.toByteArray)
    let allValues = "nameNodeAliveTracker" ! SafeDictionaryCommand.getValues
    guard let (_,allNodeAlives) = allValues as? (SwErlPassed,[NodeAlive]) else{
        logger?.error("names request failed. Incorrect request result \(allValues)")
        return portData
    }
    let namesListString = allNodeAlives.reduce(""){accum, nodeAlive in
        return accum.appending("name \(nodeAlive.nodeName) at port \(nodeAlive.portNumber)\n")
    }
    
    logger?.trace("all NodeInfo string: \(namesListString)")
    print("all NodeInfo string: \(namesListString)")
    guard var asData = namesListString.data(using: .utf8) else{
        logger?.error("connection \(id) unable to generate names list data from string \(namesListString)")
        
        return portData
    }
    asData = portData ++ asData
    
    logger?.trace("\(id) built NAMES_REQ response \(Array(asData))")
    return asData
    
}

/// Processes an ALIVE2_REQ (Alive request) from an Erlang node and registers it if possible.
/// This function parses the ALIVE2_REQ data to extract node details such as port number, node type, communication protocol, supported version numbers, node name, and extra information. It then attempts to register the node with the `nameNodeAliveTracker` and associates the connection UUID with the node name in the `UUIDNameTracker`. A creation number is generated for the node, signifying successful registration.
/// - Parameters:
///   - data: The raw data received in the ALIVE2_REQ, containing the node's registration information.
///   - uuid: A unique identifier for the connection, used for logging purposes.
///   - logger: An optional `Logger` for emitting trace and error messages.
/// - Returns: A `Data` object representing the response to the ALIVE2_REQ. This response includes a success indicator and, if successful, the generated creation number for the node. If the request is malformed or an error occurs, an error response is returned.
///
/// - Complexity: O(n) where n is the length of the data, due to the need to parse and validate the request data.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

func doAliveX(data:Data, uuid:String, logger:Logger? = nil) -> Data{
    logger?.trace("\(uuid) alive request data \(Array(data))")
    let errorArray = [EPMDCommand.alive2XResponse.rawValue,Byte(1)] + UInt32(1).toErlangInterchangeByteOrder.toByteArray
    let errorData = Data(errorArray)
    guard data.count > 9 else {
        logger?.error("\(uuid) bad message \(Array(data))")
        return errorData
    }
    let portNum = data.prefix(2).toMachineByteOrder.toUInt16
    var remaining = data.dropFirst(2)
    guard let nodeType = remaining.first?.toNodeType else{
        logger?.error("\(uuid) bad message \(Array(remaining)). No node type.")
        return errorData
    }
    remaining = remaining.dropFirst()
    guard let communicationProtocol = remaining.first?.toConnectionProtocol else{
        logger?.error("\(uuid) bad message \(Array(remaining)). No communication protocol.")
        return errorData
    }
    remaining = remaining.dropFirst()
    let highestVersion = remaining.prefix(2).toMachineByteOrder.toUInt16
    remaining = remaining.dropFirst(2)
    logger?.trace("\(uuid) highest version: \(highestVersion)")
    let lowestVersion = remaining.prefix(2).toMachineByteOrder.toUInt16
    logger?.trace("\(uuid) lowest version: \(lowestVersion)")
    remaining = remaining.dropFirst(2)
    let nameLength = Int(remaining.prefix(2).toMachineByteOrder.toUInt16)
    logger?.trace("\(uuid) name length: \(nameLength)")
    remaining = remaining.dropFirst(2)
    //the name and the length of
    guard remaining.count >= nameLength + 2 else{
        logger?.error("\(uuid) \(Array(remaining)) has insufficent length for name of size \(nameLength + 2)")
        return errorData
    }
    guard let name = String(bytes: remaining.prefix(nameLength), encoding: .utf8) else {
        logger?.error("\(uuid) unable to convert \(remaining.prefix(nameLength)) to UTF8")
        return errorData
    }
    remaining = remaining.dropFirst(nameLength)
    let extrasLength = Int(remaining.prefix(2).toMachineByteOrder.toUInt16)
    remaining = remaining.dropFirst(2)
    let extras = remaining.prefix(extrasLength)
    logger?.trace("\(uuid) extras: \(Array(extras))")
    var responseArray:[Byte] = [118,//response indicator
                                0]//registration success indicator
    let (_,creation) = "creation_generator" ! true//creation generator ignores any message sent
    guard let creation = creation as? UInt32 else{
        logger?.error("unable to generate creation in \(uuid)")
        return errorData
    }
    let anAlive = NodeAlive(portNumber: portNum, nodeType: nodeType, comProtocol: communicationProtocol, highestVersion: highestVersion, lowestVersion: lowestVersion, nodeName: name, extra: extras)
    logger?.trace("\(uuid) generated alive \(anAlive)")
    "nameNodeAliveTracker" ! (SafeDictionaryCommand.add, name, anAlive)
    "UUIDNameTracker" ! (SafeDictionaryCommand.add,uuid,name)
    logger?.trace("creation: \(creation) generated for \(uuid)")
    responseArray = responseArray +  creation.toErlangInterchangeByteOrder.toByteArray //creation data
    
    return  Data(responseArray)
}
/// Extends the `NodeAlive` structure to include a method for converting its properties to an instance of the `Data` class.
/// This extension provides a way to serialize a `NodeAlive` instance into a `Data` object suitable for network transmission. The serialization includes the node's port number, type, communication protocol, highest and lowest version numbers, node name, and any extra information. If the node name cannot be encoded, a failure response is generated instead.
///
/// - Returns: A `Data` object representing the serialized form of the `NodeAlive` instance. If the node name is not encodable, returns a predefined error response.
///
/// - Complexity: O(n), where n is the size of the serialized data, primarily depending on the length of the node name and the extra information.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
///
extension NodeAlive{
    func toData()->Data{
        let nameBytes = Array(self.nodeName.utf8)
        return Data(self.portNumber.toErlangInterchangeByteOrder.toByteArray) ++ Data([self.nodeType.rawValue,self.comProtocol.rawValue]) ++ Data(self.highestVersion.toErlangInterchangeByteOrder.toByteArray) ++ Data(self.lowestVersion.toErlangInterchangeByteOrder.toByteArray) ++ Data(UInt16(self.nodeName.count).toErlangInterchangeByteOrder.toByteArray) ++ Data(nameBytes) ++ Data(UInt16(self.extra.count).toErlangInterchangeByteOrder.toByteArray) ++ self.extra
    }
}


extension ExchangeProtocol {
    var usesTCP: Bool {
        // Check the first protocol in the transport protocol stack
        // This assumes the top-most transport protocol defines the connection type
        return self.defaultProtocolStack.transportProtocol is NWProtocolTCP.Options
    }
}
