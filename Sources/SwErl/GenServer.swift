//
//  GenServer.swift
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
//  Created by Sylvia Deal on 10/30/23.
//

import Foundation

/// SwErl process extension for internal use, particularly for segmenting modification and leveraging `GenServerBehavior`.
/// This extension is utilized by `GenServer`'s `startLink` functions and is not intended for direct use by developers.
///
/// Contains the protocol and API functions essential for creating and interacting with `GenServer` instances.
/// `GenServer`s operate as self-contained processes capable of traditional client-server communication.
/// They process messages serially in the order received, with each instance maintaining its own execution context and state.
/// State modifications are confined within the `GenServer`, ensuring encapsulated management of process state.
///
/// - Complexity: O(1) for initialization.
///
/// - Author: Sylvia Deal
/// - Version: 0.1
fileprivate extension SwErlProcess {
    
    /// Initializes a `SwErlProcess` for a given type conforming to `GenServerBehavior`.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the `GenServer` executes.
    ///   - pid: Unique process identifier, matching the corresponding PID in the registry.
    ///   - functionality: A type conforming to `GenServerBehavior` that defines the process's behavior.
    init<T:GenServerBehavior>(queue: DispatchQueue, pid: Pid, functionality: T.Type) {
        self.queue = queue
        self.registeredPid = pid
        self.genServerBehavior = functionality
    }
}



/// Defines the behavior for a generic server (`GenServer`) in the SwErl framework.
/// `GenServerBehavior` protocol allows for the creation of stateful SwErl processes that support synchronous calls and replies through a separate API.
/// This protocol is designed for user-defined processes, enabling the encapsulation of process state within the registry.
/// Types conforming to this protocol are utilized to define the functionality of user-created `GenServer` instances.
/// Multiple, separate `GenServer` instances can be initiated from a single conforming type. Each instance operates within its own execution context as a separate process.
/// Conforming types are recommended to be static, leveraging SwErl infrastructure for state management.
///
/// - Complexity:
///   - `initializeData`: O(1), typically involves simple data transformations or validations.
///   - `terminateCleanup`: O(c), executed during process termination for cleanup activities where c is the complexity of the operation performed when doing cleanup.
///   - `handleCast`: O(c), where c is the complexity of the operation performed with the cast message.
///   - `handleCall`: O(c), where c is the complexity of the operation performed with the call request.
///
/// - Author: Sylvia Deal
/// - Version: 0.1
public protocol GenServerBehavior: OTPActor_behavior {
    /// Called during server startup, allowing for the initial state modification or validation.
    /// - Parameter state: The initial state provided by `Genserver`'s `startLink` function.
    /// - Returns: The modified or verified state data used in future interactions.
    static func initializeData(_ data: Any?) -> Any?
    
    /// Executed before a server is removed from the registry, typically for cleanup based on the provided termination reason.
    /// - Parameters:
    ///   - reason: The reason for the server's termination.
    ///   - data: The current server data at the time of termination.
    static func terminateCleanup(reason: String, data: Any?)
    
    /// Handles asynchronous cast messages, where no reply is expected by the sender.
    /// - Parameters:
    ///   - request: The content of the cast message.
    ///   - data: The current server state data.
    /// - Returns: Updated server state data for future messages.
    static func handleCast(request: Any, data: Any?) -> Any?
    
    /// Handles synchronous call messages, where the sender awaits a reply.
    /// - Parameters:
    ///   - request: The content of the call request.
    ///   - data: The current server state data.
    /// - Returns: A tuple containing the response to be sent back and the updated server state data.
    static func handleCall(request: Any, data: Any) -> (Any, Any)
}


/// Provides the API for creating, messaging, and managing `GenServer` instances within the SwErl framework.
/// This static type facilitates the creation and interaction with `GenServer` instances, encapsulating the functionality
/// for synchronous and asynchronous communication, process lifecycle management, and state handling.
///
/// - Complexity:
///   - `startLink` with name: O(n) where n is the complexity of the of the `GenServerBehavior` instance's `initializeData` and process registration operations.
///   - `startLink` without name: Similar to the named version, O(n)where n is the complexity of the `GenServerBehavior` instance's `startLink` operation.
///   - `notify`: O(1), sending a message is a constant time operation assuming message delivery mechanisms are efficient.
///   - `unlink`: O(n), involves cleanup operations where n is the complexity of the `GenServerBehavior` instance's  `terminateCleanup` implementation.
///   - `cast`: O(n), where n is the complexity of the `GenServerBehavior` instance's  `handleCast` method.
///   - `call`: O(n), synchronous calls depend on the complexity of the `GenServerBehavior` instance's  `handleCall` function.
///
/// - Author: Sylvia Deal
/// - Version: 0.1
public enum GenServer {
    
