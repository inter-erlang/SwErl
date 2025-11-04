//
//  SwErl.swift
//
//MIT License
//
//Copyright (c) 2024 Lee Barney
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
//  Created by Lee Barney on 2/24/23.
//

///Documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation


/// Typealiases defining SwErl related types and handlers.
///
/// - Note: The types `SwErlState`, `SwErlValue`, `SwErlMessage`, and `SwErlResponse` are placeholders for any Swift valid type.
///   The type `SwErlResponse` is represented as a tuple with a boolean indicating success (`SwErlPassed`) and an optional associated value.
///
/// - Note: The types `SwErlClosure` and `SwErlStatelessHandler` are typealias for closures used in SwErl message handling.
///   - `SwErlClosure`: A closure that takes a `SwErlMessage` and a `SwErlState` as input and returns a `SwErlResponse` along with the updated `SwErlState`.
///   - `SwErlStatelessHandler`: A closure that takes a `Pid` and a `SwErlMessage` as input and performs some stateless operation.
// MARK: type aliases
public typealias SwErlState = Any
public typealias SwErlValue = Any
public typealias SwErlMessage = Any
public typealias SwErlResponse = (SwErlPassed, Any?)


public typealias SwErlClosure = (SwErlMessage, SwErlState) -> (SwErlResponse, SwErlState)
public typealias SwErlStatelessHandler = (Pid, SwErlMessage) -> ()





/// An enumeration representing SwErl related errors conforming to the Swift `Error` protocol.
///
/// - Note: The cases of `SwErlError` provide different error scenarios encountered in SwErl based applications.
///   - `.processAlreadyLinked`: Indicates that there is a process currently registered with the specified name.
///   - `.notRegisteredByName`: Indicates that no process is registered with the specified name.
///   - `.notRegisteredByPid`: Indicates that no process is registered with the specified process identifier (Pid).
///   - `.notGenServer_behavior`: Indicates that a behavior other than the expected `GenServer` was encountered.
///   - `.notStatem_behavior`: Indicates that a behavior other than the expected `Statem` was encountered.
///   - `.statem_behaviorWithoutState`: Indicates that the `Statem` behavior was encountered without a valid state.
///   - `.invalidCommand`: Indicates that an unknown command was received.
///   - `.invalidState`: Indicates that the state provided is invalid for the given operation.
///   - `.invalidExternalType`: Indicates that a 'Data' is not a valid Erlang external interchange format.
///   - `.invalidValue`: Indicates that a provided value is invalid for the given context.
///   - `.missingClosure`: Indicates that a required closure is missing for the specified operation.
///   - `.invalidPort`: Indicates an invalid port encountered during interaction with EPMD.
///   - `.ipNotFound`: Indicates that the IP address associated with a given port was not found.
///   - `.alreadyStarted`: Indicates an attempt to start a process that has already been started.
///
/// - Author: Lee S. Barney
/// - Version: 0.1 
// MARK: SwErlError
public enum SwErlError: Error {
    case processAlreadyLinked
    case notRegisteredByName
    case notRegisteredByPid
    case notGenServer_behavior
    case notStatem_behavior
    case statem_behaviorWithoutState
    case invalidCommand
    case badAtom
    case invalidState
    case invalidExternalType
    case invalidValue
    case missingClosure
    case invalidPort
    case ipNotFound
    case alreadyStarted
    case invalidMessage
}
///
/// Structure representing a thread-safe process ID incrementer.
///
/// - Note: The `ProcessIDCounter` structure is designed to increment the count of Erlang-like process IDs in a thread-safe manner.
///   It uses a private DispatchQueue (`counterQueue`) to synchronize access to the counter.
///
/// - Properties:
///   - `id`: A secondary counter to handle overflow of the primary `serial` counter.
///   - `serial`: The current value of the process counter.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
///
/// - Important: For each call to `next()`, a tuple of two unsigned 32-bit integers is returned representing a process ID.
///
/// - Returns: A tuple containing the next process ID.
// MARK: PID Counter
struct ProcessIDCounter {
    private var counterQueue = DispatchQueue(label: "process.counter")
    var id: UInt32 = 0
    var serial: UInt32 = 0
    
    /// Increments the count of the process ID in a thread-safe manner.
    ///
    /// - Returns: A tuple containing the next process ID and the associated serial count.
    ///
    /// - Complexity: O(1).
    ///
    mutating func next() -> (UInt32, UInt32) {
        counterQueue.sync {
            if self.serial == UInt32.max {
                self.serial = 0
                id = id + 1
            }
            self.serial = self.serial + 1
        }
        return (id,serial)
    }
}

//The global thread-safe process counter for the entire application
var pidCounter = ProcessIDCounter()


/// Structure representing a Process Identifier (Pid) in SwErl.
///
/// - Note: The `Pid` structure conforms to the `Hashable` and `Equatable` protocols.
///
/// - Properties:
///   - `id`:When `serial` would overflow UInt32, `id` is incremented and `serial` is reset to 1
///   - `serial`: The serial number of the process.
///   - `creation`: A unique identifier of the originator of the process. This is zero when the process is local, non-zero when the process is a remote node. The creation identifier is assigned to the node the first time the node accesses the EPMD (Erlang Process Mapping Daemon).
///
/// - Author:  Lee S. Barney
/// - Version: 0.1
///
/// - Important: The `Pid` structure provides a `to_string` method to convert the Pid into a comma-separated string representation.
///
// MARK: Pid
public struct Pid: Hashable, Equatable {
    let id: UInt32
    let serial: UInt32
    let creation: UInt32
    
    /// Converts the Pid into a comma-separated string representation.
    ///
    /// - Parameter PID: The Pid to be converted.
    /// - Returns: A string representation of the Pid in the format "id,serial,creation".
    ///
    /// - Complexity: O(1).
    ///
    static func to_string(_ PID: Pid) -> String {
        "\(PID.id),\(PID.serial),\(PID.creation)"
    }
}


/// Structure representing an Identifier of a process.
///
/// - Note: The `SwErlRef` structure conforms to the `Hashable` and `Equatable` protocols.
///
/// - Properties:
///   - `node`:The atom indicating the node where the the process exists.
///   - `id`: The unique identifier of the originator of the process. This is zero when the process is local, non-zero when the process is a remote node.
///   - `creation`: The creation count associated with the process.
///
/// - Author:  Lee S. Barney
/// - Version: 0.1
///

public struct SwErlRef: Hashable, Equatable {
    let node: SwErlAtom
    let id: UInt32
    let creation: UInt32
    
}

