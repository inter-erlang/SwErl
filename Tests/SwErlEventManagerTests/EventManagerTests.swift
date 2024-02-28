//
//  SwErlEventManagerTests.swift
//
//
//  Created by Lee Barney on 10/25/23.
//

import XCTest
@testable import SwErl

final class EventManagerTests: XCTestCase {

    override func setUp() {
        
        // Clear the Registrar and the counter for the PIDs
        Registrar.local.processesLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }
    
    override func tearDown() {
        // Clear the Registrar and the counter for the PIDs
        Registrar.local.processesLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }

    
    func testDefaultLink() throws {
        let PID = try EventManager.link(name: "tester", intialHandlers: [])
        XCTAssertEqual(PID,Registrar.local.processesLinkedToName["tester"])
        XCTAssertNotNil(Registrar.local.processesLinkedToPid[PID])
        XCTAssertNotNil(PID)
        XCTAssertNotNil(Registrar.local.processesLinkedToPid[PID])
        XCTAssertNotEqual(DispatchQueue.global(), Registrar.local.processesLinkedToPid[PID]!.queue)
    }

    
    func testNamedDefinedQueueLink() throws {
        let PID = try EventManager.link(queueToUse:DispatchQueue.main, name: "tester", intialHandlers: [])
        XCTAssertNotNil(Registrar.local.processesLinkedToPid[PID])
        XCTAssertNotEqual(.main, Registrar.local.processesLinkedToPid[PID]!.queue)
        XCTAssertEqual(0, Registrar.local.processesLinkedToPid[PID]!.eventHandlers!.count)
    }
    
    func testNamedWithHandlersLink() throws {
        //create a list of handlers that do nothing
        let testingHandlers = [{(PID:Pid,message:SwErlMessage) in return},{(PID:Pid,message:SwErlMessage) in return},{(PID:Pid,message:SwErlMessage) in return},{(PID:Pid,message:SwErlMessage) in return},{(PID:Pid,message:SwErlMessage) in return}]
        let PID = try EventManager.link(name: "tester", intialHandlers: testingHandlers)
        XCTAssertNotNil(PID)
        
        XCTAssertEqual(PID,Registrar.local.processesLinkedToName["tester"])
        XCTAssertNotNil(Registrar.local.processesLinkedToPid[PID])
        XCTAssertNotEqual(.main, Registrar.local.processesLinkedToPid[PID]!.queue)
        let handlers = Registrar.local.processesLinkedToPid[PID]!.eventHandlers!
        XCTAssertEqual(5, handlers.count)
    }

    func testUnlink() throws {
        Registrar.local.processesLinkedToName["not used"] = Pid(id: 0, serial: 1, creation: 0)
        Registrar.local.processesLinkedToName["not used other"] = Pid(id: 0, serial: 2, creation: 0)
        let PID = Pid(id: 0, serial: 3, creation: 0)
        let process = SwErlProcess(queueToUse:.main,registrationID: PID, eventHandlers: [])
        try Registrar.link(process, name: "real", PID: PID)
        XCTAssertNoThrow(EventManager.unlink(name: "real"))
        XCTAssertNoThrow(EventManager.unlink(name: "not real"))
        XCTAssertNoThrow(EventManager.unlink(name: "not real other"))
        //EventManager.unlink is a facade function over the top of Registrar.unlink. That function
        //has its own unit tests, so I'm not including a 'happy path' here.
    }


    func testHandlerExecution() throws{
        let expectationA = XCTestExpectation(description: "handler a.")
        let expectationB = XCTestExpectation(description: "handler b.")
        let expectationC = XCTestExpectation(description: "handler c.")
        let expectationD = XCTestExpectation(description: "handler d.")
        
        let testingHandlers = [{(PID:Pid, message:SwErlMessage) in
            expectationA.fulfill()
            return//stateless
        },{(PID:Pid, message:SwErlMessage) in
            expectationB.fulfill()
            return//stateless
        },{(PID:Pid, message:SwErlMessage) in
            expectationC.fulfill()
            return//stateless
        },{(PID:Pid, message:SwErlMessage) in
            expectationD.fulfill()
            return//stateless
        }]
        
        let PID = Pid(id: 0, serial: 3, creation: 0)
        let process = SwErlProcess(queueToUse:.main,registrationID: PID, eventHandlers: testingHandlers)
        Registrar.local.processesLinkedToName["some manager"] = PID
        Registrar.local.processesLinkedToPid[PID] = process
        EventManager.notify(PID: PID, message: "")//trigger handlers
        wait(for: [expectationA,expectationB,expectationC,expectationD], timeout: 5.0)
    }
    
    
    func testNoHandlers() throws{
        let PID = Pid(id: 0, serial: 3, creation: 0)
        let process = SwErlProcess(queueToUse:DispatchQueue.main,registrationID: PID, eventHandlers: [])
        Registrar.local.processesLinkedToName["some manager"] = PID
        Registrar.local.processesLinkedToPid[PID] = process
        
        EventManager.notify(PID: PID, message: "")
    }
    

}