    /// Initializes and registers a `GenServerBehavior` instance, uniquely identified by a name.
        /// - Parameters:
        ///   - queueEndpoint: The dispatch queue for the `DispatchQueue` that `GenServer` will process messages on.
        ///   - name: A string identifier for the `GenServerBehavior` instance.
        ///   - type: The `GenServerBehavior` conforming type of which to create an instance.
        ///   - initialState: Initial data provided to the `GenServerBehavior`'s `.initializeData` function.
        /// - Returns: The registered name of the newly created `GenServer` upon success, or a `SwErlError` on failure.
    @discardableResult public static func startLink<T: GenServerBehavior>(
        queueEndpoint: DispatchQueue = DispatchQueue.global(),
        _ name: String, _ type: T.Type, _ initialState: Any?) throws -> String {
            let pid = Registrar.generatePid()
            guard let state = type.initializeData(initialState)else {
                // BUG initializeData runs in the wrong context. Should run on the spawned process,
                // not the spawning process
                throw SwErlError.invalidState
            }
            if state as? String == "SwErlNone" {
                throw SwErlError.invalidState
            }
            let queue = DispatchQueue(label: Pid.to_string(pid), target: queueEndpoint)
            let process = SwErlProcess(queue: queue, pid: pid, functionality: type)
            try Registrar.link(process, initState: state, name: name, PID: pid)
            return name
    }
    
    /// Initializes and registers a `GenServerBehavior` instance without a specific name, later identifiable only by its PID.
    /// - Parameters:
    ///   - queueEndpoint: The dispatch queue for the `DispatchQueue` that `GenServer` will process messages on.
    ///   - name: A string identifier for the `GenServerBehavior` instance.
    ///   - type: The `GenServerBehavior` conforming type of which to create an instance.
    ///   - initialState: Initial data provided to the `GenServerBehavior`'s `.initializeData` function.
    /// - Returns: The PID of the newly created `GenServer` upon success, or a `SwErlError` on failure.
    @discardableResult public static func startLink<T: GenServerBehavior>(
    queueEndpoint: DispatchQueue = DispatchQueue.global(),
    _ type: T.Type, _ initialState: Any?) throws -> Pid {
        let pid = Registrar.generatePid()

        guard let state = type.initializeData(initialState)else {
            // BUG initializeData runs in the wrong context. Should run on the spawned process,
            // not the spawning process
            throw SwErlError.invalidState
        }
        if state as? String == "SwErlNone" {
            throw SwErlError.invalidState
        }
        // should run within the context of the process, not the context of the spawning process.
        let queue = DispatchQueue(label: Pid.to_string(pid), target: queueEndpoint)
        let process = SwErlProcess(queue: queue, pid: pid, functionality: type)
        try Registrar.link(process, initState: state, PID: pid)
        return pid
    }
    /// Sends a message to a `GenServerBehavior` identified by its registered name.
    /// - Parameters:
    ///   - name: The registered name of the `GenServerBehavior` instance.
    ///   - message: The message to send.
    public static func notify(_ name: String, _ message: SwErlMessage) {
        name ! message
    }
    /// Sends a message to a `GenServerBehavior` instance identified by its PID.
    /// - Parameters:
    ///   - pid: The PID of the `GenServer`.
    ///   - message: The message to send.
    public static func notify(_ pid: Pid, _ message: SwErlMessage) {
        pid ! message
    }
    
    /// Terminates a `GenServerBehavior` identified by its registered name.
    /// - Parameters:
    ///   - name: The registered name of the `GenServerBehavior`.
    ///   - reason: The reason for termination.
    /// - Returns: A tuple indicating the result of the operation and any relevant error.
    ///     on fail: (SwErlPassed.fail, SwErlError)
    ///     on success: (SwErlPassed.ok, nil)
    public static func unlink(_ name: String, _ reason: String) -> SwErlResponse{
        guard let pid = Registrar.getPid(forName: name) else {
            return (SwErlPassed.fail, SwErlError.notRegisteredByName)
        }
        guard let process = Registrar.getProcess(forID: pid) else {
            return (SwErlPassed.fail, SwErlError.notRegisteredByPid)
        }
        guard let genServer = process.genServerBehavior else {
            // ibidum except "OTP process exists but is not gen server"
            return (SwErlPassed.fail, SwErlError.notGenServer_behavior)
        }
        process.queue.async {

            guard let state = Registrar.getProcessState(forID: pid) else {
                return
            }
            genServer.terminateCleanup(reason: reason, data: state)
            Registrar.unlink(name)
        }
        return (SwErlPassed.ok, nil)
    }
    
