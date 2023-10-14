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
    static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> SwErl.Pid? {
        try gen_statem.start_link(name: name, actor_type: Tester_statem.self, initial_data: initial_data)
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
        Registrar.instance.processesLinkedToName = [:]
        Registrar.instance.processesLinkedToPid = [:]
        Registrar.instance.OTPActorsLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }
    
    override func tearDown() {
        // Clear the Registrar and reset the pidCounter
        Registrar.instance.processesLinkedToName = [:]
        Registrar.instance.processesLinkedToPid = [:]
        Registrar.instance.OTPActorsLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }

    //
    // gen_statem_tests
    //
    func testGenStatemStartLink() throws {
        
        //Happy path
        let PID = try gen_statem.start_link(name: "some_name", actor_type: Tester_statem.self, initial_data: ("bob",13,(22,45)))
        XCTAssertEqual(Pid(id: 0,serial: 1,creation: 0),PID)
        XCTAssertEqual(PID, Registrar.instance.processesLinkedToName["some_name"])
        let (aType,_,Data) = Registrar.instance.OTPActorsLinkedToPid[PID]!
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
        let queue_to_use = DispatchQueue(label: Pid.to_string(PID) ,target: DispatchQueue.global())
        Registrar.instance.OTPActorsLinkedToPid[PID] = (Tester_statem.self as statem_behavior.Type,queue_to_use,"hello")
        Registrar.instance.processesLinkedToName["some_name"] = PID
        
        //nasty setup: no state
        
        let PID2 = Pid(id: 0,serial: 2,creation: 0)
        Registrar.instance.OTPActorsLinkedToPid[PID2] = (Tester_statem.self as statem_behavior.Type,queue_to_use,nil)
        Registrar.instance.processesLinkedToName["stateless"] = PID2
        
        //nasty setup: not a statem
        let PID3 = Pid(id: 0,serial: 3,creation: 0)
        Registrar.instance.OTPActorsLinkedToPid[PID3] = (Not_statem.self as Not_statem.Type,queue_to_use,"hello")
        Registrar.instance.processesLinkedToName["not_statem"] = PID3
        
        
        //nasty setup: not a statem
        let PID4 = Pid(id: 0,serial: 4,creation: 0)
        Registrar.instance.processesLinkedToName["no_pid"] = PID4
        
        
        //Happy path
        try gen_statem.cast(name: "some_name", message: 50)
        let (_,_,current_state) = Registrar.instance.OTPActorsLinkedToPid[PID]!
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
        let queue_to_use = DispatchQueue(label: Pid.to_string(PID) ,target: DispatchQueue.global())
        Registrar.instance.OTPActorsLinkedToPid[PID] = (Tester_statem.self as statem_behavior.Type,queue_to_use,"hello")
        Registrar.instance.processesLinkedToName["some_name"] = PID
        
        //happy path
        XCTAssertEqual(1, Registrar.instance.processesLinkedToName.count)
        XCTAssertEqual(1, Registrar.instance.OTPActorsLinkedToPid.count)
        XCTAssertNoThrow(gen_statem.unlink(name: "some_name", reason: "testing"))
        XCTAssertEqual(0, Registrar.instance.processesLinkedToName.count)
        XCTAssertEqual(0, Registrar.instance.OTPActorsLinkedToPid.count)
        
        //nasty thoughts start here
        XCTAssertNoThrow(gen_statem.unlink(name: "not_linked", reason: "testing"))
        
    }

    func testPerformanceExample() throws {
        
        //dummy statem_behavior used across several tests
        enum Speed_statem:statem_behavior{
            
            static func cast(name:String,message:Any)throws{
                try gen_statem.cast(name: name, message: message)
            }
            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> SwErl.Pid? {
                try gen_statem.start_link(name: name, actor_type: Speed_statem.self, initial_data: initial_data)
            }
            
            static func unlink(reason: String, current_state: Any) {
                
            }
            
            
            static func initialize_state(initial_data: Any) -> Any {
                initial_data
            }
            
            static func handle_event_cast(message: Any, current_state: Any) -> Any {
                return current_state
            }
            
            
        }
        
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of registered statem_behavior  instances not including state data size: \(MemoryLayout<Tester_statem>.size + MemoryLayout<DispatchQueue>.size) bytes")
        
        let timer = ContinuousClock()
        let count:Int64 = 1000000
        var linkTime:Int64 = 0
        let names = (0..<1000000).map({"name\($0)"})
        for name in names{
            let time = try timer.measure{
                _ = try Speed_statem.start_link(queueToUse: nil, name: name, initial_data: 3)
            }
            linkTime = linkTime + time.components.attoseconds
        }
        print("statem linking took \(linkTime/count) attoseconds per link")
        
        //clear out the registrar links
        Registrar.instance.OTPActorsLinkedToPid = [:]
        Registrar.instance.processesLinkedToName = [:]
        let _ = try Speed_statem.start_link(queueToUse: nil, name: "caster", initial_data: 3)
        var castingTime:Int64 = 0
        for _ in 0..<count{
            let time = try timer.measure{
                _ = try Speed_statem.cast(name: "caster", message: 3)
            }
            castingTime = castingTime + time.components.attoseconds
        }
        
        print("casting to statem took \(castingTime/count) attoseconds per cast")
        /*
        time = try timer.measure{
            for _ in 0..<count{
                _ = try spawn(initialState: 7, function: stateful)
            }
        }
        print("stateful spawning took \(time.components.attoseconds/count) attoseconds per instantiation\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        Registrar.instance.processesLinkedToPid = [:]//clear the million registered processes
        print("!!!!!!!!!!!!!!!!!!! \n Sending \(count) messages to stateful process")
        var Pid = try spawn(initialState: 7, function: stateful)
        time = timer.measure{
            for _ in 0..<count{
                Pid ! 3
            }
        }
        print(" Stateful message passing took \(time.components.attoseconds/count) attoseconds per message sent\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        
        print("!!!!!!!!!!!!!!!!!!! \n Sending \(count) messages to stateless process")
        Pid = try spawn(function: stateless)
        time = timer.measure{
            for _ in 0..<count{
                Pid ! 3
            }
        }
        print(" Stateless message passing took \(time.components.attoseconds/count) attoseconds per message sent\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        time = timer.measure{
            for _ in 0..<count{
                Task {
                    await duplicateStatelessProcessBehavior(message:"hello")
                }
            }
        }
        print("Async/await in Tasks took \(time.components.attoseconds/count) attoseconds per task started\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        time = timer.measure{
            for _ in 0..<count{
                DispatchQueue.global().async {
                    self.doNothing()
                    
                }
            }
        }
        print("Using dispatch queue only took \(time.components.attoseconds/count) attoseconds per call started\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        self.measure {
            // Put the code you want to measure the time of here.
        }
        */
    }

}
