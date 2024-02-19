//
//  GenServer.swift
//
//  Contains the template protocol and API functions for creating and interacting with GenServers.
//  Genservers are self-contained processes which can communicate in a traditional client-server fashion.
//  Genservers, like all SwErl processes, execute messages in the order they are recieved in serial.
//  Each genServer instance has it's own execution context and a state modifiable only within the genServer.
//
//  Created by Sylvia Deal on 10/30/23.
//

import Foundation

/// SwErl process extension segmenting modification and use of genServerBehavior. Not intened for user use.Used by GenServer startlink functions.
fileprivate extension SwErlProcess {
    
    /// creates a SwErl Process from a type conforming to GenServerBehavior.
    /// - Parameters:
    ///   - queue: Dispatch queue the genserver executes on
    ///   - pid: unique process identifier identical to the corrosponding pid in the registry
    ///   - functionality: a GenServerBehavior conforming type
    init<T:GenServerBehavior>(queue: DispatchQueue, pid: Pid, functionality: T.Type) {
        self.queue = queue
        self.registeredPid = pid
        self.genServerBehavior = functionality
        self.asyncStatefulLambda = functionality.handleNotify
    }
}


/// Generic Server. A user definable SwErl process supporting synchronous calls and replies as a seperate API. Like a stateful SwErl process, it stores a process state
/// in the registry, referred to as data in all hooks. Types conforming to this protocol are used to define the functionality of user created genServers.
/// Mulitple seperate genServers may be created from one conforming type. Like SwErl processes, each GenServer instance runs in it's own context--a seperate process.
/// Conforming types should be static, using SwErl infrastructure for state management.
public protocol GenServerBehavior: OTPActor_behavior {
    /// This function is called as the server starts up, before it is added to the registry. It's primary purpose is to
    /// modify or verify the startLink initialState argument if needed. Many initializeData functions will simply return
    /// the data argument unmodified.
    /// - Parameter state:initialState from startlink call.
    /// - Returns: server data provided to the server in future messages.
    static func initializeData(_ data: Any?) -> Any?
    
    /// Called when a server is unlinked via the API function GenServer.unlink() immediately before the
    /// server is removed from the registry. 
    /// - Parameters:
    /// - reason: Description of why the server is being terminated.
    /// - data: current server data of the GenServer
    static func terminateCleanup(reason: String, data: Any?)
    
    /// Called when a server instance recieves a cast message via genServer.cast(). Casts are asynchronous requests, a reply will not be sent to the caster.
    /// - Parameters:
    ///   - request: message content supplied by the caster.
    ///   - data: current server data of the genserver instance
    /// - Returns: server data provided to genserver instance in future messages
    static func handleCast(request: Any, data: Any?) -> Any?
    
    /// Called when a server instance recieves a call message via genServer.call(). Calls are synchronous, the caller will wait for a reply.
    /// - Parameters:
    ///   - request: message content supplied by the caller
    ///   - data: current server data of the GenServer instance
    /// - Returns: (response, serverData)
    ///       response: reply content sent to the caster
    ///       serverData: server data provided to genserver instance in future messages
    ///         note: You may note that the return of GenServer.call() includes a SwErlpassed enum.
    ///         this is included by the API function GenServer.call()
    static func handleCall(request: Any, data: Any) -> (Any, Any)
    
    /// called when a server recieves a message via the messaging operatior, '!'. Bang messages are asyncrhonous, a reply is not sent to the caller.
    /// - Parameters:
    ///   - pid: pid of genserver instance
    ///   - request: message content supplied by the messager
    ///   - data: current server data of the genserver instance
    /// - Returns: server data provided to genserver instance in future messages
    static func handleNotify(pid: Pid, request: Any, data: Any?) -> Any?
}

