//
//  EPMDTests.swift
//  
//
//  Created by Barney, Lee on 3/21/24.
//

import XCTest
import Logging
@testable import SwErl

final class EPMDTests: XCTestCase {

//    override func setUpWithError() throws {
//        super.setUp()
//        mockLogger = MockLogger()
//    }
//
//    override func tearDownWithError() throws {
//        mockLogger = nil
//        super.tearDown()
//    }
    

    


    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}




final class NodeAliveTests: XCTestCase {
    
    override func setUpWithError() throws {
        
        let mockCreation:UInt32 = 15
        try spawnsysf(name: "creation_generator",initialState: UInt32.random(in: 4..<UInt32.max)){(PID,message,state) in
                return ((.ok,mockCreation),state)
            }
        try buildSafe(dictionary: [String:NodeAlive](), named: "nameNodeAliveTracker")
        try buildSafe(dictionary: [String:String](), named: "UUIDNameTracker")
        
        super.setUp()
    }

    override func tearDownWithError() throws {
        Registrar.unlink("nameNodeAliveTracker")
        Registrar.unlink("UUIDNameTracker")
        Registrar.unlink("creation_generator")
        super.tearDown()
    }
    
    func testToData_HappyPath() {
        // Given
        let nodeName = "testNode"
        let extraData = "Extra Data".data(using: .utf8)!
        let port:UInt16 = 5678
        let highest:UInt16 = 27
        let lowest:UInt16 = 10
        let node = NodeAlive(portNumber: port, nodeType: .normalNode, comProtocol: ConnectionProtocol.tcpIPv4, highestVersion: highest, lowestVersion: lowest, nodeName: nodeName, extra: extraData)
        
        let resultData = node.toData()
        
        XCTAssertNotEqual(resultData, Data([EPMDCommand.alive2Response.rawValue,Byte(1)]))//not failure case
        XCTAssertEqual(resultData.count, 30)
        XCTAssertEqual(Data(port.toErlangInterchangeByteOrder.toByteArray), Data(resultData[0...1]))
        XCTAssertEqual(resultData[2], NodeType.normalNode.rawValue)
        XCTAssertEqual(resultData[3], ConnectionProtocol.tcpIPv4.rawValue)
        XCTAssertEqual(Data(resultData[4...5]), Data(highest.toErlangInterchangeByteOrder.toByteArray))
        XCTAssertEqual(Data(resultData[8...9]), Data(UInt16(nodeName.count).toErlangInterchangeByteOrder.toByteArray))
        XCTAssertEqual(String(data:resultData[10...17], encoding: .utf8), nodeName)
        XCTAssertEqual(Data(resultData[18...19]), Data(UInt16(extraData.count).toErlangInterchangeByteOrder.toByteArray))
        XCTAssertEqual(String(data:resultData[20...29], encoding: .utf8), "Extra Data")
        
    }

    

    func testToData_EmptyExtraData() {
        // Given
        let nodeName = "testNode"
        let port:UInt16 = 5678
        let highest:UInt16 = 27
        let lowest:UInt16 = 10
        let node = NodeAlive(portNumber: port, nodeType: .normalNode, comProtocol: ConnectionProtocol.tcpIPv4, highestVersion: highest, lowestVersion: lowest, nodeName: nodeName, extra: Data())
        
        let resultData = node.toData()
        
        XCTAssertNotEqual(resultData, Data([EPMDCommand.alive2Response.rawValue,Byte(1)]))//not failure case
        XCTAssertEqual(resultData.count, 20)
        XCTAssertEqual(Data(port.toErlangInterchangeByteOrder.toByteArray), Data(resultData[0...1]))
        XCTAssertEqual(resultData[2], NodeType.normalNode.rawValue)
        XCTAssertEqual(resultData[3], ConnectionProtocol.tcpIPv4.rawValue)
        XCTAssertEqual(Data(resultData[4...5]), Data(highest.toErlangInterchangeByteOrder.toByteArray))
        XCTAssertEqual(Data(resultData[8...9]), Data(UInt16(nodeName.count).toErlangInterchangeByteOrder.toByteArray))
        XCTAssertEqual(String(data:resultData[10...17], encoding: .utf8), nodeName)
        XCTAssertEqual(Data(resultData[18...19]), Data(UInt16(0).toErlangInterchangeByteOrder.toByteArray))
    }

