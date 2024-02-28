//
//  File.swift
//  
//
//  Created by sylv on 11/19/23.
//

import Foundation
import XCTest
@testable import SwErl

final class ConcurrentAdditions : XCTestCase {
    //These tests would fail _hard_ if they failed.
    override func setUp() {
        resetRegistryAndPIDCounter()
    }
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
    @discardableResult
    func addOneGenServer(_ name: String, _ expectation: XCTestExpectation) -> String{
        try! GenServer.startLink(name, expectationServer.self, expectation)
    }

    func testConcurrentCreation() { // Registry serializes these requests respecting dictionary's thread safety level
        let Q = DispatchQueue(label: "testCQ", attributes: .concurrent)
        for i in 1...10000 {
            Q.async {
                self.addOneGenServer("gen server \(i)", XCTestExpectation(description: "unused_\(i)"))
            }

        }
        
        Q.sync(flags: .barrier) {
            XCTAssertEqual(Registrar.local.processesLinkedToName.count,
                           10000, "10000 processes not present in registrar")
        }
//        //Now for concurrent Reads and writes. It's doing setup and teardown between tests, I think!
//        // Every Server gets five requests, 20/80
//        for _ in 1...5 {
//            for i in 1...10000 {
//                Q.async {
//                    if Int.random(in: 1...5) > 1 {
//                        try! GenServer.cast("gen server \(i)", "read")
//                    }
//                    else {
//                        try! GenServer.cast("gen server \(i)", "write")
//                    }
//                }
//            }
//        }
//        Q.sync(flags: .barrier) { }
//        
//        //Add some calls in the mix!
//        for _ in 1...5 {
//            for i in 1...10000 {
//                Q.async {
//                    if Int.random(in: 1...5) > 1 {
//                        _ = try! GenServer.call("gen server \(i)", "read")
//                    }
//                    else {
//                        _ = try! GenServer.call("gen server \(i)", "write")
//                    }
//                }
//            }
//        }
        
//        Q.sync(flags: .barrier) { }
    }
}
