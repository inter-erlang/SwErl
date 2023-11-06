//
//  testingUtilities.swift
//  
//  contains functions and definitions which would otherwise
//  be repeated across tests
//  Created by SwErl on 10/30/23.
//

import XCTest
@testable import SwErl

//The first pid from the PID counter is always:
let firstPid = Pid(id: 0, serial: 1, creation: 0)

func resetRegistryAndPIDCounter() {
    Registrar.instance.processesLinkedToName = [:]
    Registrar.instance.processesLinkedToPid = [:]
    Registrar.instance.OTPActorsLinkedToPid = [:]
    pidCounter = ProcessIDCounter()
}

enum SimpleCastServer : GenServerBehavior {
    static func initializeData(initialData: Any?) -> Any? {
        return initialData
    }
    
    static func terminateCleanup(reason: String, data: Any?) {
        
    }
    
    static func handleCast(request: Any, data: Any?) {
        if let exp = data as? XCTestExpectation {
            exp.fulfill()
        }
    }
}

enum StopWithQueueSever : GenServerBehavior {
    static func initializeData(initialData: Any?) -> Any? {
        return initialData
    }
    
    static func terminateCleanup(reason: String, data: Any?) {
        
    }
    
    static func handleCast(request: Any, data: Any?) {
        switch request {
        case let request as String where request == "delay":
            sleep(2000)
        case let request as String where request == "fulfill":
            let exp = data as! XCTestExpectation
            exp.fulfill()
        default:
            return
        }
    }
}
