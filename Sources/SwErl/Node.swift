//
//  File.swift
//  Copyright (c) 2024 Lee Barney
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
//  Created by Lee Barney on 2/13/24.
//

///Documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation
import Network
import Logging



/// Defines the types of distribution headers for network messages.
///
/// The `DistHeaderType` enumeration categorizes network message headers into different types based on their characteristics:
/// normal, fragmented, and compressed. Each type is associated with a specific `UInt8` value that represents its header type
/// in the inter-node protocol.
///
/// - Cases:
///   - normal: Represents a normal message header, indicated by the `UInt8` value `68`.
///   - fragmented: Represents a fragmented message header, allowing for the transmission of messages that exceed the size limit of a single packet, indicated by `69`.
///   - compressed: Represents a compressed message header, facilitating the efficient transmission of data by reducing its size, indicated by `80`.
///
/// This enumeration is crucial for handling different types of inter-node messages, ensuring that the messaging system can
/// accommodate messages of varying sizes and optimize for network efficiency through compression.
///
/// - Complexity: O(1) for accessing any of the cases.
///
/// - Author: Lee Barney
/// - Version: 0.1
enum DistHeaderType: UInt8 {
    case normal = 68
    case fragmented = 69
    case compressed = 80
}


/// Represents the status of a network connection, including its name, capabilities, creation time, and the connection object itself.
///
/// The `Status` structure encapsulates details about a network connection, providing a straightforward way to access
/// its properties, such as the connection's name, capabilities bitmask, creation timestamp, and the `NWConnection` instance.
///
/// - Properties:
///   - name: A `String` representing the name of the connection.
///   - capabilities: A `UInt64` bitmask representing the capabilities of the connection.
///   - creation: A `UInt32` representing the creation timestamp of the connection.
///   - connection: An instance of `NWConnection` representing the network connection itself.
///
/// This structure can be used to store and manage information about network connections, making it easier to
/// query their status, capabilities, and other relevant details.
///
/// - Complexity: Accessing any of the properties is O(1), as they are direct property accesses.
///
/// - Author: Lee Barney
/// - Version: 0.1
struct Status {
    let name: String
    let capabilities: UInt64
    let creation: UInt32
    let connection: NWConnection
}
/// Starts the SwErl node with a specific configuration, initiating the ability to accept and make network connections.
///
/// This function configures and starts a node using the specified exchange protocol, name, cookie, and EPMD port.
/// It initializes necessary processes for handling handshake and connection management, and sets up a listener
/// for incoming network connections. The node's operation is logged using the provided `Logger` instance.
///
/// - Parameters:
///   - conduit: The network exchange protocol to use. Defaults to `.tcp`.
///   - name: The unique name of the node.
///   - cookie: The security cookie for node authentication.
///   - epmdPort: The port number for the Erlang Port Mapper Daemon (EPMD). Defaults to `4369`.
///   - logger: An optional `Logger` instance for recording operational messages.
///
/// The function performs several critical steps, including generation of a node creation identifier, setting up
/// handshake response processes, and configuring a network listener for handling incoming connections. It also
/// prepares the node for network communication by setting up both state update and new connection handlers.
///
/// - Complexity: The complexity varies depending on the network operations.
///
/// - Author: Lee Barney
/// - Version: 0.1
public func startNode(using conduit:ExchangeProtocol = .tcp, name:String, cookie:String, epmdPort:UInt16 = 4369, logger:Logger? = nil){
    do{
        guard let (_,creation) = ("creation_generator" ! true) as? (SwErlPassed,UInt32) else{//creation generator ignores any message sent
            logger?.error("Unable to get creation. Start terminated.")
            return
        }
        
        let parts = name.split(separator: "@")
        let shortName = String(parts[0])
        "nameCreationTracker" ! (Tracker.add,shortName,creation)
        try spawnHandshakeResponseProcess(epmdPort:epmdPort,creation:creation, logger: logger)
        try spawnHandshakeProcess(creation: creation,epmdPort: epmdPort,logger: logger)
        
        let connectionListener = try NWListener(using: conduit, on: .any)
        connectionListener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                logger?.trace("Node \(name) changed state to \(newState)")
                guard let listingPortNum = connectionListener.port?.rawValue else{
                    logger?.error("Node \(name) in ready state without a port number.")
                    return
                }
                let localProtocol:UInt8 = conduit.usesTCP ? 0 : 1
                let alive = NodeAlive(portNumber: listingPortNum, nodeType: 77, comProtocol: localProtocol, highestVersion: 6, lowestVersion: 6, nodeName: SwErlAtom(shortName), extra: Data())
                
                let (success,_) = "nameNodeAliveTracker" ! (Tracker.add, shortName, alive)
                guard success == SwErlPassed.ok else{
                    logger?.error("Node \(name) unable to register alive \(alive). Stopping listening")
                    connectionListener.cancel()
                    return
                }
                
                logger?.trace("Node \(name) ready to accept connections on port \(listingPortNum) with cookie \(cookie) using \(conduit).")
            default:
                logger?.trace("Node \(name) in unrecognized state \(newState)")
                break
            }
        }
        //connections from other nodes handshake request
        connectionListener.newConnectionHandler = { connectionFromRemote in
            logger?.trace("Node \(name) got connection from \(connectionFromRemote.endpoint)")
            let uuid = UUID().uuidString
            connectionFromRemote.stateUpdateHandler = { aState in
                switch aState {
                case .ready:
                    logger?.trace("Client connected. Assigned UUID \(uuid)")
                    
                case .failed(let error):
                    logger?.trace("\(uuid) connection failed: \(error)")
                    
                case .cancelled:
                    logger?.trace("\(uuid) connection cancelled.")
                default:
                    logger?.trace("\(uuid) connection in unrecognized state \(aState)")
                    break
                }
            }
            connectionFromRemote.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, context, _, error in
                logger?.trace("\(uuid) receiving data")
                guard var data = data, !data.isEmpty else{
                    logger?.error("\(uuid) received bad data. \(String(describing: data))")
                    return
                }
                logger?.trace("\(uuid) received \(Array(data)) data")
                if data.count >= 3 {
                    logger?.trace("connection \(uuid) did receive data: \(data.bytes)")
                    data = data.dropFirst(2)
                    let indicator = data.first!
                    logger?.trace("connection \(uuid) did receive indicator: \(indicator)")
                    switch indicator {
                    case 78:
                        logger?.trace("connection \(uuid) did receive request type: \(indicator)")
                        "handshake" ! (uuid,name,cookie, data.dropFirst(),connectionFromRemote)
                    default:
                        logger?.error("\(uuid) received incorrect initial handshake command \(indicator)")
                        return
                    }
                }//end of if got good data
                else {
                    logger?.error("Remote connection \(uuid) received unknown request \(Array(data))")
                }
            }
            //accept the connection from the remote application
            connectionFromRemote.start(queue: .global())
        }
        //start listening for connection requests from remote applications
        connectionListener.start(queue: .global())
    }
    catch{
        logger?.error("unable to start Node. \(error)")
    }
}


