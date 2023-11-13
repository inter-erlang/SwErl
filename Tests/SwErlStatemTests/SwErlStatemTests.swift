//
//  SwErlStatemTests.swift
//
//
//  Created by Lee Barney on 10/6/23.
//

import XCTest
@testable import SwErl

//dummy statem_behavior used across several tests
enum TesterStatem:GenStatemBehavior{
    
    static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
        if let (_,testHelper) = message as? (SwErlPassed,()->()){
            testHelper()
        }
        else{
            let testHelper = message as! ()->()
            testHelper()
        }
        return "executed"//return the modified state
    }
    
    static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
        //do nothing
    }
    
    
    static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
        try GenStateM.startLink(name: name, statem: TesterStatem.self, initialData: initial_data)
    }
    
    static func unlinked(message: SwErlMessage, current_state: SwErlState) {
        //do nothing
    }
    
    static func initialize(initialData: Any) throws -> SwErl.SwErlState {
        initialData
    }
    
    static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
        let (recieverHelper,responderHelper) = message as! (()->(),()->())
        recieverHelper()
        return ((SwErlPassed.ok,responderHelper), current_state)
    }
}

final class SwErlStatemTests: XCTestCase {

    override func setUp() {
        // Clear the Registrar and reset the pidCounter
        // Set up any synchronous per-test state here.
        Registrar.instance.processesLinkedToName = [:]
        Registrar.instance.processesLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }
    
    override func tearDown() {
        print("tearing down")
        // Clear the Registrar and reset the pidCounter
        Registrar.instance.processesLinkedToName = [:]
        Registrar.instance.processesLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }

    //
    // gen_statem_tests
    //
    func testGenStatemStartLink() throws {
        
        //Happy path
        let PID = try GenStateM.startLink(name: "someName", statem: TesterStatem.self, initialData: ("bob",13,(22,45)))
        XCTAssertEqual(Pid(id: 0,serial: 1,creation: 0),PID)
        XCTAssertEqual(PID, Registrar.instance.processesLinkedToName["someName"])
        let theProcess = Registrar.instance.processesLinkedToPid[PID]!
        XCTAssertEqual(PID,theProcess.registeredPid)
        XCTAssertNil(theProcess.statelessLambda)
        XCTAssertNil(theProcess.syncStatefulLambda)
        XCTAssertNil(theProcess.asyncStatefulLambda)
        
        let (_,_,_,_) = theProcess.GenStatemProcessWrappers!
        XCTAssertNotNil(Registrar.instance.processStates[PID])
        let (name,age,(weight,height)) = Registrar.instance.processStates[PID] as! (String,Int,(Int,Int))
        XCTAssertEqual("bob", name)
        XCTAssertEqual(13, age)
        XCTAssertEqual(22, weight)
        XCTAssertEqual(45, height)
        
    }
    
    func testGenStatemCast() throws{
        
        enum Not_statem:OTPActor_behavior{}
        //setup case
        //happy setup
        let (aSerial,aCreation) = pidCounter.next()
        let OTP_Pid = Pid(id: 0, serial: aSerial, creation: aCreation)
        let queueToUse = DispatchQueue(label: Pid.to_string(OTP_Pid) ,target: DispatchQueue.global())
        

        
        //mocked Pids made here for other functions in the GenStatemBehavior
        
        let handleCall = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//unused in this test
        }
        let handleCast = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),TesterStatem.handleCast(message: message, current_state: state))
        }
        
        let unlinked = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        let notify = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        //build and link the GenStatemBehavior
        let OTP_Process = SwErlProcess(queueToUse:queueToUse, registrationID: OTP_Pid, OTP_Wrappers: (handleCall,handleCast,unlinked,notify))
        try Registrar.link(OTP_Process, name: "some_name", PID: OTP_Pid)
        Registrar.instance.processStates[OTP_Pid] = 3
        
        //Happy path
        let castExpectation = XCTestExpectation(description: "cast.")
        GenStateM.cast(name: "some_name", message: {
            castExpectation.fulfill()
        })
        
        wait(for: [castExpectation], timeout: 5.0)
        
        //Nasty thoughts start here
        //name not registered
        XCTAssertNoThrow(GenStateM.cast(name: "bob", message: 50))
    }
