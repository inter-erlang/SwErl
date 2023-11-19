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
    
    
    
    @available(macOS 13.0, *)
    func testSizeAndSpeed() throws{
        
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of SwErlProcess: \(MemoryLayout<SwErlProcess>.size ) bytes\n!!!!!!!!!!!!!!!!!!! \n\n\n")
        
        let stateless = {@Sendable(procName:Pid, message:Any) in
            return
        }
        let syncStateful = {@Sendable (pid:Pid,state:Any,message:Any)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok, 7),Double.random(in: 0.0...1.0))
        }
        let asyncStateful = {@Sendable (pid:Pid,state:Any,message:Any)->SwErlState in
            return 7
        }
        let timer = ContinuousClock()
        let count:Int64 = 1000000
        var totalTime:Int64 = 0
        for _ in 0..<count{
            let time = try timer.measure{
                _ = try spawn(function: stateless)
            }
            totalTime = totalTime + time.components.attoseconds
        }
        let dAsyncPer = Double(totalTime/count)
        print("!!!!!!!!!!!!!!!!!!! \nspawning of async stateless processes took \(totalTime/count) attoseconds per occurance")
        totalTime = 0
        for _ in 0..<count{
            let time = try timer.measure{
                _ = try spawn(initialState: 7, function: syncStateful)
            }
            totalTime = totalTime + time.components.attoseconds
        }
        let dPerSyncStateful = Double(totalTime/count)
        print("spawning of synchronous stateful processes took \(totalTime/count) attoseconds per occurance")
        
        
        
        totalTime = 0
        for _ in 0..<count{
            let time = try timer.measure{
                _ = try spawn(initialState: 7, function: asyncStateful)
            }
            totalTime = totalTime + time.components.attoseconds
        }
        let dPerAsyncStateful = Double(totalTime/count)
        print("spawning of asynchronous stateful processes took \(totalTime/count) attoseconds per occurance\n")
        print("per occurrance, sync_stateful/async_stateless ratio: \((dPerSyncStateful/dAsyncPer))")
        print("per occurrance, async_stateful/async_stateless ratio: \((dPerAsyncStateful/dAsyncPer))\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        
        Registrar.instance.processesLinkedToPid = [:]//clear the million registered processes
        print("!!!!!!!!!!!!!!!!!!! \nsending \(count) messages to synchronous stateful process")
        var Pid = try spawn(initialState: 7, function: syncStateful)
        totalTime = 0
        for _ in 0..<count{
            let time = timer.measure{
                Pid ! 3
            }
            totalTime = totalTime + time.components.attoseconds
        }
        let dSycStatefulMessPass = Double(totalTime/count)
        print("synchronous Stateful SwErl message passing took \(totalTime/count) attoseconds per message sent")
        
        

//NOTE: Speed tests for async stateful processes are not really missing. Since async stateful processes just add a message to the queueu of the process and return, the time required to make the async calls is essentially the same as the time required to make the same number of calls to a stateless process. The time required to execute the queue of messages is essentially the same as the time required to execute the queue of a syncStateful process.
        
        
        
        print("sending \(count) messages to stateless process")
        Pid = try spawn(function: stateless)
        totalTime = 0
        for _ in 0..<count{
            let time = timer.measure{
                Pid ! 3
            }
            totalTime = totalTime + time.components.attoseconds
        }
        let dStatelessMessPass = Double(totalTime/count)
        print(" Stateless SwErl message passing took \(totalTime/count) attoseconds per message sent")
        print("\nper message, sync_stateful/async_stateless ratio: \(dSycStatefulMessPass/dStatelessMessPass)\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        
        
        
        
        
        totalTime = 0
        for _ in 0..<count{
            let time = timer.measure{
                Task {
                    await duplicateStatelessProcessBehavior(message:"hello")
                }
            }
            totalTime = totalTime + time.components.attoseconds
        }
        let asyncAwaitPer = Double(totalTime/count)
        print("!!!!!!!!!!!!!!!!!!!\nspawning stateless Async_await took \(totalTime/count) attoseconds per occurance\n")
        print("per occurrance, async_await/async_stateless ratio: \((asyncAwaitPer/dAsyncPer))\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        
        
        
        totalTime = 0
        for _ in 0..<count{
            let time = timer.measure{
                DispatchQueue.global().async {
                    self.doNothing()
                    
                }
            }
            totalTime = totalTime + time.components.attoseconds
        }
        let rawDispQueuePer = Double(totalTime/count)
        print("!!!!!!!!!!!!!!!!!!!\nspawning stateless, raw dispatch queue took \(totalTime/count) attoseconds per call started\n")
        print("per occurrance, raw_disp_queue/async_stateless ratio: \((rawDispQueuePer/dAsyncPer))\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        
    }
    
    //
    //The result of this test is linear, O(m) where m is the number of messages sent to a process using its name.
    //
    func testLocalNamedProcessMessageCountImpact()throws{
        print("!!!!!!!!!!!!!!!!!\nbegin ramping")
        
        let stateless = {@Sendable(procName:Pid, message:Any) in
            return
        }
        _ = try spawn(name:"silly",function: stateless)
        
        
        let timer = ContinuousClock()
        for count in stride(from: 1000, to: 501000, by: 1000) {
            var totalTime:Int64 = 0
            for _ in 0...count{
                let time = timer.measure{
                    "silly" ! 3
                }
                totalTime = totalTime + time.components.attoseconds
            }
            print("\(count),\(totalTime)")
        }
        
        print("end message ramping\n!!!!!!!!!!!!!!!!!!")
    }
    
    //
    //The result of this test is linear, O(m) where m is the number of messages sent to a process using its Pid.
    //
    func testLocalPidMessageCountImpact()throws{
        print("!!!!!!!!!!!!!!!!!\nbegin ramping")
        
        let stateless = {@Sendable(procName:Pid, message:Any) in
            return
        }
        let Pid = try spawn(function: stateless)
        
        
        let timer = ContinuousClock()
        for count in stride(from: 1000, to: 501000, by: 1000) {
            var totalTime:Int64 = 0
            for _ in 0...count{
                let time = timer.measure{
                    Pid ! 3
                }
                totalTime = totalTime + time.components.attoseconds
            }
            print("\(count),\(totalTime)")
        }
        
        print("end message ramping\n!!!!!!!!!!!!!!!!!!")
    }
    
    
    //
    //The result of this test is linear, O(n) where n is the number of linked processes.
    //
    func testLocalPidProcessCountImpact()throws{
        print("!!!!!!!!!!!!!!!!!\nbegin process ramping")
        
        let stateless = {@Sendable(procName:Pid, message:Any) in
            return
        }
        
        for count in stride(from: 1000, to: 101000, by: 1000) {
            var pids:[Pid] = []
            for _ in 1...count{
                pids.append(try spawn(function: stateless))
            }
            //send 10000 messages to random pid
            let Pid = pids.randomElement()!
            let timer = ContinuousClock()
            var totalTime:Int64 = 0
            for _ in 0..<count{
                let time = timer.measure{
                    Pid ! 3
                }
                totalTime = totalTime + time.components.attoseconds
            }
            print("\(count),\(totalTime)")
        }
        print("end process ramping\n!!!!!!!!!!!!!!!!!!")
    }
    
    //
    //The result of this test is linear, O(n) where n is the number of named linked processes. f(n)~= 1.8n
    //
    func testNamedProcessCountImpact()throws{
        print("!!!!!!!!!!!!!!!!!\nbegin process ramping")
        
        
        for count in stride(from: 1000, to: 501000, by: 1000) {
            for processCount in 0..<10{
                do{
                    _ = try spawn(name:"silly\(processCount)"){@Sendable(procID:Pid, message:Any) in
                        return
                    }
                }
                catch{}
            }
            //send 10000 messages to random named process
            let name = "silly\(Int.random(in: 1...count))"
            let timer = ContinuousClock()
            var totalTime:Int64 = 0
            for _ in 0..<count{
                let time = timer.measure{
                    name ! 3
                }
                totalTime = totalTime + time.components.attoseconds
            }
            print("\(count),\(totalTime)")
        }
        print("end process ramping\n!!!!!!!!!!!!!!!!!!")
    }
    
    
    //
    //The result of this test is linear, O(n) where n is the number of named processes being linked.
    //
    func testSpawningNamedProcessCountImpact()throws{
        print("!!!!!!!!!!!!!!!!!\nbegin spawn ramping")
        
    let timer = ContinuousClock()
        
        for count in stride(from: 1000, to: 501000, by: 1000) {
            
            // Clear the Registrar and the counter for the PIDs
            Registrar.instance.processesLinkedToPid = [:]
            pidCounter = ProcessIDCounter()
            
            var totalTime:Int64 = 0
            for processCount in 1...count {
                do{
                    let time = try timer.measure{
                        _ = try spawn(name:"silly\(processCount)"){@Sendable(procID:Pid, message:Any) in
                            return
                        }
                    }
                    totalTime = totalTime + time.components.attoseconds
                }
                catch{}
            }
            print("\(count),\(totalTime)")
        }
        print("end spawn ramping\n!!!!!!!!!!!!!!!!!!")
    }
    
    
    
    func duplicateStatelessProcessBehavior(message:String) async{
        return
    }
    func doNothing(){
        return
    }
    
    func factorial(num:Int64)->Int64{
        let nums: [Int64] = Array(1...num)
        return nums.reduce(1){$0*$1}
    }

}