/// Structure representing an Erlang Newer Identifier for a process.
///
/// - Note: The `SwErlRef` structure conforms to the `Hashable` and `Equatable` protocols.
///
/// - Properties:
///   - `node`:The atom indicating the node where the the process exists.
///   - `id`: The unique identifier of the originator of the process. This is an `Data` of at most 5 bytes.
///   - `creation`: The `UInt32` creation count associated with the process.
///
/// - Author:  Lee S. Barney
/// - Version: 0.1
///
public struct SwErlNewerRef: Hashable, Equatable {
    let node: SwErlAtom
    let creation:UInt32
    let id: Data
}

/// Structure representing an Erlang-like atom in SwErl.
///
/// - Note: The `SwErlAtom` structure conforms to the `Hashable` and `Equatable` protocols.
///
/// - Property:
///   - `value`: The string value of the atom, stored in a lowercase form. It is optional, allowing for an uninitialized state.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
///
/// - Important: The `SwErlAtom` structure provides an initializer that accepts a string value. If the string is empty, the `value` property is set to `nil`.
///   Otherwise, the lowercase version of the string is stored in the `value` property.
// MARK: SwErlAtom
public struct SwErlAtom: Hashable, Equatable {
    private var value: String?
    
    /// Initializes an atom with the provided string value.
    ///
    /// - Parameter value: The string value to be associated with the Atom.
    init(_ value: String) {
        if value.isEmpty {
            self.value = nil
        }
        else{
            self.value = value.lowercased()
        }
    }
}
/// Extension on `SwErlAtom` providing a computed property to get the string value.
///
/// - Note: The `string` property returns the optional string value stored in the `SwErlAtom`.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
///
/// - Returns: The optional string value of the `SwErlAtom`.
public extension SwErlAtom {
    var string: String? {
        return self.value
    }
}

/// Extension on `SwErlAtom` providing a computed property to get the string value as a `Data` in UTF8.
///
/// - Note: The `utf8` property returns the optional string value stored in the `SwErlAtom`.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
///
/// - Returns: An optional `Data` value of the `SwErlAtom`.
public extension SwErlAtom{
    var utf8: Data?{
        return self.value?.data(using: .utf8)
    }
}

/// Represents a bit string with a specified bit count and internal byte data.
///
/// - Parameters:
///   - bitCount: The number of bits (1 - 8) used in the last byte.
///   - internalBytes: The internal byte data of the bit string.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: BitString Struct
struct BitString: Hashable, Equatable {
    var bitCount:UInt8//the number of bits, 1 - 8, of bits used in the last Byte
    var internalBytes:Data
}

/// The `SwErlExportFunc` structure is designed to store information about Erlang functions that were registered globally in some other node. It also represents any function registered globally in a SwErl node.
///
/// - Properties:
///   - `module`: An instance of `SwErlAtom` representing the module to which the exported function belongs.
///   - `function`: An instance of `SwErlAtom` representing the exported Erlang function.
///   - `arity`: An 8-bit unsigned integer (`UInt8`) indicating the arity (number of arguments) of the exported function.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
///
struct SwErlExportFunc: Hashable, Equatable  {
    let module: SwErlAtom
    let function: SwErlAtom
    let arity: Int
}

/// A structure representing a bit binary in SwErl.
/// - Parameters:
///   - finalBitCount: The final bit count, which can only be in the range of 1 to 8.
///   - bits: The binary data representing the bits.
/// - Author: Lee S. Barney
/// - Version: 0.1
struct SwErlBitBinary: Hashable, Equatable  {
    
    /// The final bit count, which can only be in the range of 1 to 8.
    let finalBitCount: UInt8
    
    /// The binary data representing the bits.
    let bits: Data
}

/// A structure representing a SwErlPort.
/// - Parameters:
///   - node: The node associated with the port.
///   - ID: The port ID as a 32-bit unsigned integer.
///   - creation: The creation value, with only the lowest 2 bits being significant.
/// - Author: Lee S. Barney
/// - Version: 0.1
struct SwErlPort: Hashable, Equatable  {
    
    /// The node associated with the port.
    let node: SwErlAtom
    
    /// The port ID as a 32-bit unsigned integer.
    let ID: UInt32
    
    /// The creation value, with only the lowest 2 bits being significant.
    let creation: UInt8
}


/// A structure representing a NewSwErlPort.
/// - Parameters:
///   - node: The node associated with the new port.
///   - ID: The port ID as a 32-bit unsigned integer.
///   - creation: The creation value, with only the lowest 28 bits being significant.
/// - Author: Lee S. Barney
/// - Version: 0.1
struct SwErlNewPort: Hashable, Equatable  {
    
    /// The node associated with the new port.
    let node: SwErlAtom
    
    /// The port ID as a 32-bit unsigned integer.
    let ID: UInt32
    
    /// The creation value, with only the lowest 28 bits being significant.
    let creation: UInt32
}

/// A structure representing a SwErlV4Port with a 64-bit ID.
/// - Parameters:
///   - node: The node associated with the port.
///   - ID: The port ID as a 64-bit unsigned integer.
///   - creation: The creation value, with only the lowest 32 bits being significant.
/// - Author: Lee S. Barney
/// - Version: 0.1
struct SwErlV4Port: Hashable, Equatable  {
    
    /// The node associated with the port.
    let node: SwErlAtom
    
    /// The port ID as a 64-bit unsigned integer.
    let ID: UInt64
    
    /// The creation value, with only the lowest 32 bits being significant.
    let creation: UInt32
}


/// Enum representing different types of registration for SwErl processes.
///
/// - Note: The cases of `RegistrationType` include:
///   - `.local`: Indicates local process registration within a node.
///   - `.global`: Indicates global process registration across nodes.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

public enum RegistrationType{
    case local
    case global
}


/// This enum is used in the values of some SwErl functions.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
public enum SwErlPassed{
    case ok
    case fail
}


///
///  This function is used to link a unique name to a stateless function or closure that is executed asynchronously with no result being sent to the process sending the message. Any DispatchQueue desired for running the function or closure can be passed as the first parameter. The state can be any valid Swift type, a tuple, a list, a dictionary, optional, closure, etc.
/// - Parameters:
///   - makeAvailable: The registration type, either local or global. The default is local.
///   - queueToUse: The dispatch queue to use for the new process. The default is `DispatchQueue.global()`
///   - name: The unique `String` identifier for the process. If not provided, the process will not be named.
///   - function: The  the function or closure to be executed by the new process.
/// - Returns: The newly generated `Pid` associated with the spawned process using the declared `DispatchQueue`.
/// - Throws: An error if linking the process encounters issues.

