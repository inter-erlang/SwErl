//
//  ExternalToNativeTests.swift
//  
//
//
//Copyright (c) 2023 Lee Barney
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//
//
//  Created by Lee Barney on 12/8/23.
//

import XCTest
import BigInt
@testable import SwErl

/*Each of the extensions converting the Erlang external representation to native Swift expects to have the initial indicator of the type of conversion to be done not included in the data representation.
 */

final class ExternalToNativeTests: XCTestCase {
    
    // MARK: atom External Tests
    func testFromSmallatomUTF8Ext() throws {
        var atomStr = "true"
        var asData = Data([Byte(atomStr.count)]) ++ atomStr.data(using: .utf8)!
        var (result,reduced) = asData.fromSmallAtomUTF8Ext!
        
        XCTAssertEqual(atomStr, result)
        XCTAssertEqual(0, reduced.count)
        
        atomStr = "😇😁 fun"
        asData = Data([Byte(12)]) ++ "😇😁 fun".data(using: .utf8)!
        (result,reduced) = asData.fromSmallAtomUTF8Ext!
        XCTAssertEqual(atomStr,result)
        XCTAssertEqual(0, reduced.count)
        
    }
    
    func testFromLargeatomUTF8() throws {
        
        
        //all atoms are lower case even if created using upper-case text
        let longString = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem. Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem.".lowercased().replacingOccurrences(of: " ", with: "")
        
        let countAs32Bit:UInt32 = UInt32(longString.count)
        let countData = Data(countAs32Bit.toErlangInterchangeByteOrder.toByteArray)
        let asData = countData ++ longString.data(using: .utf8)!
        let (result,reduced) = asData.fromAtomUTF8Ext!
        XCTAssertEqual(longString,result)
        XCTAssertEqual(0, reduced.count)
    }
    
    // MARK: Int External Tests
    
    //8 bit representation conversion
    func testFromSmallIntegerExt() throws {
        var asData = Data(Int8(127).toByteArray)
        var (value,reduced) = asData.fromSmallIntegerExt!
        
        XCTAssertEqual(127, value)
        XCTAssertEqual(0, reduced.count)
        
        asData = Data(Int8(-22).toByteArray)
        //negative number representation
        (value,reduced) = asData.fromSmallIntegerExt!
        
        XCTAssertEqual(-22, value)
        XCTAssertEqual(0,reduced.count)
        
        
        //get just the 4 byte int from the data, return the rest
        asData = Data(Int8(-22).toByteArray + [UInt8(107)])
        (value,reduced) = asData.fromSmallIntegerExt!
        
        
        XCTAssertEqual(-22, value)
        XCTAssertEqual(reduced, Data([UInt8(107)]))
        
    }
    //32 bit representation conversion
    func testFromIntegerExt() throws {
        var asData = Data(Int32(1073741823).toByteArray).toErlangInterchangeByteOrder
        var (result,reduced) = asData.fromIntegerExt!
        
        XCTAssertEqual(1073741823, result)
        XCTAssertEqual(0, reduced.count)
        
        
        asData = Data(Int32(-1073741823).toByteArray).toErlangInterchangeByteOrder
        (result,reduced) = asData.fromIntegerExt!
        
        XCTAssertEqual(-1073741823, result)
        XCTAssertEqual(0, reduced.count)
        
        
        //get just the 4 byte int from the data, return the rest
        //the 107 represents some more data later on in the Data instance
        asData = Data(Int32(1073741823).toByteArray).toErlangInterchangeByteOrder ++ Data([UInt8(107)])
        (result,reduced) = asData.fromIntegerExt!
        XCTAssertEqual(1073741823, result)
        XCTAssertEqual(reduced, Data([UInt8(107)]))
    }
    
    // MARK: BigInt External tests
    // at most 255 bytes big integer representation conversion
    func testFromSmallBigExt() throws {
        // Test positive BigInt with SMALL_BIG_EXT representation
        
        var expected = BigInt("12345678901234567890")
        var asData = Data([0, 0, 0, 9, 0, 171, 84, 169, 140, 235, 31, 10, 210])
        var (result,reduced) = asData.fromLargeBigExt!
        XCTAssertEqual(expected,result)
        XCTAssertEqual(0, reduced.count)
        
        // Test negative BigInt with SMALL_BIG_EXT representation
        expected = BigInt("-12345678901234567890")
        asData = Data([0, 0, 0, 9, 1, 171, 84, 169, 140, 235, 31, 10, 210])
        (result,reduced) = asData.fromLargeBigExt!
        XCTAssertEqual(expected,result)
        XCTAssertEqual(0, reduced.count)
    }
    
