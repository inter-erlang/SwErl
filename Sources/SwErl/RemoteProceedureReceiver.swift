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


/// Represents the status of a network connection, including its capabilities, creation time, and the connection object itself.
///
/// The `Status` structure encapsulates details about a network connection, providing a straightforward way to access
/// its properties, such as the connection's capabilities bitmask, creation timestamp, and the `NWConnection` instance.
///
/// - Properties:
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
    let capabilities: UInt64
    let creation: UInt32
    let connection: NWConnection
}
/// Starts the SwErl remote proceedure receiver with a specific configuration, initiating the ability to accept connections.
///
/// This function configures and starts a node using the specified exchange protocol, name, cookie, and EPMD port.
/// It initializes necessary processes for handling handshake and connection management, and sets up a listener
/// for incoming network connections. The node's operation is logged using the provided `Logger` instance.
///
/// - Parameters:
///   - conduit: The network exchange protocol to use. Defaults to `.tcp`.
///   - name: The unique name of the node where the portion after the `@` symbol is resolvable via DNS.
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
func startReceiver(using conduit:ExchangeProtocol = .tcp, name:String, cookie:String, epmdPort:UInt16 = 4369, logger:Logger? = nil){
    do{
        guard let (_,creation) = ("creation_generator" ! true) as? (SwErlPassed,UInt32) else{//creation generator ignores any message sent
            logger?.error("Unable to get creation. Start terminated.")
            return
        }
        var shortName = ""
        if name.contains("@"){
            let parts = name.split(separator: "@")
            shortName = String(parts[0])
        }
        else{
            logger?.error("Invalid node name \(name)")
            return
        }
        "nameCreationTracker" ! (SafeDictCommand.add,shortName,creation)
        let connectionListener = try NWListener(using: conduit, on: .any)
        connectionListener.stateUpdateHandler = { newState in
            switch newState {
            case .ready:
                logger?.trace("Node \(shortName) changed state to \(newState)")
                guard let listingPortNum = connectionListener.port?.rawValue else{
                    logger?.error("Node \(shortName) in ready state without a port number.")
                    return
                }
                let localProtocol:UInt8 = conduit.usesTCP ? 0 : 1
                let alive = NodeAlive(portNumber: listingPortNum, nodeType: 77, comProtocol: localProtocol, highestVersion: 6, lowestVersion: 6, nodeName: SwErlAtom(shortName), extra: Data())
                
                let (success,_) = "nameNodeAliveTracker" ! (SafeDictCommand.add, shortName, alive)
                guard success == SwErlPassed.ok else{
                    logger?.error("Node \(shortName) unable to register alive \(alive). Stopping listening")
                    connectionListener.cancel()
                    return
                }
                
                logger?.trace("Node \(shortName) ready to accept connections on port \(listingPortNum) with cookie \(cookie) using \(conduit).")
            default:
                logger?.trace("Node \(shortName) in unrecognized state \(newState)")
                break
            }
        }
        //connections from other nodes handshake request
        connectionListener.newConnectionHandler = { connectionFromRemote in
            logger?.trace("Node \(shortName) got connection from \(connectionFromRemote.endpoint)")
            let uuid = UUID().uuidString
            connectionFromRemote.stateUpdateHandler = { aState in
                switch aState {
                case .ready:
                    logger?.trace("Client connected. Assigned UUID \(uuid) to node name \(shortName)")
                    
                case .failed(let error):
                    logger?.trace("connection \(uuid) connection failed: \(error)")
                    "atom_cache" ! (SafeDictCommand.remove,uuid)
                case .cancelled:
                    logger?.trace("connection \(uuid) connection cancelled.")
                default:
                    logger?.trace("connection \(uuid) connection in unrecognized state \(aState)")
                    break
                }
            }
            connectionFromRemote.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, context, _, error in
                logger?.trace("connection \(uuid) receiving data")
                guard var data = data, !data.isEmpty else{
                    logger?.error("connection \(uuid) received bad data. \(String(describing: data))")
                    return
                }
                logger?.trace("connection \(uuid) received \(Array(data)) data")
                if data.count >= 3 {
                    logger?.trace("connection \(uuid) did receive data: \(data.bytes)")
                    data = data.dropFirst(2)
                    let indicator = data.first!
                    logger?.trace("connection \(uuid) did receive indicator: \(indicator)")
                    switch indicator {
                    case 78://'N'
                        logger?.trace("connection \(uuid) did receive request type: \(indicator)")
                        doHandshake(uuid: uuid, localNodeName: name, cookie: cookie, data: data.dropFirst(), connection: connectionFromRemote, localCreation: creation, logger: logger)
                    default:
                        logger?.error("connection \(uuid) received incorrect initial handshake command \(indicator)")
                        return
                    }
                }//end of if got good data
                else {
                    logger?.error("connection \(uuid) received unknown request \(Array(data))")
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




func doHandshake(uuid:String,localNodeName:String, cookie:String,data:Data,connection:NWConnection,epmdPort:UInt16 = 4369,localCreation:UInt32,logger:Logger?){
    
    var localData = data
    logger?.trace("connection \(uuid) starting handshake")
    let capabilityFlags = localData.prefix(8).toMachineByteOrder.toUInt64
    localData = localData.dropFirst(8)
    let remoteCreation = data.prefix(4).toMachineByteOrder.toUInt32
    localData = localData.dropFirst(4)
    let nameLength = localData.prefix(2).toMachineByteOrder.toUInt16
    localData = localData.dropFirst(2)
    guard let remoteNodeName = String(bytes: localData.prefix(Int(nameLength)), encoding: .utf8) else {
        logger?.error("connection \(uuid) unable to convert \(localData.prefix(Int(nameLength))) to UTF8")
        return
    }
    let remoteStatus = Status(capabilities: capabilityFlags, creation: remoteCreation, connection: connection)
    //TODO: start this safe dictionary in the startNode function along with calling startReceiver
    "remoteStatusTracker" ! (SafeDictCommand.add,remoteNodeName,remoteStatus)
    guard var responseData = "ok".data(using: .utf8) else{
        return
    }
    responseData = Data([115]) ++ responseData
    let responseLength = UInt16(responseData.count).toErlangInterchangeByteOrder.toByteArray
    responseData = Data(responseLength) ++ responseData
    
    connection.send(content: responseData, completion: NWConnection.SendCompletion.contentProcessed { error in
        logger?.trace("connection \(uuid) status sent.")
        //now send a challenge
        let challenge = UInt32.random(in: UInt32.min...UInt32.max).bigEndian//is always big-endian
        
        let challengeDigest = "\(cookie)\(challenge)".MD5//MD5 hash coming back should be this.
        guard let localNameData = localNodeName.data(using: .utf8) else{
            logger?.error("connection \(uuid) unable to convert node name \(remoteNodeName) to utf8")
            return
        }
        //currently echoing back capability flags
        var challengeData = Data([78]) ++ Data(capabilityFlags.toErlangInterchangeByteOrder.toByteArray) ++ Data(challenge.toErlangInterchangeByteOrder.toByteArray) ++ Data(localCreation.toErlangInterchangeByteOrder.toByteArray) ++ Data(UInt16(localNameData/*shortName*/.count).toErlangInterchangeByteOrder.toByteArray) ++ localNameData
        challengeData = Data(UInt16(challengeData.count).toErlangInterchangeByteOrder.toByteArray) ++ challengeData
        logger?.trace("connection \(uuid) sending challenge \(Array(challengeData))")
        //send the challenge
        connection.send(content: challengeData, completion: NWConnection.SendCompletion.contentProcessed { error in
            logger?.trace("connection \(uuid) challenge sent.")
            
        })
        //when the connection is closed by the remote node, you get nil for  the incoming data.
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { challengeReplayData, _, _, error in
            logger?.trace("connection \(uuid) receiving data")
            guard var challengeReplyData = challengeReplayData/*, data.count < 21*/ else{
                logger?.error("connection \(uuid) received bad data. \(String(describing: challengeReplayData))")
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
                logger?.error("connection \(uuid) mismatched echo digest")
                return//let the remote time out
            }
            challengeReplyData = challengeReplyData.dropFirst(16)
            var challengeAck = Data([97]) ++ remoteNodeChallengeDigest
            challengeAck = Data(UInt16(challengeAck.count).toErlangInterchangeByteOrder.toByteArray) ++ challengeAck
            //send the final ack
            logger?.trace("connection \(uuid) sending ack: \(Array(challengeAck))")
            connection.send(content: challengeAck, completion: NWConnection.SendCompletion.contentProcessed { error in
                logger?.trace("connection \(uuid) challenge ack sent.")
//                connection.stateUpdateHandler = { newState in
//                    guard connection.state == NWConnection.State.ready else{//has not been cancled by the remote
//                        //remove from status storage dictionary
//                        return
//                    }
//                    //add to status storage dictionary, key is name of remote
//                }
                startRepeatingNetworkTask(interval: 15,connection:connection){//send a tick every fifteen seconds
                    connection.send(content: Data([0,0,0]), completion: .contentProcessed { error in
                        if let error = error {
                            logger?.error("\(uuid) failed to send tick: \(error)")
                        } else {
                            logger?.trace("\(uuid) sent tick")
                        }
                    })
                    return
                }
                startRepeatingNetworkTask(interval: 60, connection: connection){//check for in or out activity every 60 seconds
                    logger?.trace("\(uuid) checking in/out activity")
                    guard case let (SwErlPassed.ok,last) = "activity_cache" ! (SafeDictCommand.get, uuid), let last = last as? Date else{
                        logger?.error("\(uuid) missing its activity cache")
                        return
                    }
                    if Date().timeIntervalSince(last) >= 60{
                        logger?.trace("\(uuid) cancelling due to inactivity")
                        connection.cancel()
                    }
                }
                doRPCResponse(uuid:uuid, connection:connection, status:remoteStatus, logger: logger)
            })
        }
    })
}

fileprivate func doRPCResponse(uuid:String, connection:NWConnection, status:Status,logger:Logger? = nil) {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, error in
        guard let data = data, data.count >= 3 else{
            logger?.trace("connection \(uuid) got invalid waitForData data: \(String(describing: data))")
            connection.cancel()
            return
        }
        logger?.trace("connection \(uuid) request data \(Array(data))")
        
        //the message may be a 'is_alive' message consisting of 4 bytes that are all zeros. If so, short circut any further computation.
        guard data.count != 4,data.prefix(4) != Data([0,0,0,0]) else{
            return
        }
        
        let currentCacheDate = Date()
        "activity_cache" ! (SafeDictCommand.add, uuid, currentCacheDate)
        logger?.trace("\(uuid) updated activity cache with \(currentCacheDate)")
        
        readDistributionMessage(connection: connection, message: data, uuid: uuid, logger: logger)
        
        //        guard var (atomCacheRefs,flags,remainingData) = decodeDistributionHeader(data: data, uuid: uuid, connection: connection, status: status, logger: logger) else{
        //            logger?.trace("connection \(uuid) unable to read distribution header.")
        //            doRPCResponse(uuid: uuid, connection: connection, status: status, logger:logger)//call again on failure
        //            return
        //        }
        
        
        
        //        switch indicator {
        //
        //            //call handler function(s) for that type
        //        }
        
        
        doRPCResponse(uuid:uuid, connection: connection, status: status, logger: logger)//recursively call this function. stack overflow problem?
    }
}

fileprivate func readDistributionMessage(connection:NWConnection, message:Data, uuid:String, logger:Logger?){
    guard message.count > 4 else{
        return
    }
    let messageLength = message.prefix(4).toMachineByteOrder.toUInt32
    logger?.trace("\(uuid) reading \(messageLength) bytes as message")
    var remainingMessage = message.dropFirst(4)
    guard let termIndicator = remainingMessage.first, termIndicator == 131 else{
        logger?.error("connection \(uuid) bad message")
        return
    }
    logger?.trace("\(uuid) got term indicator \(termIndicator)")
    remainingMessage = remainingMessage.dropFirst()
    guard let normalSplitIndicator = DistHeaderType(rawValue: remainingMessage.first ?? 100) else{
        logger?.error("connection \(uuid) bad message type indicator")
        return
    }
    logger?.trace("\(uuid) normal/split message indicator is \(normalSplitIndicator)")
    remainingMessage = remainingMessage.dropFirst()
    switch normalSplitIndicator {
    case DistHeaderType.normal:
        readNormalMessage(connection:connection,message:remainingMessage, ofLength: Int(messageLength), uuid:uuid, logger:logger)
    case DistHeaderType.fragmented:
        logger?.trace("\(uuid) not yet implemented")
    case DistHeaderType.compressed:
        logger?.trace("\(uuid) not yet implemented")
    }
    
}

fileprivate func readNormalMessage(connection:NWConnection, message:Data, ofLength:Int, uuid:String, logger:Logger?){
    // Retrieve and decompose the response into success and pairAtomCache
    logger?.trace("\(uuid) reading \(Array(message)) as normal message")
    var (success,pairAtomCache) = "atom_cache" ! (SafeDictCommand.get,uuid) as? (SwErlPassed,NodePairAtomCache) ?? (SwErlPassed.fail,NodePairAtomCache())
    if success == SwErlPassed.fail {
        logger?.trace("\(uuid) creating atom cache for connection")
        // Initialize a new atom cache if the retrieval failed
        pairAtomCache = NodePairAtomCache()
        logger?.trace("\(uuid) adding empty atom cache for connection")
        // Add the new atom cache to "atom_cache"
        "atom_cache" ! (SafeDictCommand.add, uuid, pairAtomCache)
    }
    var messageCount = ofLength
    guard var numAtomCacheRefs = message.first else{
        logger?.error("\(uuid) no atom cache refs in control message")
        return
    }
    logger?.trace("\(uuid) number of atom cache refs \(numAtomCacheRefs)")
    var remainingMessage = message.dropFirst()
    messageCount = messageCount - 1
    guard remainingMessage.count > 0 else{
        return
    }
    if numAtomCacheRefs > 0{
        let flagByteCount = Int(numAtomCacheRefs/2 + 1)
        let flagBytes = remainingMessage.prefix(flagByteCount)
        //print("flagBytes: \(flagBytes.bytes)")
        remainingMessage.removeFirst(flagByteCount)
        messageCount = messageCount - flagByteCount
        var flagList = Array(flagBytes.map{getNibbles(from:$0)}.joined())
        logger?.trace("\(uuid) atom flags: \(flagList)")
        var usesLongAtoms = false
        if numAtomCacheRefs % 2 == 0 && flagList.last != 0{
            logger?.trace("\(uuid) uses long atoms")
            usesLongAtoms = true
            flagList.removeLast(2)//get rid of the long atoms flags so they aren't misinterpreted as cache entry/segment index nibbles.
        }
        else if flagList[flagList.count - 2] != 0{//odd count
            logger?.trace("\(uuid) uses long atoms")
            usesLongAtoms = true
            flagList.remove(at: flagList.count - 2)//get rid of the long atoms flag so it isn't misinterpreted as a cache entry/segment index nibble.
        }
        //decode the flags
        // TODO: this flag decoding is being done wrong. It yeilds the wrong existing cache ref count
        let (existingCacheRefCount,_) = flagList.reduce((UInt8(0),[UInt8]())){accum, flag in
            var (existingAccum,indexAccum) = accum
            let isNewCacheEntry = (flag & 0b1000) == 0b1000
            let segmentIndex = flag & 0b111
            if isNewCacheEntry == false{
                logger?.trace("\(uuid) \(flag) indicates cached entry")
                existingAccum = existingAccum + 1
            }
            indexAccum.append(segmentIndex)
            return (existingAccum,indexAccum)
        }
        logger?.trace("\(uuid) existing cached refs count \(existingCacheRefCount)")
        //ignore the existing atom cache refs we can look them up later anyway.
        remainingMessage.removeFirst(Int(existingCacheRefCount))
        logger?.trace("\(uuid) ignoring existing cached atoms \(Array(remainingMessage.prefix(Int(existingCacheRefCount))))")
        numAtomCacheRefs = numAtomCacheRefs - existingCacheRefCount
        remainingMessage = updateAtomCache(message: remainingMessage, cacheRefCount: numAtomCacheRefs, pairAtomCache: pairAtomCache as! NodePairAtomCache, longAtoms: usesLongAtoms, uuid: uuid, logger: logger)
        logger?.trace("\(uuid) decoding \(Array(remainingMessage)) as control message")
        guard let ((controlData,controlType),remainingMessage) = decodeControlMessage(data: remainingMessage, uuid: uuid, logger: logger) as? ((Any,UInt8),Data) else{
            logger?.error("connection \(uuid) bad control message in rpc request")
            return
        }
        guard !remainingMessage.isEmpty && remainingMessage.firstByte == 140 else{
            logger?.info("connection \(uuid) has no message payload after control message")
            return
        }
        guard var (payloadData,remainingMessage) = consumeExternal(rep: remainingMessage) else{
            logger?.info("connection \(uuid) has bad message payload after control message")
            return
        }
        
        //act on request
        switch controlType {
        case ERL.REG_SEND:
            guard let (remotePid,remoteName) = controlData as? (Pid,String) else{
                logger?.info("connection \(uuid) has bad control message data")
                return
            }
            guard let (pid,atomCacheRef) = payloadData as? (Pid,UInt8) else{
                logger?.info("connection \(uuid) has bad message payload data")
                return
            }
            let (found,name) = "atom_cache" ! (SafeDictCommand.get,atomCacheRef)
            guard found == SwErlPassed.ok, let name = name as? String else{
                logger?.info("connection \(uuid) has bad atom in message payload")
                return
            }
            "connection_cache" ! (SafeDictCommand.add, name, connection)//store the connection so the name can be used in SwErl code to send an rpc request to the node via the long-lived connection
            // MARK: Update of Connection State Handler
            //update the state listener for the connection so the connection can be appropriately removed from the connection_cache.
            connection.stateUpdateHandler = { aState in
                switch aState {
                case .ready:
                    logger?.trace("Client connected. Assigned UUID \(uuid) to node name \(name)")
                    
                case .failed(let error):
                    logger?.trace("connection \(uuid) connection failed: \(error)")
                    "atom_cache" ! (SafeDictCommand.remove,uuid)
                    "connection_cache" ! (SafeDictCommand.remove, name)
                    connection.cancel()
                case .cancelled:
                    logger?.trace("connection \(uuid) connection cancelled.")
                    "atom_cache" ! (SafeDictCommand.remove,uuid)
                    "connection_cache" ! (SafeDictCommand.remove, name)
                    
                    //remove the cached values for the 60 second activity limit timer for this connection.
                    guard case let (SwErlPassed.ok, trackers) = "tick_activity_timer_cache" ! (SafeDictCommand.get, uuid), let (tickTracker,activityTracker) = trackers as? (DispatchSourceTimer,DispatchSourceTimer) else{
                        logger?.error("\(uuid) unable to find activity and tick tracker. Activity tracker and timer not removed from caches.")
                        return
                    }
                    tickTracker.cancel()
                    activityTracker.cancel()
                    "tick_activity_timer_cache" ! (SafeDictCommand.remove, uuid)
                default:
                    logger?.trace("connection \(uuid) connection in unrecognized state \(aState)")
                    break
                }
            }
            
            //respond to request using data provided
        default:
            //do something
            logger?.error("\(uuid) request contained bad control type indicator \(controlType)")
        }
        
        //act on control message
        
        
        
        
        if remainingMessage.count > 0{
            readDistributionMessage(connection: connection, message: remainingMessage, uuid: uuid, logger: logger)
        }
    }
    
    
    
    
    
    readDistributionMessage(connection: connection, message: remainingMessage, uuid: uuid, logger: logger)
}

//        let internalSegmentIndex = remainingMessage.firstByte
//        remainingMessage = remainingMessage.dropFirst()
//        messageCount = messageCount - 1
//        let atomCharacterCount = Int(remainingMessage.firstByte)*atomCharacterLength
//        remainingMessage = remainingMessage.dropFirst()
//        messageCount = messageCount - 1
//        guard let atom = String(bytes: remainingMessage.prefix(atomCharacterCount), encoding: .utf8) else {
//            logger?.error("\(uuid) unable to convert \(remainingMessage.prefix(atomCharacterCount)) to UTF8")
//            return
//        }
//        remainingMessage = remainingMessage.dropFirst(atomCharacterCount)
//        messageCount = messageCount - atomCharacterCount
//        if isNewCacheEntry{
//            //put it in the atom cache
//            tempCache[AtomLocation(segmentIndex,internalSegmentIndex)] = atom
//            print("tempCache: \(tempCache)")
//        }
//    }
//}

func updateAtomCache(message:Data, cacheRefCount:UInt8, pairAtomCache:NodePairAtomCache, longAtoms:Bool, uuid:String, logger:Logger?)->Data{
    var localMessage = message
    logger?.trace("\(uuid) caching \(cacheRefCount) atoms")
    for _ in 0..<cacheRefCount{
        let cacheRef = localMessage.firstByte
        localMessage.removeFirst()
        let atomCharacterCount = localMessage.firstByte
        localMessage.removeFirst()
        guard let atomString = String(data:localMessage.prefix(Int(atomCharacterCount)), encoding: .utf8) else{
            logger?.error("connection \(uuid) failed to convert \(localMessage.prefix(Int(atomCharacterCount))) to an atom string")
            continue
        }
        localMessage.removeFirst(Int(atomCharacterCount))
        logger?.trace("\(uuid) caching atom \(atomString)")
        "atom_cache" ! (SafeDictCommand.add,cacheRef,SwErlAtom(atomString,cacheRef))
    }
    return localMessage
}

func getNibbles(from byte: UInt8) -> [UInt8] {
    let upperNibble = byte >> 4
    let lowerNibble = byte & 0x0F
    return [upperNibble, lowerNibble]
}

fileprivate func decodeDistributionHeader(data:Data, uuid:String, connection:NWConnection, status:Status, logger:Logger?)->([AtomCacheRefIndex],[Byte],Data)?{
    guard let headerIndicator = data.first, headerIndicator == 131 else{
        logger?.error("connection \(uuid) bad distribution header")
        return nil
    }
    var localData = data.dropFirst()
    guard let distributionTypeIndicator:UInt8 = data.first else{
        logger?.error("connection \(uuid) missing header type")
        return nil
    }
    localData = localData.dropFirst()
    switch DistHeaderType(rawValue: distributionTypeIndicator){
    case .normal:
        guard let numAtomCacheRefs = data.first else{
            return nil
        }
        localData = localData.dropFirst()
        if numAtomCacheRefs == 0{
            return ([UInt8](),[UInt8](),localData)
        }
        logger?.trace("connection \(uuid) num atom cache references \(numAtomCacheRefs)")
        
        let flagByteCount = Int(numAtomCacheRefs/2+1)
        let flags = data.prefix(flagByteCount).bytes
        localData = localData.dropFirst(flagByteCount)
        
        print("after drop flags request data \(Array(localData))")
        
        let cacheRefIndexes = localData.prefix(Int(numAtomCacheRefs)).bytes
        return (cacheRefIndexes,flags,localData.dropFirst(Int(numAtomCacheRefs)))
    case .fragmented:
        return nil
    case .compressed:
        return nil
    default:
        return nil
    }
    return nil
}

func decodeControlMessage(data: Data, uuid: String, logger: Logger?)->((Any,UInt8)?,Data){
    guard data.firstByte == 104 else {//the control message must always be an encoded tuple according to the documentation.
        logger?.error("\(uuid) bad control message expected 104 got \(data.firstByte)")
        return (nil,data)
    }
    var remainingData = data.dropFirst()
    let controlArity = remainingData.firstByte
    remainingData.removeFirst()//the arity of the control tuple is not needed in this code
    guard remainingData.firstByte == 97 else{//the first element of the tuple must be of type small_int
        logger?.error("\(uuid) bad control message expected 97 got \(remainingData.firstByte)")
        return (nil,data)
    }
    remainingData.removeFirst()
    for _ in 0..<controlArity{
        let operationType = remainingData.firstByte
        remainingData.removeFirst()
        switch operationType {
        case ERL.LINK:
            //the next two items are FromPid and ToPid
            return (nil,remainingData)//place holder code
        case ERL.SEND:
            //the next two items are Unused and ToPid
            return (nil,remainingData)//place holder code
        case ERL.EXIT:
            //the next three items are FromPid, ToPid, and Reason
            return (nil,remainingData)//place holder code
            //case ERL.UNLINK://(Obsolete)
        case ERL.NODE_LINK:
            return ((5,ERL.NODE_LINK),remainingData)
        case ERL.REG_SEND:
            //the next three items are FromPid, Unused, and ToName
            guard let result = remainingData.fromNewPidExt else{
                logger?.error("\(uuid) unable to generate pid from \(remainingData)")
                return (nil,remainingData)
            }
            return ((result,ERL.REG_SEND),remainingData)
        case ERL.GROUP_LEADER:
            //the next two items are FromPid and ToPid
            return (nil,remainingData)//place holder code
        case ERL.EXIT2:
            //the next two items are FromPid and ToPid
            return (nil,remainingData)//place holder code
        case ERL.SEND_TT:
            //the next three items are Unused, ToPid, TraceToken
            return (nil,remainingData)//place holder code
        case ERL.EXIT_TT:
            //the next four items are FromPid, ToPid, TraceToken, and Reason
            return (nil,remainingData)//place holder code
        case ERL.REG_SEND_TT:
            //the next four items are FromPid, Unused, ToName, and TraceToken
            return (nil,remainingData)//place holder code
        case ERL.EXIT2_TT:
            //the next four items are FromPid, ToPid, TraceToken, Reason
            return (nil,remainingData)//place holder code
        case ERL.MONITOR_P:
            //the next three items are FromPid, ToProc, Ref
            return (nil,remainingData)//place holder code
        case ERL.DEMONITOR_P:
            //the next three items are FromPid, ToProc, Ref
            return (nil,remainingData)//place holder code
        case ERL.MONITOR_P_EXIT:
            //the next four items are FromProc, ToPid, Ref, Reason
            return (nil,remainingData)//place holder code
        case ERL.SEND_SENDER:
            //the next two items are FromPId, ToPid
            return (nil,remainingData)//place holder code
        case ERL.SEND_SENDER_TT:
            //the next three items are FromPid, ToPid, TraceToken
            return (nil,remainingData)//place holder code
        case ERL.PAYLOAD_EXIT:
            //the next two items are FromPid, ToPid
            return (nil,remainingData)//place holder code
        case ERL.PAYLOAD_EXIT_TT:
            //the next three items are FromPid, ToPid, TraceToken
            return (nil,remainingData)//place holder code
        case ERL.PAYLOAD_EXIT2:
            //the next two items are FromPid, ToPid
            return (nil,remainingData)//place holder code
        case ERL.PAYLOAD_EXIT2_TT:
            //the next three items are FromPid, ToPid, TraceToken
            return (nil,remainingData)//place holder code
        case ERL.PAYLOAD_MONITOR_P_EXIT:
            //the next three items are FromProc, ToPid, Ref
            return (nil,remainingData)//place holder code
        case ERL.SPAWN_REQUEST:
            //the next five items are ReqId, From, GroupLeader, {Module, Function, Arity}, OptList
            return (nil,remainingData)//place holder code
        case ERL.SPAWN_REQUEST_TT:
            //the next six items are ReqId, From, GroupLeader, {Module, Function, Arity}, OptList, TraceToken
            return (nil,remainingData)//place holder code
        case ERL.SPAWN_REPLY:
            //the next four items are ReqId, To, Flags, Result
            return (nil,remainingData)//place holder code
        case ERL.SPAWN_REPLY_TT:
            //the next five items are ReqId, To, Flags, Result, TraceToken
            return (nil,remainingData)//place holder code
        case ERL.UNLINK_ID:
            //the next three items are Id, FromPid, ToPid
            return (nil,remainingData)//place holder code
        case ERL.UNLINK_ID_ACK:
            //the next three items are Id, FromPid, ToPid
            return (nil,remainingData)//place holder code
        case ERL.ALIAS_SEND:
            //the next two items are FromPid, Alias
            return (nil,remainingData)//place holder code
        case ERL.ALIAS_SEND_TT:
            //the next three items are FromPid, Alias, TraceToken
            return (nil,remainingData)//place holder code
        default:
            logger?.error("Unknown Control Message Type \(operationType)")
            return (nil,remainingData)
        }
    }
    return (nil,data)
}

//func doHandshake(uuid:String,localNodeName:String, cookie:String,data:Data,connection:NWConnection,epmdPort:UInt16 = 4369,creation:UInt32,logger:Logger?) {
//    let uuid = UUID().uuidString
//
//    //TODO: check to see if there is already a connection to the node. If there is, stop.
//    //connect to EPMD and find out the port the node is listening on.
//    let parts = node.split(separator: "@")
//    var hostName = "127.0.0.1"
//    if parts.count == 2{
//        hostName = String(parts[1])
//    }
//
//    let shortName:String = String(parts[0])
//    guard let shortNameData = shortName.data(using: .utf8) else{
//        return
//    }
//    logger?.trace("connection \(uuid) initializing handshake with node \(shortName)@\(hostName)")
//    var PORT_PLEASE2_Data = Data([122]) ++ shortNameData
//    PORT_PLEASE2_Data = Data(UInt16(PORT_PLEASE2_Data.count).toErlangInterchangeByteOrder.toByteArray) ++ PORT_PLEASE2_Data
//
//    let host = NWEndpoint.Host(hostName)
//    let port = NWEndpoint.Port(rawValue: epmdPort)!
//
//    // Create the connection
//    logger?.trace("connection \(uuid) connecting to \(host):\(port)")
//    let epmdConnection = NWConnection(host: host, port: port, using: .tcp)
//
//
//    // Start the connection
//    epmdConnection.start(queue: .global())
//
//    logger?.trace("connection \(uuid) sending port please data \(Array(PORT_PLEASE2_Data))")
//    //send the data array
//    epmdConnection.send(content: PORT_PLEASE2_Data, completion: .contentProcessed({ error in
//        if let error = error {
//            logger?.error("connection \(uuid) failed to send data: \(error)")
//            epmdConnection.cancel()
//        } else {
//            logger?.trace("connection \(uuid) port please message was sent.")
//            epmdConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
//                if var data = data, !data.isEmpty {
//                    logger?.trace("connection \(uuid) received response: \(Array(data))")
//                    guard data.first == 119 else{
//                        logger?.error("connection \(uuid) bad epmd response indicator")
//                        return
//                    }
//                    data = data.dropFirst()
//                    guard data.first == 0 else{
//                        logger?.error("connection \(uuid) failed")
//                        return
//                    }
//                    data = data.dropFirst()
//                    let portNum = data.prefix(2).toMachineByteOrder.toUInt16
//                    //all we care about, at this point in time, is the port number.
//                    logger?.trace("connection \(uuid) closing EPMD Connection")
//                    epmdConnection.cancel() // Close the EPMD connection
//                    //connect to the Node.
//                    logger?.trace("connection \(uuid) connecting to \(host) on port \(portNum)")
//                    let nodePort = NWEndpoint.Port(rawValue: portNum)!
//
//                    // Create the connection
//                    let nodeConnection = NWConnection(host: host, port: nodePort, using: .tcp)
//
//                    //use a made up creation number. see if it works.
//                    var sendNameData = Data(UInt32(123456).toErlangInterchangeByteOrder.toByteArray)
//                    guard let nameData =  localNodeName.data(using: .utf8) else{
//                        logger?.error("connection \(uuid) bad node name \(node)")
//                        return
//                    }
//                    sendNameData = Data([78]) ++ Data(DIST_MANDATORY.toErlangInterchangeByteOrder.toByteArray) ++ sendNameData ++ Data(UInt16(nameData.count).toErlangInterchangeByteOrder.toByteArray) ++ nameData
//                    sendNameData = Data(UInt16(sendNameData.count).toErlangInterchangeByteOrder.toByteArray) ++ sendNameData
//
//                    let nameDataToSend = sendNameData
//                    nodeConnection.start(queue: .global())
//                    nodeConnection.send(content: nameDataToSend, completion: .contentProcessed({ error in
//                        if let error = error {
//                            logger?.error("connection \(uuid) failed to send data: \(error)")
//                            nodeConnection.cancel()
//                            return
//                        } else {
//                            logger?.trace("connection \(uuid) sent \(Array(nameDataToSend)).")
//                            nodeConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
//                                guard var statusData = data, !statusData.isEmpty else{
//                                    logger?.error("connection \(uuid) got bad status data \(String(describing: data))")
//                                    return
//                                }
//                                logger?.trace("connection \(uuid) received status response: \(Array(statusData))")
//                                statusData = statusData.dropFirst(2)
//                                let indicator = statusData.first
//                                guard indicator == 115 else{
//                                    logger?.error("connection \(uuid) got bad status indicator \(String(describing: indicator))")
//                                    return
//                                }
//                                statusData = statusData.dropFirst()
//                                guard let status = String(data: statusData, encoding: .utf8),status == "ok" || status == "ok_simultaneous" else{
//                                    logger?.trace("connection \(uuid) handshake not ok to continue")
//                                    return
//                                }
//                                // read the incoming challenge
//                                nodeConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
//                                    if var challengeData = data, !challengeData.isEmpty {
//                                        logger?.trace("connection \(uuid) received response: \(Array(challengeData))")
//                                        challengeData = challengeData.dropFirst(2)
//                                        guard challengeData.first == 78 else{
//                                            logger?.error("connection \(uuid) bad challenge  indicator \(challengeData.first)")
//                                            return
//                                        }
//                                        challengeData = challengeData.dropFirst()
//                                        let flags = challengeData.prefix(8).toMachineByteOrder.toUInt64
//                                        challengeData = challengeData.dropFirst(8)
//                                        let remoteChallenge = challengeData.prefix(4).toMachineByteOrder.toUInt32
//
//                                        challengeData = challengeData.dropFirst(4)
//                                        let creation = challengeData.prefix(4).toMachineByteOrder.toUInt32
//                                        challengeData = challengeData.dropFirst(4)
//                                        let nameLength = challengeData.prefix(2).toMachineByteOrder.toUInt16
//                                        challengeData = challengeData.dropFirst(2)
//                                        let remoteName = String(data: challengeData, encoding: .utf8)
//                                        //send back the digest and another challenge
//                                        let remoteChallengeDigest = "\(cookie)\(remoteChallenge)".MD5
//                                        let blah = "\(remoteChallenge)\(cookie)".MD5
//                                        let blif = "\(remoteChallenge.byteSwapped)\(cookie)".MD5
//                                        let blew = "\(cookie)\(remoteChallenge.byteSwapped)".MD5
//
//                                        print("all: \(remoteChallengeDigest)\n\(blah)\n\(blif)\n\(blew)")
//
//
//                                        logger?.trace("connection \(uuid) digest for remote challenge created using: \(cookie)\(remoteChallenge) digest: \(remoteChallengeDigest)")
//                                        let challengeData = Data(UInt32.random(in: UInt32.min...UInt32.max).toErlangInterchangeByteOrder.toByteArray)
//                                        var challengeReplyData = Data([114]) ++ challengeData ++ remoteChallengeDigest
//                                        challengeReplyData = Data(UInt16(challengeReplyData.count).toErlangInterchangeByteOrder.toByteArray) ++ challengeReplyData
//                                        logger?.trace("connection \(uuid) sending challenge reply \(Array(challengeReplyData))")
//                                        nodeConnection.send(content: challengeData, completion: .contentProcessed({ error in
//                                            if let error = error {
//                                                logger?.error("connection \(uuid) failed to send data: \(error)")
//                                                nodeConnection.cancel()
//                                                return
//                                            }
//
//                                            logger?.trace("connection \(uuid) \(node) sent challenge \(remoteChallenge) and creation \(creation) waiting for challenge ack")
//                                            nodeConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
//                                                let blah = 1+1
//                                                guard var data = data else{
//                                                    logger?.error("connection \(uuid) faild to receive challenge ack")
//                                                    return
//                                                }
//                                                logger?.trace("connection \(uuid) received challenge ack \(Array(data))")
//                                            }
//
//
//                                        }))
//
//                                    }
//                                }//end of receive challenge
//                            }
//                        }
//                    })
//                    )//end of nodeConnection send
//                }
//
//            }//end of connection receive
//        }
//    })
//    )
//}
