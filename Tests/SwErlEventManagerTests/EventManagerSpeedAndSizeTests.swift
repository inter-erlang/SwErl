//
//  SwErlEventManagerSpeedAndSizeTests.swift
//  
//
//  Created by yenrab on 11/27/23.
//

import XCTest
@testable import SwErl

final class SwErlEventManagerSpeedAndSizeTests: XCTestCase {

    func testEventManagerSize() throws{
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of registered state machine proces  instances not including handlers' size: \(MemoryLayout<SwErlProcess>.size + MemoryLayout<DispatchQueue>.size) bytes")
        print("!!!!!!!!!!!!!!!!!!!")
    }
    func testlinkPerformance() throws {
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting link speed")
        let testingHandlers = [{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        }]
        
        let timer = ContinuousClock()
        let count:UInt64 = 1000000
        var linkTime:UInt64 = 0
        for i in (0..<count){
            let time = try timer.measure{
                _ = try EventManager.link(name: "tester\(i)", intialHandlers: testingHandlers)
            }
            linkTime = linkTime + UInt64(time.components.attoseconds)
        }
        print("event manager link took \(linkTime/count) attoseconds per link")
        print("!!!!!!!!!!!!!!!!!!!")
    }
    
    
    func testNotifyPerformance() throws {
        
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \ntesting notify speed")
        let testingHandlers = [{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        },{(PID:Pid, message:SwErlMessage) in
            return
        }]
        _ = try EventManager.link(name: "tester", intialHandlers: testingHandlers)
        
        let timer = ContinuousClock()
        let count:UInt64 = 1000000
        var linkTime:UInt64 = 0
        for i in (0..<count){
            let time = timer.measure{
                let _ = EventManager.notify(name: "tester", message: i)
            }
            linkTime = linkTime + UInt64(time.components.attoseconds)
        }
        print("event manager notify took \(linkTime/count) attoseconds per message")
        print("!!!!!!!!!!!!!!!!!!!")
    }

}