    func testFromLargeBigExt() throws {
        // Test BigInt with LARGE_BIG_EXT representation
        var expected = BigInt("12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890")
       
        var bigIntBytes = Data(expected.serialize())
        let size = UInt32(bigIntBytes.count-1).toErlangInterchangeByteOrder.toByteArray//don't count the sign byte in the count
        var asData = Data(size + bigIntBytes)
        var (result,reduced) = asData.fromLargeBigExt!
        
        XCTAssertEqual(expected,result)
        XCTAssertEqual(0, reduced.count)
        
        // Test negative BigInt with LARGE_BIG_EXT representation
        expected = BigInt("-12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890")
        bigIntBytes = expected.serialize()
        asData = Data(size + bigIntBytes)
        (result,reduced) = asData.fromLargeBigExt!
        
        XCTAssertEqual(expected,result)
        XCTAssertEqual(0, reduced.count)
        
        // Test negative BigInt with LARGE_BIG_EXT representation with remaining bytes in the data
        expected = BigInt("-12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890")
        bigIntBytes = expected.serialize()
        asData = Data(size + bigIntBytes + [Byte(107)])
        (result,reduced) = asData.fromLargeBigExt!
        
        XCTAssertEqual(expected,result)
        XCTAssertEqual(Data([Byte(107)]), reduced)
    }
    // MARK: Float External Tests
    func testFromFloatExt() throws {
        
        var expected = Double(123.456)
        var str = String(format: "%.20e", expected)
        var asData = str.data(using: .utf8)!
        //the representation has 5 unused bytes
        asData = asData ++ Data([Byte(),Byte(),Byte(),Byte(),Byte()])
        var (result,reduced) = asData.fromFloatExt!
        XCTAssertEqual(expected, result, accuracy: 0.000001)
        XCTAssertEqual(0, reduced.count)
        
        
        expected = Double(-123.456)
        str = String(format: "%.20e", expected)
        asData = str.data(using: .utf8)!
        //the representation has 4 unused bytes
        asData = asData ++ Data([Byte(),Byte(),Byte(),Byte()])
        (result,reduced) = asData.fromFloatExt!
        XCTAssertEqual(expected, result, accuracy: 0.000001)
        XCTAssertEqual(0, reduced.count)
        
    }
    
    func testFromNewFloatExt() throws {
        // Test positive float
        var expected: Double = 3.14
        //The Erlang NEW_FLOAT_EXT documentation says the bitPattern bytes will be big-endian.
        var asData = Data(expected.bitPattern.toErlangInterchangeByteOrder.toByteArray)
        var (result,reduced) = asData.fromNewFloatExt!
        
        XCTAssertEqual(expected, result, accuracy: 0.000001)
        XCTAssertEqual(0, reduced.count)
        
        // Test negative float
        expected = -2.71828
        asData = Data(Data(expected.bitPattern.toErlangInterchangeByteOrder.toByteArray))
        (result,reduced) = asData.fromNewFloatExt!
        
        XCTAssertEqual(expected, result, accuracy: 0.000001)
        XCTAssertEqual(0, reduced.count)
        
        // Test zero float
        expected = 0.0
        asData = Data([0, 0, 0, 0, 0, 0, 0, 0])
        (result,reduced) = asData.fromNewFloatExt!
        
        XCTAssertEqual(expected, result)
        XCTAssertEqual(0, reduced.count)
    }
    
    func testFromStringExt() throws {
        var expected = "hello"
        var asData = Data(UInt32(5).toErlangInterchangeByteOrder.toByteArray) ++ "hello".data(using: .utf8)!
        var (result,reduced) = asData.fromStringExt!
        
        XCTAssertEqual(expected,result)
        XCTAssertEqual(0, reduced.count)
        
        expected = "😇😁 fun"
        asData = Data(UInt32(12).toErlangInterchangeByteOrder.toByteArray) ++ "😇😁 fun".data(using: .utf8)!
        (result,reduced) = asData.fromStringExt!
        
        XCTAssertEqual(expected,result)
        XCTAssertEqual(0, reduced.count)
        
        
        expected = ""
        asData = Data(UInt32(0).toErlangInterchangeByteOrder.toByteArray) ++ "".data(using: .utf8)!
        (result,reduced) = asData.fromStringExt!
        
        XCTAssertEqual(expected,result)
        XCTAssertEqual(0, reduced.count)
    }
    