    func testDoAliveX_HappyPath() {
        //Given
        
        let mockCreation:UInt32 = 15
        let portNum:UInt16 = 5678
        let nodeType:UInt8 = NodeType.normalNode.rawValue
        let comProtocol:UInt8 = ConnectionProtocol.tcpIPv4.rawValue
        let highestVersion:UInt16 = 27
        let lowestVersion:UInt16 = 25
        let nodeName = "none such"
        let nameLength = nodeName.count
        let extraData = "Extra Data".data(using: .utf8)!
        let extraLength:UInt16 = UInt16(extraData.count)
        
        let incomingData = Data(portNum.toErlangInterchangeByteOrder.toByteArray) ++ Data([nodeType]) ++ Data([comProtocol]) ++ Data(highestVersion.toErlangInterchangeByteOrder.toByteArray) ++ Data(lowestVersion.toErlangInterchangeByteOrder.toByteArray) ++ Data(nameLength.toErlangInterchangeByteOrder.toByteArray) ++ nodeName.data(using: .utf8)! ++ Data(extraLength.toErlangInterchangeByteOrder.toByteArray) ++ extraData
        let uuid = "testUUID"
        
        let result = doAliveX(data: incomingData, uuid: uuid, logger: nil)
        let expectedResult = Data([EPMDCommand.alive2XResponse.rawValue,EPMDCommand.success.rawValue]) ++ Data(mockCreation.toErlangInterchangeByteOrder.toByteArray)
        XCTAssertEqual(6, result.count)
        
        XCTAssertEqual(EPMDCommand.alive2XResponse.rawValue, expectedResult[0])
        XCTAssertEqual(EPMDCommand.success.rawValue, expectedResult[1])
        print("\(mockCreation.toErlangInterchangeByteOrder.toByteArray) : \(result[2..<result.count].toUInt32.toByteArray)")
        
    }

    func testDoAliveX_DataTooShort_LogsErrorAndReturnsErrorData() {
        let mockCreation:UInt32 = 15
        let portNum:UInt16 = 5678
        let nodeType:UInt8 = NodeType.normalNode.rawValue
        let comProtocol:UInt8 = ConnectionProtocol.tcpIPv4.rawValue
        let highestVersion:UInt16 = 27
        let lowestVersion:UInt16 = 25
        let nodeName = "none such"
        let nameLength = nodeName.count
        let extraData = "Extra Data".data(using: .utf8)!
        let extraLength:UInt16 = UInt16(extraData.count)
        
        let shortData = Data(portNum.toErlangInterchangeByteOrder.toByteArray) ++ Data([nodeType]) ++ Data([comProtocol]) ++ Data(highestVersion.toErlangInterchangeByteOrder.toByteArray) ++ Data(lowestVersion.toErlangInterchangeByteOrder.toByteArray)// Data shorter than 10 bytes
        let uuid = "testUUID"
        
        let result = doAliveX(data: shortData, uuid: uuid, logger: nil)
        
        let errorData = Data([EPMDCommand.alive2XResponse.rawValue,Byte(1)] + UInt32(1).toErlangInterchangeByteOrder.toByteArray)// The expected error data
        XCTAssertEqual(result, errorData)
    }
}

final class NodeNamesReqTests: XCTestCase {

    override func setUpWithError() throws {
        let port:UInt16 = 5678
        let highest:UInt16 = 27
        let lowest:UInt16 = 10
        let nodeA = NodeAlive(portNumber: port, nodeType: .normalNode, comProtocol: ConnectionProtocol.tcpIPv4, highestVersion: highest, lowestVersion: lowest, nodeName: "A", extra: Data())
        let nodeB = NodeAlive(portNumber: port, nodeType: .normalNode, comProtocol: ConnectionProtocol.tcpIPv4, highestVersion: highest, lowestVersion: lowest, nodeName: "B", extra: Data())
        let nodeC = NodeAlive(portNumber: port, nodeType: .normalNode, comProtocol: ConnectionProtocol.tcpIPv4, highestVersion: highest, lowestVersion: lowest, nodeName: "C", extra: Data())
        try buildSafe(dictionary: [String:NodeAlive](), named: "nameNodeAliveTracker")
        "nameNodeAliveTracker" ! (SafeDictionaryCommand.add,"A",nodeA)
        "nameNodeAliveTracker" ! (SafeDictionaryCommand.add,"B",nodeB)
        "nameNodeAliveTracker" ! (SafeDictionaryCommand.add,"C",nodeC)
        super.setUp()
    }

    override func tearDownWithError() throws {
        Registrar.unlink("nameNodeAliveTracker")
        super.tearDown()
    }

    func testDoNamesReq_SuccessfulNamesList() {
        // Setup
        let port: UInt32 = 1234
        let id = "testID"
        
        let descripters = ["name A at port 5678".data(using: .utf8),"name B at port 5678".data(using: .utf8),"name C at port 5678".data(using: .utf8)].compactMap { $0 }// This removes any nil values from the array
        
        var resultData = doNamesReq(port: port, id: id, logger: nil)
        
        XCTAssertEqual(Data(port.toErlangInterchangeByteOrder.toByteArray), resultData.prefix(4))
        resultData = resultData.dropFirst(4)
        
        // Splitting the data at each newline character
        let lines = Set(resultData.split(separator: 0x0A).compactMap { $0 })//0x0A is '\n'
        
        XCTAssertEqual(3, lines.count)
        XCTAssertTrue(lines.contains(descripters[0]))
        XCTAssertTrue(lines.contains(descripters[1]))
        XCTAssertTrue(lines.contains(descripters[2]))
    }
}

