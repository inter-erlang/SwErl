//
//  File.swift
//  
//
//  Created by Sylvia Deal on 11/5/23.
//

import Foundation
import XCTest
@testable import SwErl

final class Unnamed : XCTestCase {
    override func setUp() {
        resetRegistryAndPIDCounter()
    }
    
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
//    //It is difficult to testStateless as type declarations refuse to close over
//    //Values defined outside of scope. I'd like to have a captured expectation to fulfill
//    // But that'll probably need to be done using some other kind of criminality.
//    func testStateless() {
//
//    }
    func testNameless() throws {
        let initialState: Any = 10 as Any
        let serverPid = try! GenServer.startLink(SimpleCastServer.self, initialState)
        //check that the registry populated correctly
        let process = try XCTUnwrap(
            Registrar.instance.processesLinkedToPid[serverPid], "failed to unwrap type from pid")
        let serverData = try XCTUnwrap(
            Registrar.instance.processStates[serverPid], "failed to unwrap data from dict")
        XCTAssertNoThrow(serverData as! Int)
        XCTAssertNoThrow(process.genServerBehavior as! SimpleCastServer.Type)
        XCTAssertEqual(10, serverData as! Int, "State not properly registered")
    }
        

}

final class Named : XCTestCase {
    override func setUp() {
        resetRegistryAndPIDCounter()
    }
    
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
    func testNamed() throws {
        let initialState: Any = 10 as Any
        let name = try GenServer.startLink("name_test", SimpleCastServer.self, initialState)
        let serverPid = try XCTUnwrap(
            Registrar.instance.processesLinkedToName[name], "failed to unwrap pid from name")
        let process = try XCTUnwrap(
            Registrar.instance.processesLinkedToPid[serverPid], "failed to unwrap type from pid")
        let serverData = try XCTUnwrap(
            Registrar.instance.processStates[serverPid], "failed to unwrap data from dict")
        XCTAssertNoThrow(process.genServerBehavior as! SimpleCastServer.Type)
        XCTAssertNoThrow(serverData as! Int)
        XCTAssertEqual(firstPid, serverPid, "PID not registered")
        XCTAssertEqual(10, serverData as! Int, "State not properly registered")
    }
}

final class Stateful : XCTestCase {
    override func setUp() {
        resetRegistryAndPIDCounter()
    }
    
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    
    func testStateful() throws {
        let initState = "A simple state"
        try GenServer.startLink("simple stateful", SimpleCastServer.self, initState)
        print(Registrar.instance.processesLinkedToName)
        let serverPid = try XCTUnwrap(
            Registrar.instance.processesLinkedToName["simple stateful"], "failed to unwrap pid from name")
        let serverData = try XCTUnwrap(
            Registrar.instance.processStates[serverPid], "failed to unwrap type from pid")
        
        let unwrappedData = try XCTUnwrap(serverData, "failed to unwrap serverData") //May not need bonus unwrap?
        
        let string: String = unwrappedData as! String //BUG this unwrap should be attached to an assert!
        
        XCTAssertEqual("A simple state", string, "State not properly registered")
    }
    
    func testComplexState() throws {
        let initState = ("pretend_atom", false,(3.1415 ,[2, 3, 5, 7, 11]))
        try GenServer.startLink("complex stateful", SimpleCastServer.self, initState)
        let serverPid = try XCTUnwrap(
            Registrar.instance.processesLinkedToName["complex stateful"], "failed to unwrap pid from name")
        let serverData = try XCTUnwrap(
            Registrar.instance.processStates[serverPid], "failed to unwrap data from dict")
        
        let (string, bool, (float, list)) = serverData as! (String, Bool, (Double, Array<Int>))
        XCTAssertEqual(string, "pretend_atom", "string Saved incorrectly")
        XCTAssertFalse(bool, "bool saved incorrectly")
        XCTAssertEqual(float, 3.1415, "float saved incorrectly")
        XCTAssertEqual(list, [2,3,5,7,11], "list saved incorrectly")
    }
}