    // MARK: External to Pid
    
    func testFromNewPidExt() throws {
        
        let expectedName = "😇😁 fun"
        let expectedNameData = expectedName.data(using: .utf8)!
        let expectedPid = Pid(id: 5, serial: 12, creation: 0)
        let atomData = Data([Byte(119)]) ++ Data([Byte(expectedNameData.count)]) ++ expectedNameData
        let asData = atomData ++  Data(UInt32(5).toErlangInterchangeByteOrder.toByteArray) ++ Data(UInt32(12).toErlangInterchangeByteOrder.toByteArray) ++ Data(UInt32(0).toErlangInterchangeByteOrder.toByteArray)
        
        let ((pid,nodeName),reduced) = asData.fromNewPidExt!
        XCTAssertEqual(expectedPid, pid)
        XCTAssertEqual(expectedName, nodeName)
        XCTAssertEqual(0, reduced.count)
    }
    
    //This is here for backward compatibility reasons only.
    //No SwErl node will generate this version of a Pid
    //external representation.
    func testFromPidExt() throws {
        
        let expectedName = "😇😁 fun"
        let expectedNameData = expectedName.data(using: .utf8)!
        let expectedPid = Pid(id: 5, serial: 12, creation: 0)
        let asData = Data([Byte(119)]) ++ Data([Byte(expectedNameData.count)]) ++ expectedNameData ++ Data(UInt32(5).toErlangInterchangeByteOrder.toByteArray) ++ Data(UInt32(12).toErlangInterchangeByteOrder.toByteArray) ++ Data(
            [Byte(0)])
        
        let ((pid,nodeName),reduced) = asData.fromPidExt!
        XCTAssertEqual(expectedPid, pid)
        XCTAssertEqual(expectedName, nodeName)
        XCTAssertEqual(0, reduced.count)
    }
    
    // MARK: External to Tuple
    //in this next set of tests, the keys and values are only those
    //direct types found in the tests above.
    func testFromSmallTupleExt() throws {
        let aDouble: Double = 123456.789012345
        let largeBigInt = BigInt("12345678901234567890")
        let smallBigInt = BigInt(65536)
        let expected = (3,"hello",smallBigInt, aDouble, largeBigInt)
        
        let smallSerialized = smallBigInt.serialize()
        let incoming =
        /*1st*/Data([Byte(5)]) ++ Data([Byte(97),Byte(3)]) ++
        /*2nd*/Data([Byte(107)]) ++ Data(UInt32(5).toErlangInterchangeByteOrder.toByteArray) ++ "hello".data(using: .utf8)! ++
        /*3rd*/Data([Byte(110),Byte(smallSerialized.count-1)])/*don't include the sign byte in the count*/ ++ smallSerialized ++
        /*4th*/Data([Byte(70)]) ++ Data(aDouble.bitPattern.bigEndian.toByteArray) ++
        /*5th*/Data([Byte(111), Byte(0), Byte(0), Byte(0), Byte(8), Byte(0), Byte(171), Byte(84), Byte(169), Byte(140), Byte(235), Byte(31), Byte(10), Byte(210)])
        let ((num,message,littleBigNum,floater,bigInt),remaining) = incoming.fromSmallTupleExt as!((Int,String,BigInt,Double,BigInt),Data)
        
        
        XCTAssertEqual(Data(), remaining)
        XCTAssertEqual(expected.0,num)
        XCTAssertEqual(expected.1, message)
        XCTAssertEqual(expected.2, littleBigNum)
        XCTAssertEqual(expected.3, floater, accuracy: 0.0000000001)
        XCTAssertEqual(expected.4, bigInt)
    }
    
