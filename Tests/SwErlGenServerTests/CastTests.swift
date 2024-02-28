//
//  CastTests.swift
//  
//
//  Created by Sylvia Deal on 11/5/23.
//

import XCTest

@testable import SwErl

final class Cast : XCTestCase {
    let castExp = XCTestExpectation(description: "sucessful cast to server")
    
    override func setUpWithError() throws {
        resetRegistryAndPIDCounter()
        try! GenServer.startLink("test server", SimpleCastServer.self, castExp) //BUG This should do more than just fail th tests, this should log a message why.
        
    }
    
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
    //cast to extant process with a non-erroring message.
    func testHappy() {
        try! GenServer.cast("test server", "anything")
        wait(for: [castExp], timeout: 10)
    }
    
    func testUnregisteredPid() {
        XCTAssertThrowsError(
            try GenServer.cast(Pid(id: 100, serial: 100, creation: 100), "any message"),
            "unregistered Pid did not error"){ (error) in
                XCTAssertEqual(error as! SwErlError, SwErlError.notGenServer_behavior)
            }
    }
    
    func testUnregisteredName() {
        XCTAssertThrowsError(
            try GenServer.cast("unregistered name", "any message"),
            "unregistered Name did not error"){ (error) in
                XCTAssertEqual(error as! SwErlError, SwErlError.notRegisteredByName,
                               "incorrect error type")
            }
    }
    
    func testWrongBehavior() {
        XCTAssertThrowsError(
            try GenServer.cast(Pid(id: 0, serial: 2, creation: 0), "any message"),
            "attempt to cast to non-genserver type did not error"){ (error) in
                XCTAssertEqual(error as! SwErlError, SwErlError.notGenServer_behavior,
                               "incorrect error type")
            }
    }
    func testStateMutation() {
        let azalea = try! GenServer.startLink(concurrencyServer.self, 0)
        try! GenServer.cast(azalea, "write")
        Thread.sleep(forTimeInterval: 1) //ensure no concurrent read+write on Registrar
        XCTAssertEqual(1, Registrar.local.processStates[azalea] as! Int, "cast failed to mutate state")
    }
}

final class CastMultipleServers : XCTestCase {
    let lilyExpectation = XCTestExpectation(description: "successful cast to lily (Server 1)")

    let tulipExpectation = XCTestExpectation(description: "successful cast to tulip (Server 2")
  
    override func setUpWithError() throws {
        resetRegistryAndPIDCounter()
        // arbitrary names to abate confusion from generic numbering
        // eg: server1, server2 -> lily, tulip
        try! GenServer.startLink("lily" , SimpleCastServer.self, lilyExpectation)
        try! GenServer.startLink("tulip", SimpleCastServer.self, tulipExpectation)
    }
    
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
    func testCasts() {
        try! GenServer.cast("lily", "message")
        try! GenServer.cast("tulip", "message")
        wait(for: [lilyExpectation, tulipExpectation], timeout: 10)
    }
}
