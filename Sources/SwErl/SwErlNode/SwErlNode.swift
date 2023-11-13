//
//  SwErlNode.swift
//
//Copyright (c) 2022 Lee Barney
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
//
//  Created by Lee Barney on 3/3/22.
//

import Foundation
import Network
import Logging

var logger:Logger? = nil

public enum NodeRequest{
    static let handshake = "handshake"
}
public enum SwErlConnection{
    case keep
    case drop
    case store
    case get
}

public enum ConStatus{
    case ok
    case ok_simultaneous
    case nok
    case not_allowed
    case alive
    case named
}

//@available(macOS 10.14, *)
public typealias RemoteNodeDescription = (capabilityFlags:UInt64,cookie:String,
                                     connection:NWConnection)


//@available(macOS 10.14, *)
public typealias SwErlNode = (selfPort:NWEndpoint.Port,
                              selfHost:NWEndpoint.Host, listener:NWListener, nodeName:String, outCookie:String)



/*
 //@available(macOS 10.15, *)
 func spawnProcessesFor(node:SwErlNode)throws {
 ///
 ///The node connection process is a stateful process where
 ///the state is a dictionary with the key being the name of
 ///the peer node and the value is the TCP connection to the node
 ///
 _ = try spawn(name: "nodeConnections", initialState: Dictionary<String,RemoteNodeDescription>()){(pid,state,message) in
 
 var updateState = state as! Dictionary<String,RemoteNodeDescription>
 if let (tracker,command,name,description) = message as? (UUID,SwErlConnection,String,RemoteNodeDescription){
 switch command{
 case .store:
 updateState[name] = description
 logger?.trace("\(tracker): stored node description for \(name)")
 case .drop:
 updateState.removeValue(forKey: name)
 logger?.trace("\(tracker): dropped connection for \(name)")
 default:
 logger?.error("\(tracker): incorrect command \(command)")
 }
 }
 else if let (tracker,command,name,nextPid) = message as? (UUID,SwErlConnection,String,UUID){
 switch command{
 case .get:
 nextPid ! updateState[name] as Any
 default:
 logger?.error("\(tracker): incorrect command \(command)")
 
 }
 }
 else{
 logger?.error("unknown message \(message)")
 }
 return updateState
 }
 //
 //Initializes a handshale request with another Erlang node
 //
 _ = try spawn(name: "startHandshake"){(pid,message) in
 if let (tracker, node, connection, remoteCookie, ultimatePid) = message as? (UUID,SwErlNode,NWConnection,String,UUID){
 logger?.trace("\(tracker): starting handshake")
 let nameMessage = buildNameMessage(requester:node)
 connection.send(content: nameMessage, completion: NWConnection.SendCompletion.contentProcessed { error in
 guard let error = error else{
 logger?.trace("\(tracker): sent successfully")
 
 //change this to send to the process that handles the incoming request instead of clearing the buffer.
 "recieve_status" ! (tracker, node, connection, remoteCookie, ultimatePid)//sending to next process
 
 return
 }
 logger?.error("\(tracker): error \(error) send error")
 connection.cancel()
 logger?.error("\(tracker): connection closed")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 })
 NSLog("\(tracker): sent register_node request ")
 }
 else{
 logger?.error("unknown message \(message)")
 }
 }
 
 _ = try spawn(name: "recieve_status"){(pid,message) in
 if let (tracker, node, connection, remoteCookie, ultimatePid) = message as? (UUID,SwErlNode,NWConnection,String,UUID){
 logger?.trace("\(tracker): recieved connection for status communication")
 connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _context, isDone, error in
 guard let error = error else{
 logger?.trace("\(tracker): received message")
 if let data = data, !data.isEmpty {
 let statusMessageLength = data[0...1].toUInt16.toMachineByteOrder
 guard case data[2] = UInt8(115) else {// not an 's' character
 logger?.trace("\(tracker): message is not a status message. Message type: \(Character(UnicodeScalar(data[2]))))")
 connection.cancel()
 logger?.trace("\(tracker): connection attempt canceled")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 return
 
 }
 logger?.trace("\(tracker): message is a status message")
 switch statusMessageLength {
 case 2://ok
 //continue with handshake
 logger?.trace("\(tracker): connection allowed")
 "receiveChallenge" ! (tracker, node, connection, remoteCookie, ultimatePid)
 case 15://ok_simultaneous
 logger?.trace("\(tracker): connection continuing. There is another connection request that will be canceled.")
 //contiue with handshake
 "receiveChallenge" ! (tracker, node, connection, remoteCookie, ultimatePid)
 case 3://nok
 logger?.trace("\(tracker): connection not allowed")
 connection.cancel()
 logger?.trace("\(tracker): connection canceled")
 ultimatePid ! (tracker, node, ConStatus.nok)
 case 11://not_allowed
 logger?.trace("\(tracker): connection not allowed")
 connection.cancel()
 logger?.trace("\(tracker): connection canceled")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 //
 //These two cases still need to be completed
 //
 case 5://alive
 logger?.trace("\(tracker): apparent existing connection")
 ultimatePid ! (tracker, node, ConStatus.alive)
 default:
 logger?.trace("\(tracker): unknown status received")
 }
 }
 return
 }
 logger?.error("\(tracker): error \(error) send error")
 connection.cancel()
 logger?.error("\(tracker): connection closed")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 }
 
 }
 else{
 logger?.error("unknown message \(message)")
 }
 }
 
 _ = try spawn(name: "receiveChallenge"){(pid,message) in
 if let (tracker, node, connection, remoteCookie, ultimatePid) = message as? (UUID,SwErlNode,NWConnection,String,UUID){
 logger?.trace("\(tracker): recieved connection for status communication")
 connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _context, isDone, error in
 guard let error = error else{
 logger?.trace("\(tracker): received message")
 if let data = data, !data.isEmpty {
 _ = data[0...1].toUInt16.toMachineByteOrder
 guard case data[2] = UInt8(78) else {// not an 'N' character
 logger?.trace("\(tracker): message is not a challenge message. Message type: \(Character(UnicodeScalar(data[2])))")
 connection.cancel()
 logger?.trace("\(tracker): connection attempt canceled")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 return
 
 }
 logger?.trace("\(tracker): message is a challenge message")
 let capabilityFlags = data[3...10].toUInt64.toMachineByteOrder
 let challenge = data[11...14].toUInt32.toMachineByteOrder
 let creation = data[15...18].toUInt32.toMachineByteOrder
 let remoteNameLength = data[19...20].toUInt16.toMachineByteOrder
 let remoteName = String(decoding: data[21...(20+remoteNameLength)], as: UTF8.self)
 
 "sendChallengeReply" ! (tracker, node, connection, remoteCookie,  ultimatePid,(capabilityFlags,challenge,creation,remoteName))
 }
 return
 }
 logger?.error("\(tracker): error \(error) send error")
 connection.cancel()
 logger?.error("\(tracker): connection closed")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 }
 
 }
 else{
 logger?.error("unknown message \(message)")
 }
 }
 //
 //Sends a response to a received challenge
 //
 _ = try spawn(name: "sendChallengeReply"){(pid,message) in
 if let (tracker, node, connection, remoteCookie, ultimatePid,(capabilityFlags,challenge,creation,remoteName)) = message as? (UUID,SwErlNode,NWConnection,String,UUID,(UInt64,UInt32,UInt32,String)){
 logger?.trace("\(tracker): starting handshake")
 let (replyMessage,localChallenge) = buildChallengeReplyMessage(challenge: challenge, remoteCookie: remoteCookie)
 connection.send(content: replyMessage, completion: NWConnection.SendCompletion.contentProcessed { error in
 guard let error = error else{
 logger?.trace("\(tracker): sent successfully")
 
 //change this to send to the process that handles the incoming request instead of clearing the buffer.
 "recieve_challenge_ack" ! (tracker, node, connection, ultimatePid,(capabilityFlags,localChallenge,creation,remoteName,remoteCookie))//sending to next process
 
 return
 }
 logger?.error("\(tracker): error \(error) send error")
 connection.cancel()
 logger?.error("\(tracker): connection closed")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 })
 NSLog("\(tracker): sent register_node request ")
 }
 else{
 logger?.error("unknown message \(message)")
 }
 }
 //
 //Receives the digest generated by the remote node using its knowledge of the local node's cookie.
 //
 _ = try spawn(name: "recieve_challenge_ack"){(pid,message) in
 if let (tracker, node, connection, ultimatePid,(capabilityFlags,localChallenge,creation,remoteName,remoteCookie)) = message as? (UUID,SwErlNode,NWConnection,UUID,(UInt64,UInt32,UInt32,String,String)){
 logger?.trace("\(tracker): recieved challenge ack")
 connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _context, isDone, error in
 guard let error = error else{
 logger?.trace("\(tracker): received digest")
 if let data = data, !data.isEmpty {
 _ = data[0...1].toUInt16.toMachineByteOrder
 guard case data[2] = UInt8(97) else {// not an 'a' character
 logger?.trace("\(tracker): message is not an ack-type message. Message type: \(Character(UnicodeScalar(data[2])))")
 connection.cancel()
 logger?.trace("\(tracker): connection attempt canceled")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 return
 
 }
 logger?.trace("\(tracker): message is an ack-type message")
 let digest = String(decoding: data[3...18], as: UTF8.self)
 let check = String(("\(localChallenge)"+node.outCookie).MD5.utf8)
 guard digest == check else{
 logger?.trace("\(tracker): digest received: \(digest) does not match expected \(check)")
 connection.cancel()
 logger?.trace("\(tracker): connection attempt canceled")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 return
 }
 let description = (capabilityFlags,remoteCookie,
 connection)
 "nodeConnections" ! (tracker, SwErlConnection.store, remoteName,description)
 ultimatePid ! (tracker, node, ConStatus.alive)
 }
 logger?.error("\(tracker): error no data read")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 return
 }
 logger?.error("\(tracker): error \(error) send error")
 connection.cancel()
 logger?.error("\(tracker): connection closed")
 ultimatePid ! (tracker, node, ConStatus.not_allowed)
 }
 
 }
 else{
 logger?.error("unknown message \(message)")
 }
 }
 
 _ = try spawn(name: "respondToHandshake"){(pid,message) in
 if let (tracker, connection, ultimatePid) = message as? (UUID,NWConnection,UUID){
 logger?.trace("\(tracker): handshake requested")
 }
 else{
 logger?.error("unknown message \(message)")
 }
 }
 
 //
 //
 _ = try spawn(name: "handshakeComplete"){(pid,message) in
 if let tracker = message as? UUID{
 logger?.trace("\(tracker): handshake done")
 }
 else{
 logger?.error("unknown handshake complete message \(message)")
 }
 }
 }
 
 //@available(macOS 10.14, *)
 func buildNameMessage(requester:SwErlNode)->Data{
 
 let messageLength = 3//replace with real value
 
 var protocolData = Data(capacity: Int(messageLength))
 //protocolData.writeAll(in: protcolBytes)
 return protocolData
 }
 
 //@available(macOS 10.15, *)
 func buildChallengeReplyMessage(challenge:UInt32, remoteCookie:String)->(Data,UInt32){
 
 let messageLength = 21
 let localChallenge = UInt32.random(in: 1...UInt32.max)
 let digest = [Byte](("\(challenge)"+remoteCookie).MD5.utf8)
 let protcolBytes:[[Byte]] = [[Byte(messageLength)],[Byte(114)],digest]
 var protocolData = Data(capacity: messageLength+2)
 protocolData.writeAll(in: protcolBytes)
 return (protocolData,localChallenge)
 }
 
 //@available(macOS 10.14, *)
 func buildAcceptHandshakeMessage(requester:SwErlNode)->Data{
 
 let messageLength = 3//replace with real value
 
 var protocolData = Data(capacity: Int(messageLength))
 //protocolData.writeAll(in: protcolBytes)
 return protocolData
 }
 
 ///
 ///This function starts the SwErlNode listening and starts
 ///the EPMD client. Starting the client does not register
 ///the SwErlNode. That is done by sending a message to
 ///the appropriate Process ID (PID).
 ///
 //@available(macOS 10.14, *)
 public func start(node:SwErlNode, client:EPMD){
 //add a connection handler to the SwErlNode
 node.listener.newConnectionHandler = { connection in
 let tracker = UUID()//tracker for connection request handling
 logger?.trace("\(tracker): connection requested")
 "respondToHandshake" ! (tracker,connection)
 //don't store the connection until both this node and the other node come to an agreement via the handshake
 logger?.trace("\(tracker): starting handshake")
 }
 let tracker = UUID()
 logger?.trace("\(tracker): about to start node")
 node.listener.start(queue: .global())
 logger?.trace("\(tracker): started node")
 start(client: client)
 }
 
 ///
 ///This function stops both the node and the client connection to the EPMD
 ///service. This causes the EPMD server to unregister the node.
 ///
 //@available(macOS 10.14, *)
 public func stop(node:SwErlNode, client:EPMD, tracker:Any) {
 logger?.trace("\(tracker): about to stop node")
 node.listener.cancel()
 logger?.trace("\(tracker): did stop node")
 stop(client: client, tracker: tracker)
 }
 */
