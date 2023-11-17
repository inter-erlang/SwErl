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
        

        
        //wrappers used by GenStateM
        
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
    
    func testGenStatemCall() throws{
        
        //setup case
        enum requesterStatem:GenStatemBehavior{
            static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
                return//do nothing
            }
            
            static func initialize(initialData: Any) throws -> SwErl.SwErlState {
                initialData
            }
            
            static func unlinked(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) {
                return//do nothing
            }
            
            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
                return 5
            }
            
            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
                let responseHelper = message as! ()->()
                responseHelper()
                return ((SwErlPassed.ok,5 + (current_state as! Int)),current_state)
            }
            
            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
                try GenStateM.startLink(name: name, statem: requesterStatem.self, initialData: initial_data)
            }
        }
        
        //wrappers used by GenStateM
        let handleCall = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return (requesterStatem.handleCall(message: message, current_state: state))
        }
        let handleCast = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//unused in this test
        }
        
        let unlinked = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        let notify = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        
        let (aSerial,aCreation) = pidCounter.next()
        let OTP_Pid = Pid(id: 0, serial: aSerial, creation: aCreation)
        let queueToUse = DispatchQueue(label: Pid.to_string(OTP_Pid) ,target: DispatchQueue.global())
        
        //build and link the GenStatemBehavior
        let OTP_Process = SwErlProcess(queueToUse:queueToUse, registrationID: OTP_Pid, OTP_Wrappers: (handleCall,handleCast,unlinked,notify))
        try Registrar.link(OTP_Process, name: "some_name", PID: OTP_Pid)
        Registrar.instance.processStates[OTP_Pid] = 3
        
        //Happy path
        let castExpectation = XCTestExpectation(description: "cast.")
        let (success,response) = GenStateM.call(name: "some_name", message: {
            castExpectation.fulfill()
        })
        XCTAssertEqual(8, (response as! Int))
        XCTAssertEqual(success, SwErlPassed.ok)
    }
    
    func testUnlink() throws{
        //setup case
        enum requesterStatem:GenStatemBehavior{
            static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
                return
            }
            
            static func initialize(initialData: Any) throws -> SwErl.SwErlState {
                initialData
            }
            
            static func unlinked(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) {
                let responseHelper = message as! ()->()
                responseHelper()
                return
            }
            
            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
                return 5
            }
            
            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
                return ((SwErlPassed.ok,5),5)
            }
            
            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
                try GenStateM.startLink(name: name, statem: requesterStatem.self, initialData: initial_data)
            }
        }
        
        //wrappers used by GenStateM
        let handleCall = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return (requesterStatem.handleCall(message: message, current_state: state))
        }
        let handleCast = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//unused in this test
        }
        
        let unlinked = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        let notify = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        
        let (aSerial,aCreation) = pidCounter.next()
        let OTP_Pid = Pid(id: 0, serial: aSerial, creation: aCreation)
        let queueToUse = DispatchQueue(label: Pid.to_string(OTP_Pid) ,target: DispatchQueue.global())
        
        //build and link the GenStatemBehavior
        let OTP_Process = SwErlProcess(queueToUse:queueToUse, registrationID: OTP_Pid, OTP_Wrappers: (handleCall,handleCast,unlinked,notify))
        try Registrar.link(OTP_Process, name: "some_name", PID: OTP_Pid)
        Registrar.instance.processStates[OTP_Pid] = 3
        
        //Happy path
        let castExpectation = XCTestExpectation(description: "unlink.")
        let (passed,response) = GenStateM.unlink(name: "some_name", message: {
            castExpectation.fulfill()
        })
        //make sure the code functions even though these values have no real meaning
        XCTAssertEqual(SwErlPassed.ok, passed)
        XCTAssertNil(response)
        //making sure the registrar was updated correctly
        XCTAssertNil(Registrar.instance.processesLinkedToName["some_name"])
        XCTAssertNil(Registrar.instance.processesLinkedToPid[OTP_Pid])
        
    }
    
    func testNotify() throws{
        //setup case
        enum requesterStatem:GenStatemBehavior{
            static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
                let responseHelper = message as! ()->()
                responseHelper()
                return
            }
            
            static func initialize(initialData: Any) throws -> SwErl.SwErlState {
                initialData
            }
            
            static func unlinked(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) {
                return
            }
            
            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
                return 5
            }
            
            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
                return ((SwErlPassed.ok,5),5)
            }
            
            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
                try GenStateM.startLink(name: name, statem: requesterStatem.self, initialData: initial_data)
            }
        }
        
        //wrappers used by GenStateM
        let handleCall = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return (requesterStatem.handleCall(message: message, current_state: state))
        }
        let handleCast = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//unused in this test
        }
        
        let unlinked = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        let notify = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        
        let (aSerial,aCreation) = pidCounter.next()
        let OTP_Pid = Pid(id: 0, serial: aSerial, creation: aCreation)
        let queueToUse = DispatchQueue(label: Pid.to_string(OTP_Pid) ,target: DispatchQueue.global())
        
        //build and link the GenStatemBehavior
        let OTP_Process = SwErlProcess(queueToUse:queueToUse, registrationID: OTP_Pid, OTP_Wrappers: (handleCall,handleCast,unlinked,notify))
        try Registrar.link(OTP_Process, name: "some_name", PID: OTP_Pid)
        Registrar.instance.processStates[OTP_Pid] = 3
        
        //Happy path
        let castExpectation = XCTestExpectation(description: "unlink.")
        GenStateM.notify(name: "some_name", message: {
            castExpectation.fulfill()
        })
    }
    
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
    func testCallPerformance() throws {
        enum SpeedStatem:GenStatemBehavior{
            static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
                //do nothing
            }
            
            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
                return 5
            }
            
            static func initialize(initialData: Any) throws -> SwErl.SwErlState {
                initialData
            }
            
            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
                try GenStateM.startLink(name: name, statem: SpeedStatem.self, initialData: initial_data)
            }
            
            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
                return ((SwErlPassed.ok,Double.random(in: 0.0...1.0)),current_state)
            }
            
            static func unlinked(message reason: SwErlMessage, current_state: SwErlState) {
                
            }
        }
        
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of registered statem_behavior  instances not including state data size: \(MemoryLayout<SpeedStatem>.size + MemoryLayout<DispatchQueue>.size) bytes")
        print("!!!!!!!!!!!!!!!!!!!")
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting call speed")
        _ = try SpeedStatem.start_link(queueToUse: nil, name: "statemSpeed", initial_data: ("Are you there?",3))
        
        let timer = ContinuousClock()
        let count:UInt64 = 1000000
        var linkTime:UInt64 = 0
        for i in (0..<count){
            let time = timer.measure{
                let _ = GenStateM.call(name: "statemSpeed", message: i)
            }
            linkTime = linkTime + UInt64(time.components.attoseconds)
        }
        print("statem linking took \(linkTime/count) attoseconds per link")
        print("!!!!!!!!!!!!!!!!!!!")
    }

}
