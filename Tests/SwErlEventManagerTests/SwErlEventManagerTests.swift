//
//  SwErlEventManagerTests.swift
//
//
//  Created by Lee Barney on 10/25/23.
//

import XCTest
@testable import SwErl

final class SwErlEventManagerTests: XCTestCase {

    override func setUp() {
        
        // Clear the Registrar and the counter for the PIDs
        Registrar.instance.processesLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }
    
    override func tearDown() {
        // Clear the Registrar and the counter for the PIDs
        Registrar.instance.processesLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }

    
    func testDefaultLink() throws {
        let PID = try EventManager.link(name: "tester", intialHandlers: [])
        XCTAssertEqual(PID,Registrar.instance.processesLinkedToName["tester"])
        XCTAssertNotNil(Registrar.instance.processesLinkedToPid[PID])
        XCTAssertNotNil(PID)
        XCTAssertNotNil(Registrar.instance.processesLinkedToPid[PID])
        XCTAssertNotEqual(DispatchQueue.global(), Registrar.instance.processesLinkedToPid[PID]!.queue)
    }

    
    func testNamedDefinedQueueLink() throws {
        let PID = try EventManager.link(queueToUse:DispatchQueue.main, name: "tester", intialHandlers: [])
        XCTAssertNotNil(Registrar.instance.processesLinkedToPid[PID])
        XCTAssertNotEqual(.main, Registrar.instance.processesLinkedToPid[PID]!.queue)
        XCTAssertEqual(0, Registrar.instance.processesLinkedToPid[PID]!.eventHandlers!.count)
    }
    
    func testNamedWithHandlersLink() throws {
        //create a list of handlers that do nothing
        let testingHandlers = [{(PID:Pid,message:SwErlMessage) in return},{(PID:Pid,message:SwErlMessage) in return},{(PID:Pid,message:SwErlMessage) in return},{(PID:Pid,message:SwErlMessage) in return},{(PID:Pid,message:SwErlMessage) in return}]
        let PID = try EventManager.link(name: "tester", intialHandlers: testingHandlers)
        XCTAssertNotNil(PID)
        
        XCTAssertEqual(PID,Registrar.instance.processesLinkedToName["tester"])
        XCTAssertNotNil(Registrar.instance.processesLinkedToPid[PID])
        XCTAssertNotEqual(.main, Registrar.instance.processesLinkedToPid[PID]!.queue)
        let handlers = Registrar.instance.processesLinkedToPid[PID]!.eventHandlers!
        XCTAssertEqual(5, handlers.count)
    }

    func testUnlink() throws {
        Registrar.instance.processesLinkedToName["not used"] = Pid(id: 0, serial: 1, creation: 0)
        Registrar.instance.processesLinkedToName["not used other"] = Pid(id: 0, serial: 2, creation: 0)
        let PID = Pid(id: 0, serial: 3, creation: 0)
        let process = SwErlProcess(queueToUse:.main,registrationID: PID, eventHandlers: [])
        try Registrar.link(process, name: "real", PID: PID)
        XCTAssertNoThrow(EventManager.unlink(name: "real"))
        XCTAssertNoThrow(EventManager.unlink(name: "not real"))
        XCTAssertNoThrow(EventManager.unlink(name: "not real other"))
        //EventManager.unlink is a facade function over the top of Registrar.unlink. That function
        //has its own unit tests, so I'm not including a 'happy path' here.
    }

    func testAddHandler() throws {

        let PID = Pid(id: 0, serial: 3, creation: 0)
        let process = SwErlProcess(queueToUse:.main,registrationID: PID, eventHandlers: [])
        Registrar.instance.processesLinkedToName["some manager"] = PID
        Registrar.instance.processesLinkedToPid[PID] = process
        EventManager.add(handler:{(PID,message) in
            //this is a testing do-nothing handler
        },to: "some manager")
        XCTAssertEqual(1, Registrar.instance.processesLinkedToPid[PID]!.eventHandlers!.count)
        //closures are not equatable, therefore not test can be done to make sure void return closures are in the correct locations.

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
        Registrar.instance.processesLinkedToName["some manager"] = PID
        Registrar.instance.processesLinkedToPid[PID] = process
        
        EventManager.notify(PID: PID, message: "")
        wait(for: [expectationA,expectationB,expectationC,expectationD], timeout: 5.0)
    }
    
    func testNoHandlers() throws{
        let PID = Pid(id: 0, serial: 3, creation: 0)
        let process = SwErlProcess(queueToUse:.main,registrationID: PID, eventHandlers: [])
        Registrar.instance.processesLinkedToName["some manager"] = PID
        Registrar.instance.processesLinkedToPid[PID] = process
        
        EventManager.notify(PID: PID, message: "")
    }
    
    func testlinkPerformance() throws {
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of registered state machine proces  instances not including handlers' size: \(MemoryLayout<SwErlProcess>.size + MemoryLayout<DispatchQueue>.size) bytes")
        print("!!!!!!!!!!!!!!!!!!!")
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting link speed")
        let testingHandlers = [{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        }]
        
        let timer = ContinuousClock()
        let count:UInt64 = 1000000
        var linkTime:UInt64 = 0
        for i in (0..<count){
            let time = try timer.measure{
                _ = try EventManager.link(name: "tester\(i)", intialHandlers: testingHandlers)
            }
            linkTime = linkTime + UInt64(time.components.attoseconds)
        }
        print("event manager link took \(linkTime/count) attoseconds per link")
        print("!!!!!!!!!!!!!!!!!!!")
    }
    
    func testAddHandlerPerformance() throws {
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of registered state machine proces  instances not including handlers' size: \(MemoryLayout<SwErlProcess>.size + MemoryLayout<DispatchQueue>.size) bytes")
        print("!!!!!!!!!!!!!!!!!!!")
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting add speed")
        let testingHandler:@Sendable (Pid,SwErlMessage)->() = {(PID:Pid, message:SwErlMessage) in
            return
        }
        _ = try EventManager.link(name: "tester", intialHandlers: [])
        
        let timer = ContinuousClock()
        let count:UInt64 = 10000
        var linkTime:UInt64 = 0
        for _ in (0..<count){
            let time = timer.measure{
                EventManager.add(handler: testingHandler, to: "tester")
            }
            linkTime = linkTime + UInt64(time.components.attoseconds)
        }
        print("event manager add took \(linkTime/count) attoseconds per addition")
        print("!!!!!!!!!!!!!!!!!!!")
    }
    
    func testNotifyPerformance() throws {
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of registered state machine proces  instances not including handlers' size: \(MemoryLayout<SwErlProcess>.size + MemoryLayout<DispatchQueue>.size) bytes")
        print("!!!!!!!!!!!!!!!!!!!")
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting notify speed")
        let testingHandlers = [{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        }]
        _ = try EventManager.link(name: "tester", intialHandlers: testingHandlers)
        
        let timer = ContinuousClock()
        let count:UInt64 = 1000000
        var linkTime:UInt64 = 0
        for i in (0..<count){
            let time = timer.measure{
                let _ = EventManager.notify(name: "tester", message: i)
            }
            linkTime = linkTime + UInt64(time.components.attoseconds)
        }
        print("event manager notify took \(linkTime/count) attoseconds per message")
        print("!!!!!!!!!!!!!!!!!!!")
    }

}
