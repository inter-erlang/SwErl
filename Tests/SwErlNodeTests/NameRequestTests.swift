//
//  NodeAliveTests.swift
//  
//
//  Created by Barney, Lee on 5/1/24.
//

import XCTest
@testable import SwErl

final class NodeAliveTests: XCTestCase {
    let nodeAlives = [NodeAlive(portNumber: 23, nodeType: 77, comProtocol: 0, highestVersion: 6, lowestVersion: 6, nodeName: SwErlAtom("Node1"), extra: Data()), NodeAlive(portNumber: 24, nodeType: 77, comProtocol: 0, highestVersion: 6, lowestVersion: 6, nodeName: SwErlAtom("Node2"), extra: Data())]
    override func setUp()  {
        do{
            try buildSafe(dictionary: ["first":nodeAlives[0],"second":nodeAlives[1]], named: "nameNodeAliveTracker")
        }
        catch{
            //if the name is already linked, an error is thrown.
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDoNamesReq_WithValidNodeAlives() {
            let port: UInt32 = 8080
            let id = "456"
            let expectedPortData = Data(port.toErlangInterchangeByteOrder.toByteArray)

        
            let expectedNamesList = nodeAlives.reduce("") { accum, nodeAlive in
                accum.appending("name \(nodeAlive.nodeName.string!) at port \(nodeAlive.portNumber)\n")
            }
            
            let expectedResult = expectedPortData + expectedNamesList.data(using: .utf8)!
            
            let result = doNamesReq(port: port, id: id, logger: nil)
        print("result: \(result.bytes)\nexpected: \(expectedResult.bytes))")
            XCTAssertEqual(result, expectedResult)
        }

        func testDoNamesReq_WithInvalidResponse() {
            let port: UInt32 = 8080
            let id = "456"
            let expectedPortData = Data(port.toErlangInterchangeByteOrder.toByteArray)
            
            let result = doNamesReq(port: port, id: id, logger: nil)
            
            XCTAssertEqual(result, expectedPortData)
        }


}