    func testFromLargeTupleExt() throws {
        
        var received = Data(UInt32(1000).toErlangInterchangeByteOrder.toByteArray)
        for _ in 0..<1000{
            received = received ++ Data([Byte(97), Byte(1)])
        }
        
        var (result,remainingData) = received.fromLargeTupleExt as! ([Int],Data)
        
        
        XCTAssertEqual(Data(), remainingData)
        XCTAssertEqual(1000, result.count)
        result.removeAll{ $0 == 1}
        XCTAssertEqual(0, result.count)
        
    }
    
// MARK: External to Array
    func testFromListExt() throws {
        
        var received = Data(UInt32(1000).toErlangInterchangeByteOrder.toByteArray)
        for _ in 0..<1000{
            received = received ++ Data([Byte(97), Byte(1)])
        }
        received = received ++ Data([UInt8(106)])
        
        var (result,remainingData) = received.fromListExt as! ([Int],Data)
        
        
        XCTAssertEqual(Data(), remainingData)
        XCTAssertEqual(1000, result.count)
        result.removeAll{ $0 == 1}
        XCTAssertEqual(0, result.count)
        
    }
    
    func testFromListBadData() throws {
        
        var received = Data(UInt32(1000).toErlangInterchangeByteOrder.toByteArray)
        for _ in 0..<500{
            received = received ++ Data([Byte(97), Byte(1)])
        }
        for _ in 0..<500{
            received = received ++ Data([Byte(254)])
        }
        received = received ++ Data([UInt8(106)])
        
        XCTAssertNil(received.fromListExt)
    }
    
    func testFromListMissingTerminator() throws {
        
        var received = Data(UInt32(1000).toErlangInterchangeByteOrder.toByteArray)
        for _ in 0..<500{
            received = received ++ Data([Byte(97), Byte(1)])
        }
        
        XCTAssertNil(received.fromListExt)
    }
    
// MARK: External to Dictionary
    func testFromMapExtTests() throws {
        let one = Data([Byte(107)]) ++ Data(UInt32("one".count).toByteArray).toErlangInterchangeByteOrder ++ "one".data(using: .utf8)!
        let two = Data([Byte(107)]) ++ Data(UInt32("two".count).toByteArray).toErlangInterchangeByteOrder ++ "two".data(using: .utf8)!
        let three = Data([Byte(107)]) ++ Data(UInt32("three".count).toByteArray).toErlangInterchangeByteOrder ++ "three".data(using: .utf8)!
        let uno = Data([Byte(97),Byte(1)])
        let dos = Data([Byte(97),Byte(2)])
        let tres = Data([Byte(97),Byte(3)])
        var received = Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray) ++ one ++ uno ++ two ++ dos ++ three ++ tres
        
        let expected = ["one":1,"two":2, "three":3]
        let (result,remaining) = received.fromMapExt as! ([String:Int],Data)
        
