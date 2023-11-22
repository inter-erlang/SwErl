//
//  File.swift
//  
//
//  Created by jonah on 11/19/23.
//

import Foundation

import XCTest
@testable import SwErl


final class CallTests : XCTestCase {
    override func setUpWithError() throws {
        resetRegistryAndPIDCounter()
        try GenServer.startLink("wisteria", concurrencyServer.self, 0)
    }
    
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
    func testNonMutatingCall() {
        XCTAssertNoThrow(try GenServer.call("wisteria", "read"), "call threw error")
    }
    
    func testMutatingCall() {
        let res = try! GenServer.call("wisteria", "write")
        XCTAssertEqual(1, res as! Int, "state did not mutate correctly")
    }
}
