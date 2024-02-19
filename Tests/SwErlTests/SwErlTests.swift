//
//  SwErlTests.swift
//
//Copyright (c) 2023 Lee Barney
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//
//  Created by Lee Barney on 2/24/23.
//

import XCTest
@testable import SwErl



final class SwErlTests: XCTestCase {
    
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
    
    func testPidCounter() throws {
        for n in 1..<10{
            let (count,_)=pidCounter.next()
            XCTAssertEqual(UInt32(n), count)
        }
    }
    func testPidCounterRollover() throws{
        //get it ready for a rollover
        pidCounter.value = UInt32.max - 1
        pidCounter.creation = 0
        let (count,creation) = pidCounter.next()
        XCTAssertEqual(0, count)
        XCTAssertEqual(1, creation)
    }
    
    
    func testHappyPathSpawnStateless() throws {
        let PID = try spawn{(PID, message) in
            print("hello \(message)")
            return
        }
        XCTAssertEqual(1,Registrar.instance.processesLinkedToPid.count)
        XCTAssertEqual(Pid(id: 0, serial: 1, creation: 0), PID)
    }
    
    
    func testHappyPathSpawnStateful() throws {
        let _ = try spawn(initialState: 3){(procName, message,state) in
            return (true,5)
        }
        XCTAssertEqual(1,Registrar.instance.processesLinkedToPid.count)
        
    }
    func testHappyPathSpawnWithName() throws {
        _ = try spawn(name:"silly"){(PID, message) in
            print("hello \(message)")
            return
        }
        XCTAssertEqual(1,Registrar.instance.processesLinkedToName.count)
    }
    
    
    func testSendMessageUsingName() throws {
        let expectation = XCTestExpectation(description: "send completed.")
        let _ = try spawn(name:"silly"){(PID, message) in
            expectation.fulfill()
            return
        }
        let (worked,result) = "silly" ! 5
        XCTAssertEqual(SwErlPassed.ok, worked)
        XCTAssertNil(result)
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testSendMessageUsingPid() throws {
        let expectation = XCTestExpectation(description: "send completed.")
        let Pid = try spawn{(PID, message) in
            expectation.fulfill()
            return
        }
        let (worked,result) = Pid ! 5
        XCTAssertEqual(SwErlPassed.ok, worked)
        XCTAssertNil(result)
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testStatefulProcessSendMessageUsingPid() throws {
        let expectation = XCTestExpectation(description: "send completed.")
        let Pid = try spawn(initialState: 3)
        {(PID, state, message) in
            expectation.fulfill()
            return 3
        }
        let (worked,result) = Pid ! 5
        XCTAssertEqual(SwErlPassed.ok, worked)
        XCTAssertNil(result)
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testNotRegisteredPid() throws{
        XCTAssertNoThrow(Pid(id: 0, serial: 0, creation: 0) ! "hello")
        let (worked,error) = Pid(id: 0, serial: 0, creation: 0) ! "hello"
        guard let error = error as? SwErlError else{
            XCTAssertTrue(false)
            return
        }
        XCTAssertEqual(SwErlPassed.fail, worked)
        XCTAssertEqual(SwErlError.notRegisteredByPid, error)
    }
    func testChainingByCapture() throws{
        //don't let the test end until the last process
        //executes
        let expectation = XCTestExpectation(description: "second completed.")
        let secondPid = try spawn{(PID, message) in
            print("goodbye \(message)")
            expectation.fulfill()
            return
        }
        //capture the next pid
        let initialPid = try spawn{(PID, message) in
            print("hello \(message)")
            secondPid ! message
            return
        }
        XCTAssertEqual(2, Registrar.instance.processesLinkedToPid.count)
        
        initialPid ! "Sue"
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testRawChainingByList() throws {
        
        let expectation = XCTestExpectation(description: "all completed.")
        
        let initialPid = try spawn{(PID, message) in
            var (chain,data) = message as! ([Pid], Int)
            XCTAssertEqual(data, 2)
            chain.removeFirst() ! (chain,data + 3)
            return
        }
        let secondPid = try spawn{(PID, message) in
            var (chain,data) = message as! ([Pid], Int)
            XCTAssertEqual(data, 5)
            chain.removeFirst() ! (chain,data * 5)
            return
        }
        let finalPid = try spawn{(PID, message) in
            let (_,data) = message as! ([Pid], Int)
            XCTAssertEqual(data, 25)
            expectation.fulfill()
            return
        }
        let chain = [secondPid,finalPid]
        
        initialPid ! (chain,2)
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testSendMessageToStatelessProcess() throws {
        let anID = Pid(id: 0, serial: 1, creation: 0)
        
        let stateless = try SwErlProcess(registrationID: anID){(name, message) in
            return
        }
        XCTAssertNoThrow(try Registrar.link(stateless, PID: anID))
        XCTAssertNoThrow(anID ! "hello")
        XCTAssertNotNil(Registrar.instance.processesLinkedToPid[anID])
        
        let stopperID = Pid(id: 0, serial: 2, creation: 0)
        let stopper = try SwErlProcess(registrationID: stopperID){(name, message) in
            return
        }
        XCTAssertNoThrow(try Registrar.link(stopper, PID: stopperID))
        XCTAssertNoThrow(stopperID ! "hello")
        
        XCTAssertNotNil(Registrar.instance.processesLinkedToPid[stopperID])
        XCTAssertEqual(2, Registrar.instance.processesLinkedToPid.count)
    }
    
    func testStatelessSwerlProcessWithDefaults() throws {
        let bingo = Pid(id: 0, serial: 1, creation: 0)
        let stateless = try SwErlProcess(registrationID: bingo){(name, message) in
            return
        }
        XCTAssertNil(stateless.syncStatefulLambda)
        XCTAssertNil(stateless.asyncStatefulLambda)
        XCTAssertEqual(stateless.queue, DispatchQueue.global())
        XCTAssertEqual(stateless.registeredPid, bingo)
        XCTAssertNotNil(stateless.statelessLambda)
        XCTAssertNoThrow(stateless.statelessLambda!(bingo,3))
    }
    
    func testStatelessSwerlProcessNoDefaults() throws {
        let mainBingo = Pid(id: 0, serial: 1, creation: 0)
        let stateless = try SwErlProcess(queueToUse:DispatchQueue.main, registrationID: mainBingo){(name, message) in
            return
        }
        XCTAssertNil(stateless.syncStatefulLambda)
        XCTAssertNil(stateless.asyncStatefulLambda)
        XCTAssertEqual(stateless.queue, DispatchQueue.main)
        XCTAssertEqual(stateless.registeredPid, mainBingo)
        XCTAssertNotNil(stateless.statelessLambda)
        XCTAssertNoThrow(stateless.statelessLambda!(mainBingo,3))
    }
    
    func testStatefulSwerlProcessWithDefaults() throws {
        let hasStatePID = Pid(id: 0, serial: 1, creation: 0)
        let stateful:SwErlProcess = SwErlProcess(registrationID: hasStatePID){(procName, message ,state) -> (SwErlResponse,SwErlState) in
            var updatedState:[String] = state as![String]
            updatedState.append(message as! String)
            return ((SwErlPassed.ok,7),updatedState)
        }
        XCTAssertNil(stateful.statelessLambda)
        XCTAssertEqual(stateful.queue.label, Pid.to_string(hasStatePID))
        XCTAssertEqual(stateful.registeredPid, hasStatePID)
        XCTAssertNotNil(stateful.syncStatefulLambda)
        //test the stored closure
        let ((passed,responseValue),ingredients) = stateful.syncStatefulLambda!(hasStatePID,"butter",["salt","water"]) as!((SwErlPassed,Int),[String])
        XCTAssertEqual(SwErlPassed.ok, passed)
        XCTAssertEqual(7, responseValue)
        XCTAssertEqual(["salt","water","butter"], ingredients)
    }
    
    func testStatefulSwerlProcessNoDefaults() throws {
        let hasStatePID = Pid(id: 0, serial: 1, creation: 0)
        let stateful:SwErlProcess = SwErlProcess(registrationID: hasStatePID){(procName, message ,state)-> (SwErlResponse,SwErlState) in
                var updatedState:[String] = state as![String]
                updatedState.append(message as! String)
            return ((SwErlPassed.ok,7),updatedState)
            }
        XCTAssertNil(stateful.statelessLambda)
        XCTAssertNil(stateful.asyncStatefulLambda)
        XCTAssertEqual(stateful.queue.label, Pid.to_string(hasStatePID))
        XCTAssertEqual(stateful.registeredPid, hasStatePID)
        XCTAssertNotNil(stateful.syncStatefulLambda)
        //test the stored closure
        let ((passed,responseValue),ingredients) = stateful.syncStatefulLambda!(hasStatePID,"butter",["salt","water"]) as!((SwErlPassed,Int),[String])
        XCTAssertEqual(SwErlPassed.ok, passed)
        XCTAssertEqual(7, responseValue)
        XCTAssertEqual(["salt","water","butter"], ingredients)
    }
    
    func testSwErlRegistry() throws{
        let first = Pid(id: 0, serial: 1, creation: 0)
        let second = Pid(id: 0, serial: 2, creation: 0)
        let third = Pid(id: 0, serial: 3, creation: 0)
        XCTAssertEqual(Registrar.instance.processesLinkedToPid.count, 0)
        let firstProc = try SwErlProcess(registrationID: first){(procName, message) in
            return
        }
        let secondProc = try SwErlProcess(registrationID: second){(procName, message) in
            return
        }
        let thirdProc = try SwErlProcess(registrationID: third){(procName, message) in
            return
        }
        XCTAssertNil(Registrar.instance.processesLinkedToPid[first])
        XCTAssertNil(Registrar.instance.processesLinkedToPid[second])
        XCTAssertNil(Registrar.instance.processesLinkedToPid[third])
        
        XCTAssertNoThrow(try Registrar.link(firstProc, PID: first))
        XCTAssertNoThrow(try Registrar.link(secondProc, PID: second))
        XCTAssertNoThrow(try Registrar.link(thirdProc, PID: third))
        
        
        XCTAssertNotNil(Registrar.instance.processesLinkedToPid[first])
        XCTAssertNotNil(Registrar.instance.processesLinkedToPid[second])
        XCTAssertNotNil(Registrar.instance.processesLinkedToPid[third])
        XCTAssertEqual(3, Registrar.instance.processesLinkedToPid.count)
        
        
        XCTAssertThrowsError(try Registrar.link(thirdProc, PID: third))
        
        XCTAssertTrue(Registrar.getAllPIDs().contains(first))
        XCTAssertTrue(Registrar.getAllPIDs().contains(second))
        XCTAssertTrue(Registrar.getAllPIDs().contains(third))
        XCTAssertFalse(Registrar.getAllPIDs().contains(Pid(id: 0, serial: 0, creation: 0)))
        
        XCTAssertNotNil(Registrar.getProcess(forID: second))
        XCTAssertNil(Registrar.getProcess(forID: Pid(id: 0, serial: 0, creation: 0)))
        
        XCTAssertNoThrow(Registrar.unlink(second))
        XCTAssertNil(Registrar.getProcess(forID: second))
        XCTAssertEqual(2, Registrar.getAllPIDs().count)
        
        
        XCTAssertTrue(Registrar.pidLinked(third), "pidLinked not reporting true for extant pid")
        XCTAssertFalse(Registrar.pidLinked(second), "pidLinked not reporting false for extant pid")

    }
    func testSequencingOfSyncStatefulProcesses()throws{
        
        var expectations:[XCTestExpectation] = []
        let PID = try spawn(initialState: ""){(procID,state,message) ->(SwErlResponse,SwErlState) in
            guard let (data,expectation) = message as? (Double,XCTestExpectation) else{
                return ((SwErlPassed.fail,"malformed message"),state)
            }
            guard let state = state as? String else{
                return ((SwErlPassed.fail,SwErlError.invalidState),"")
            }
            expectation.fulfill()
            if state == ""{
                return ((SwErlPassed.ok,"worked"),"\(data)")
            }
            return ((SwErlPassed.ok,"worked"),"\(state),\(data)")
        }
        expectations.append(XCTestExpectation(description: "first"))
        expectations.append(XCTestExpectation(description: "second"))
        expectations.append(XCTestExpectation(description: "third"))
        PID ! (5.0,expectations[0])
        PID ! (2.0,expectations[1])
        PID ! (0.0,expectations[2])
        
        wait(for: expectations, timeout: 30.0)
        XCTAssertEqual("5.0,2.0,0.0", Registrar.instance.processStates[PID] as! String)
    }
    
    func testSequencingOfAsyncStatefulProcesses()throws{
        
        let expectation1 = XCTestExpectation(description: "first serially correct")
        let expectation2 = XCTestExpectation(description: "second serially correct")
        let expectation3 = XCTestExpectation(description: "third serially correct")
        let pid = try spawn(initialState: ""){(procID,state,message) ->Any in
            _ = self.factorial(num: 15)
            guard let state = state as? String else{
                return ""
            }
            if message as! Double == 5.0 && state == ""{
                    expectation1.fulfill()
            }
            else if message as! Double == 2.0 && state == "5.0"{
                expectation2.fulfill()
            }
            else if message as! Double == 0.0 && state == "5.0,2.0"{
                expectation3.fulfill()
            }
            if state == ""{
                return "\(message as! Double)"
            }
            return "\(state),\(message as! Double)"
        }
        var (passed,_) = pid ! 5.0
        XCTAssertEqual(SwErlPassed.ok, passed)
        (passed,_) = pid ! 2.0
        XCTAssertEqual(SwErlPassed.ok, passed)
        (passed,_) = pid ! 0.0
        XCTAssertEqual(SwErlPassed.ok, passed)
    }
    
    func factorial(num:Int64)->Int64{
        let nums: [Int64] = Array(1...num)
        return nums.reduce(1){$0*$1}
    }
}
