//
//  AliveXTests.swift
//  
//
//  Created by Barney, Lee on 5/2/24.
//

import XCTest
@testable import SwErl

class AliveXTests: XCTestCase {
    override func setUp() {
        //spawning these multiple times causes the all but the first to throw an exception.
        do{
            //setup the mock creation generator
            try spawnsysf(name: "creation_generator",initialState: UInt32(5)){(PID,message,state) in
                return ((.ok,state),state)
            }
            //buildMock node to alive data tracker
            try buildSafe(dictionary: [String:NodeAlive](), named: "nameNodeAliveTracker")
            
        }
        catch{}
    }
    func testDoAliveX_WithValidData() {
        "nameNodeAliveTracker" ! SafeDictCommand.clear
        let uuid = "UUID123"
        let data = Data([
            0x00, 0x50, // Port number (80)
            0x01,       // Node type
            0x02,       // Communication protocol
            0x00, 0x01, // Highest version
            0x00, 0x01, // Lowest version
            0x00, 0x04, // Name length
            0x6e, 0x6f, 0x64, 0x65, // "node"
            0x00, 0x02, // Extras length
            0x01, 0x02  // Extras
        ])
        
        
        let expectedResponse = Data([0x76, 0x00]) + Int32(5).toErlangInterchangeByteOrder.toByteArray

        let result = doAliveX(data: data, uuid: uuid, logger: nil)
        print("exp: \(expectedResponse.bytes)\nres: \(result!.bytes)")
        XCTAssertEqual(result!, expectedResponse)
    }

    func testDoAliveX_WithDataTooShort() {
        "nameNodeAliveTracker" ! SafeDictCommand.clear
        let uuid = "UUID123"
        let data = Data([0x00])  // Insufficient data
        
        let expectedErrorData = Data([0x76, 0x01]) + UInt32(1).toErlangInterchangeByteOrder.toByteArray

        let result = doAliveX(data: data, uuid: uuid, logger: nil)

        XCTAssertEqual(result, expectedErrorData)
    }

    func testDoAliveX_WithInvalidNameLength() {
        "nameNodeAliveTracker" ! SafeDictCommand.clear
        let uuid = "UUID123"
        let data = Data([
            0x00, 0x50, // Port number (80)
            0x01,       // Node type
            0x02,       // Communication protocol
            0x00, 0x01, // Highest version
            0x00, 0x01, // Lowest version
            0x00, 0x20, // Exaggerated name length
            // Missing the rest of the data
        ])

        let expectedErrorData = Data([0x76, 0x01]) + UInt32(1).toErlangInterchangeByteOrder.toByteArray

        let result = doAliveX(data: data, uuid: uuid, logger: nil)

        XCTAssertEqual(result, expectedErrorData)
    }

    func testDoAliveX_WithExistingName() {
        let uuid = "UUID123"
        let data = Data([
            0x00, 0x50, // Port number (80)
            0x01,       // Node type
            0x02,       // Communication protocol
            0x00, 0x01, // Highest version
            0x00, 0x01, // Lowest version
            0x00, 0x04, // Name length
            0x6e, 0x6f, 0x64, 0x65, // "node"
            0x00, 0x02, // Extras length
            0x01, 0x02  // Extras
        ])

        let expectedErrorData = Data([0x76, 0x01]) + UInt32(1).toErlangInterchangeByteOrder.toByteArray

        _ = doAliveX(data: data, uuid: uuid, logger: nil)
        let result = doAliveX(data: data, uuid: uuid, logger: nil)
        print("res: \(result!.bytes)")
        XCTAssertEqual(result, expectedErrorData)
    }
}