    /// Terminates a `GenServerBehavior` identified by its PID.
    /// - Parameters:
    ///   - pid: The PID of the `GenServerBehavior`.
    ///   - reason: The reason for termination.
    /// - Returns: A tuple indicating the result of the operation and any relevant error.
    ///     on fail: (SwErlPassed.fail, SwErlError)
    ///     on success: (SwErlPassed.ok, nil)
    public static func unlink(_ pid: Pid, _ reason: String) -> SwErlResponse {
        guard let process = Registrar.getProcess(forID: pid) else {
            return (SwErlPassed.fail, SwErlError.notRegisteredByPid)
        }
        guard let genServer = process.genServerBehavior else {
            // ibidum except "OTP process exists but is not gen server"
            return (SwErlPassed.fail, SwErlError.notGenServer_behavior)
        }
        process.queue.async {
            guard let state = Registrar.getProcessState(forID: pid) else {
                return
            }
            genServer.terminateCleanup(reason: reason, data: state)
            Registrar.unlink(pid)
        }
        return (SwErlPassed.ok, nil)
    }
    
    /// Asynchronously sends a cast message to a `GenServerBehavior` instance identified by its name.
    /// - Parameters:
    /// - Parameters:
    ///   - name: The registered name of the `GenServerBehavior`.
    ///   - message: The message content.
    public static func cast(_ name: String, _ message: Any) throws {
        guard let pid = Registrar.getPid(forName: name) else {
            throw SwErlError.notRegisteredByName
        }
        try cast(pid, message)
    }
    /// Asynchronously sends a cast message to a `GenServerBehavior` instance identified by its PID.
    /// - Parameters:
    ///   - id: The PID of the `GenServerBehavior`.
    ///   - message: The message content.
    public static func cast(_ id: Pid, _ message: Any) throws {
        guard let process = Registrar.getProcess(forID: id) else {
            throw SwErlError.notGenServer_behavior
        }
        guard let genServer = process.genServerBehavior else {
            throw SwErlError.notGenServer_behavior
        }
        guard let _ = Registrar.getProcessState(forID: id) else {
            throw SwErlError.invalidState //Notable Race condition here (though also an unreachable
            // state): this state check happens, the OTP process manipulates state to nil,
            // the genserver is cast to with a nil state.
            // Left as is for now because this error, being caused internally, should error
            // within the context of the process and result in erlang-style error handling.
            // Bubbling up through the links until something is configured to trap exits.

        }
        process.queue.async {

            guard let state = Registrar.getProcessState(forID: id) else {
                return
            }
            //if handle cast returns nil, return early
            guard let updatedState =  genServer.handleCast(request: message, data: state) else{
                return
            }
            //if handle state returns something other than nil, set the new state to be the current state.
            Registrar.setProcessState(forID: id, value:
                                       updatedState)
        }
    }
    
    /// Synchronously sends a call message to a `GenServerBehavior` instance and waits for a reply.
    /// - Parameters:
    ///   - name: The registered name of the `GenServerBehavior`.
    ///   - message: The message content.
    /// - Returns: A tuple indicating the success or failure of the operation and the reply or error.
    ///     on fail: (SwerlPassed.fail, SwErlError)
    ///     on success: (SwErlPassed.ok, Any)
    public static func call(_ name: String, _ message: Any) throws  -> SwErlResponse {
        guard let pid = Registrar.getPid(forName: name) else {
            throw SwErlError.notRegisteredByName
        }
        return try call(pid, message)
    }
  
    /// Synchronously sends a call message to a `GenServerBehavior` identified by its PID and waits for a reply.
    /// - Parameters:
    ///   - pid: The PID of the `GenServerBehavior` instance.
    ///   - message: The message content.
    /// - Returns: A tuple indicating the success or failure of the operation and the reply or error.
    ///     on fail: (SwerlPassed.fail, SwErlError)
    ///     on success: (SwErlPassed.ok, Any)
    public static func call(_ id: Pid, _ message: Any) throws -> SwErlResponse {
        guard let process = Registrar.getProcess(forID: id) else {
            throw SwErlError.notGenServer_behavior
        }
        guard let genServer = process.genServerBehavior else {
            throw SwErlError.notGenServer_behavior
        }
        guard let _ = Registrar.getProcessState(forID: id) else {
            throw SwErlError.invalidState //Notable Race condition here (though also an unreachable
            // state): this state check happens, the OTP process manipulates state to nil,
            // the genserver is cast to a nil state.
            // Left as is for now because this error, being caused internally, should error
            // within the context of the process and result in erlang-style error handling.
            // Bubbling up through the links until something is configured to trap exits.

        }
        let response = process.queue.sync { () -> Any in
            guard let state = Registrar.getProcessState(forID: id) else {
                return (SwErlPassed.fail, SwErlError.invalidState)

            }
            let (response, updateState) = genServer.handleCall(request: message, data: state)
            
            Registrar.setProcessState(forID: id, value: updateState)
            return response
        }
        return (SwErlPassed.ok, response)
    }
}