/// - Complexity: O(1).
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: Spawn
@discardableResult public func spawnasysl(_ makeAvailable: RegistrationType = .local, queueToUse: DispatchQueue = .global(), name: String? = nil, function: @escaping @Sendable (Pid, SwErlMessage) -> Void) throws -> Pid {
    let PID = Registrar.generatePid()
    
    guard let name = name else {
        try Registrar.link(SwErlProcess(queueToUse: queueToUse, registrationID: PID, functionality: function), PID: PID)
        return PID
    }
    
    try Registrar.link(SwErlProcess(queueToUse: queueToUse, registrationID: PID, functionality: function), name: name, PID: PID)
    return PID
}

///
///  This function is used to link a unique name to a stateful function or closure that is executed synchronously with a result being sent to the process sending the message. Any DispatchQueue desired for running the function or closure can be passed as the first parameter. The state can be any valid Swift type, a tuple, a list, a dictionary, optional, closure, etc.
///
/// - Parameters:
///   - makeAvailable: The registration type, either local or global. The default is local.
///   - queueToUse: The dispatch queue to use for the new process. The default is `DispatchQueue.global()`
///   - name: The unique `String` identifier for the process. If not provided, the process will not be named.
///   - initialState: The initial state for the process.
///   - function: The synchronous stateful function or closure to be executed synchronously by the new process.
///
/// - Returns: The newly generated `Pid` associated with the spawned process using the declared `DispatchQueue`.
/// - Throws: An error if linking the process encounters issues.
///
/// - Complexity: O(1).
///
/// - Author: Lee S. Barney
/// - Version: 0.1
@discardableResult public func spawnsysf(_ makeAvailable: RegistrationType = .local, queueToUse: DispatchQueue = .global(), name: String? = nil, initialState: SwErlState, function: @escaping @Sendable (Pid,SwErlMessage,SwErlState) -> (SwErlResponse, SwErlState)) throws -> Pid {
    let PID = Registrar.generatePid()
    guard let name = name else {
        try Registrar.link(SwErlProcess(queueToUse: queueToUse, registrationID: PID, functionality: function), PID: PID)
        Registrar.setProcessState(forID: PID, value: initialState)
        return PID
    }
    try Registrar.link(SwErlProcess(queueToUse: queueToUse, registrationID: PID, functionality: function), initState:initialState, name: name, PID: PID)
    Registrar.setProcessState(forID: PID, value: initialState)
    return PID
}

/// Spawns a new synchronous, stateless SwErl process.
/// - Parameters:
///   - makeAvailable: The registration type, either local or global. The default is local.
///   - queueToUse: The dispatch queue to use for the new process. The default is `DispatchQueue.global()`.
///   - name: The unique `String` identifier for the process. If not provided, the process will not be named.
///   - function: The function or closure to be executed by the new process. This closure returns a `SwErlResponse`.
/// - Returns: The newly generated `Pid` associated with the spawned process using the declared `DispatchQueue`.
/// - Throws: An error if linking the process encounters issues.
///
/// - Complexity: O(1), assuming `Registrar.link` and `Registrar.generatePid` operate in constant time.
///
/// - Author: Lee Barney
/// - Version: 0.9
// MARK: System-Level Spawn

@discardableResult public func spawnsysl(_ makeAvailable: RegistrationType = .local, queueToUse: DispatchQueue = .global(), name: String? = nil, function: @escaping @Sendable (Pid,SwErlMessage) -> SwErlResponse) throws -> Pid {
    let PID = Registrar.generatePid()
    guard let name = name else {
        try Registrar.link(SwErlProcess(queueToUse: queueToUse, registrationID: PID, functionality: function), PID: PID)
        return PID
    }
    try Registrar.link(SwErlProcess(queueToUse: queueToUse, registrationID: PID, functionality: function), name: name, PID: PID)
    return PID
}

/**
 This function is used to link a unique name to a stateful function or closure that is executed asynchronously with no result being sent to the process sending the message. Any DispatchQueue desired for running the function or closure can be passed as the first parameter. The state can be any valid Swift type, a tuple, a list, a dictionary, optional, closure, etc.
 - Parameters:
 - makeAvailable: options:Availability.local or Availability.global. The .global option allows other nodes to execute the function or closure on the node it is spawned inside of.
 - queueToUse: any DispatchQueue, custom or built-in. Default is _DispatchQueue.global()_
 - name: a unique string optional used as an identifier. . Default is nil_
 - function: the function or closure to execute using the DispatchQueue
 - Value: a SwErl Pid
 - Author:
 Lee S. Barney
 - Version:
 0.1
 */
@discardableResult public func spawnasysf(queueToUse:DispatchQueue = DispatchQueue.global(),name:String?=nil,initialState:SwErlState,function:@escaping @Sendable(Pid,SwErlState,SwErlMessage)->SwErlState)throws -> Pid {
    let PID = Registrar.generatePid()
    guard let name = name else{
        try Registrar.link(SwErlProcess(queueToUse:queueToUse, registrationID: PID, functionality: function), PID: PID)
        Registrar.setProcessState(forID: PID, value: initialState)
        return PID
    }
    try Registrar.link(SwErlProcess(queueToUse:queueToUse, registrationID: PID, functionality: function), name: name, PID: PID)
    Registrar.setProcessState(forID: PID, value: initialState)
    return PID
}

/**
 This function is used to link a unique name to a stateless function or closure that is executed asynchronously. The function is then available to be called remotely from any SwErl compatable node. Any DispatchQueue desired for running the function or closure can be passed as the first parameter.
 - Parameters:
 - queueToUse: any DispatchQueue, custom or built-in. Default is _DispatchQueue.global()_
 - name: a unique string used as an identifier.
 - function: the function or closure to execute using the DispatchQueue
 - Value: a SwErl Pid
 - Author:
 Lee S. Barney
 - Version:
 0.1
 */
// MARK: Spawn Globally
@discardableResult public func spawnGlobally(queueToUse:DispatchQueue = DispatchQueue.global(),name:String,function:@escaping @Sendable(Pid,SwErlMessage)->Void)throws -> Pid {
    let PID = Registrar.generatePid()
    try Registrar.link(SwErlProcess(queueToUse:queueToUse, registrationID: PID, functionality: function), .global, name: name, PID: PID)
    return PID
}

