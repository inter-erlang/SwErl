//
//  EPMD.swift
//  
//
//  Created by Lee Barney on 3/1/23.
//

import Foundation
import Network
import Logging
import SwErl

struct PeerInfo {
    let port:UInt16
    let nodeType:UInt8
    let msgProtocol:UInt8
    let highestVersion:UInt16
    let lowestVersion:UInt16
    let nodeName:String
    let extras:Data
}

///
///The peer ports process is a stateful process where
///the state is a dictionary where the key is the name of
///the peer and the value is all of the information, including
///the peer's communication port, sent by the EPMD server
///
func startPeerPortsDictionary() throws{
    _ = try spawn(name: "peerPorts", initialState: Dictionary<String,PeerInfo>()){(pid,state,message)in
        let (peerName,port) = message as! (String,UInt16)
        var updateState = state as! Dictionary<String,UInt16>
        updateState[peerName] = port
        return updateState
    }
}


public enum EPMDRequest{
    static let register_node = "register"
    static let port_please = "port_please"
    static let names = "names"
    //static let dump = "dump"//this is for debugging purposes only, therefore it is not implemented in SwErl at this time.
    static let kill = "kill"
    //static let stop = "stop"//this is not used in practice, therefore it is not implemented in SwErl
}
@available(macOS 10.14, *)
public typealias EPMD = (EPMDPort:NWEndpoint.Port,
                  EPMD_Host:NWEndpoint.Host,
                  connection:NWConnection,
                         nodeName:String, nodePort:UInt16)