//    
//    func testGenStatemCall() throws{
//        
//        //setup case
//        enum requester_statem:statem_behavior{
//            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
//                
//                return ((SwErlPassed.ok,"nothing"),current_state)
//            }
//            
//            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState? {
//                let responseHelper = message as! ()->()
//                responseHelper()
//                return 5//return the modified state
//            }
//            
//            static func initializeState(initialData: Any) throws -> Any {
//                initialData
//            }
//            
//            static func notify(PID: Pid, message: Any) {
//                return
//            }
//            
//            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
//                try gen_statem.start_link(name: name, actor_type: tester_statem.self, initialData: initial_data)
//            }
//            
//            static func unlinked(reason: String, current_state: Any) {
//                //do nothing
//            }
//        }
//        
//        let RequesterPID = Pid(id: 0,serial: 1,creation: 0)
//        let queue_to_use = DispatchQueue(label: Pid.to_string(RequesterPID) ,target: DispatchQueue.global())
//        Registrar.instance.OTPActorsLinkedToPid[RequesterPID] = (requester_statem.self as statem_behavior.Type,queue_to_use,3)
//        Registrar.instance.processesLinkedToName["requester"] = RequesterPID
//        
//        //the responder is the tester_statem at the top of this file
//        let ResponderPID = Pid(id: 0,serial: 2,creation: 0)
//        Registrar.instance.OTPActorsLinkedToPid[ResponderPID] = (tester_statem.self as statem_behavior.Type,queue_to_use,3)
//        Registrar.instance.processesLinkedToName["responder"] = ResponderPID
//        
//        
//        let receivedExpectation = XCTestExpectation(description: "received")
//        let respondedExpectation = XCTestExpectation(description: "responded")
//        
//        //Happy path
//        let helperClosureTuple = ({
//            ()->() in
//            receivedExpectation.fulfill()
//        }, {
//            ()->() in
//            respondedExpectation.fulfill()
//        })
//        try gen_statem.call(name: "responder", from: "requester", message: helperClosureTuple)
//        
//    }
//    
//    func testUnlink() throws{
//        let PID = Pid(id: 0,serial: 1,creation: 0)
//        let queue_to_use = DispatchQueue(label: Pid.to_string(PID) ,target: DispatchQueue.global())
//        Registrar.instance.OTPActorsLinkedToPid[PID] = (tester_statem.self as statem_behavior.Type,queue_to_use,"hello")
//        Registrar.instance.processesLinkedToName["some_name"] = PID
//        
//        //happy path
//        XCTAssertEqual(1, Registrar.instance.processesLinkedToName.count)
//        XCTAssertEqual(1, Registrar.instance.OTPActorsLinkedToPid.count)
//        XCTAssertNoThrow(gen_statem.unlink(name: "some_name", reason: "testing"))
//        XCTAssertEqual(0, Registrar.instance.processesLinkedToName.count)
//        XCTAssertEqual(0, Registrar.instance.OTPActorsLinkedToPid.count)
//        
//        //nasty thoughts start here
//        XCTAssertNoThrow(gen_statem.unlink(name: "not_linked", reason: "testing"))
//        
//    }
//    
    func testStartlinkPerformance() throws {
        enum SpeedStatem:GenStatemBehavior{
            static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
                //do nothing
            }
            
            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
                current_state
            }
            
            
            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
                try GenStateM.startLink(name: name, statem: SpeedStatem.self, initialData: initial_data)
            }
            
            
            static func unlinked(message: SwErlMessage, current_state: SwErlState) {
                
            }
            static func initialize(initialData: Any) throws -> SwErl.SwErlState {
                initialData
            }
            
            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState? {
                return current_state
            }
            
            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
                ((SwErlPassed.ok,3),3)
            }
        }
        
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of registered statem_behavior  instances not including state data size: \(MemoryLayout<SpeedStatem>.size + MemoryLayout<DispatchQueue>.size) bytes")
        print("!!!!!!!!!!!!!!!!!!!")
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting start_link speed")
        let timer = ContinuousClock()
        let count:UInt64 = 1000000
        var linkTime:UInt64 = 0
        let names = (0..<1000000).map({"name\($0)"})
        for name in names{
            let time = try timer.measure{
                _ = try SpeedStatem.start_link(queueToUse: nil, name: name, initial_data: 3)
            }
            linkTime = linkTime + UInt64(time.components.attoseconds)
        }
        print("statem linking took \(linkTime/count) attoseconds per link")
        print("!!!!!!!!!!!!!!!!!!!")
    }
    
    func testCastPerformance() throws {
        enum SpeedStatem:GenStatemBehavior{
            static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
                //do nothing
            }
            
            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
                guard let (_,expect) = message as? (UInt64,XCTestExpectation) else{
                    return current_state
                }
                expect.fulfill()
                return ("hello",Double.random(in: 0.0...1.0))
            }
            
            static func initialize(initialData: Any) throws -> SwErl.SwErlState {
                initialData
            }
            
            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
                try GenStateM.startLink(name: name, statem: SpeedStatem.self, initialData: initial_data)
            }
            
            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
                ((SwErlPassed.ok,3),3)
            }
            
            static func unlinked(message reason: SwErlMessage, current_state: SwErlState) {
                
            }
        }
        
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of registered statem_behavior  instances not including state data size: \(MemoryLayout<SpeedStatem>.size + MemoryLayout<DispatchQueue>.size) bytes")
        print("!!!!!!!!!!!!!!!!!!!")
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting cast speed")
        _ = try SpeedStatem.start_link(queueToUse: nil, name: "statemSpeed", initial_data: ("Are you there?",3))
        
        var expectations:[XCTestExpectation] = []
        let timer = ContinuousClock()
        let count:UInt64 = 1000000
        var linkTime:UInt64 = 0
        for i in (0..<count){
            let anExpectation = XCTestExpectation(description: "\(i)")
            expectations.append(anExpectation)
            let time = timer.measure{
                GenStateM.cast(name: "statemSpeed", message: (i,anExpectation))
            }
            linkTime = linkTime + UInt64(time.components.attoseconds)
        }
        wait(for: expectations, timeout: 30.0)
        print("statem linking took \(linkTime/count) attoseconds per link")
        print("!!!!!!!!!!!!!!!!!!!")
    }