        XCTAssertEqual(expected, result)
        XCTAssertEqual(0, remaining.count)
        
        
        received = Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray) ++ uno ++ one ++ dos ++ two ++ tres ++ three
        let expected2 = [1:"one",2:"two", 3:"three"]
        let (result2,remaining2) = received.fromMapExt as! ([Int:String],Data)
        
        XCTAssertEqual(expected2, result2)
        XCTAssertEqual(0, remaining2.count)
        
        received = Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray) ++ one ++ uno ++ two ++ dos ++ tres ++ three
        let (result3,remaining3) = received.fromMapExt!
        
        XCTAssertEqual(1,result3["one"] as! Int)
        XCTAssertEqual(2,result3["two"] as! Int)
        XCTAssertEqual("three",result3[3] as! String)
        XCTAssertEqual(0, remaining3.count)
    }
    
    
    // MARK: External to SwErlNewRef
    func testFromNewerRefExt() throws {
        
        let creationValue:UInt32 = 235
        let atomString = "hello"
        let atomData = Data([Byte(119),Byte(atomString.count)]) ++ atomString.data(using: .utf8)!
        let idDataCount = Data(UInt16(3).toErlangInterchangeByteOrder.toByteArray)
        let creationData = Data(creationValue.toErlangInterchangeByteOrder.toByteArray)
        let idData =   Data(UInt32(123456789).toErlangInterchangeByteOrder.toByteArray) ++ Data(UInt32(456789).toErlangInterchangeByteOrder.toByteArray)
        let received = idDataCount ++ atomData ++ creationData ++ idData
        
        let expected = SwErlNewerRef(node: atomString, creation: creationValue, id: idData)
        let (result,remaining) = received.fromNewerReferenceExt!
        
        XCTAssertEqual(expected, result)
        XCTAssertEqual(Data(),remaining)
    }
    // MARK: External to Export
    func testFromExportExt() throws {
        let moduleName = "testModule"
        let moduleNameData = moduleName.data(using: .utf8)!
        let moduleData = Data([Byte(119),Byte(moduleNameData.count)]) ++ moduleNameData
        
        let functionName = "testFunction"
        let functionNameData = functionName.data(using: .utf8)!
        let functionData = Data([Byte(119),Byte(functionNameData.count)]) ++ functionNameData
        
        let arityData = Data([Byte(97),Byte(5)])
        
        let received = moduleData ++ functionData ++ arityData
        
        let (export,remaining) = received.fromExportExt!
    
        XCTAssertEqual(moduleName.lowercased(),export.module)
        XCTAssertEqual(functionName.lowercased(), export.function)
        XCTAssertEqual(5, export.arity)
        XCTAssertEqual(0, remaining.count)
    }
    
    // MARK: External to Local
    func testFromLocalExt() throws {
        
        let received = Data([Byte(4),Byte(3)])
        let expected:Int64 = 5
        let (computed,remaining) = received.fromLocal{(information) ->(Any?,Data)? in
            guard let num = information.first else{
                return nil
            }
            return (Int64(num) + 1,information.dropFirst())
        }!
        
        XCTAssertEqual(expected, computed as! Int64)
        XCTAssertEqual(Data([Byte(3)]), remaining)
        
        XCTAssertNil(received.fromLocal(decoder: nil))
    }
    
    // MARK: External to SwErlPort
    func testFromPortExt() throws {
        
        let creationValue:UInt8 = 125
        let atomString = "hello"
        let atomData = Data([Byte(119),Byte(atomString.count)]) ++ atomString.data(using: .utf8)!
        let creationData = Data(creationValue.toErlangInterchangeByteOrder.toByteArray)
        let idData =   Data(UInt32(123456789).toErlangInterchangeByteOrder.toByteArray)
        let received = atomData ++ idData ++ creationData
        
        
        let expected = SwErlPort(node: atomString, ID: 123456789, creation: 125 & 0b00000000000000000000000000000011)
        let (result,remaining) = received.fromPortExt!
        
        XCTAssertEqual(expected, result)
        XCTAssertEqual(Data(),remaining)
    }
    
    // MARK: External to SwErlNewPort
    func testFromNewPortExt() throws {
        
        var creationValue:UInt32 = 78965432
        let atomString = "hello"
        let atomData = Data([Byte(119),Byte(atomString.count)]) ++ atomString.data(using: .utf8)!
        var creationData = Data(creationValue.toErlangInterchangeByteOrder.toByteArray)
        let idData =   Data(UInt32(123456789).toErlangInterchangeByteOrder.toByteArray)
        var received = atomData ++ idData ++ creationData
        
        var expected = SwErlNewPort(node: atomString, ID: 123456789, creation: creationValue & 0b00001111111111111111111111111111)
        var (result,remaining) = received.fromNewPortExt!
        
        XCTAssertEqual(expected, result)
        XCTAssertEqual(Data(),remaining)
        
        
        creationValue = UInt32(22) + 0b00001111111111111111111111111111
        
        creationData = Data(creationValue.toErlangInterchangeByteOrder.toByteArray)
        received = atomData ++ idData ++ creationData
        
        expected = SwErlNewPort(node: atomString, ID: 123456789, creation: creationValue & 0b00001111111111111111111111111111)
        (result,remaining) = received.fromNewPortExt!
        
        XCTAssertEqual(expected, result)
        XCTAssertEqual(Data(),remaining)
    }
    
    // MARK: External to SwErlV4Port
    func testFromV4PortExt() throws {
        
        let creationValue:UInt32 = 78965432
        let atomString = "hello"
        let atomData = Data([Byte(119),Byte(atomString.count)]) ++ atomString.data(using: .utf8)!
        let creationData = Data(creationValue.toErlangInterchangeByteOrder.toByteArray)
        let idData =   Data(UInt64(12345678943214321).toErlangInterchangeByteOrder.toByteArray)
        let received = atomData ++ idData ++ creationData
        
        let expected = SwErlV4Port(node: atomString, ID: 12345678943214321, creation: creationValue)
        let (result,remaining) = received.fromV4PortExt!
        
        XCTAssertEqual(expected, result)
        XCTAssertEqual(Data(),remaining)
    }
}




