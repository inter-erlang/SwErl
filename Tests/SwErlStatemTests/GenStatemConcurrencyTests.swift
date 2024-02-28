//
//  GenStatemConcurrencyTests.swift
//  
//
//  Created by yenrab on 11/27/23.
//

import XCTest
@testable import SwErl

final class GenStatemConcurrencyTests: XCTestCase {

    //This StateM expects to get an XCT expectation as state. when casted, called, or  notified it
    // fulfills the expectation.
    enum expectationStateM:GenStatemBehavior{
        
        static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
            if let exp = message as? XCTestExpectation {
                exp.fulfill()
            }
            return current_state
        }
        
        static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
            if let exp = message as? XCTestExpectation {
                exp.fulfill()
            }
        }
        
        
        static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
            try GenStateM.startLink(name: name, statem: expectationStateM.self, initialData: initial_data)
        }
        
        static func unlinked(message: SwErlMessage, current_state: SwErlState) {
            //do nothing
        }
        
        static func initialize(initialData: Any) -> SwErl.SwErlState {
            initialData
        }
        
        static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
            if let exp = message as? XCTestExpectation {
                exp.fulfill()
            }
            return ((SwErlPassed.ok,"ok"), current_state)
        }
    
    }
    
    override func setUp() {
        Registrar.local.processesLinkedToName = [:]
        Registrar.local.processesLinkedToPid = [:]
        Registrar.local.processStates = [:]
        Registrar.local.OTPActorsLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
    }
    override func tearDown() {
        Registrar.local.processesLinkedToName = [:]
        Registrar.local.processesLinkedToPid = [:]
        Registrar.local.processStates = [:]
        Registrar.local.OTPActorsLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
    }
    
    func testConcurrentCreation() {
        
        let testQueue = DispatchQueue(label: "testCQ", attributes: .concurrent)
        let count = 100000
        var expectations:[XCTestExpectation] = []
        for i in 1...count {
            let linkExpectation = XCTestExpectation(description: "link\(i)")
            expectations.append(linkExpectation)
            testQueue.async {
                _ = try! GenStateM.startLink(name: "\(i)", statem: expectationStateM.self, initialData: 3)
                linkExpectation.fulfill()
            }
        }
        wait(for: expectations, timeout: 20.0)
        
        XCTAssertEqual(count, Registrar.local.processesLinkedToName.count)
        XCTAssertEqual(count, Registrar.local.processStates.count)
        XCTAssertEqual(count, Registrar.local.processesLinkedToPid.count)
    }
    func testConcurrentCall()throws{
        try GenStateM.startLink(name: "called_to", statem: expectationStateM.self, initialData: 3)
        let testQueue = DispatchQueue(label: "testCQ", attributes: .concurrent)
        let count = 100000
        var expectations:[XCTestExpectation] = []
        for i in 1...count {
            let callExpectation = XCTestExpectation(description: "call\(i)")
            expectations.append(callExpectation)
            testQueue.async {
                _ = GenStateM.call(name: "called_to",message: callExpectation)
            }
        }
        wait(for: expectations, timeout: 20.0)
    }
    
    func testConcurrentCast()throws{
        try GenStateM.startLink(name: "cast_to", statem: expectationStateM.self, initialData: 3)
        let testQueue = DispatchQueue(label: "testCQ", attributes: .concurrent)
        let count = 100000
        var expectations:[XCTestExpectation] = []
        for i in 1...count {
            let callExpectation = XCTestExpectation(description: "cast\(i)")
            expectations.append(callExpectation)
            testQueue.async {
                GenStateM.cast(name: "cast_to",message: callExpectation)
            }
        }
        wait(for: expectations, timeout: 20.0)
    }
    
    func testConcurrentNotify()throws{
        try GenStateM.startLink(name: "notice_receiver", statem: expectationStateM.self, initialData: 3)
        let testQueue = DispatchQueue(label: "testCQ", attributes: .concurrent)
        let count = 100000
        var expectations:[XCTestExpectation] = []
        for i in 1...count {
            let noticeExpectation = XCTestExpectation(description: "notice\(i)")
            expectations.append(noticeExpectation)
            testQueue.async {
                GenStateM.notify(name: "notice_receiver",message: noticeExpectation)
            }
        }
        wait(for: expectations, timeout: 20.0)
    }

}