///this needs to NOT be directly recursive. The plan is to embed this in a spawned stateful async process.
fileprivate func waitForData(uuid:String, connection:NWConnection, status:Status,logger:Logger? = nil) {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
        guard var data = data, data.count >= 3 else{
            logger?.trace("\(uuid) got invalid waitForData data")
            waitForData(uuid: uuid, connection: connection, status: status, logger:logger)
            return
        }
        logger?.trace("\(uuid) request data \(Array(data))")
        let requestLength = data.prefix(4).toMachineByteOrder.toUInt32
        print("length: \(data.count) \(requestLength)")
        data = data.dropFirst(4)
        guard let headerIndicator = data.first, headerIndicator == 131 else{
            logger?.error("\(uuid) bad distribution header")
            waitForData(uuid:uuid, connection: connection, status: status, logger: logger)//recursively call this function. stack overflow problem?
            return
        }
        data = data.dropFirst()
        guard let distributionTypeIndicator:UInt8 = data.first else{
            logger?.error("\(uuid) missing header type")
            waitForData(uuid:uuid, connection: connection, status: status, logger: logger)//recursively call this function. stack overflow problem?
            return
        }
        data = data.dropFirst()
        switch DistHeaderType(rawValue: distributionTypeIndicator){
        case .normal:
            guard var numAtomCacheRefs = data.first else{
                return
            }
            data = data.dropFirst()
            if numAtomCacheRefs != 0{
                logger?.trace("\(uuid) num atom cache references \(numAtomCacheRefs)")
                
                print("after cache ref count request data \(Array(data))")
                let flagByteCount = Int(numAtomCacheRefs/2+1)
                let flags = data.prefix(flagByteCount)
                data = data.dropFirst(flagByteCount)
                
                print("after drop flags request data \(Array(data))")
            }
        case .fragmented:
            1+1
        case .compressed:
            1+1
        default:
            1+1
        }
                
//        switch indicator {
//            
//            //call handler function(s) for that type
//        }
        
        
        waitForData(uuid:uuid, connection: connection, status: status, logger: logger)//recursively call this function. stack overflow problem?
    }
}