final class DoPortPleaseTests: XCTestCase {
    var nodeA:NodeAlive? = nil
    var nodeB:NodeAlive? = nil
    var nodeC:NodeAlive? = nil
    override func setUpWithError() throws {
        let port:UInt16 = 5678
        let highest:UInt16 = 27
        let lowest:UInt16 = 10
        nodeA = NodeAlive(portNumber: port, nodeType: .normalNode, comProtocol: ConnectionProtocol.tcpIPv4, highestVersion: highest, lowestVersion: lowest, nodeName: "A", extra: Data())
        nodeB = NodeAlive(portNumber: port, nodeType: .normalNode, comProtocol: ConnectionProtocol.tcpIPv4, highestVersion: highest, lowestVersion: lowest, nodeName: "B", extra: Data())
        nodeC = NodeAlive(portNumber: port, nodeType: .normalNode, comProtocol: ConnectionProtocol.tcpIPv4, highestVersion: highest, lowestVersion: lowest, nodeName: "C", extra: Data())
        try buildSafe(dictionary: [String:NodeAlive](), named: "nameNodeAliveTracker")
        "nameNodeAliveTracker" ! (SafeDictionaryCommand.add,"A",nodeA!)
        "nameNodeAliveTracker" ! (SafeDictionaryCommand.add,"B",nodeB!)
        "nameNodeAliveTracker" ! (SafeDictionaryCommand.add,"C",nodeC!)
        super.setUp()
    }
    override func tearDownWithError() throws {
        Registrar.unlink("nameNodeAliveTracker")
        super.tearDown()
    }
    
    
    func testDoPortPleaseWithSuccessfulResponse() {
        // setup
        let request = "A".data(using: .utf8)!
        var result = doPortPlease(bytes: request, id: "testingUUID", logger: nil)
        
        XCTAssertEqual(Data([EPMDCommand.port2Response.rawValue, Byte(0)]),result.prefix(2))
                       
        result = result.dropFirst(2)
        XCTAssertEqual(nodeA?.toData(), result)
    }
    
    func testDoPortPleaseWithUTF8DecodingFailure() {
        // Given
        let invalidBytes = Data([0xFF, 0xFE, 0xFD]) // Invalid UTF-8
        let id = "testID"
        let expectedFailureResponse = Data([119, 1])
        
        // When
        let result = doPortPlease(bytes: invalidBytes, id: id, logger: nil)
        
        // Then
        XCTAssertEqual(result, expectedFailureResponse)
    }
    
    func testDoPortPleaseWithNodeAliveLookupFailure() {
        // Given
        let nodeName = "UnknownNode"
        let id = "testID"
        let bytes = Data(nodeName.utf8)
        let result = doPortPlease(bytes: bytes, id: id, logger: nil)
        
        // Then
        let expectedFailureResponse = Data([119, 1])
        XCTAssertEqual(result, expectedFailureResponse)
    }
}

final class DealWithRequestTests: XCTestCase {
    let mockCreation:UInt32 = 15
    var nodeA:NodeAlive? = nil
    override func setUpWithError() throws {
        let port:UInt16 = 5678
        let highest:UInt16 = 27
        let lowest:UInt16 = 10
        nodeA = NodeAlive(portNumber: port, nodeType: .normalNode, comProtocol: ConnectionProtocol.tcpIPv4, highestVersion: highest, lowestVersion: lowest, nodeName: "A", extra: Data())
        try spawnsysf(name: "creation_generator",initialState: UInt32.random(in: 4..<UInt32.max)){(PID,message,state) in
            return ((.ok,self.mockCreation),state)
            }
        try buildSafe(dictionary: [String:NodeAlive](), named: "nameNodeAliveTracker")
        try buildSafe(dictionary: [String:String](), named: "UUIDNameTracker")
        "nameNodeAliveTracker" ! (SafeDictionaryCommand.add,"A",nodeA!)
        
        super.setUp()
    }

    override func tearDownWithError() throws {
        Registrar.unlink("nameNodeAliveTracker")
        Registrar.unlink("UUIDNameTracker")
        Registrar.unlink("creation_generator")
        nodeA = nil
        super.tearDown()
    }
    
