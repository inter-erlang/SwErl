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
        let PID = try event_manager.link(name: "tester", intialHandlers: [])
        XCTAssertEqual(1, Registrar.instance.processesLinkedToName.keys.count)
        XCTAssertEqual(1,Registrar.instance.OTPActorsLinkedToPid.keys.count)
        XCTAssertNotNil(PID)
        let OTPActorDefinition = Registrar.instance.OTPActorsLinkedToPid[PID]
        XCTAssertNotNil(OTPActorDefinition)
        let (OTPType,queueToUse,intialHandlers) = OTPActorDefinition!
        XCTAssertNoThrow(OTPType as! event_manager.Type)
        XCTAssertNotEqual(DispatchQueue.global(), queueToUse)
        XCTAssertEqual(0, (intialHandlers as! [Any]).count)
    }
    
    func testDefaultNamedLink() throws {
        XCTAssertNoThrow(try event_manager.link(name: "tester", intialHandlers: []))
        XCTAssertEqual(1, Registrar.instance.processesLinkedToName.keys.count)
        XCTAssertEqual(1,Registrar.instance.OTPActorsLinkedToPid.keys.count)
        let PID = Registrar.instance.processesLinkedToName["tester"]
        XCTAssertNotNil(PID)
        let OTPActorDefinition = Registrar.instance.OTPActorsLinkedToPid[PID!]
        XCTAssertNotNil(OTPActorDefinition)
        let (OTPType,queueToUse,intialHandlers) = OTPActorDefinition!
        XCTAssertNoThrow(OTPType as! event_manager.Type)
        XCTAssertNotEqual(.global(), queueToUse)
        XCTAssertEqual(0, (intialHandlers as! [Any]).count)
    }
    
    func testNamedDefinedQueueLink() throws {
        XCTAssertNoThrow(try event_manager.link(queueToUse:DispatchQueue.main, name: "tester", intialHandlers: []))
        XCTAssertEqual(1, Registrar.instance.processesLinkedToName.keys.count)
        XCTAssertEqual(1,Registrar.instance.OTPActorsLinkedToPid.keys.count)
        let PID = Registrar.instance.processesLinkedToName["tester"]
        XCTAssertNotNil(PID)
        let OTPActorDefinition = Registrar.instance.OTPActorsLinkedToPid[PID!]
        XCTAssertNotNil(OTPActorDefinition)
        let (OTPType,queueToUse,intialHandlers) = OTPActorDefinition!
        XCTAssertNoThrow(OTPType as! event_manager.Type)
        XCTAssertNotEqual(.main, queueToUse)
        XCTAssertEqual(0, (intialHandlers as! [Any]).count)
    }
    
    func testNamedWithHandlersLink() throws {
        let testingHandlers = [Pid(id: 0, serial: 1, creation: 0),
                        Pid(id:0, serial: 2, creation: 0),
                        Pid(id: 0, serial: 3, creation: 0)]
        XCTAssertNoThrow(try event_manager.link(name: "tester", intialHandlers: testingHandlers))
        XCTAssertEqual(1, Registrar.instance.processesLinkedToName.keys.count)
        XCTAssertEqual(1,Registrar.instance.OTPActorsLinkedToPid.keys.count)
        let PID = Registrar.instance.processesLinkedToName["tester"]
        XCTAssertNotNil(PID)
        let OTPActorDefinition = Registrar.instance.OTPActorsLinkedToPid[PID!]
        XCTAssertNotNil(OTPActorDefinition)
        let (OTPType,queueToUse,intialHandlers) = OTPActorDefinition!
        guard let intialHandlers = intialHandlers as? [Pid] else{
            XCTAssertTrue(false)
            return
        }
        XCTAssertNoThrow(OTPType as! event_manager.Type)
        XCTAssertNotEqual(.main, queueToUse)
        XCTAssertEqual(3, intialHandlers.count)
        XCTAssertEqual(testingHandlers[0], intialHandlers[0])
        XCTAssertEqual(testingHandlers[1], intialHandlers[1])
        XCTAssertEqual(testingHandlers[2], intialHandlers[2])
    }
    
    func testUnlink() throws {
        Registrar.instance.processesLinkedToName["bad_name"] = Pid(id: 0, serial: 1, creation: 0)
        Registrar.instance.processesLinkedToName["not manager"] = Pid(id: 0, serial: 2, creation: 0)
        Registrar.instance.OTPActorsLinkedToPid[Pid(id: 0, serial: 2, creation: 0)] = (gen_statem.Type.self,DispatchQueue.global(),4) as? (any OTPActor_behavior.Type, DispatchQueue, Any?)
        XCTAssertNoThrow(event_manager.unlink(name: "no_exist"))
        XCTAssertNoThrow(event_manager.unlink(name: "bad_name"))
        XCTAssertNoThrow(event_manager.unlink(name: "not manager"))
        //event_manager.unlink is a facade function over the top of Registrar.unlink. That function
        //has its own unit tests, so I'm not including a 'happy path' here.
    }
    
    func testAddStatelessHandler() throws {
        
        Registrar.instance.processesLinkedToName["some manager"] = Pid(id: 0, serial: 1, creation: 0)
        let OTPActorDescription:(any OTPActor_behavior.Type, DispatchQueue, Any?) = (gen_statem.self,DispatchQueue.global(),[])
        Registrar.instance.OTPActorsLinkedToPid[Pid(id: 0, serial: 1, creation: 0)] =  OTPActorDescription
        XCTAssertNoThrow(try event_manager.add(to: "some manager"){(PID,message) in
            //this is a testing do-nothing handler
        })
        let (_,_,handlers) = Registrar.instance.OTPActorsLinkedToPid[Pid(id: 0, serial: 1, creation: 0)] as! (any OTPActor_behavior.Type, DispatchQueue, [Pid])
        XCTAssertEqual(1, handlers.count)
        //closures are not equatable, therefore not test can be done to make sure void return closures are in the correct locations.
        
    }
    
    func testAddStatefulHandler() throws {
        
        Registrar.instance.processesLinkedToName["some manager"] = Pid(id: 0, serial: 1, creation: 0)
        let OTPActorDescription:(any OTPActor_behavior.Type, DispatchQueue, Any?) = (gen_statem.self,DispatchQueue.global(),[])
        Registrar.instance.OTPActorsLinkedToPid[Pid(id: 0, serial: 1, creation: 0)] =  OTPActorDescription
        XCTAssertNoThrow(try event_manager.add(to: "some manager", initialState: ""){(PID,state, message) -> SwErlState in
            return 3
        })
        let (_,_,handlers) = Registrar.instance.OTPActorsLinkedToPid[Pid(id: 0, serial: 1, creation: 0)] as! (any OTPActor_behavior.Type, DispatchQueue, [Pid])
        XCTAssertEqual(1, handlers.count)
        //closures are not equatable, therefore not test can be done to make sure void return closures are in the correct locations.
    }
    
    func testHandlerExecution() throws{
        let expectationA = XCTestExpectation(description: "handler a.")
        let expectationB = XCTestExpectation(description: "handler b.")
        let expectationC = XCTestExpectation(description: "handler c.")
        let expectationD = XCTestExpectation(description: "handler d.")
        
        let testManagerPid = Pid(id: 0, serial: 1, creation: 0)
        Registrar.instance.processesLinkedToName["test manager"] = testManagerPid
        let OTPActorDescription:(any OTPActor_behavior.Type, DispatchQueue, Any?) = (event_manager.self,DispatchQueue.global(),[try spawn(name:"A"){(PID:Pid, message:SwErlMessage) in
            expectationA.fulfill()
            return//stateless
        },try spawn(name:"B"){(PID, message) in
            expectationB.fulfill()
            return//stateless
        },try spawn(name:"C",initialState: ""){(PID:Pid, state:SwErlState, message:SwErlMessage) -> (SwErlResponse,SwErlState) in
            expectationC.fulfill()
            return ((SwErlPassed.ok,"response"),3)//Stateful process with response. Response is ignored. This is an valid, though strange, type of process for event managers. It should not crash.
        },try spawn(name:"D",initialState: ""){(PID:Pid, state:SwErlState, message:SwErlMessage) -> SwErlState in
            expectationD.fulfill()
            return 3//stateful no response sent back
        }])
        Registrar.instance.OTPActorsLinkedToPid[Pid(id: 0, serial: 1, creation: 0)] =  OTPActorDescription
        XCTAssertNoThrow(try event_manager.notify(PID: testManagerPid, message: ""))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
