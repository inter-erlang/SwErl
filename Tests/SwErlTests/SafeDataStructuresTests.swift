//
//  SafeDataStructuresTEsts.swift
//
//
//  Created by yenrab on 2/26/24.
//

import XCTest
@testable import SwErl

final class SafeDataStructuresTests: XCTestCase {
    
    override func setUpWithError() throws {
      
        Registrar.local.processesLinkedToPid = [:]
        Registrar.local.processesLinkedToName = [:]
    }
    
    override func tearDownWithError() throws {
        
          Registrar.local.processesLinkedToPid = [:]
          Registrar.local.processesLinkedToName = [:]
    }
    
    func testBuildSafeAddGet() throws {
        
        try buildSafe(dictionary: [String: Int](), named: "TestDictionary")
        "TestDictionary" ! (SafeDictCommand.add, "testKey", 1)
        // Verify the state is as expected
        guard let (success,value) = ("TestDictionary" ! (SafeDictCommand.get, "testKey")) as? (SwErlPassed,Int) else{
            XCTFail()
            return
        }
        XCTAssertEqual(SwErlPassed.ok,success)
        XCTAssertEqual(value, 1)
    }
    
    func testBuildSafeAddGetRaw() throws {
        
        try buildSafe(dictionary: [String: Int](), named: "TestDictionary")
        "TestDictionary" ! (SafeDictCommand.add, "testKey", 1)
        // Verify the state is as expected
        guard let (success,dict) = ("TestDictionary" ! (SafeDictCommand.getRaw)) as? (SwErlPassed,[
            String:Int]) else{
            XCTFail()
            return
        }
        XCTAssertEqual(SwErlPassed.ok,success)
        XCTAssertEqual(dict.count, 1)
        XCTAssertEqual(dict["testKey"], 1)
    }
    
    func testBuildSafeAddRemove() throws {
        try buildSafe(dictionary: [String: Int](), named: "TestDictionary")
        "TestDictionary" ! (SafeDictCommand.add, "testKey", 1)
        // Verify the state is as expected
        let (success,_) = ("TestDictionary" ! (SafeDictCommand.remove,"testKey"))
        
        guard let (rawSuccess,rawDict) = ("TestDictionary" ! (SafeDictCommand.getRaw)) as? (SwErlPassed,[
            String:Int]) else{
            XCTFail()
            return
        }
        XCTAssertEqual(SwErlPassed.ok,rawSuccess)
        XCTAssertEqual(rawDict.count, 0)
        XCTAssertEqual(rawDict["testKey"], nil)
    }
    
    func testBuildSafeGet() throws {
        let dictionary = ["testKey": 1]
        let name = "TestDictionary"
        
        try buildSafe(dictionary: dictionary, named: name)
        // Verify the state is as expected
        guard let (success,value) = ("TestDictionary" ! (SafeDictCommand.get, "testKey")) as? (SwErlPassed,Int) else{
            XCTFail()
            return
        }
        XCTAssertEqual(SwErlPassed.ok,success)
        XCTAssertEqual(value, 1)
    }
    
    func testBuildSafeGetKeys() throws {
        let dictionary = ["testKey": 1, "anotherKey": 2]
        let name = "TestDictionary"
        
        try buildSafe(dictionary: dictionary, named: name)
        
        guard let (success,keys) = ("TestDictionary" ! SafeDictCommand.getKeys) as? (SwErlPassed,[String]) else{
            XCTFail()
            return
        }
        XCTAssertEqual(SwErlPassed.ok,success)
        XCTAssertEqual(keys.count, 2)
        XCTAssertTrue(keys.contains("testKey"))
        XCTAssertTrue(keys.contains("anotherKey"))
    }
    
    func testBuildSafeGetValues() throws {
        let dictionary = ["testKey": 1, "anotherKey": 2]
        let name = "TestDictionary"
        
        try buildSafe(dictionary: dictionary, named: name)
        guard let (success,keys) = ("TestDictionary" ! SafeDictCommand.getValues) as? (SwErlPassed,[Int]) else{
            XCTFail()
            return
        }
        XCTAssertEqual(SwErlPassed.ok,success)
        XCTAssertEqual(keys.count, 2)
        XCTAssertTrue(keys.contains(1))
        XCTAssertTrue(keys.contains(2))
    }
    
    func testBuildSafeGetRaw() throws {
        let dictionary = ["testKey": 1]
        
        try buildSafe(dictionary: dictionary, named: "TestDictionary")
        guard let (success,rawDict) = ("TestDictionary" ! (SafeDictCommand.getRaw)) as? (SwErlPassed,[
            String:Int]) else{
            XCTFail()
            return
        }
        XCTAssertEqual(SwErlPassed.ok,success)
        XCTAssertEqual(rawDict.count, 1)
        XCTAssertEqual(rawDict["testKey"], 1)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
