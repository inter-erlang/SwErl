//
//  GenStatemSizeAndSpeedTests.swift
//
//
//  Created by yenrab on 11/27/23.
//

import XCTest
@testable import SwErl

@available(iOS 16.0, *)
final class GenStatemSizeAndSpeedTests: XCTestCase {

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
            static func initialize(initialData: Any) -> SwErl.SwErlState {
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
            
            static func initialize(initialData: Any) -> SwErl.SwErlState {
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
        let count:UInt64 = 10000
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
            
            static func initialize(initialData: Any) -> SwErl.SwErlState {
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