/// Gen Server API. This static type is used to create and message any and all genserver instances local to this node.
public enum GenServer {
    @discardableResult
    /// Creates and registers a genserver instance.
    /// - Parameters:
    ///   - queueEndpoint: Target dispatch queue for the GCD serial queue the genserver instance will process messages on.
    ///   - name: registers a string identifier for the genserver in addition to an automatically generated PID
    ///   - type: GenServerBehavior conforming type providing functionality ot the genserver.
    ///   - initialState: initial data provided to the genserver's .initializeData function during creation.
    /// - Returns:
    ///     on fail: SwErlError explaining the cause of failure--no genServer is registered.
    ///     on succeed: the registered name of the newly created Genserver
    static func startLink<T: GenServerBehavior>(
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
    
    @discardableResult
    /// Creates and registers a genserver instance.
    /// - Parameters:
    ///   - queueEndpoint: Target dispatch queue for the GCD serial queue the genserver instance will process messages on.
    ///   - type: GenServerBehavior conforming type providing functionality ot the genserver.
    ///   - initialState: initial data provided to the genserver's .initializeData function during creation.
    /// - Returns:
    ///     on fail: SwErlError explaining the cause of failure--no genServer is registered.
    ///     on succeed: the registered pid of the newly created Genserver
    static func startLink<T: GenServerBehavior>(
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
    /// wrapper for bang message to a given process. Functionally equivelent to `name ! message`
    /// - Parameters:
    ///   - name: registered name of a genserver
    ///   - message: message to send to the provided genserver
    static func notify(_ name: String, _ message: SwErlMessage) {
        name ! message
    }
    /// wrapper for bang message to a given process. Functionally equivelent to `pid ! message`
    /// - Parameters:
    ///   - pid: registered pid of a genserver
    ///   - message: message to send to the provided genserver
    static func notify(_ pid: Pid, _ message: SwErlMessage) {
        pid ! message
    }
    
    /// terminates a given SwErl Process. No messages recieved after an unlink message will be processed.
    /// - Parameters:
    ///   - name: registered name of a genserver
    ///   - reason: reason for termination, provided to the genserver instance's .terminateCleanup() function.
    /// - Returns:
    ///     on fail: (SwErlPassed.fail, SwErlError)
    ///         SwErlPassed.fail: an enum indicating the provided process did not unlink
    ///         SwErlError: a SwErlError indicating why the GenServer associated with the given id did not unlink
    ///     on success: (SwErlPassed.ok, nil)
    ///         SwErlPassed.ok: an enum indicating the provided process unlinked
    ///         nil: provided for consistency of return form with the failure state. nil can of course be ingorned.
    static func unlink(_ name: String, _ reason: String) -> SwErlResponse{
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
    
    /// terminates a given SwErl Process. No messages recieved after an unlink message will be processed.
    /// - Parameters:
    ///   - pid: registered pid of a genserver
    ///   - reason: reason for termination, provided to the genserver instance's .terminateCleanup() function.
    /// - Returns:
    ///     on fail: (SwErlPassed.fail, SwErlError)
    ///         SwErlPassed.fail: an enum indicating the provided process did not unlink
    ///         SwErlError: a SwErlError indicating why the GenServer associated with the given id did not unlink
    ///     on success: (SwErlPassed.ok, nil)
    ///         SwErlPassed.ok: an enum indicating the provided process unlinked
    ///         nil: provided for consistency of return form with the failure state. nil can of course be ingorned.
    static func unlink(_ pid: Pid, _ reason: String) -> SwErlResponse {
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
    
    /// Sends a cast message to a given genserver instance. The corrosponding .handleCast() method will be executed by the
    /// genserver instance. This function returns immediately.
    /// - Parameters:
    ///   - name: registered name of genserver instance
    ///   - message: message content sent to the genserver instance. provided as the message argument to the genserver instance's handleCast method.
    static func cast(_ name: String, _ message: Any) throws {
        guard let pid = Registrar.getPid(forName: name) else {
            throw SwErlError.notRegisteredByName
        }
        try cast(pid, message)
    }
    /// Sends a cast message to a given genserver instance. The corrosponding .handleCast() method will be executed by the
    /// genserver instance. This function returns immediately.
    /// - Parameters:
    ///   - pid: registered pid of genserver instance
    ///   - message: message content sent to the genserver instance. provided as the message argument to the genserver instance's handleCast method.
    static func cast(_ id: Pid, _ message: Any) throws {
        guard let process = Registrar.getProcess(forID: id) else {
            throw SwErlError.notGenServer_behavior
        }
        guard let genServer = process.genServerBehavior else {
            throw SwErlError.notGenServer_behavior
        }
        guard let _ = Registrar.getProcessState(forID: id) else {
            throw SwErlError.invalidState //Notable Race condition here (though also an unreachable
            // state): this state check happens, the OTP process manipulates state to nil,
            // the genserver is casted to with a nil state.
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
    
    /// Sends a call message to a given genserver instance. The corrosponding .handleCall() method will be executed by the
    /// genserver instance. This function waits for the called genserver to finish executing and returns a reply.
    /// - Parameters:
    ///   - name: registered name of genserver instance
    ///   - message: message content sent to the genserver instance. provided as the message argument to the genserver instance's handleCast method.
    /// - Returns:
    ///     on fail: (SwerlPassed.fail, SwErlError)
    ///         SwErlPassed.fail: An enum indicating the call failed.
    ///         SwErlError: an error enum indicating the reason for failure
    ///     on success: (SwErlPassed.ok, Any)
    ///         SwErlPassed.ok: An enum indicating the call succeeded
    ///         Any: The content of the reply from the called genserver instance.
    static func call(_ name: String, _ message: Any) throws  -> SwErlResponse {
        guard let pid = Registrar.getPid(forName: name) else {
            throw SwErlError.notRegisteredByName
        }
        return try call(pid, message)
    }
  
    /// Sends a call message to a given genserver instance. The corrosponding .handleCall() method will be executed by the
    /// genserver instance. This function waits for the called genserver to finish executing and returns a reply.
    /// - Parameters:
    ///   - pid: registered pid of genserver instance
    ///   - message: message content sent to the genserver instance. provided as the message argument to the genserver instance's handleCast method.
    /// - Returns:
    ///     on fail: (SwerlPassed.fail, SwErlError)
    ///         SwErlPassed.fail: An enum indicating the call failed.
    ///         SwErlError: an error enum indicating the reason for failure
    ///     on success: (SwErlPassed.ok, Any)
    ///         SwErlPassed.ok: An enum indicating the call succeeded
    ///         Any: The content of the reply from the called genserver instance.
    static func call(_ id: Pid, _ message: Any) throws -> SwErlResponse {
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