@available(macOS 10.14, *)
func spawnProcessesFor(EPMD:EPMD) throws{
    let (_,_,connection,nodeName,nodePort) = EPMD
    //this process is used to consume responses that
    //contain no needed data
    
    //
    // register each node, by name, with the EPMD
    //
    _ = try spawn(name:"clear_buffer"){(senderPID,message) in
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _context, isDone, error in
            var ultimateMessage = "fail"
            if let  (tracker,ultimatePid) = message as? (UUID,UUID){
                if data != nil {
                    logger?.trace("\(tracker): data for request was ignored")
                    ultimateMessage = "ok"
                }
                else if isDone {
                    logger?.trace("\(tracker): EOF")//EPMD terminated
                    stop(client: EPMD,tracker: tracker)
                    ultimateMessage = "EOF"
                }
                else if error != nil {
                    logger?.error("\(tracker): error \(error!)")
                    ultimateMessage = "fail"
                }
                
                ultimatePid ! (tracker,ultimateMessage)
            }
            if let tracker = message as? UUID {
                if data != nil {
                    logger?.trace("\(tracker): data for request was ignored")
                }
                else if isDone {
                    logger?.trace("\(tracker): EOF")//EPMD terminated
                    stop(client: EPMD,tracker: tracker)
                }
                else if error != nil {
                    logger?.error("\(tracker): error \(error!)")
                }
            }
            return
        }
    }
    _ = try
    spawn(name:EPMDRequest.register_node){(senderPID,ultimatePid) in
        
        let protocolData = buildRegistrationMessageUsing(nodeName: nodeName, port: nodePort, extras: [])
        let tracker = UUID()
        NSLog("\(tracker): sending register_node request ")
        connection.send(content: protocolData, completion: NWConnection.SendCompletion.contentProcessed { error in
            guard let error = error else{
                logger?.trace("\(tracker): sent successfully")
                
                "clear_buffer" ! (tracker,ultimatePid)//sending to next process
                
                return
            }
            logger?.error("\(tracker): error \(error) send error")
            stop(client:EPMD,tracker: tracker)
        })
        NSLog("\(tracker): sent register_node request ")
    }
    
    //
    //store the port and node information for a named remote node
    //
    _ = try spawn(name:"store_port"){(senderPID,message) in
        let tracker:UUID
        let remoteNodeName:String
        var ultimatePid:UUID?
        if let (aTracker,aName,finalPid) = message as? (UUID,String,UUID){
            tracker = aTracker
            remoteNodeName = aName
            ultimatePid = finalPid
        }
        else{
            let (aTracker,aName) = message as! (UUID,String)
            tracker = aTracker
            remoteNodeName = aName
        }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _context, isDone, error in
            //this code is here for debugging
            //replace it with logging later
            if let data = data, !data.isEmpty {
                
                //convert the data to a port number UInt16
                let responseID = data[0]
                logger?.trace("\(tracker): response type is \(responseID) ?? 119")
                if data.count == 2{//error happened
                    let NPMDError = data[1]
                    logger?.error("\(tracker): NPMD error \(NPMDError) for \(remoteNodeName)")
                    guard let ultimatePid = ultimatePid else{
                        return
                    }
                    ultimatePid ! (tracker,NPMDError)
                    return
                }
                
                let port = data[2...3].toUInt16.toMachineByteOrder
                let nodeType = data[4]
                let msgProtocol = data[5]
                let highestVersion = data[6...7].toUInt16.toMachineByteOrder
                let lowestVersion = data[8...9].toUInt16.toMachineByteOrder
                let nameLength = Int(data[10...11].toUInt16.toMachineByteOrder)
                let nameEndIndex = 12+nameLength-1
                let nodeName = String(bytes: data[12...nameEndIndex], encoding: .utf8)
                let extrasLength = Int(data[nameEndIndex+1...nameEndIndex+2].toUInt16.toMachineByteOrder)
                var extras = Data()
                if extrasLength > 0{
                    extras = data[nameEndIndex+2...nameEndIndex+2+extrasLength]
                }
                logger?.trace("\(tracker): peer info converted")
                let peerInfo = PeerInfo(port: port,nodeType: nodeType,
                                        msgProtocol:msgProtocol,
                                        highestVersion: highestVersion,
                                        lowestVersion: lowestVersion,
                                        nodeName: nodeName ?? "not_parsable",
                                        extras: extras)
                "peerPorts" ! peerInfo
                guard let ultimatePid = ultimatePid else{
                    return
                }
                ultimatePid ! (tracker,peerInfo)
                
            }
            if let error = error {
                logger?.error("\(tracker): error \(error) for \(remoteNodeName)")
                return
            }
            if isDone {
                logger?.trace("\(tracker): EOF")//EPMD terminated
                stop(client: EPMD,tracker: tracker)
                return
            }
        }
    }
    _ = try
    spawn(name:EPMDRequest.port_please){(senderPID,message) in
        var finalPid:UUID? = nil
        let remoteNodeName:String
        if let (remoteName,ultimatePid) = message as? (String,UUID){
            finalPid = ultimatePid
            remoteNodeName = remoteName
        }
        else{
            remoteNodeName = message as! String
        }
        
        let protocolData = buildPortPleaseMessageUsing(nodeName: remoteNodeName)
        let tracker = UUID()
        logger?.trace("\(tracker): sending port_please request for \(remoteNodeName)")
        connection.send(content: protocolData, completion: NWConnection.SendCompletion.contentProcessed { error in
            guard let error = error else{
                logger?.trace("\(tracker): sent successfully")
                guard let finalPid = finalPid else{
                    "store_port" ! (tracker,remoteNodeName)//sending to next process
                    return
                }
                "store_port" ! (tracker,remoteNodeName,finalPid)
                return
            }
            logger?.error("\(tracker): send error \(error) for \(remoteNodeName)")
            stop(client:EPMD,tracker: tracker)
        })
    }
    
    //
    //Get all the registered names
    //
    _ = try spawn(name:"read_names"){(senderPID,message) in
        let (tracker,recieverPid) = message as! (UUID,Any)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _context, isDone, error in
            
            if let data = data, !data.isEmpty {
                
                //convert the data to a port number UInt16
                let dataPort = data[0...3].toUInt32
                logger?.trace("\(tracker): EPMD port is \(dataPort)")
                
                /*//this code here is only valid if the port sent by the EPMD service is a distinct port from which to do an additional read. This seems highly unlikely. Most likely, it is echoing the initial connection port for the EPMD service. The documentation is very unclear regarding this response from the service.
                guard let endPort = NWEndpoint.Port("\(dataPort)") else{
                    logger?.error("\(tracker): error \(dataPort) can not be converted to NWEndpoint")
                    return
                }
                let readConnection = NWConnection(host: host, port: endPort, using: .tcp)
                readConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { namesData, _context, namesAreDone, error in
                    if let namesData = namesData{
                        if let usablePid = recieverPid as? UUID{
                            usablePid ! String(data: namesData, encoding: .utf8) as Any
                        }
                        else if let usableName = recieverPid as? String{
                            usableName ! String(data: namesData, encoding: .utf8) as Any
                        }
                        else{
                            logger?.error("\(tracker): recieverPid  \(recieverPid) is must be either a string or a UUID")
                        }
                    }
                    if let error = error {
                        logger?.error("\(tracker): error \(error) reading names")
                        return
                    }
                    if isDone {
                        logger?.trace("\(tracker): EOF")//EPMD terminated
                        stop(client: EPMD,tracker: tracker)
                        return
                    }
                }
                 */
                
            }
            if let error = error {
                logger?.error("\(tracker): error \(error) reading names port")
                return
            }
            if isDone {
                logger?.trace("\(tracker): EOF")//EPMD terminated
                stop(client: EPMD, tracker: tracker)
                return
            }
        }
    }
    
    //the reciever pid is the process to which the read names
    //are to be sent as data
    _ = try
    spawn(name:EPMDRequest.names){(senderPID,recieverPid) in
        
        let protocolData = buildNamesMessage()
        let tracker = UUID()
        logger?.trace("\(tracker): sending names request")
        connection.send(content: protocolData, completion: NWConnection.SendCompletion.contentProcessed { error in
            guard let error = error else{
                logger?.trace("\(tracker): sent successfully")
                
                "read_names" ! (tracker,recieverPid)//sending to next process
                
                return
            }
            logger?.error("\(tracker): send error \(error)")
            stop(client:EPMD,tracker: tracker)
        })
    }
    
    //
    // Kill abruptly the EPMD Server. This is almost never used in practice.
    //
    _ = try
    spawn(name:EPMDRequest.kill){(senderPID,ultimatePid) in
        
        let protocolData = buildKillMessage()
        let tracker = UUID()
        logger?.trace("\(tracker): sending kill request ")
        connection.send(content: protocolData, completion: NWConnection.SendCompletion.contentProcessed { error in
            guard let error = error else{
                logger?.trace("\(tracker): sent successfully")
                
                "clear_buffer" ! (tracker,ultimatePid)//sending to next process
                
                return
            }
            logger?.error("\(tracker): error \(error) send error")
            stop(client:EPMD,tracker: tracker)
        })
    }
}