/**
 This function is used to link a unique name to a stateful function or closure that is executed synchronously. The function is then available to be called remotely from any SwErl compatable node. A result is sent back to the process sending the initial message. Any DispatchQueue desired for running the function or closure can be passed as the first parameter. The state can be any valid Swift type, a tuple, a list, a dictionary, optional, closure, etc.
 - Parameters:
 - queueToUse: any DispatchQueue, custom or built-in.. Default is _DispatchQueue.global()_
 - name: a unique string used as an identifier.
 - function: the function or closure to execute using the DispatchQueue
 - Value: a SwErl Pid
 - Author:
 Lee S. Barney
 - Version:
 0.1
 */
@discardableResult public func spawnGlobally(queueToUse:DispatchQueue = DispatchQueue.global(),name:String,initialState:SwErlState,function:@escaping @Sendable(Pid,SwErlState,SwErlMessage) -> (SwErlResponse,SwErlState))throws -> Pid {
    let PID = Registrar.generatePid()
    try Registrar.link(SwErlProcess(registrationID: PID, functionality: function), .global, name: name, PID: PID)
    Registrar.setProcessState(forID: PID, value: initialState)
    return PID
}

/// An infix operator used to send messages to an already spawned process. The left-hand side can be either a SwErl Pid or the unique string previously passed as an identifier to the spawn function.
/// - Value: none
/// - Note:
/// - Author: Lee S. Barney
/// - Version: 0.1



/// Custom send infix operator `!` for invoking asynchronous or synchronous statefule or stateless processes on a `Pid` with a `SwErlMessage`.
///
/// - Complexity:
///   - Time: O(1) - The function execution time is constant and does not depend on the size of the data being processed.
///   - Space: O(1) - The memory usage is constant, and no additional data structures are created.
///
/// This operator allows synchronous and asynchronous execution of closures associated with a `Pid` based on the type of closure defined for the process.
///
/// - Parameters:
///   - lhs: The left-hand side operand, a `Pid` representing the process to invoke the closure on.
///   - rhs: The right-hand side operand, a message of type `Any` to be processed by the process.
///
/// - Returns:
///   A `SwErlResponse` tuple containing the result of executing the closure. The first element of the tuple represents the execution status (`SwErlPassed.ok` or `SwErlPassed.fail`), and the second element is a `SwErlError?` indicating any error that occurred during execution or `nil` if there was no error .
///
/// - Important:
///   If a stateful process has nil as it's state, the stateful lambda will be passed an empty tuple as the state to use.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: The ! Send Operator
infix operator ! : LogicalConjunctionPrecedence

extension Pid {
    @discardableResult public static func !( lhs: Pid, rhs: SwErlMessage)->SwErlResponse{
        guard let process = Registrar.getProcess(forID: lhs) else{
            return (SwErlPassed.fail,SwErlError.notRegisteredByPid)
        }
        //stateful-synchronous processes handling done here.
        if let statefulClosure = process.syncStatefulLambda{
            return process.queue.sync(flags: .barrier) {
                guard let state = Registrar.getProcessState(forID: lhs) else{
                    return (SwErlPassed.fail,SwErlError.statem_behaviorWithoutState)
                }
                let (response,nextState) = statefulClosure(lhs,rhs,state)
                //Registrar.local.processStates[lhs] = nextState
                Registrar.setProcessState(forID: lhs, value: nextState)
                return response
            }
        }
        //stateless-synchronous processes handling done here.
        if let statelessClosure = process.syncStatelessLambda{
            return process.queue.sync(flags: .barrier) {
                
                let response = statelessClosure(lhs,rhs)
                
                return response
            }
        }
        //stateful-asynchronous processes handling done here.
        else if let statefulClosure = process.asyncStatefulLambda{
            //Use the global dispatch queue to asynchronously place the requests
            // in a syncronous queue. This allows this execution to return without
            //waiting for the closure to complete.
            DispatchQueue.global().async(flags: .barrier){
                guard let state = Registrar.getProcessState(forID: lhs) else{
                    return
                }
                let nextState = statefulClosure(lhs,rhs,state)
                //Registrar.local.processStates[lhs] = nextState
                Registrar.setProcessState(forID: lhs, value: nextState)
                return
            }
            return (SwErlPassed.ok,nil)
        }
        //must be stateless asynchronous closure
        guard let statelessClosure = process.asyncStatelessLambda else{
            return (SwErlPassed.fail, SwErlError.missingClosure)
        }
        process.queue.async{()->Void in
            statelessClosure(process.registeredPid,rhs)
        }
        return (SwErlPassed.ok,nil)
    }
}

/// A facade function for invoking sending messages to a process identified by its registered name.
///
/// - Complexity:
///   - Time: O(1) - The function execution time is constant and does not depend on the size of the data being processed.
///   - Space: O(1) - The memory usage is constant, and no additional data structures are created.
///
/// This function uses the `!` operator with a `String` operand representing the registered name of the process.
///
/// - Parameters:
///   - lhs: The left-hand side operand, a `String` representing the registered name of the process.
///   - rhs: The right-hand side operand, a message of type `Any` to be processed by the process.
///
/// - Returns:
///   A `SwErlResponse` tuple containing the result of executing the closure. The first element of the tuple represents the execution status (`SwErlPassed.ok` or `SwErlPassed.fail`), and the second element is a `SwErlError?` indicating any error that occurred during execution or `nil` if there was no error .
///
/// - Important:
///   If a stateful process has nil as it's state, the stateful lambda will be passed an empty tuple as the state to use.
///
/// - Note:
///   This function relies on the `!` operator for `Pid` to perform the actual invocation based on the process identified by its registered name.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
extension String {
    @discardableResult public static func !( lhs: String, rhs: Any)->SwErlResponse{
        guard let pid = Registrar.getPid(forName: lhs) else{
            return (SwErlPassed.fail,SwErlError.notRegisteredByName)
        }
        return pid ! rhs
    }
}

