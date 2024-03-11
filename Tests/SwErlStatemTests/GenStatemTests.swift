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
        Registrar.local.processesLinkedToName = [:]
        Registrar.local.processesLinkedToPid = [:]
        Registrar.local.OTPActorsLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
        
        //setup case
        enum RequesterStatem:GenStatemBehavior{
            static func start_link(queueToUse: DispatchQueue?, name: String, initial_data: Any) throws -> Pid? {
                try GenStateM.startLink(name: name, statem: RequesterStatem.self, initialData: initial_data)
            }
            
            static func initialize(initialData: Any) -> SwErl.SwErlState {
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
        let (id,aSerial) = pidCounter.next()
        let OTP_Pid = Pid(id: id, serial: aSerial, creation: 0)
        let queueToUse = DispatchQueue(label: Pid.to_string(OTP_Pid) ,target: DispatchQueue.global())
        
        //build and link the GenStatemBehavior
        let OTP_Process = SwErlProcess(queueToUse:queueToUse, registrationID: OTP_Pid, OTP_Wrappers: (handleCall,handleCast,unlinked,notify))
        do{
            try Registrar.link(OTP_Process, name: "requester", PID: OTP_Pid)
            Registrar.local.processStates[OTP_Pid] = 3
        }
        catch{
            print("\n\n!!!!!!!! setUp FAILED !!!!!!!!\n\(error)\n\n")
        }
     }
    
    override func tearDown() {
        // Clear the Registrar and reset the pidCounter
        Registrar.local.processesLinkedToName = [:]
        Registrar.local.processesLinkedToPid = [:]
        Registrar.local.OTPActorsLinkedToPid = [:]
        pidCounter = ProcessIDCounter()
     }

    //
    // gen_statem_tests
    //
    func testGenStatemStartLink() throws {
        //
        // Use a specific state machine for this test that
        // won't conflict with the requester state machine
        // used in the other tests.
        //
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
            
            static func initialize(initialData: Any) -> SwErl.SwErlState {
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
        XCTAssertEqual(PID, Registrar.local.processesLinkedToName["someName"])
        let theProcess = Registrar.local.processesLinkedToPid[PID]!
        XCTAssertEqual(PID,theProcess.registeredPid)
        XCTAssertNil(theProcess.asyncStatelessLambda)
        XCTAssertNil(theProcess.syncStatefulLambda)
        XCTAssertNil(theProcess.asyncStatefulLambda)
        XCTAssertNil(theProcess.eventHandlers)
        
        let (_,_,_,_) = theProcess.GenStatemProcessWrappers!
        XCTAssertNotNil(Registrar.local.processStates[PID])
        let (name,age,(weight,height)) = Registrar.local.processStates[PID] as! (String,Int,(Int,Int))
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
        XCTAssertNil(Registrar.local.processesLinkedToName["requester"])
        XCTAssertNil(Registrar.local.processesLinkedToPid[Pid(id: 0,serial: 1,creation: 0)])
        
    }
    
    func testNotify() throws{
        
        //Happy path
        let notifyExpectation = XCTestExpectation(description: "unlink.")
        GenStateM.notify(name: "requester", message: {
            notifyExpectation.fulfill()
        })
        wait(for: [notifyExpectation], timeout: 5.0)
    }

}



