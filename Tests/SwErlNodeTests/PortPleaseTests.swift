//
//  PortPleaseTests.swift
//  
//
//  Created by Barney, Lee on 5/1/24.
//

import XCTest
@testable import SwErl

class PortPleaseTests: XCTestCase {
    let validAlive = NodeAlive(portNumber: 23, nodeType: 77, comProtocol: 0, highestVersion: 6, lowestVersion: 6, nodeName: SwErlAtom("bob"), extra: Data())
    override func setUp()  {
        print("!!!!!!!!!!!!!building alive tracker!!!!!!!!!!!!!!")
        do{
            let initalState:[String:NodeAlive] = ["someName":validAlive]
            try buildSafe(dictionary: initalState, named: "nameNodeAliveTracker")
        }
        catch{
            //if the name is already linked, an error is thrown.
        }
    }
    func testDoPortPlease_WithValidName() {
        let expectedBytes = Data([119, 0]) + validAlive.toData()
        let bytes = Data("someName".utf8)
        let trackingID = "123"
        
        let result = doPortPlease(bytes: bytes, id: trackingID, logger: nil)
        XCTAssertEqual(result, expectedBytes)
    }

    func testDoPortPlease_WithUnavailableNode() {
        let expectedFailureResponse = Data([119, 1])
        let bytes = Data("unavailableNode".utf8)
        let id = "123"
        
        let result = doPortPlease(bytes: bytes, id: id, logger: nil)
        
        XCTAssertEqual(result, expectedFailureResponse)
    }
}






