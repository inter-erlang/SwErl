//
//  SwErlSpeedTests.swift
//  
//
//  Created by yenrab on 11/27/23.
//

import XCTest
@testable import SwErl

@available(iOS 16.0, *)
final class SwErlSpeedTests: XCTestCase {

    @available(macOS 13.0, *)
    func testSize() throws{
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of SwErlProcess: \(MemoryLayout<SwErlProcess>.size ) bytes\n!!!!!!!!!!!!!!!!!!! \n\n\n")
    }
    @available(macOS 13.0, *)
    func testAsyncStatelessSpawnSpeed() throws{
        
        
        
        let stateless = {@Sendable(procName:Pid, message:Any) in
            return
        }
        
        let timer = ContinuousClock()
        let count:Int64 = 1000000
        var totalTime:Int64 = 0
        for _ in 0..<count{
            let time = try timer.measure{
                _ = try spawnasysl(function: stateless)
            }
            totalTime = totalTime + time.components.attoseconds
        }
        print("!!!!!!!!!!!!!!!!!!! \nspawning of async stateless processes took \(totalTime/count) attoseconds per occurance")
    }
    
    func testStatefulSyncSpawnSpeed()throws{
        let syncStateful = {@Sendable (pid:Pid,state:Any,message:Any)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok, 7),Double.random(in: 0.0...1.0))
        }
        let timer = ContinuousClock()
        var totalTime:Int64 = 0
        let count:Int64 = 100000
        for _ in 0..<count{
            let time = try timer.measure{
                _ = try spawnsysf(initialState: 7, function: syncStateful)
            }
            totalTime = totalTime + time.components.attoseconds
        }
        print("spawning of synchronous stateful processes took \(totalTime/count) attoseconds per occurance")
    }
    func testStatefulAsyncSpawnSpeed()throws{
        
        
        let asyncStateful = {@Sendable (pid:Pid,state:Any,message:Any)->SwErlState in
            return 7
        }
        
        let timer = ContinuousClock()
        var totalTime:Int64 = 0
        let count:Int64 = 1000000
        for _ in 0..<count{
            let time = try timer.measure{
                _ = try spawnasysf(initialState: 7, function: asyncStateful)
            }
            totalTime = totalTime + time.components.attoseconds
        }
        print("spawning of asynchronous stateful processes took \(totalTime/count) attoseconds per occurance\n")
    }
    
    func testMessageSpeedSyncStatefull()throws{
        
        
        let syncStateful = {@Sendable (pid:Pid,state:Any,message:Any)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok, 7),Double.random(in: 0.0...1.0))
        }
        
        let timer = ContinuousClock()
        var totalTime:Int64 = 0
        let count:Int64 = 100000
        print("!!!!!!!!!!!!!!!!!!! \nsending \(count) messages to synchronous stateful process")
        let Pid = try spawnsysf(initialState: 7, function: syncStateful)
        totalTime = 0
        for _ in 0..<count{
            let time = timer.measure{
                Pid ! 3
            }
            totalTime = totalTime + time.components.attoseconds
        }
        print("synchronous Stateful SwErl message passing took \(totalTime/count) attoseconds per message sent")
        
    }

//NOTE: Speed tests for async stateful processes are not really missing. Since async stateful processes just add a message to the queueu of the process and return, the time required to make the async calls is essentially the same as the time required to make the same number of calls to a stateless process. The time required to execute the queue of messages is essentially the same as the time required to execute the queue of a syncStateful process.
        
    func testMessageSpeedStateless()throws{
        
        
        let stateless = {@Sendable(procName:Pid, message:Any) in
            return
        }
        
        let timer = ContinuousClock()
        var totalTime:Int64 = 0
        let count:Int64 = 1000000
        print("sending \(count) messages to stateless process")
        let Pid = try spawnasysl(function: stateless)
        
        for _ in 0..<count{
            let time = timer.measure{
                Pid ! 3
            }
            totalTime = totalTime + time.components.attoseconds
        }
        print(" Stateless SwErl message passing took \(totalTime/count) attoseconds per message sent")
        
    }
    
        
    func testSpeedAsyncAwait()throws{
        let timer = ContinuousClock()
        var totalTime:Int64 = 0
        let count:Int64 = 1000000
        for _ in 0..<count{
            let time = timer.measure{
                Task {
                    await duplicateStatelessProcessBehavior(message:"hello")
                }
            }
            totalTime = totalTime + time.components.attoseconds
        }
        print("!!!!!!!!!!!!!!!!!!!\nspawning stateless Async_await took \(totalTime/count) attoseconds per occurance\n")
        
        
        
        totalTime = 0
        for _ in 0..<count{
            let time = timer.measure{
                DispatchQueue.global().async {
                    self.doNothing()
                    
                }
            }
            totalTime = totalTime + time.components.attoseconds
        }
        print("!!!!!!!!!!!!!!!!!!!\nspawning stateless, raw dispatch queue took \(totalTime/count) attoseconds per call started\n")
    }
    
    //
    //The result of this test is linear, O(m) where m is the number of messages sent to a process using its name.
    //
    func testLocalNamedProcessMessageCountImpact()throws{
        print("!!!!!!!!!!!!!!!!!\nbegin ramping")
        
        let stateless = {@Sendable(procName:Pid, message:Any) in
            return
        }
        _ = try spawnasysl(name:"silly",function: stateless)
        
        
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
        let Pid = try spawnasysl(function: stateless)
        
        
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
                pids.append(try spawnasysl(function: stateless))
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
                    _ = try spawnasysl(name:"silly\(processCount)"){@Sendable(procID:Pid, message:Any) in
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
            Registrar.local.processesLinkedToPid = [:]
            pidCounter = ProcessIDCounter()
            
            var totalTime:Int64 = 0
            for processCount in 1...count {
                do{
                    let time = try timer.measure{
                        _ = try spawnasysl(name:"silly\(processCount)"){@Sendable(procID:Pid, message:Any) in
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
}