/// Facade function for invoking functions on a process identified by a `SwErlAtom`.
///
/// - Complexity:
///   - Time: O(1) - The function execution time is constant and does not depend on the size of the data being processed.
///   - Space: O(1) - The memory usage is constant, and no additional data structures are created.
///
/// This function uses the `!` operator with a `SwErlAtom` operand.
///
/// - Parameters:
///   - lhs: The left-hand side operand, a `SwErlAtom`.
///   - rhs: The right-hand side operand, a message of type `Any` to be processed by the process.
///
/// - Returns:
///   A `SwErlResponse` tuple containing the result of executing the closure. The first element of the tuple represents the execution status (`SwErlPassed.ok` or `SwErlPassed.fail`), and the second element is a `SwErlError?` indicating any error that occurred during execution or `nil` if there was no error .
///
/// - Important:
///   If a stateful process has nil as it's state, the stateful lambda will be passed an empty tuple as the state to use.
///
/// - Note:
///   This function relies on the `!` operator for `Pid` and the `String` extension to perform the actual invocation based on the process identified by its registered name.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: SwErlAtom
extension SwErlAtom {
    @discardableResult public static func !( lhs: SwErlAtom, rhs: Any)->SwErlResponse{
        guard let atomName = lhs.string else {
            return (SwErlPassed.fail,SwErlError.badAtom)
        }
        return atomName ! rhs
    }
}





/// SwErlProcess represents an Erlang-like process in Swift, designed to handle synchronous, asynchronous, stateful, and stateless operations.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
///
/// This struct encapsulates the behavior of an Erlang-like process, providing different closures for handling various types of operations. It includes support for synchronous stateful, asynchronous stateful, stateless, Simple, GenServer, GenStatem, and EventManager processes.
///
///A Simple process consists of a spawned closure. GenServers, GenStatems (state machines), and Event Managers are pre-built, common types of behaviors used in software development and engineering.
/// All of these types of processes are thread-safe.
///

// MARK: SwErlProcess
public struct SwErlProcess {
    /// Serial dispatch queue for handling the process operations.
    public var queue: DispatchQueue
    
    /// Lambda for synchronous stateful operations used if this is a Simple synchronous statefule process.
    /// - Parameters:
    ///   - Pid: The registered name of the process.
    ///   - SwErlState: The current state of the process.
    ///   - SwErlMessage: The message triggering the operation.
    /// - Returns:
    ///   A tuple containing a `SwErlResponse` indicating success or failure and the updated state of the process.
    public var syncStatefulLambda: ((Pid, SwErlState, SwErlMessage) -> (SwErlResponse, SwErlState))? = nil
    
    /// Lambda for asynchronous stateful operations used if this is a Simple stateful process.
    /// - Parameters:
    ///   - Pid: The registered name of the process.
    ///   - SwErlState: The current state of the process.
    ///   - SwErlMessage: The message triggering the operation.
    /// - Returns:
    ///   The updated state of the process.
    public var asyncStatefulLambda: ((Pid, SwErlState, SwErlMessage) -> SwErlState)? = nil
    
    /// Lambda for asynchronous stateless operations used if this is a Simple stateless process.
    /// - Parameters:
    ///   - Pid: The registered name of the process.
    ///   - SwErlMessage: The message triggering the operation.
    public var asyncStatelessLambda: ((Pid, SwErlMessage) -> Void)? = nil
    
    
    public var syncStatelessLambda: ((Pid, SwErlMessage) -> SwErlResponse)? = nil
    
    /// Tuple of GenStatem process wrappers used if this is a state machine process.
    public var GenStatemProcessWrappers: (SwErlClosure, SwErlClosure, SwErlClosure, SwErlClosure)? = nil
    var genServerBehavior: GenServerBehavior.Type? = nil
    /// Array of event handlers for if this is an EventManager process.
    public var eventHandlers: [SwErlStatelessHandler]? = nil
    
    /// The registered Pid of the process.
    public let registeredPid: Pid
    
    /// Initializes a synchronous stateful process.
    ///
    /// - Parameters:
    ///   - queueToUse: Optional. The dispatch queue for handling operations. The default for this parameter is `DispatchQueue.global()`.
    ///   - registrationID: The registered name of the process.
    ///   - functionality: The closure for handling synchronous stateful operations.
    ///
    /// - Important:
    ///   The second element of the returned value is used as the next state.
    public init(queueToUse: DispatchQueue = DispatchQueue.global(),
                registrationID: Pid,
                functionality: @escaping @Sendable (Pid, SwErlState, SwErlMessage) -> (SwErlResponse, SwErlState)) {
        self.queue = DispatchQueue(label: Pid.to_string(registrationID) ,target: queueToUse)
        self.syncStatefulLambda = functionality
        self.registeredPid = registrationID
    }
    
    /// Initializes an asynchronous stateful process.
    ///
    /// - Parameters:
    ///   - queueToUse: Optional. The dispatch queue for handling operations. The default for this parameter is `DispatchQueue.global()`.
    ///   - registrationID: The registered name of the process.
    ///   - functionality: The closure for handling asynchronous stateful operations.
    ///
    /// - Important:
    ///   The second element of the returned value is used as the next state.
    public init(queueToUse: DispatchQueue = DispatchQueue.global(),
                registrationID: Pid,
                functionality: @escaping @Sendable (Pid, SwErlState, SwErlMessage) -> SwErlState) {
        self.queue = DispatchQueue(label: Pid.to_string(registrationID) ,target: queueToUse)
        self.asyncStatefulLambda = functionality
        self.registeredPid = registrationID
        
    }
    
    /// Initializes an asynchronous stateless process.
    ///
    /// - Parameters:
    ///   - queueToUse: Optional. The dispatch queue for handling operations. The default for this parameter is `DispatchQueue.global()`.
    ///   - registrationID: The registered name of the process.
    ///   - functionality: The closure for handling stateless operations.
    public init(queueToUse: DispatchQueue = DispatchQueue.global(),
                registrationID: Pid,
                functionality: @escaping @Sendable (Pid, SwErlMessage) -> Void) throws {
        self.queue = queueToUse
        self.asyncStatelessLambda = functionality
        self.registeredPid = registrationID
    }
    
    /// Initializes a new instance of a synchronous stateless SwErlProcess.
    /// This initializer sets up the SwErlProcess with a dispatch queue, registration ID, and a function or closure to execute.
    ///
    /// - Parameters:
    ///   - queueToUse: The `DispatchQueue` to be used by the SwErlProcess. Defaults to the global concurrent queue.
    ///   - registrationID: A `Pid` value that uniquely identifies the SwErlProcess.
    ///   - functionality: A closure that takes a `Pid` and a `SwErlMessage` as inputs and returns a `SwErlResponse`. This is the functionality to be executed by the SwErlProcess.
    ///
    /// - Complexity: O(1).
    ///
    /// - Throws: An error if the process initialization encounters issues.
    ///
    /// - Author: Lee Barney
    /// - Version: 0.1

