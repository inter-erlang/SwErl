//
//  EventManagerConcurrencyTests.swift
//  
//
//  Created by yenrab on 11/27/23.
//

import XCTest
@testable import SwErl

final class EventManagerConcurrencyTests: XCTestCase {
    
    func testConcurrentCreation() {
        let testingHandlers = [{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        }]
        let testQueue = DispatchQueue(label: "testCQ", attributes: .concurrent)
        let count = 100000
        var expectations:[XCTestExpectation] = []
        for i in 1...count {
            let linkExpectation = XCTestExpectation(description: "link\(i)")
            expectations.append(linkExpectation)
            testQueue.async {
                do{
                    _ = try EventManager.link(name: "tester\(i)", intialHandlers: testingHandlers)
                    linkExpectation.fulfill()
                }
                catch{
                    print("Creation failed: \(error)")
                }
            }
        }
        wait(for: expectations, timeout: 20.0)
        XCTAssertEqual(count, Registrar.instance.processesLinkedToName.count)
        XCTAssertEqual(0, Registrar.instance.processStates.count)
        XCTAssertEqual(count, Registrar.instance.processesLinkedToPid.count)
    }
    
    func testConcurrentNotifcation()throws {
        let count = 100000
        let expectationA = XCTestExpectation(description: "A")
        expectationA.expectedFulfillmentCount = count
        let expectationB = XCTestExpectation(description: "B")
        expectationB.expectedFulfillmentCount = count
        let expectationC = XCTestExpectation(description: "C")
        expectationC.expectedFulfillmentCount = count
        let expectationD = XCTestExpectation(description: "D")
        expectationD.expectedFulfillmentCount = count
        
        let expectations = [expectationA,expectationB,expectationC,expectationD]
        
        let testingHandlers = [{(PID:Pid, message:SwErlMessage) in
            expectationA.fulfill()
            return
        },{(PID:Pid, message:SwErlMessage) in
            expectationB.fulfill()
            return
        },{(PID:Pid, message:SwErlMessage) in
            expectationC.fulfill()
            return
        },{(PID:Pid, message:SwErlMessage) in
            expectationD.fulfill()
            return
        }]
        _ = try EventManager.link(name: "notification_tester", intialHandlers: testingHandlers)
        let testQueue = DispatchQueue(label: "testCQ", attributes: .concurrent)
        for i in 1...count {
            testQueue.async {
                EventManager.notify(name: "notification_tester", message: i)
            }
        }
        wait(for: expectations, timeout: 20.0)
    }
}
