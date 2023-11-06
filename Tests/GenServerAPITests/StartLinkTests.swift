//
//  File.swift
//  
//
//  Created by SwErl on 11/5/23.
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
        let initialState: Any? = nil
        let serverPid = try! GenServer.startLink(SimpleCastServer.self, initialState)
        //check that the registry populated correctly
        let (serverType,_,serverData) = try XCTUnwrap(
            Registrar.instance.OTPActorsLinkedToPid[serverPid], "failed to unwrap type from pid")
        XCTAssertNoThrow(serverType as! SimpleCastServer.Type)
        XCTAssertNil(serverData, "State not properly registered")
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
        let initialState: Any? = nil
        let name = try GenServer.startLink("name_test", SimpleCastServer.self, initialState)
        let serverPid = try XCTUnwrap(
            Registrar.instance.processesLinkedToName[name], "failed to unwrap pid from name")
        let (serverType,_,serverData) = try XCTUnwrap(
            Registrar.instance.OTPActorsLinkedToPid[serverPid], "failed to unwrap type from pid")
        XCTAssertNoThrow(serverType as! SimpleCastServer.Type)
        XCTAssertEqual(firstPid, serverPid, "PID not registered")
        XCTAssertNil(serverData, "State not properly registered")
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
        
        let serverPid = try XCTUnwrap(
            Registrar.instance.processesLinkedToName[name], "failed to unwrap pid from name")
        let (_,_,serverData) = try XCTUnwrap(
            Registrar.instance.OTPActorsLinkedToPid[serverPid], "failed to unwrap type from pid")
        
        let unwrappedData = try XCTUnwrap(serverData, "failed to unwrap serverData")
        
        let string: String = unwrappedData as! String //BUG this unwrap should be attached to an assert!
        
        XCTAssertEqual("A simple State", string, "State not properly registered")
    }
    
    func testComplexState() throws {
        let initState = ("pretend_atom", false,(3.1415 ,[2, 3, 5, 7, 11]))
        try GenServer.startLink("complex stateful", SimpleCastServer.self, initState)
        let serverPid = try XCTUnwrap(
            Registrar.instance.processesLinkedToName[name], "failed to unwrap pid from name")
        let (_,_,serverData) = try XCTUnwrap(
            Registrar.instance.OTPActorsLinkedToPid[serverPid], "failed to unwrap type from pid")
        
        let unwrappedData = try XCTUnwrap(serverData, "failed to unwrap serverData")
        
        let (string, bool, (float, list)) = unwrappedData as! (String, Bool, (Float, [Int])) //BUG this should be attached to an assert!
        XCTAssertEqual(string, "pretend_atom", "string Saved incorrectly")
        XCTAssertFalse(bool, "bool saved incorrectly")
        XCTAssertEqual(float, 3.1415, "float saved incorrectly")
        XCTAssertEqual(list, [1,2,3,4,5], "list saved incorrectly")
    }
}
