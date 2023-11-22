//
//  File.swift
//  
//
//  Created by SwErl on 10/30/23.
//

// What if we're 	meant to make a type for "String or tuple"


import Foundation

public protocol GenServerBehavior: OTPActor_behavior {
    
    static func initializeData(_ state: Any?) -> Any?
    
    static func terminateCleanup(reason: String, data: Any?)
        
    static func handleCast(request: Any, data: Any?) -> Any?
    
    static func handleCall(request: Any, data: Any) -> (Any, Any)
    
//    static func handleCall(Request: Any, From: String, data: Any?)
//    static func handleMessage()
}

public enum GenServer {
    @discardableResult
    static func startLink<T: GenServerBehavior>(
        queueEndpoint: DispatchQueue = DispatchQueue.global(),
        _ name: String, _ type: T.Type, _ initialState: Any?) throws -> String {
            let (aSerial, aCreation) = pidCounter.next()
            let pid = Pid(id: 0, serial: aSerial, creation: aCreation)
            let state = queueEndpoint.sync { type.initializeData(initialState) }
            try Registrar.link(callbackType: type, processQueue: queueEndpoint, initState: state, name: name, PID: pid)
            return name
    }
    
    @discardableResult
    static func startLink<T: GenServerBehavior>(
        queueEndpoint: DispatchQueue = DispatchQueue.global(),
        _ type: T.Type, _ initialState: Any?) throws -> Pid {
            let (aSerial, aCreation) = pidCounter.next()
            let pid = Pid(id: 0, serial: aSerial, creation: aCreation)
            let state = queueEndpoint.sync { type.initializeData(initialState) }
            try Registrar.link(callbackType: type, processQueue: queueEndpoint, initState: state, PID: pid)
            return pid
    }
    
    static func stop(_ name: String, _ reason: String) {
        guard let pid = Registrar.getPid(forName: name) else {
            return
        }
        guard let (callbackType, queue) = Registrar.getOtpProcess(forID: pid) else {
            // This... may actually wish to send a message like "process exists but is not OTP process
            return
        }
        guard let genServer = callbackType as? GenServerBehavior.Type else {
            // ibidum except "OTP process exists but is not gen server"
            return
        }
        queue.async {
            guard let state = Registrar.getProcessState(forID: pid) else {
                return
            }
            genServer.terminateCleanup(reason: reason, data: state)
            Registrar.unlink(name) //may need a completion handler here.
        }
    }
    
    static func cast(_ name: String, _ message: Any) throws {
        guard let pid = Registrar.getPid(forName: name) else {
            throw SwErlError.notRegisteredByName
        }
        try cast(pid, message)
    }
    
    static func cast(_ id: Pid, _ message: Any) throws {
        guard let (callbackType, queue) = Registrar.getOtpProcess(forID: id) else {
            throw SwErlError.notGenServer_behavior
        }
        guard let genServer = callbackType as? GenServerBehavior.Type else {
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
        queue.async {
            guard let state = Registrar.getProcessState(forID: id) else {
                return
            }
            Registrar.setProcessState(forID: id, value:
                                        genServer.handleCast(request: message, data: state))
        }

    }
    static func call(_ name: String, _ message: Any) throws  -> Any {
        guard let pid = Registrar.getPid(forName: name) else {
            throw SwErlError.notRegisteredByName
        }
        return try call(pid, message)
    }
    
    static func call(_ id: Pid, _ message: Any) throws -> Any {
        guard let (callbackType, queue) = Registrar.getOtpProcess(forID: id) else {
            throw SwErlError.notGenServer_behavior
        }
        guard let genServer = callbackType as? GenServerBehavior.Type else {
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
        return queue.sync {
            guard let state = Registrar.getProcessState(forID: id) else {
                return
            }
            let (response, updateState) = genServer.handleCall(request: message, data: state)
            
            Registrar.setProcessState(forID: id, value: updateState)
            return response
        }
    }
}