/// Initiates a handshake response process that waits for a network connection request from a remote node.
///
/// This function spawns a new asynchronous, stateless process specifically designed to handle
/// the handshake procedure initiated by a remote node for a connection to the local SwErl node. It validates and processes
/// incoming handshake messages, generates challenges, and manages the exchange of connection
/// status information.
///
/// - Parameters:
///   - epmdPort: The port number of the Erlang Port Mapper Daemon (EPMD) as a `UInt16`. Defaults to `4369`.
///   - creation: The creation identifier of the local node as a `UInt32`. Used in establishing the network connection.
///   - logger: An optional `Logger` instance for logging messages during the handshake process.
/// - Throws: An error if the process spawning encounters issues.
///
/// The handshake process involves several steps, including validating incoming messages, generating
/// and sending challenge responses, and ultimately establishing a connection status. This function
/// leverages the `spawnasysl` function to create a dedicated process for handling these tasks in
/// an asynchronous and stateless manner.
///
/// - Complexity: The complexity varies depending on the network conditions and the processing time
///   required for MD5 hash generation and data manipulation.
///
/// - Author: Lee Barney
/// - Version: 0.1
           
fileprivate func spawnHandshakeResponseProcess(epmdPort:UInt16 = 4369,creation:UInt32,logger:Logger?) throws{
    //async stateless
    try spawnasysl(name: "handshake") { Pid, message in
        guard let (uuid,localNodeName,cookie,data,connection) = message as? (String,String,String,Data,NWConnection) else{
            logger?.error("handshake got bad message \(message)")
            return
        }
        var localData = data
        logger?.trace("connection \(uuid) starting handshake")
        let capabilityFlags = localData.prefix(8).toMachineByteOrder.toUInt64
        localData = localData.dropFirst(8)
        let remoteCreation = data.prefix(4).toMachineByteOrder.toUInt32
        localData = localData.dropFirst(4)
        let nameLength = localData.prefix(2).toMachineByteOrder.toUInt16
        localData = localData.dropFirst(2)
        guard let remoteNodeName = String(bytes: localData.prefix(Int(nameLength)), encoding: .utf8) else {
            logger?.error("\(uuid) unable to convert \(localData.prefix(Int(nameLength))) to UTF8")
            return
        }
        let remoteStatus = Status(name: remoteNodeName, capabilities: capabilityFlags, creation: creation, connection: connection)
        guard var responseData = "ok".data(using: .utf8) else{
            return
        }
        responseData = Data([115]) ++ responseData
        let responseLength = UInt16(responseData.count).toErlangInterchangeByteOrder.toByteArray
        responseData = Data(responseLength) ++ responseData
        
        connection.send(content: responseData, completion: NWConnection.SendCompletion.contentProcessed { error in
            logger?.trace("\(uuid) status sent.")
            //now send a challenge
            let challenge = UInt32.random(in: UInt32.min...UInt32.max).bigEndian//is always big-endian
           
            let challengeDigest = "\(cookie)\(challenge)".MD5//MD5 hash coming back should be this.
            guard let localNameData = localNodeName.data(using: .utf8) else{
                logger?.error("\(uuid) unable to convert node name \(remoteNodeName) to utf8")
                return
            }
            //currently echoing back capability flags
            var challengeData = Data([78]) ++ Data(capabilityFlags.toErlangInterchangeByteOrder.toByteArray) ++ Data(challenge.toErlangInterchangeByteOrder.toByteArray) ++ Data(creation.toErlangInterchangeByteOrder.toByteArray) ++ Data(UInt16(localNameData/*shortName*/.count).toErlangInterchangeByteOrder.toByteArray) ++ localNameData
            challengeData = Data(UInt16(challengeData.count).toErlangInterchangeByteOrder.toByteArray) ++ challengeData
            logger?.trace("\(uuid) sending challenge \(Array(challengeData))")
            //send the challenge
            connection.send(content: challengeData, completion: NWConnection.SendCompletion.contentProcessed { error in
                logger?.trace("\(uuid) challenge sent.")
                
            })
            //when the connection is closed by the remote node, you get nil for  the incoming data.
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { challengeReplayData, _, _, error in
                logger?.trace("\(uuid) receiving data")
                guard var challengeReplyData = challengeReplayData/*, data.count < 21*/ else{
                    logger?.error("\(uuid) received bad data. \(String(describing: challengeReplayData))")
                    //log error here
                    return
                }
                print("got data: \(Array(challengeReplyData))")
                challengeReplyData = challengeReplyData.dropFirst(2)
                guard challengeReplyData.first == 114 else{
                    //log error here
                    return
                }
                challengeReplyData = challengeReplyData.dropFirst()
                let challengeBytes = challengeReplyData.prefix(4)
                print("chbytes: \(Array(challengeBytes))")
                let challenge:UInt32 = challengeBytes.toUInt32//current
        
                let blah = "\(cookie)\(challenge.toMachineByteOrder)".MD5
                let remoteNodeChallengeDigest = "\(cookie)\(challenge.byteSwapped)".MD5
                print("all: \(Array(remoteNodeChallengeDigest))\n\(Array(blah))\n")
                challengeReplyData = challengeReplyData.dropFirst(4)
                let MD5Echo = challengeReplyData.prefix(16)
                guard challengeDigest == MD5Echo else{
                    logger?.error("\(uuid) mismatched echo digest")
                    return//let the remote time out
                }
                challengeReplyData = challengeReplyData.dropFirst(16)
                var challengeAck = Data([97]) ++ remoteNodeChallengeDigest
                challengeAck = Data(UInt16(challengeAck.count).toErlangInterchangeByteOrder.toByteArray) ++ challengeAck
                //send the final ack
                logger?.trace("\(uuid) sending ack: \(Array(challengeAck))")
                connection.send(content: challengeAck, completion: NWConnection.SendCompletion.contentProcessed { error in
                    logger?.trace("\(uuid) challenge ack sent.")
                    connection.stateUpdateHandler = { newState in
                        guard connection.state == NWConnection.State.ready else{//has not been cancled by the remote
                            //remove from status storage dictionary
                            return
                        }
                        //add to status storage dictionary, key is name of remote
                    }
                    waitForData(uuid:uuid, connection:connection, status:remoteStatus, logger: logger)//break this out into an async stateless process execution.
                })
            }
        })
    }
}

