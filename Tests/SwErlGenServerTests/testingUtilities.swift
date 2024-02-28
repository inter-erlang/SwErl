//
//  testingUtilities.swift
//  
//  contains functions and definitions which would otherwise
//  be repeated across tests
//  Created by Sylvia Deal on 10/30/23.
//

import XCTest
@testable import SwErl

//The first pid from the PID counter is always:
let firstPid = Pid(id: 0, serial: 1, creation: 0)

func resetRegistryAndPIDCounter() {
    Registrar.local.processesLinkedToName = [:]
    Registrar.local.processesLinkedToPid = [:]
    Registrar.local.processStates = [:]
    pidCounter = ProcessIDCounter()
}

enum SimpleCastServer : GenServerBehavior {
    static func handleNotify(pid: Pid, request: Any, data: Any?) -> Any? {
        return nil
    }
    static func initializeData(_ state: Any?) -> Any? {
        return state
    }
    static func terminateCleanup(reason: String, data: Any?) {
        
    }
    static func handleCast(request: Any, data: Any?)  -> Any?{
        if let exp = data as? XCTestExpectation {
            exp.fulfill()
        }
        return data
    }
    static func handleCall(request: Any, data: Any) -> (Any, Any) {
        return (request, data)
    }
}

enum expectationServer : GenServerBehavior {
    static func handleNotify(pid: SwErl.Pid, request: Any, data: Any?) -> Any? {
        return nil
    }
    static func initializeData(_ state: Any?) -> Any? {
        return state
    }
    
    static func terminateCleanup(reason: String, data: Any?) {
        
    }
    
    static func handleCast(request: Any, data: Any?)  -> Any?{
        switch request {
        case let request as String where request == "delay":
            Thread.sleep(forTimeInterval: 2)
        case let request as String where request == "fulfill":
            let exp = data as! XCTestExpectation
            exp.fulfill()
        default:
            return data
        }
        return data
    }
    static func handleCall(request: Any, data: Any) -> (Any, Any) {
        return (request, data)
    }
}

enum concurrencyServer : GenServerBehavior {
    static func handleNotify(pid: SwErl.Pid, request: Any, data: Any?) -> Any? {
        return nil
    }
    static func initializeData(_ state: Any?) -> Any? {
        state
    }
    static func terminateCleanup(reason: String, data: Any?) {
        
    }
    static func handleCast(request: Any, data: Any?) -> Any?{
        switch request {
        case let request as String where request == "read" :
            return data
        default :
            return data as! Int + 1
        }
    }
    static func handleCall(request: Any, data: Any) -> (Any, Any) {
        return (data as! Int + 1, data as! Int + 1)
    }
}
