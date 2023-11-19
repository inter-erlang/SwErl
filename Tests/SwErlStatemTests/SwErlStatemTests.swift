//
//  SwErlStatemTests.swift
//
//
//  Created by Lee Barney on 10/6/23.
//

import XCTest
@testable import SwErl

final class SwErlStatemTests: XCTestCase {

    override func setUp(){
        // Clear the Registrar and reset the pidCounter
        Registrar.instance.processesLinkedToName = [:]
        Registrar.instance.processesLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
        
        //setup case
        enum RequesterStatem:GenStatemBehavior{
            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
                try GenStateM.startLink(name: name, statem: RequesterStatem.self, initialData: initial_data)
            }
            
            static func initialize(initialData: Any) throws -> SwErl.SwErlState {
                initialData
            }
            
            static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
                let responseHelper = message as! ()->()
                responseHelper()
                return ((SwErlPassed.ok,5),current_state)
            }
            
            static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
                return ((SwErlPassed.ok,(message as! Int) + (current_state as! Int)),current_state)
            }
            
            static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
                let responseHelper = message as! ()->()
                responseHelper()
                return
            }
            
            static func unlinked(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) {
                let responseHelper = message as! ()->()
                responseHelper()
                return
            }
        }
        
        //wrappers used by GenStateM in the test
        let handleCall = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return (RequesterStatem.handleCall(message: message, current_state: state))
        }
        let handleCast = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),RequesterStatem.handleCast(message: message, current_state: state))
        }
        let unlinked = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            RequesterStatem.unlinked(message: message, current_state: state)
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        let notify = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            RequesterStatem.notify(message: message, state: state)
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        //put everything in the correct place
        let (aSerial,aCreation) = pidCounter.next()
        let OTP_Pid = Pid(id: 0, serial: aSerial, creation: aCreation)
        let queueToUse = DispatchQueue(label: Pid.to_string(OTP_Pid) ,target: DispatchQueue.global())
        
        //build and link the GenStatemBehavior
        let OTP_Process = SwErlProcess(queueToUse:queueToUse, registrationID: OTP_Pid, OTP_Wrappers: (handleCall,handleCast,unlinked,notify))
        do{
            try Registrar.link(OTP_Process, name: "requester", PID: OTP_Pid)
            Registrar.instance.processStates[OTP_Pid] = 3
        }
        catch{
            print("\n\n!!!!!!!! setUp FAILED !!!!!!!!\n\(error)\n\n")
        }
     }
    
    override func tearDown() {
        // Clear the Registrar and reset the pidCounter
        Registrar.instance.processesLinkedToName = [:]
        Registrar.instance.processesLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }

    //
    // gen_statem_tests
    //
    func testGenStatemStartLink() throws {
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
        //Happy path
        let PID = try GenStateM.startLink(name: "someName", statem: TesterStatem.self, initialData: ("bob",13,(22,45)))
        XCTAssertEqual(Pid(id: 0,serial: 2,creation: 0),PID)//the pid's serial should be 2 since the setup pid's serial is 1
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
        
        //Happy path
        let castExpectation = XCTestExpectation(description: "cast.")
        GenStateM.cast(name: "requester", message: {
            castExpectation.fulfill()
        })
        
        wait(for: [castExpectation], timeout: 5.0)
        
        //Nasty thoughts start here
        //name not registered
        XCTAssertNoThrow(GenStateM.cast(name: "bob", message: 50))
    }
    
    func testGenStatemCall() throws{
        
        //Happy path
        let (success,response) = GenStateM.call(name: "requester", message: 5)
      
        XCTAssertEqual(8, (response as! Int))
        XCTAssertEqual(success, SwErlPassed.ok)
    }
    
    func testUnlink() throws{
        
        //Happy path
        let unlinkExpectation = XCTestExpectation(description: "unlink.")
        let (passed,response) = GenStateM.unlink(name: "requester", message: {
            unlinkExpectation.fulfill()
        })
        wait(for: [unlinkExpectation], timeout: 5.0)
        //make sure the code functions even though these values have no real meaning
        XCTAssertEqual(SwErlPassed.ok, passed)
        XCTAssertNil(response)
        //making sure the registrar was updated correctly
        XCTAssertNil(Registrar.instance.processesLinkedToName["requester"])
        XCTAssertNil(Registrar.instance.processesLinkedToPid[Pid(id: 0,serial: 1,creation: 0)])
        
    }
    
    func testNotify() throws{
        
        //Happy path
        let notifyExpectation = XCTestExpectation(description: "unlink.")
        GenStateM.notify(name: "requester", message: {
            notifyExpectation.fulfill()
        })
        wait(for: [notifyExpectation], timeout: 5.0)
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


final class ConcurrencyTests: XCTestCase {
    
    //This StateM expects to get an XCT expectation as state. when casted, called, or  notified it
    // fulfills the expectation.
    
    //This fails hard, though. It downright segfaults which is annoying to catch to say the least.
    enum expectationStateM:GenStatemBehavior{
        
        static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
            if let exp = current_state as? XCTestExpectation {
                exp.fulfill()
            }
            return current_state
        }
        
        static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState) {
            //do nothing
        }
        
        
        static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
            try GenStateM.startLink(name: name, statem: expectationStateM.self, initialData: initial_data)
        }
        
        static func unlinked(message: SwErlMessage, current_state: SwErlState) {
            //do nothing
        }
        
        static func initialize(initialData: Any) throws -> SwErl.SwErlState {
            initialData
        }
        
        static func handleCall(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> (SwErl.SwErlResponse, SwErl.SwErlState) {
            if let exp = current_state as? XCTestExpectation {
                exp.fulfill()
            }
            return ((SwErlPassed.ok,"ok"), current_state)
        }
    
    }
    
    override func setUp() {
        Registrar.instance.processesLinkedToName = [:]
        Registrar.instance.processesLinkedToPid = [:]
        Registrar.instance.processStates = [:]
        pidCounter = ProcessIDCounter()
    }
    override func tearDown() {
        Registrar.instance.processesLinkedToName = [:]
        Registrar.instance.processesLinkedToPid = [:]
        Registrar.instance.processStates = [:]
        pidCounter = ProcessIDCounter()
    }
    
    @discardableResult
    func addOneStateM(_ name: String, _ expectation: XCTestExpectation) -> Pid {
        try! GenStateM.startLink(name: name, statem: expectationStateM.self, initialData: expectation)
    }
    
    func testConcurrentCreation() {
            for i in 1...1000000 {
                DispatchQueue.global().async {
                self.addOneStateM("statem_\(i)", XCTestExpectation(description: "unused_\(i)"))
            }
        }
        Thread.sleep(forTimeInterval: 10)
        print(Registrar.instance.processesLinkedToName)
    }
}
