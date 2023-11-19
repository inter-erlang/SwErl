//
//  File.swift
//  
//
//  Created by SwErl on 10/30/23.
//

// What if we're 	meant to make a type for "String or tuple"


import Foundation

public protocol GenServerBehavior: OTPActor_behavior {
    
    static func initializeData(initialData:Any?) -> Any?
    
    static func terminateCleanup(reason: String, data: Any?)
        
    static func handleCast(request: Any, data: Any?)
    
//    static func handleCall(Request: Any, From: String, data: Any?)
//    static func handleMessage()
}

public enum GenServer {
    
    static func startLink<T: GenServerBehavior>(
            queueEndpoint: DispatchQueue = DispatchQueue.global(),
             _ type: T.Type, _ initialState: Any?) throws -> Pid {
        return Pid(id:0,serial:0,creation:0)
    }
    
    @discardableResult
    static func startLink<T: GenServerBehavior>(
            queueEndpoint: DispatchQueue = DispatchQueue.global(),
            _ name: String, _ type: T.Type, _ initialState: Any?) throws -> String {
        return "ok"
    }
    
    static func stop(_ name: String, _ reason: String) {
        
    }
    
    static func stop(_ id: Pid, _ reason: String) {
        
    }
    
    static func cast(_ name: String, _ message: Any) throws {
        
    }
//    static func cast(_ id: Pid, _ message: Any) throws {
//        
//    }
    
//    static func call(name: String, message: Any) throws {
//
//    }
//    static func call(id: Pid, message: Any) throws {
//
//    }
}

