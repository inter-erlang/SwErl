//
//  SwErlStatemTests.swift
//  
//
//  Created by Lee Barney on 10/6/23.
//

import XCTest
@testable import SwErl

//dummy statem_behavior used across several tests
enum Tester_statem:statem_behavior{
    static func start_link(queueToUse: DispatchQueue?, name: String, actor_type: SwErl.statem_behavior, initial_data: Any) throws -> SwErl.Pid? {
        nil
    }
    
    static func unlink(reason: String, current_state: Any) {
        
    }
    
    
    static func initialize_state(initial_data: Any) -> Any {
        initial_data
    }
    
    static func handle_event_cast(message: Any, current_state: Any) -> Any {
        XCTAssertEqual("hello", current_state as! String)
        return "executed"//return the modified state
    }
    
    
}

final class SwErlStatemTests: XCTestCase {

    override func setUp() {
        // Clear the Registrar and reset the pidCounter
        // Set up any synchronous per-test state here.
        Registrar.instance.processesRegisteredByPid = [:]
        pidCounter = ProcessIDCounter()
     }
    
    override func tearDown() {
        // Clear the Registrar and reset the pidCounter
        Registrar.instance.processesRegisteredByPid = [:]
        pidCounter = ProcessIDCounter()
     }

    //
    // gen_statem_tests
    //
    func testGenStatemStartLink() throws {
        
        //Happy path
        let PID = try gen_statem.start_link(name: "some_name", actor_type: Tester_statem.self, initial_data: ("bob",13,(22,45)))
        XCTAssertEqual(Pid(id: 0,serial: 1,creation: 0),PID)
        XCTAssertEqual(PID, Registrar.instance.processesRegisteredByName["some_name"])
        let (aType,Data) = Registrar.instance.OTPActorsRegisteredByPid[PID]!
        XCTAssertNoThrow(aType as! Tester_statem.Type)
        let (name,age,(x,y)) = Data! as! (String, Int, (Int, Int))
        XCTAssertEqual("bob",name)
        XCTAssertEqual(13, age)
        XCTAssertEqual(22, x)
        XCTAssertEqual(45, y)
        
        //nasty thoughts start here
        
    }
    
    func testGenStatemCast() throws{
        
        enum Not_statem:OTPActor_behavior{}
        //setup case
        //happy setup
        let PID = Pid(id: 0,serial: 1,creation: 0)
        Registrar.instance.OTPActorsRegisteredByPid[PID] = (Tester_statem.self as statem_behavior.Type,"hello")
        Registrar.instance.processesRegisteredByName["some_name"] = PID
        
        //nasty setup: no state
        
        let PID2 = Pid(id: 0,serial: 2,creation: 0)
        Registrar.instance.OTPActorsRegisteredByPid[PID2] = (Tester_statem.self as statem_behavior.Type,nil)
        Registrar.instance.processesRegisteredByName["stateless"] = PID2
        
        //nasty setup: not a statem
        let PID3 = Pid(id: 0,serial: 3,creation: 0)
        Registrar.instance.OTPActorsRegisteredByPid[PID3] = (Not_statem.self as Not_statem.Type,"hello")
        Registrar.instance.processesRegisteredByName["not_statem"] = PID3
        
        
        //nasty setup: not a statem
        let PID4 = Pid(id: 0,serial: 4,creation: 0)
        Registrar.instance.processesRegisteredByName["no_pid"] = PID4
        
        
        //Happy path
        try gen_statem.cast(name: "some_name", message: 50)
        let (_, current_state) = Registrar.instance.OTPActorsRegisteredByPid[PID]!
        XCTAssertEqual("executed", current_state as! String)
        
        //Nasty thoughts start here
        
        XCTAssertThrowsError(try gen_statem.cast(name: "stateless", message: 50))
        //name not registered
        XCTAssertThrowsError(try gen_statem.cast(name: "bob", message: 50))
        XCTAssertThrowsError(try gen_statem.cast(name: "not_statem", message: 50))
        XCTAssertThrowsError(try gen_statem.cast(name: "no_pid", message: 50))
    }
    
    func testUnlink() throws{
        let PID = Pid(id: 0,serial: 1,creation: 0)
        Registrar.instance.OTPActorsRegisteredByPid[PID] = (Tester_statem.self as statem_behavior.Type,"hello")
        Registrar.instance.processesRegisteredByName["some_name"] = PID
        
        //happy path
        XCTAssertEqual(1, Registrar.instance.processesRegisteredByName.count)
        XCTAssertEqual(1, Registrar.instance.OTPActorsRegisteredByPid.count)
        XCTAssertNoThrow(gen_statem.unlink(name: "some_name", reason: "testing"))
        XCTAssertEqual(0, Registrar.instance.processesRegisteredByName.count)
        XCTAssertEqual(0, Registrar.instance.OTPActorsRegisteredByPid.count)
        
        //nasty thoughts start here
        XCTAssertNoThrow(gen_statem.unlink(name: "not_linked", reason: "testing"))
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