    public init(queueToUse: DispatchQueue = DispatchQueue.global(),
                registrationID: Pid,
                functionality: @escaping @Sendable (Pid, SwErlMessage) -> SwErlResponse) throws {
        self.queue = queueToUse
        self.syncStatelessLambda = functionality
        self.registeredPid = registrationID
    }
    
    /// Initializes a GenStatem process.
    ///
    /// - Parameters:
    ///   - queueToUse: Optional. The dispatch queue for handling operations.  The default for this parameter is `DispatchQueue.global()`.
    ///   - registrationID: The registered name of the process.
    ///   - OTP_Wrappers: Tuple of GenStatem process wrappers.
    public init(queueToUse: DispatchQueue = DispatchQueue.global(),
                registrationID: Pid,
                OTP_Wrappers: (SwErlClosure, SwErlClosure, SwErlClosure, SwErlClosure)) {
        self.queue = queueToUse
        self.GenStatemProcessWrappers = OTP_Wrappers
        self.registeredPid = registrationID
    }
    
    /// Initializes an EventManager process.
    ///
    /// - Parameters:
    ///   - queueToUse: Optional. The dispatch queue for handling operations.  The default for this parameter is `DispatchQueue.global()`.
    ///   - registrationID: The registered name of the process.
    ///   - eventHandlers: Array of event handlers for the EventManager process.
    public init(queueToUse: DispatchQueue = DispatchQueue.global(),
                registrationID: Pid,
                eventHandlers: [SwErlStatelessHandler]) {
        self.queue = queueToUse
        self.registeredPid = registrationID
        self.eventHandlers = eventHandlers
    }
}

// The Registrar could have been done with dynamic member lookup.
// I have chosen not to do so for potential slowness caused by
// interpretation at runtime rather than at compile time.

/// The `Registrar` struct manages local and global mappings of names and Pids to SwErl Simple, GenStatem, GenServer, and EventManager processes. It provides functions for linking, unlinking, and accessing these processes by Pid or name. The `Registar` instance retains all local and global mappings of names and Pids to SwErl processes. It uses a concurrent queue for thread safety, ensuring proper synchronization for concurrent reads and writes.
/// - Author: Lee S. Barney
/// - Version: 0.1
///
// MARK: Registrar
struct Registrar{
    /// Instance of the `Registrar` used for locally registered processes.
    static var local:Registrar = Registrar()
    /// Instance of the `Registrar` used for globally registered processes.
    static var global:Registrar = Registrar()
    
    /// Concurrent queue for thread-safe access to `Registrar`s dictionary-type properties.
    private static let queue = DispatchQueue(label: "Registrar Concurrent Queue")
    
    /// Dictionary mapping Pids to SwErl processes.
    private var processesLinkedToPid:[Pid:SwErlProcess] = [:]
    
    /// Dictionary mapping unique names to Pids.
    private var processesLinkedToName:[String:Pid] = [:]
    
    /// Dictionary mapping Pids to OTP Actors and their associated dispatch queues.
    private var OTPActorsLinkedToPid: [Pid : (OTPActor_behavior.Type, DispatchQueue)] = [:]
    
    /// Dictionary mapping Pids to their associated states.
    private var processStates:[Pid:Any] = [:]
    
    /// Generates a new `Pid` using a thread-safe shared counter.
    ///
    /// - Returns: A new `Pid`.
    ///
    /// - Complexity: O(1) constant time.
    static func generatePid()->Pid{
        queue.sync{
            let (anID,aSerial) = pidCounter.next()
            return Pid(id: anID, serial: aSerial, creation: 0)
        }
    }
    
    /// Links a SwErl process to a `Pid` or name, making it available globally or locally.
    ///
    /// - Parameters:
    ///   - toBeAdded: The SwErl process to link.
    ///   - makeAvailable: Optional. The registration type (local or global). The default is local.
    ///   - initState: Optional. The initial state of the process if any.
    ///   - name: Optional. The unique name identifier.
    ///   - PID: The `Pid` of the process.
    ///
    /// - Throws: `SwErlError.processAlreadyLinked` if the process is already linked.
    ///
    /// - Complexity: O(1) constant time for local or global link.
    // MARK: Registrar Link
    static func link(_ toBeAdded:SwErlProcess,_ makeAvailable:RegistrationType = RegistrationType.local, initState:Any = "SwErlNone", name:String = "SwErlNone", PID:Pid) throws{
        try queue.sync {
            //This implementation has a lot of code duplication in it.
            //The implementation where a local variable is used to hold
            //the registrar instance to use, local or global,
            //and then used one set of code for the checks and updates reduces
            //code duplication dramatically, but runs 100 to 150x SLOWER.
            if makeAvailable == RegistrationType.global{
                if Registrar.global.processesLinkedToPid[PID] != nil{
                    throw SwErlError.processAlreadyLinked
                }
                Registrar.global.processesLinkedToPid[PID] = toBeAdded
                
                if name != "SwErlNone"{
                    Registrar.global.processesLinkedToName[name] = PID
                    
                }
                guard let stateString = initState as? String else{
                    Registrar.global.processStates[PID] = initState
                    return
                }
                if stateString != "SwErlNone"{
                    Registrar.global.processStates[PID] = initState
                }
                return
            }
            if Registrar.local.processesLinkedToPid[PID] != nil || Registrar.local.processesLinkedToName[name] != nil{
                throw SwErlError.processAlreadyLinked
            }
            Registrar.local.processesLinkedToPid[PID] = toBeAdded
            
            if name != "SwErlNone"{
                Registrar.local.processesLinkedToName[name] = PID
                
            }
            guard let stateString = initState as? String else{
                Registrar.local.processStates[PID] = initState
                return
            }
            if stateString != "SwErlNone"{
                Registrar.local.processStates[PID] = initState
            }
        }
    }
    
    /// Links an OTP Actor to a `Pid`, making it available globally or locally.
    ///
    /// - Parameters:
    ///   - callbackType: The type of the OTP Actor.
    ///   - makeAvailable: Optional. The registration type (local or global). The default is local.
    ///   - processQueue: The dispatch queue associated with the OTP Actor.
    ///   - initState: Optional. The initial state of the OTP Actor, if any.
    ///   - name: Optional. The unique name identifier.
    ///   - PID: The Pid of the OTP Actor.
    ///
    /// - Throws: `SwErlError.processAlreadyLinked` if the process is already linked.
    ///
    /// - Complexity: O(1) constant time for local or global link.
    