//    /*
//    func testCallPerformance() throws{
//        //setup case
//        enum requester_statem:statem_behavior{
//            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
//                
//                return ((SwErlPassed.ok,"nothing"),current_state)
//            }
//            
//            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState? {
//                let responseHelper = message as! ()->()
//                responseHelper()
//                return 5//return the modified state
//            }
//            
//            static func initializeState(initialData: Any) throws -> Any {
//                initialData
//            }
//            
//            static func notify(PID: Pid, message: Any) {
//                return
//            }
//            
//            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
//                try gen_statem.start_link(name: name, actor_type: tester_statem.self, initialData: initial_data)
//            }
//            
//            static func unlinked(reason: String, current_state: Any) {
//                //do nothing
//            }
//        }
//        
//        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting call speed")
//        let RequesterPID = Pid(id: 0,serial: 1,creation: 0)
//        let queue_to_use = DispatchQueue(label: Pid.to_string(RequesterPID) ,target: DispatchQueue.global())
//        Registrar.instance.OTPActorsLinkedToPid[RequesterPID] = (requester_statem.self as statem_behavior.Type,queue_to_use,3)
//        Registrar.instance.processesLinkedToName["requester"] = RequesterPID
//        
//        //the responder is the tester_statem at the top of this file
//        let ResponderPID = Pid(id: 0,serial: 2,creation: 0)
//        Registrar.instance.OTPActorsLinkedToPid[ResponderPID] = (tester_statem.self as statem_behavior.Type,queue_to_use,3)
//        Registrar.instance.processesLinkedToName["responder"] = ResponderPID
//        
//        let count:Int64 = 10
//        var expectations:[XCTestExpectation] = []
//        let timer = ContinuousClock()
//        var callingTime:Int64 = 0
//        for id in 0..<count{
//            let aReceivedExpectation = XCTestExpectation(description: "received \(id)")
//            let aRespondedExpectation = XCTestExpectation(description: "responded \(id)")
//            expectations.append(aReceivedExpectation)
//            expectations.append(aRespondedExpectation)
//            //Happy path
//            let helperClosureTuple = ({
//                ()->() in
//                aReceivedExpectation.fulfill()
//            }, {
//                ()->() in
//                aRespondedExpectation.fulfill()
//            })
//            let time = try timer.measure{
//                try gen_statem.call(name: "responder", from: "requester", message: helperClosureTuple)
//            }
//            callingTime = callingTime + time.components.attoseconds
//        }
//        
//        wait(for: expectations, timeout: 30.0)
//        print("sending message via cast to statem took \(callingTime/count) attoseconds per call")
//        print("!!!!!!!!!!!!!!!!!!!")
//        
//        
//    }
//    
//    
//    func testCastPerformance() throws{
//        enum Speed_statem:statem_behavior{
//            
//            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
//                try gen_statem.start_link(name: name, actor_type: Speed_statem.self, initialData: initial_data)
//            }
//            
//            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState? {
//                guard let expectation = message as? XCTestExpectation else {
//                    print("couldn't cast correctly")
//                    return current_state
//                }
//                expectation.fulfill()
//                return current_state
//            }
//            
//            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
//                ((SwErlPassed.ok,3),3)
//            }
//            
//            static func notify(PID: Pid, message: Any) {
//                
//            }
//            
//            static func initializeState(initialData: Any) throws -> Any {
//                initialData
//            }
//            
//            static func unlinked(reason: String, current_state: Any) {
//                
//            }
//        }
//        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting cast speed")
//        let timer = ContinuousClock()
//        let count:Int64 = 10
//        let _ = try Speed_statem.start_link(queueToUse: .global(), name: "caster", initial_data: "")
//        var castingTime:Int64 = 0
//        var expectations:[XCTestExpectation] = []
//        let castingGroup = DispatchGroup()
//        for count in 0..<1000{
//            let anExpection = XCTestExpectation(description: "\(count)")
//            expectations.append(anExpection)
//            let time = try timer.measure{
//                _ = try gen_statem.cast(name: "caster", message: anExpection)
//            }
//            castingTime = castingTime + time.components.attoseconds
//        }
//        wait(for: expectations, timeout: 30.0)
//        castingGroup.wait()
//        print("sending message via cast to statem took \(castingTime/count) attoseconds per cast")
//        print("!!!!!!!!!!!!!!!!!!!")
//    }
//     */

}