/// Initiates a handshake process used to initialize and establish a connection with a remote node.
///
/// This function spawns an asynchronous, stateless process named "toNodeHandshake" to handle the handshake procedure
/// with a remote node. It involves connecting to the Erlang Port Mapper Daemon (EPMD) to retrieve the port number of the
/// remote node, establishing a connection with the remote node, and performing a handshake that includes challenge-response
/// verification for security purposes.
///
/// - Parameters:
///   - creation: The creation number of the local node, used in the handshake process.
///   - epmdPort: The port number of the EPMD. Defaults to `4369`.
///   - logger: An optional `Logger` instance for logging messages during the handshake process.
/// - Throws: An error if the process spawning encounters issues.
///
/// The handshake process is critical for establishing a secure and authenticated connection between distributed nodes.
/// It ensures that both parties can verify each other's identity and establish a secure communication channel.
///
/// - Complexity: The complexity varies depending on network conditions, the responsiveness of the remote node and EPMD,
///   and the processing time required for generating and verifying cryptographic challenges.
///
/// - Author: Lee Barney
/// - Version: 0.1
func spawnHandshakeProcess(creation:UInt32, epmdPort:UInt16 = 4369, logger:Logger? = nil) throws {
    try spawnasysl(name: "toNodeHandshake") { Pid, message in
        let uuid = UUID().uuidString
        guard let (localNode,node,cookie) = message as? (String,String,String) else{
            logger?.error("\(uuid) toNodeHandshake got bad message \(message)")
            return
        }
        
        //TODO: check to see if there is already a connection to the node. If there is, stop.
        //connect to EPMD and find out the port the node is listening on.
        let parts = node.split(separator: "@")
        var hostName = "127.0.0.1"
        if parts.count == 2{
            hostName = String(parts[1])
        }
        
        let shortName:String = String(parts[0])
        guard let shortNameData = shortName.data(using: .utf8) else{
            return
        }
        logger?.trace("\(uuid) initializing handshake with node \(shortName)@\(hostName)")
        var PORT_PLEASE2_Data = Data([122]) ++ shortNameData
        PORT_PLEASE2_Data = Data(UInt16(PORT_PLEASE2_Data.count).toErlangInterchangeByteOrder.toByteArray) ++ PORT_PLEASE2_Data
        
        let host = NWEndpoint.Host(hostName)
        let port = NWEndpoint.Port(rawValue: epmdPort)!
        
        // Create the connection
        logger?.trace("\(uuid) connecting to \(host):\(port)")
        let epmdConnection = NWConnection(host: host, port: port, using: .tcp)
        
        
        // Start the connection
        epmdConnection.start(queue: .global())
        
        logger?.trace("\(uuid) sending port please data \(Array(PORT_PLEASE2_Data))")
        //send the data array
        epmdConnection.send(content: PORT_PLEASE2_Data, completion: .contentProcessed({ error in
            if let error = error {
                logger?.error("\(uuid) failed to send data: \(error)")
                epmdConnection.cancel()
            } else {
                logger?.trace("\(uuid) port please message was sent.")
                epmdConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
                    if var data = data, !data.isEmpty {
                        logger?.trace("\(uuid) received response: \(Array(data))")
                        guard data.first == 119 else{
                            logger?.error("\(uuid) bad epmd response indicator")
                            return
                        }
                        data = data.dropFirst()
                        guard data.first == 0 else{
                            logger?.error("\(uuid) failed")
                            return
                        }
                        data = data.dropFirst()
                        let portNum = data.prefix(2).toMachineByteOrder.toUInt16
                        //all we care about, at this point in time, is the port number.
                        logger?.trace("\(uuid) closing EPMD Connection")
                        epmdConnection.cancel() // Close the EPMD connection
                        //connect to the Node.
                        logger?.trace("\(uuid) connecting to \(host) on port \(portNum)")
                        let nodePort = NWEndpoint.Port(rawValue: portNum)!
                        
                        // Create the connection
                        let nodeConnection = NWConnection(host: host, port: nodePort, using: .tcp)
                        
                        //use a made up creation number. see if it works.
                        var sendNameData = Data(UInt32(123456).toErlangInterchangeByteOrder.toByteArray)
                        guard let nameData =  localNode.data(using: .utf8) else{
                            logger?.error("\(uuid) bad node name \(node)")
                            return
                        }
                        sendNameData = Data([78]) ++ Data(DIST_MANDATORY.toErlangInterchangeByteOrder.toByteArray) ++ sendNameData ++ Data(UInt16(nameData.count).toErlangInterchangeByteOrder.toByteArray) ++ nameData
                        sendNameData = Data(UInt16(sendNameData.count).toErlangInterchangeByteOrder.toByteArray) ++ sendNameData
                        
                        let nameDataToSend = sendNameData
                        nodeConnection.start(queue: .global())
                        nodeConnection.send(content: nameDataToSend, completion: .contentProcessed({ error in
                            if let error = error {
                                logger?.error("\(uuid) failed to send data: \(error)")
                                nodeConnection.cancel()
                                return
                            } else {
                                logger?.trace("\(uuid) sent \(Array(nameDataToSend)).")
                                nodeConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
                                    guard var statusData = data, !statusData.isEmpty else{
                                        logger?.error("\(uuid) got bad status data \(String(describing: data))")
                                        return
                                    }
                                    logger?.trace("\(uuid) received status response: \(Array(statusData))")
                                    statusData = statusData.dropFirst(2)
                                    let indicator = statusData.first
                                    guard indicator == 115 else{
                                        logger?.error("\(uuid) got bad status indicator \(String(describing: indicator))")
                                        return
                                    }
                                    statusData = statusData.dropFirst()
                                    guard let status = String(data: statusData, encoding: .utf8),status == "ok" || status == "ok_simultaneous" else{
                                        logger?.trace("\(uuid) handshake not ok to continue")
                                        return
                                    }
                                    // read the incoming challenge
                                    nodeConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
                                        if var challengeData = data, !challengeData.isEmpty {
                                            logger?.trace("\(uuid) received response: \(Array(challengeData))")
                                            challengeData = challengeData.dropFirst(2)
                                            guard challengeData.first == 78 else{
                                                logger?.error("\(uuid) bad challenge  indicator \(challengeData.first)")
                                                return
                                            }
                                            challengeData = challengeData.dropFirst()
                                            let flags = challengeData.prefix(8).toMachineByteOrder.toUInt64
                                            challengeData = challengeData.dropFirst(8)
                                            let remoteChallenge = challengeData.prefix(4).toMachineByteOrder.toUInt32
                                            
                                            challengeData = challengeData.dropFirst(4)
                                            let creation = challengeData.prefix(4).toMachineByteOrder.toUInt32
                                            challengeData = challengeData.dropFirst(4)
                                            let nameLength = challengeData.prefix(2).toMachineByteOrder.toUInt16
                                            challengeData = challengeData.dropFirst(2)
                                            let remoteName = String(data: challengeData, encoding: .utf8)
                                            //send back the digest and another challenge
                                            let remoteChallengeDigest = "\(cookie)\(remoteChallenge)".MD5
                                            let blah = "\(remoteChallenge)\(cookie)".MD5
                                            let blif = "\(remoteChallenge.byteSwapped)\(cookie)".MD5
                                            let blew = "\(cookie)\(remoteChallenge.byteSwapped)".MD5
                                            
                                            print("all: \(remoteChallengeDigest)\n\(blah)\n\(blif)\n\(blew)")
                                            
                                            
                                            logger?.trace("\(uuid) digest for remote challenge created using: \(cookie)\(remoteChallenge) digest: \(remoteChallengeDigest)")
                                            let challengeData = Data(UInt32.random(in: UInt32.min...UInt32.max).toErlangInterchangeByteOrder.toByteArray)
                                            var challengeReplyData = Data([114]) ++ challengeData ++ remoteChallengeDigest
                                            challengeReplyData = Data(UInt16(challengeReplyData.count).toErlangInterchangeByteOrder.toByteArray) ++ challengeReplyData
                                            logger?.trace("\(uuid) sending challenge reply \(Array(challengeReplyData))")
                                            nodeConnection.send(content: challengeData, completion: .contentProcessed({ error in
                                                if let error = error {
                                                    logger?.error("\(uuid) failed to send data: \(error)")
                                                    nodeConnection.cancel()
                                                    return
                                                }
                                                
                                                logger?.trace("\(uuid) \(node) sent challenge \(remoteChallenge) and creation \(creation) waiting for challenge ack")
                                                nodeConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
                                                    let blah = 1+1
                                                    guard var data = data else{
                                                        logger?.error("\(uuid) faild to receive challenge ack")
                                                        return
                                                    }
                                                    logger?.trace("\(uuid) received challenge ack \(Array(data))")
                                                }
                                                
                                                
                                            }))
                                            
                                        }
                                    }//end of receive challenge
                                }
                            }
                        })
                        )//end of nodeConnection send
                    }
                    
                }//end of connection receive
            }
        })
        )
    }
}