    static func link<T:OTPActor_behavior>(callbackType: T.Type,_ makeAvailable:RegistrationType = RegistrationType.local, processQueue: DispatchQueue, initState: Any?, name:String = "SwErlNone", PID:Pid) throws{
        try queue.sync {
            //This implementation has a lot of code duplication in it.
            //The implementation where a local variable is used to hold
            //the registrar instance to use, local or global,
            //and then used one set of code for the checks and updates reduces
            //code duplication dramatically, but runs 100 to 150x SLOWER.
            if makeAvailable == RegistrationType.global{
                
                if Registrar.global.processesLinkedToPid[PID] != nil || Registrar.global.processesLinkedToName[name] != nil{
                    throw SwErlError.processAlreadyLinked
                }
                
                Registrar.global.processStates[PID] = initState
                Registrar.global.OTPActorsLinkedToPid[PID] = (callbackType, processQueue)
                if name != "SwErlNone"{
                    Registrar.global.processesLinkedToName[name] = PID
                }
                return
            }
            if Registrar.local.processesLinkedToPid[PID] != nil || Registrar.local.processesLinkedToName[name] != nil{
                throw SwErlError.processAlreadyLinked
            }
            
            Registrar.local.processStates[PID] = initState
            Registrar.local.OTPActorsLinkedToPid[PID] = (callbackType, processQueue)
            if name != "SwErlNone"{
                Registrar.local.processesLinkedToName[name] = PID
            }
        }
    }
    
    /// Removes the link between a `Pid` and a SwErl process, and removes the process.
    ///
    /// - Parameters:
    ///   - registrationID: The `Pid` of the process.
    ///
    /// - Complexity: O(1) constant time.
    // MARK: Registrar Unlink
    static func unlink(_ registrationID:Pid){
        _ = queue.sync { local.processesLinkedToPid.removeValue(forKey: registrationID) }
        _ = queue.sync { local.OTPActorsLinkedToPid.removeValue(forKey: registrationID) }
    }
    
    /// Removes the link between a name and a `Pid`, and removes the associated process.
    ///
    /// - Parameters:
    ///   - name: The unique string identifier of the SwErl or OTP process.
    ///
    /// - Complexity: O(1) constant time.
    static func unlink(_ name:String){
        guard let PID = Registrar.getPid(forName: name) else{
            return
        }
        _ = queue.sync{ local.processesLinkedToName.removeValue(forKey: name) }
        Registrar.unlink(PID)
    }
    
    /// - Parameters:
    ///   - forID: The `Pid` of the desired process.
    ///
    /// - Returns: The associated process or _nil_ if there is no process linked to the Pid.
    ///
    /// - Complexity: O(1) constant time.
    // MARK: Registrar GetProcessForPid
    static func getProcess(forID:Pid)->SwErlProcess?{
        return queue.sync{
            local.processesLinkedToPid[forID]
        }
    }
    
    /// Returns the number of processes linked to names in the local registry.
    ///
    /// This method retrieves the count of all processes that have been linked to a specific name within the local scope of the `Registrar`. It's useful for understanding how many named processes are currently managed by the local registrar.
    ///
    /// - Returns: An `Int` representing the total number of named processes linked in the local registrar.
    /// - Complexity: O(1), as it directly accesses the count property of the collection holding the named processes.
    ///
    /// - Author: Lee Barney
    /// - Version: 0.9
    // MARK: - Process Count Retrieval
    static func getNumNameLinkedProcesses()->Int{
        return Registrar.local.processesLinkedToName.count
    }
    
    /// Returns the total number of process states managed by the local registrar.
    ///
    /// This method provides a quick way to retrieve the count of all process states within the local scope of the `Registrar`. It's beneficial for monitoring the overall number of processes in various states (e.g., running, suspended) managed by the local registrar.
    ///
    /// - Returns: An `Int` representing the total number of process states in the local registrar.
    /// - Complexity: O(1), as it simply accesses the count property of the collection holding the process states.
    ///
    /// - Author: Lee Barney
    /// - Version: 0.9
    // MARK: - Process State Count Retrieval
    static func getNumProcessStates()->Int{
        return Registrar.local.processStates.count
    }
    
    /// Returns the number of processes linked to PIDs in the local registry.
    ///
    /// This static method fetches the count of all processes that have been linked to a Process ID (PID) within the local scope of the `Registrar`. It is instrumental for gauging how many processes are currently associated with PIDs by the local registrar, providing insights into the registry's utilization and management efficiency.
    ///
    /// - Returns: An `Int` representing the total number of processes linked to PIDs in the local registrar.
    /// - Complexity: O(1), given it merely accesses the count property of the collection containing the processes linked to PIDs.
    ///
    /// - Author: Lee Barney
    /// - Version: 0.9
    // MARK: - PID-Linked Process Count Retrieval
    static func getNumProcessesLinkedToPid()->Int{
        return Registrar.local.processesLinkedToPid.count
    }
    
    /// Removes the state associated with a specific process identified by its `Pid`. This operation is synchronized to ensure thread safety, particularly when manipulating the process state storage.
    ///
    /// This function is typically called when a process is terminated or when its state needs to be explicitly cleared from the system. The removal is performed within a synchronous block on a designated queue to maintain consistency and prevent race conditions.
    ///
    /// - Parameter forID: The `Pid` of the process whose state is to be removed.
    ///
    /// - Complexity: O(1)
    ///
    /// - Author: Lee Barney
    /// - Version: 0.1
    static func removeState(forID:Pid){
        _ = queue.sync{
            local.processStates.removeValue(forKey: forID)
        }
    }
    
    /// Provides access to an OTP Actor process by `Pid`.
    ///
    /// - Parameters:
    ///   - forID: The `Pid` of the desired OTP Actor process.
    ///
    /// - Returns: A tuple containing the OTP Actor type and its associated dispatch queue, or _nil_ if there is no OTP Actor process linked to the Pid.
    ///
    /// - Complexity: O(1) constant time.
    static func getOtpProcess(forID: Pid) -> (OTPActor_behavior.Type, DispatchQueue)? {
        return queue.sync{ local.OTPActorsLinkedToPid[forID] }
    }
    /// Provides access to a process by name.
    ///
    /// - Parameters:
    ///   - forID: The unique string identifier of the desired process.
    ///
    /// - Returns: The associated process or _nil_ if there is no process linked to the identifier.
    
    /// - Complexity: O(1) constant time.
    static func getProcess(forID:String)->SwErlProcess?{
        guard let pid = queue.sync(flags: .barrier, execute: {local.processesLinkedToName[forID]}) else {
            return nil
        }
        return getProcess(forID: pid)
    }
    