func buildRegistrationMessageUsing(nodeName:String,port:UInt16,extras:[Byte]) -> Data {
    let extrasLength = UInt16(extras.count)
    let nameBytes = [Byte](nodeName.utf8)
    let nameLength = UInt16(nameBytes.count)
    let nodePort = port.toMessageByteOrder.toByteArray
    let messageLength = extrasLength + nameLength + 13//13 is the size of all the other components of the message. The 'fixed size' components.
    let protcolBytes:[EPMDMessageComponent] = [messageLength.toMessageByteOrder.toByteArray,.EPMD_ALIVE2_REQ,nodePort,.NODE_TYPE,.TCP_IPv4,.HIGHEST_OTP_VERSION,.LOWEST_OTP_VERSION,nameLength.toMessageByteOrder.toByteArray,nameBytes,extrasLength.toMessageByteOrder.toByteArray,extras]
    var protocolData = Data(capacity: Int(messageLength))
    protocolData.writeAll(in: protcolBytes)
    return protocolData
}

func buildPortPleaseMessageUsing(nodeName:String)->Data{
    let nodePidBytes = [Byte](nodeName.utf8)
    let nodePidLength = UInt16(nodePidBytes.count)
    let messageLength = nodePidLength + UInt16(EPMDMessageComponent.PORT_PLEASE_REQ.count)
        
    let protcolBytes:[EPMDMessageComponent] = [messageLength.toMessageByteOrder.toByteArray,
        .PORT_PLEASE_REQ,nodePidBytes]
    var protocolData = Data(capacity: Int(messageLength+2))//the length of the message plus the two bytes for the length(2 bytes) that gets prepended to every request to the EPMD server.
    protocolData.writeAll(in: protcolBytes)
    return protocolData
}

func buildNamesMessage()->Data{
    let messageLength = UInt16(1).toMessageByteOrder.toByteArray
    let messageID:[Byte] = [110]
    let protocolBytes:[EPMDMessageComponent] = [messageLength,messageID]
    var protocolData = Data(capacity: 1+2)//the length(2 bytes) of the message plus the two bytes for the length that gets prepended to every request to the EPMD server.
    protocolData.writeAll(in: protocolBytes)
    return protocolData
}


func buildKillMessage()->Data{
    let messageLength = UInt16(1).toMessageByteOrder.toByteArray
    let messageID:[Byte] = [107]
    let protocolBytes:[EPMDMessageComponent] = [messageLength,messageID]
    var protocolData = Data(capacity: 1+2)//the length(2 bytes) of the message plus the two bytes for the length that gets prepended to every request to the EPMD server.
    protocolData.writeAll(in: protocolBytes)
    return protocolData
}



//startup the listener for the client
@available(macOS 10.14, *)
func start(client:EPMD){
    let tracker = UUID()
    logger?.trace("\(tracker): about to start EPMD")
    client.connection.start(queue: .global())
    logger?.trace("\(tracker): started EPMD")
}

///
///This function kills the client connection to the EPMD
///server. This causes the EPMD server to unregister the node.
@available(macOS 10.14, *)
func stop(client:EPMD, tracker:Any) {
    logger?.trace("\(tracker): about to stop")
    client.connection.cancel()
    logger?.trace("\(tracker): did stop")
}