    func testDealWithRequest_Alive2Request_ValidData() {
        // setup
        let mockCreation:UInt32 = 15
        let portNum:UInt16 = 5678
        let nodeType:UInt8 = NodeType.normalNode.rawValue
        let comProtocol:UInt8 = ConnectionProtocol.tcpIPv4.rawValue
        let highestVersion:UInt16 = 27
        let lowestVersion:UInt16 = 25
        let nodeName = "none such"
        let nameLength = nodeName.count
        let extraData = "Extra Data".data(using: .utf8)!
        let extraLength:UInt16 = UInt16(extraData.count)
        
        var requestData = Data(portNum.toErlangInterchangeByteOrder.toByteArray) ++ Data([nodeType]) ++ Data([comProtocol]) ++ Data(highestVersion.toErlangInterchangeByteOrder.toByteArray) ++ Data(lowestVersion.toErlangInterchangeByteOrder.toByteArray) ++ Data(nameLength.toErlangInterchangeByteOrder.toByteArray) ++ nodeName.data(using: .utf8)! ++ Data(extraLength.toErlangInterchangeByteOrder.toByteArray) ++ extraData
        let uuid = "testUUID"
        let epmdPort: UInt16 = 4369
        
        let result = doAliveX(data: requestData, uuid: uuid, logger: nil)
        // Construct valid data for an alive2Request
        let commandByte = EPMDCommand.alive2Request.rawValue
        requestData = Data([0, 0, commandByte]) ++ requestData//the first two bytes are ignored
        
        let (command, resultData) = dealWithRequest(data: requestData, uuid: uuid, logger: nil, epmdPort: epmdPort)
        
        // Then
        XCTAssertEqual(command, .alive2Request)
        XCTAssertNotNil(resultData)//correct result data creation is tested in a different test
    }

    func testDealWithRequest_PortPlease2Request_ValidData() {
        // setup
        let uuid = "testUUID"
        let epmdPort: UInt16 = 4369
        // Construct valid data for a portPlease2Request
        let commandByte = EPMDCommand.portPlease2Request.rawValue
        let requestData = Data([0, 0, commandByte]) //the first two bytes are ignored
        
        let (command, resultData) = dealWithRequest(data: requestData, uuid: uuid, logger: nil, epmdPort: epmdPort)
        
        XCTAssertEqual(command, .portPlease2Request)
        XCTAssertNotNil(resultData)//correct result data is checked in a different test
    }

    func testDealWithRequest_NamesReq_ValidData() {
        // setup
        let uuid = "testUUID"
        let epmdPort: UInt16 = 4369
        // Construct valid data for a namesReq
        let commandByte = EPMDCommand.namesReq.rawValue
        let requestData = Data([0, 0, commandByte]) //the first two bytes are ignored
        
        let (command, resultData) = dealWithRequest(data: requestData, uuid: uuid, logger: nil, epmdPort: epmdPort)
        
        XCTAssertEqual(command, .namesReq)
        XCTAssertNotNil(resultData)//correct data creation is checked in a different test
    }

    func testDealWithRequest_InvalidCommand() {
        // setup
        let uuid = "testUUID"
        let epmdPort: UInt16 = 4369
        // Data with an invalid command byte
        let invalidCommandByte: UInt8 = 255 // 255 is not a valid command
        let requestData = Data([0, 0, invalidCommandByte])//the first two bytes are ignored
        
        let (command, resultData) = dealWithRequest(data: requestData, uuid: uuid, logger: nil, epmdPort: epmdPort)
        
        XCTAssertEqual(command, .error)
        XCTAssertNil(resultData)//correct data creation is checked in a different test
    }

    func testDealWithRequest_NilOrShortData() {
        // setup
        let uuid = "testUUID"
        let epmdPort: UInt16 = 4369
        let requestData: Data? = nil // Testing nil data scenario
        
        let (command, resultData) = dealWithRequest(data: requestData, uuid: uuid, logger: nil, epmdPort: epmdPort)
        
        XCTAssertEqual(command, .error)
        XCTAssertNil(resultData)
        
        // Repeat test with data too short to contain a valid command
        let shortData = Data([0, 0]) // Missing command byte
        let (commandShort, resultDataShort) = dealWithRequest(data: shortData, uuid: uuid, logger: nil, epmdPort: epmdPort)
        XCTAssertEqual(commandShort, .error)
        XCTAssertNil(resultDataShort)
    }
}

class CreationStreamTests: XCTestCase {
    
    override func tearDownWithError() throws {
        Registrar.unlink("creation_generator")
        super.tearDown()
    }
    func testCreationStreamInitialization() throws{
        try initializeCreationStream(logger: nil)
        
        let (passed,creation) = "creation_generator" ! true
        XCTAssertEqual(SwErlPassed.ok, passed)
        XCTAssertNoThrow(creation as! UInt32)//generator starts at a random UInt32 value, increments, and loops
    }
}