    /// Provides access to a `Pid` linked to a name.
    ///
    /// - Parameters:
    ///   - forName: The unique string identifier of the desired `Pid`.
    ///
    /// - Returns: The associated `Pid` or _nil_ if there is no `Pid` linked to the identifier.
    ///
    /// - Complexity: O(1) constant time.
    static func getPid(forName:String)->Pid?{
        return queue.sync{local.processesLinkedToName[forName]}
    }
    
    /// Provides access to the state of a process by `Pid`.
    ///
    /// - Parameters:
    ///   - forID: The `Pid` of the desired process.
    ///
    /// - Returns: The associated state or _nil_ if there is no state linked to the `Pid`.
    ///
    /// - Complexity: O(1) constant time.
    // MARK: Get/Set Process State
    static func getProcessState(forID: Pid) -> Any? {
        return queue.sync{ local.processStates[forID] }
    }
    /// Sets the state of a process represented by a `Pid`.
    ///
    /// - Parameters:
    ///   - forID: The `Pid` of the desired process.
    ///   - value: The new state value.
    ///
    /// - Complexity: O(1) constant time.
    static func setProcessState(forID: Pid, value: Any) {
        return queue.sync{ local.processStates[forID] = value }
    }
    
    static func clearAllProcessStates(){
        queue.sync{ local.processStates = [:] }
    }
    
    /// Checks if a `Pid` is linked to an OTP Actor.
    ///
    /// - Parameters:
    ///   - forID: The `Pid` to check.
    ///
    /// - Returns: `true` if the `Pid` is linked to an OTP Actor, `false` otherwise.
    ///
    /// - Complexity: O(1) constant time.
    static func otpPidLinked(_ forID: Pid) -> Bool {
        queue.sync {
            switch local.OTPActorsLinkedToPid[forID] {
            case nil :
                return false
            default:
                return true
            }
        }
    }
    
    /// Checks if a `Pid` is linked to any process.
    ///
    /// - Parameters:
    ///   - forID: The `Pid` to check.
    ///
    /// - Returns: `true` if the `Pid` is linked to any process, `false` otherwise.
    ///
    /// - Complexity: O(1) constant time.
    static func pidLinked(_ forID: Pid) -> Bool {
        queue.sync {
            switch local.processesLinkedToPid[forID] {
            case nil :
                return false
            default:
                return true
            }
        }
    }
    
    /// Checks if a name is linked to any process.
    ///
    /// - Parameters:
    ///   - forName: The name to check.
    ///
    /// - Returns: `true` if the name is linked to any process, `false` otherwise.
    ///
    /// - Complexity: O(1) constant time.
    static func nameLinked(_ forName: String) -> Bool {
        queue.sync {
            switch local.processesLinkedToName[forName] {
            case nil :
                return false
            default:
                return true
            }
        }
    }
    /// Provides a list of all linked `Pid`s.
    ///
    /// - Returns: The list of all linked Pids.
    ///
    /// - Complexity: O(n) where n is the number of linked`Pid`s.
    static func getAllPIDs()->Dictionary<Pid, SwErlProcess>.Keys{
        return queue.sync{ local.processesLinkedToPid.keys }
    }
    /// Provides a list of all unique identifiers linked to `Pids` and SwErl or OTP processes.
    ///
    /// - Returns: The list of all linked unique identifiers.
    ///
    /// - Complexity: O(n) where n is the number of linked unique identifiers.
    static func getAllNames()->Dictionary<String, Pid>.Keys{
        return queue.sync{ local.processesLinkedToName.keys }
    }
}

/// Converts any sized tuple to an array.
///
/// - Parameters:
///   - tuple: A tuple of any size with any number of elements of any type.
///
/// - Returns:
///   An array, `[Any]`, of the same size and containing the same elements as the tuple.
///
/// - Complexity:
///   The function has a time complexity of O(n), where n is the number of elements in the tuple.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: Tuple to Array
func tupleToArray<T>(_ tuple: T) -> [Any] {
    let mirror = Mirror(reflecting: tuple)
    let elements = mirror.children.map { $0.value }
    return elements
}




/// This extension converts any Array with less than or equal to 30 elements of any type, [Any].
/// - Returns: A tuple of the same size as the Array containing the same elements as the Array.
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: Array to Tuple
extension Array {
    
    var toTuple: Any? {
        toTuples[self.count](self)
    }
}

/// A computed property that converts arrays to tuples.
/// If you want tuples of size greater than 30, add them in.
/// Do NOT skip any sizes of Arrays and Tuples as this could
/// cause undefined behavior.
///
/// This solution to Array to tuple converson is required until Swift.org adds tuple generation
/// of size N. Something like `<Array>.toTuple` but being
/// done natively, not like it is implemented here.
let toTuples: [([Any]) -> Any?] = [
    { elements in
        guard elements.isEmpty else {
            return nil
        }
        return ()
    },
    { elements in
        guard elements.count == 1 else {
            return nil
        }
        return elements[0]
    },
    { elements in
        guard elements.count == 2 else {
            return nil
        }
        return (elements[0], elements[1])
    },
    { elements in
        guard elements.count == 3 else {
            return nil
        }
        return (elements[0], elements[1], elements[2])
    },
    { elements in
        guard elements.count == 4 else {
            return nil
        }
        return (elements[0], elements[1], elements[2], elements[3])
    },
    { elements in
        guard elements.count == 5 else {
            return nil
        }
        return (elements[0], elements[1], elements[2], elements[3], elements[4])
    },
    { elements in
        guard elements.count == 6 else {
            return nil
        }
        return (elements[0], elements[1], elements[2], elements[3], elements[4], elements[5])
    },
    { elements in
        guard elements.count == 7 else {
            return nil
        }
        return (elements[0], elements[1], elements[2], elements[3], elements[4], elements[5], elements[6])
    },
    { elements in
        guard elements.count == 8 else {
            return nil
        }
        return (elements[0], elements[1], elements[2], elements[3], elements[4], elements[5], elements[6], elements[7])
    },
    { elements in
        guard elements.count == 9 else {
            return nil
        }
        return (elements[0], elements[1], elements[2], elements[3], elements[4], elements[5], elements[6], elements[7], elements[8])
    },
    { elements in
        guard elements.count == 10 else {
            return nil
        }
        return (elements[0], elements[1], elements[2], elements[3], elements[4], elements[5], elements[6], elements[7], elements[8], elements[9])
    }
]
