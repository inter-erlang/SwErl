//
// TypeConverterTests.swift
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
// Created by Lee Barney on 12/4/23.
//

import XCTest
import BigInt
@testable import SwErl

class NativeToExternalTests: XCTestCase {
    
   //MARK: - Bool Extension Tests
   
   func testBoolToBoolExtTrue() {
       let boolValue = true
       let boolExt = boolValue.toBoolExt
       let expected = Data([119]+[4]+[UInt8]("true".utf8))
       XCTAssertEqual(boolExt, expected)
   }
   
   func testBoolToBoolExtFalse() {
       let boolValue = false
       let boolExt = boolValue.toBoolExt
       let expected = Data([119]+[5]+[UInt8]("false".utf8))
       XCTAssertEqual(boolExt, expected)
   }
   
   //MARK: - UInt8 Extension Tests
   
   func testUInt8ToatomCacheRef() {
       let byte: Byte = 42
       let atomCacheRef = byte.toAtomCacheRef
       XCTAssertEqual(atomCacheRef, Data([82, 42]))
   }
   
   //MARK: - Int8 Extension Tests
   
   func testInt8ToSmallIntegerExt() {
       let int8Value: Int8 = 42
       let smallIntegerExt = int8Value.toIntegerExt
       XCTAssertEqual(smallIntegerExt, Data([97, 42]))
   }
   
   func testUInt8ToSmallIntegerExt() {
       let uint8Value: UInt8 = 42
       let smallIntegerExt = uint8Value.toIntegerExt
       XCTAssertEqual(smallIntegerExt, Data([97, 42]))
   }
   
   //MARK: - UInt16 Extension Tests
   
   func testUInt16ToIntegerExt() {
       var uint16Value: UInt16 = 300
       var integerExt = uint16Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 0, 0, 1, 44]))
       
       uint16Value = UInt16.max
       integerExt = uint16Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 0, 0, 255, 255]))
   }
   func testInt16ToIntegerExt() {
       var int16Value: Int16 = 300
       var integerExt = int16Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 0, 0, 1, 44]))
       //big positive
       int16Value = Int16.max
       integerExt = int16Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 0, 0, 127, 255]))
       //negative value
       int16Value = int16Value * -1
       integerExt = int16Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 255, 255, 128, 1]))
   }
   
   
   
   
   //MARK: - Int32 Extension Tests
   
   func testInt32ToIntegerExt() {
       var int32Value: Int32 = Int32.max/2
       var integerExt = int32Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 63, 255, 255, 255]))
       
       int32Value = Int32.max
       integerExt = int32Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 127, 255, 255, 255]))
       
       int32Value = Int32.max * -1
       integerExt = int32Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 128, 0, 0, 1]))
   }
   
   func testUInt32ToIntegerExt() {
       var uint32Value = UInt32(Int32.max)
       var integerExt = uint32Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 127,255, 255, 255]))
       
       uint32Value = UInt32.max
       integerExt = uint32Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([111, 0, 0, 0, 4, 0, 255, 255, 255, 255]))
       
       uint32Value = 0
       integerExt = uint32Value.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 0, 0, 0, 0]))
   }
   
   //MARK: - Int64 Extension Tests
   
   //Int64 and UInt64 use the big int extensions
   func testUInt64ToIntegerExt() {
       var uint64Value: UInt64 = 9999999999
       var expected = Data(Array(([111, 0, 0, 0, 5] + [0, 2, 84, 11, 227, 255])))
       var integerExt = uint64Value.toIntegerExt
       XCTAssertEqual(expected,integerExt)
       
       
       uint64Value = UInt64.max
       expected = Data([111, 0, 0, 0, 8, 0, 255, 255, 255, 255, 255, 255, 255, 255])
       integerExt = uint64Value.toIntegerExt
       XCTAssertEqual(expected,integerExt)
   }
   
   func testInt64ToIntegerExt() {
       var int64Value: Int64 = 9999999999
       var expected = Data(Array(([111, 0, 0, 0, 5] + [0, 2, 84, 11, 227, 255])))
       var integerExt = int64Value.toIntegerExt
       XCTAssertEqual(expected,integerExt)
       
       
       int64Value = Int64.max
       expected = Data([111, 0, 0, 0, 8, 0, 127, 255, 255, 255, 255, 255, 255, 255])
       integerExt = int64Value.toIntegerExt
       XCTAssertEqual(expected,integerExt)
   }
   
   //MARK: - BigInt Extension Tests
   //BigExt expects the Data to have the value stored little endian
   func testBigIntToBigExt() {
       //Test positive BigInt with SMALL_BIG_EXT representation
       let positiveBigInt = BigInt(12345)
       let expected = Data([110, 2, 0 , 48, 57])
       let result = positiveBigInt.toBigExt
       XCTAssertEqual(result, expected)
       
       //Test negative BigInt with SMALL_BIG_EXT representation
       let negativeBigInt = BigInt(-12345)
       let negativeExpectedResult = Data([110, 2, 1 , 48, 57])
       
       XCTAssertEqual(negativeBigInt.toBigExt, negativeExpectedResult)
       
       //Test BigInt with LARGE_BIG_EXT representation
       let largeBigInt = BigInt("12345678901234567890")
       let largeExpectedResult = Data([111, 0, 0, 0, 8, 0, 171, 84, 169, 140, 235, 31, 10, 210])
       XCTAssertEqual(largeBigInt.toBigExt, largeExpectedResult)
       
       //Test negative BigInt with LARGE_BIG_EXT representation
       let negLargeBigInt = BigInt("-12345678901234567890")
       let negLargeExpectedResult = Data([111, 0, 0, 0, 8, 1, 171, 84, 169, 140, 235, 31, 10, 210])
       XCTAssertEqual(negLargeBigInt.toBigExt, negLargeExpectedResult)
       
   }
   
//MARK: Int = 0 external tests
   func testIntToExt(){
       var intValue: Int = 42
       var integerExt = intValue.toIntegerExt
       XCTAssertEqual(integerExt, Data([97, 42]))
       
       intValue = Int(Int16.max)
       integerExt = intValue.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 0, 0, 127, 255]))
       
       intValue = Int(Int32.max/2)
       integerExt = intValue.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 63, 255, 255, 255]))
       
       intValue = Int(Int64.max)
       var expected = Data([111, 0, 0, 0, 8, 0, 127, 255, 255, 255, 255, 255, 255, 255])
       integerExt = intValue.toIntegerExt
       XCTAssertEqual(expected,integerExt)
       
       intValue = Int.min
       expected = Data([111, 0, 0, 0, 8, 1, 128, 0, 0, 0, 0, 0, 0, 0])
       integerExt = intValue.toIntegerExt
       XCTAssertEqual(expected, integerExt)
   }
   
   func testUIntToExt(){
       var intValue: UInt = 42
       var integerExt = intValue.toIntegerExt
       XCTAssertEqual(integerExt, Data([97, 42]))
       
       intValue = UInt(UInt16.max)
       integerExt = intValue.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 0, 0, 255, 255]))
       
       intValue = UInt(UInt32.max/2)
       integerExt = intValue.toIntegerExt
       XCTAssertEqual(integerExt, Data([98, 127, 255, 255, 255]))
       
       intValue = UInt(UInt64.max)
       let expected = Data([111, 0, 0, 0, 8, 0, 255, 255, 255, 255, 255, 255, 255, 255])
       integerExt = intValue.toIntegerExt
       XCTAssertEqual(expected,integerExt)
   }
   
   
   //MARK: floating point external tests
   func testFloatToNewFloatExt() {
       //Test positive float
       let positiveFloat: Float = 3.14
       let positiveExpectedResult = Data([70, 0, 0, 0, 96, 184, 30, 9, 64])
       
       XCTAssertEqual(positiveFloat.toNewFloatExt, positiveExpectedResult)
//
       //Test negative float
       let negativeFloat: Float = -2.71828
       let negativeExpectedResult = Data([70, 0, 0, 0, 160, 9, 191, 5, 192])
       
       XCTAssertEqual(negativeFloat.toNewFloatExt, negativeExpectedResult)
//
       //Test zero float
       let zeroFloat: Float = 0.0
       let zeroExpectedResult = Data([70, 0, 0, 0, 0, 0, 0, 0, 0])
       
       XCTAssertEqual(zeroFloat.toNewFloatExt, zeroExpectedResult)
   }
//
   func testDoubleToNewFloatExt() {
       //Test positive double
       let positiveDouble: Double = 123456.789012345
       let positiveExpectedResult = Data([70, 159, 104, 203, 159, 12, 36, 254, 64])
       XCTAssertEqual(positiveDouble.toNewFloatExt, positiveExpectedResult)
//
       //Test negative double
       let negativeDouble: Double = -987654.321098765
       let negativeExpectedResult = Data([70, 173, 14, 103, 164, 12, 36, 46, 193])
       XCTAssertEqual(negativeDouble.toNewFloatExt, negativeExpectedResult)
//
       //Test zero double
       let zeroDouble: Double = 0.0
       let zeroExpectedResult = Data([70, 0, 0, 0, 0, 0, 0, 0, 0])
       XCTAssertEqual(zeroDouble.toNewFloatExt, zeroExpectedResult)
   }
   
//MARK: - String = "" to external tests
   
   func testStringToExt(){
       var ext = "hello".toStringExt
       var expected = Data([Byte(107)]) ++ Data(UInt32(5).toByteArray).toErlangInterchangeByteOrder ++ "hello".data(using: .utf8)!
       XCTAssertEqual(expected,ext)
       
       ext = "😇😁 fun".toStringExt
       expected = Data([Byte(107)]) ++ Data(UInt32(12).toByteArray).toErlangInterchangeByteOrder ++ "😇😁 fun".data(using: .utf8)!
       XCTAssertEqual(expected,ext)
       
       
       ext = "".toStringExt
       expected = Data([Byte(107)]) ++ Data(UInt32(0).toByteArray).toErlangInterchangeByteOrder ++ "".data(using: .utf8)!
       XCTAssertEqual(expected,ext)
   }
   
   func testAtomToExt(){
       var ext = SwErlAtom("hello").toAtomExt
       var expected = Data([Byte(119)]) ++ Data([Byte(5)]) ++ "hello".data(using: .utf8)!
       XCTAssertEqual(expected, ext)
       
       ext = SwErlAtom("😇😁 fun").toAtomExt
       expected = Data([Byte(119)]) ++ Data([Byte(12)]).toErlangInterchangeByteOrder ++ "😇😁 fun".data(using: .utf8)!
       XCTAssertEqual(expected,ext)
       
       //all atoms are lower case even if created using upper-case text
       let longString = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem.".lowercased()
       ext = SwErlAtom(longString).toAtomExt
       expected = Data([Byte(118)]) ++ Data(UInt32(260).toByteArray).toErlangInterchangeByteOrder ++ longString.data(using: .utf8)!
       XCTAssertEqual(expected,ext)
       
       ext = SwErlAtom("").toAtomExt
       XCTAssertEqual(nil, ext)
   }
   
   //MARK: - Pid to external tests
   func testPidToExt(){
       var testPID = Pid(id: 0,serial: 1,creation: 0)
       var idBytes = Data(UInt32(0).toErlangInterchangeByteOrder.toByteArray)
       var serialBytes = Data(UInt32(1).toErlangInterchangeByteOrder.toByteArray)
       var creationBytes = Data(UInt32(0).toErlangInterchangeByteOrder.toByteArray)
       let atomBytes = Data([Byte(119)]) ++ Data([Byte(4)]) ++ "test".data(using: .utf8)!
       
       var expected = Data([Byte(88)]) ++ atomBytes ++ idBytes ++ serialBytes ++ creationBytes
       
       XCTAssertEqual(expected, toNewPidExt(testPID,SwErlAtom("test")))
       
       testPID = Pid(id: UInt32.max,serial: UInt32.max,creation: UInt32.max)
       idBytes = Data(UInt32.max.toErlangInterchangeByteOrder.toByteArray)
       serialBytes = Data(UInt32.max.toErlangInterchangeByteOrder.toByteArray)
       creationBytes = Data(UInt32.max.toErlangInterchangeByteOrder.toByteArray)
       
       expected = Data([Byte(88)]) ++ atomBytes ++ idBytes ++ serialBytes ++ creationBytes
       
       XCTAssertEqual(expected, toNewPidExt(testPID,SwErlAtom("test")))
   }
   
   //MARK: - Tuple to external tests
   //in this next set of tests, the keys and values are only those
   //direct types found in the tests above.
   func testSimpleTupleToExt(){
       let aDouble: Double = 123456.789012345
       let largeBigInt = BigInt("12345678901234567890")
       let testTuple = (3,"hello",BigInt(65536), aDouble, largeBigInt)
       let expected =
    /*1st*/Data([Byte(104)]) ++ Data(Byte(5).toByteArray) ++ Data([Byte(97),Byte(3)]) ++
    /*2nd*/Data([Byte(107)]) ++ Data(UInt32(5).toByteArray).toErlangInterchangeByteOrder ++ "hello".data(using: .utf8)! ++
    /*3rd*/Data([Byte(110),Byte(3), Byte(0), Byte(1), Byte(0), Byte(0)]) ++
    /*4th*/Data([Byte(70), Byte(159), Byte(104), Byte(203), Byte(159), Byte(12), Byte(36), Byte(254), Byte(64)]) ++
    /*5th*/Data([Byte(111), Byte(0), Byte(0), Byte(0), Byte(8), Byte(0), Byte(171), Byte(84), Byte(169), Byte(140), Byte(235), Byte(31), Byte(10), Byte(210)])
       
       XCTAssertEqual(expected,toTupleExt(testTuple))
   }
   
   func testBigTupleToExt(){
       //tuple of 500 Ints
       let testTuple = (1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)
//
       var expected = Data([Byte(105)]) ++ Data(UInt32(1000).toErlangInterchangeByteOrder.toByteArray)
       for _ in 0..<1000{
           expected = expected ++ Data([Byte(97), Byte(1)])
       }
       XCTAssertEqual(expected, toTupleExt(testTuple))
   }
   
   //MARK: - Array to external tests
   func testSimpleArrayToExt(){
       let testArray = [3,3.14,123456.789012345]
       //3 is changed to be 3.0 in the above array
       let threeBytes:[Byte] = [70, 0, 0, 0, 0, 0, 0, 8, 64]
       let piBytes:[Byte] = [70, 31, 133, 235, 81, 184, 30, 9, 64]
       let bigBytes:[Byte] = [70, 159, 104, 203, 159, 12, 36, 254, 64]
//
       var expected = Data([Byte(108)]) ++ Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray) ++ Data(threeBytes) ++ Data(piBytes) ++ Data(bigBytes) ++ Data([Byte(106)])
       XCTAssertEqual(expected, testArray.toListExt)
       
       let intArray:[Int] = [255,255,255,-255]
       let bytes255 = [Byte(98),Byte(0),Byte(0),Byte(0),Byte(255)]
       let bytesNeg255 = [Byte(98),Byte(255),Byte(255),Byte(255),Byte(1)]
       
       expected = Data([Byte(108),Byte(0),Byte(0),Byte(0),Byte(4)] + bytes255 + bytes255  + bytes255 + bytesNeg255 + [Byte(106)])
       
       
       XCTAssertEqual(expected, intArray.toListExt)
       
       let emptyList:[String] = []
       expected = Data([Byte(108),Byte(0),Byte(0),Byte(0),Byte(0),Byte(106)])
       XCTAssertEqual(expected, emptyList.toListExt)
   }
   
   //MARK: - Dictionary to external tests
   func testSimpleDictToMapExt(){
       let one = Data([Byte(107)]) ++ Data(UInt32("one".count).toByteArray).toErlangInterchangeByteOrder ++ "one".data(using: .utf8)!
       let two = Data([Byte(107)]) ++ Data(UInt32("two".count).toByteArray).toErlangInterchangeByteOrder ++ "two".data(using: .utf8)!
       let three = Data([Byte(107)]) ++ Data(UInt32("three".count).toByteArray).toErlangInterchangeByteOrder ++ "three".data(using: .utf8)!
       let uno = Data([Byte(97),Byte(1)])
       let dos = Data([Byte(97),Byte(2)])
       let tres = Data([Byte(97),Byte(3)])
       let header = Data([116]) ++ Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray)
       
       var testDict = ["one":1,"two":2, "three":3]
       var result = toMapExt(testDict)!
       
       XCTAssertEqual(37, result.count)
       XCTAssertEqual(header, result[0..<header.count])
       XCTAssertNotNil(result.range(of: one ++ uno))
       XCTAssertNotNil(result.range(of: two ++ dos))
       XCTAssertNotNil(result.range(of: three ++ tres))
       
       let nonStringKeyTestDict = [1:"one",2:"two", 3:"three"]
       result = toMapExt(nonStringKeyTestDict)!
       XCTAssertEqual(37, result.count)
       XCTAssertEqual(header, result[0..<header.count])
       XCTAssertNotNil(result.range(of: uno ++ one))
       XCTAssertNotNil(result.range(of: dos ++ two))
       XCTAssertNotNil(result.range(of: tres ++ three))
       
       
       testDict = [:]
       result = toMapExt(testDict)!
       XCTAssertEqual(5, result.count)
       XCTAssertEqual(Data([116]) ++ Data(UInt32(0).toMachineByteOrder.toByteArray), result[0..<header.count])
       
   }
   
   //in this next set of tests, the keys and values can be tuples, arrays, or Dicts.
   //MARK: - Tuple of other data structures to external tests
   //tuple outer container
   func testTupleOfTuplesToExt(){
       let testTuple = ((1,1),(1,1))
       let expected = Data([Byte(104)]) ++ Data(Byte(2).toByteArray) ++ Data([Byte(104)]) ++ Data(Byte(2).toByteArray) ++ Data([Byte(97),Byte(1),Byte(97),Byte(1)]) ++ Data([Byte(104)]) ++ Data(Byte(2).toByteArray) ++ Data([Byte(97),Byte(1),Byte(97),Byte(1)])
       
       XCTAssertEqual(expected, toTupleExt(testTuple))
   }
   
   func testTupleOfArraysToExt(){
       let testTuple = ([1,1],[1,1],[1,1])
       
       let expected = Data([Byte(104)]) ++ Data([Byte(3)])//small tuple
           ++ Data([Byte(108)]) ++ Data(UInt32(2).toErlangInterchangeByteOrder.toByteArray) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(106)])//lists have a termination indicator
           ++ Data([Byte(108)]) ++ Data(UInt32(2).toErlangInterchangeByteOrder.toByteArray) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(106)])
           ++ Data([Byte(108)]) ++ Data(UInt32(2).toErlangInterchangeByteOrder.toByteArray) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(106)])
       
       XCTAssertEqual(expected, toTupleExt(testTuple))
   }
   
   func testTupleOfDictsToExt(){
       let one = Data([Byte(107)]) ++ Data(UInt32("one".count).toByteArray).toErlangInterchangeByteOrder ++ "one".data(using: .utf8)!
       let two = Data([Byte(107)]) ++ Data(UInt32("two".count).toByteArray).toErlangInterchangeByteOrder ++ "two".data(using: .utf8)!
       let three = Data([Byte(107)]) ++ Data(UInt32("three".count).toByteArray).toErlangInterchangeByteOrder ++ "three".data(using: .utf8)!
       let uno = Data([Byte(97),Byte(1)])
       let dos = Data([Byte(97),Byte(2)])
       let tres = Data([Byte(97),Byte(3)])
       let dictHeader = Data([116]) ++ Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray)
       let tupleHeader = Data([Byte(104)]) ++ Data([Byte(2)])//small tuple
       
       let testTuple = (["one":1,"two":2, "three":3],["one":1,"two":2,"three":3])
       
       let result = toTupleExt(testTuple)!
       
       XCTAssertEqual(76, result.count)
       XCTAssertEqual(tupleHeader, result[0..<tupleHeader.count])
       XCTAssertNotNil(result[tupleHeader.count ..< tupleHeader.count + 37].range(of: dictHeader))
       XCTAssertNotNil(result[tupleHeader.count ..< tupleHeader.count + 37].range(of: one ++ uno))
       XCTAssertNotNil(result[tupleHeader.count ..< tupleHeader.count + 37].range(of: two ++ dos))
       XCTAssertNotNil(result[tupleHeader.count ..< tupleHeader.count + 37].range(of: three ++ tres))
       
       
       XCTAssertNotNil(result[tupleHeader.count  + 37 ..< result.count].range(of: dictHeader))
       XCTAssertNotNil(result[tupleHeader.count + 37 ..< result.count].range(of: one ++ uno))
       XCTAssertNotNil(result[tupleHeader.count + 37 ..< result.count].range(of: two ++ dos))
       XCTAssertNotNil(result[tupleHeader.count + 37 ..< result.count].range(of: three ++ tres))
   }
   
   //MARK: - Array of data structures to external tests
   //array outer container
   func testArrayOfArraysToExt(){
       let testArray = [[1,1],[1,1],[1,1]]
       
       let expected = Data([Byte(108)]) ++ Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray)
           ++ Data([Byte(108)]) ++ Data(UInt32(2).toErlangInterchangeByteOrder.toByteArray) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(106)])//lists have a termination indicator
           ++ Data([Byte(108)]) ++ Data(UInt32(2).toErlangInterchangeByteOrder.toByteArray) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(106)])
           ++ Data([Byte(108)]) ++ Data(UInt32(2).toErlangInterchangeByteOrder.toByteArray) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(106)])
       ++ Data([Byte(106)])//end indicator of outer array
   
       XCTAssertEqual(expected,  testArray.toListExt)
   }
   
   func testArrayOfTuplesToExt(){
       let testArray = [(1,1),(1,1),(1,1)]
       
       var expected = Data([Byte(108)]) ++ Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray)
       
       for _ in 0..<testArray.count{
       expected = expected ++ Data([Byte(104)]) ++ Data([Byte(2)])//small tuple
                           ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(97), Byte(1)])
       }
       expected = expected ++ Data([Byte(106)])//end indicator of outer array
       XCTAssertEqual(expected,  testArray.toListExt)
   }
   
   func testArrayOfDictsToExt(){
       
       let one = Data([Byte(107)]) ++ Data(UInt32("one".count).toByteArray).toErlangInterchangeByteOrder ++ "one".data(using: .utf8)!
       let two = Data([Byte(107)]) ++ Data(UInt32("two".count).toByteArray).toErlangInterchangeByteOrder ++ "two".data(using: .utf8)!
       let three = Data([Byte(107)]) ++ Data(UInt32("three".count).toByteArray).toErlangInterchangeByteOrder ++ "three".data(using: .utf8)!
       let uno = Data([Byte(97),Byte(1)])
       let dos = Data([Byte(97),Byte(2)])
       let tres = Data([Byte(97),Byte(3)])
       let dictHeader = Data([116]) ++ Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray)
       let arrayHeader = Data([Byte(108)]) ++ Data(UInt32(2).toErlangInterchangeByteOrder.toByteArray)
       let arrayTail = Data([Byte(106)])
       
       let testArray = [["one":1,"two":2, "three":3],["one":1,"two":2,"three":3]]
       
       let result = testArray.toListExt!
       
       XCTAssertEqual(80, result.count)
       XCTAssertEqual(arrayHeader, result.prefix(arrayHeader.count))
       XCTAssertEqual(arrayTail, result.suffix(arrayTail.count))
      
       XCTAssertNotNil(result[arrayHeader.count ..< arrayHeader.count + 37].range(of: dictHeader))
       XCTAssertNotNil(result[arrayHeader.count ..< arrayHeader.count + 37].range(of: one ++ uno))
       XCTAssertNotNil(result[arrayHeader.count ..< arrayHeader.count + 37].range(of: two ++ dos))
       XCTAssertNotNil(result[arrayHeader.count ..< arrayHeader.count + 37].range(of: three ++ tres))
//
       
       XCTAssertNotNil(result[arrayHeader.count  + 37 ..< result.count].range(of: dictHeader))
       XCTAssertNotNil(result[arrayHeader.count + 37 ..< result.count].range(of: one ++ uno))
       XCTAssertNotNil(result[arrayHeader.count + 37 ..< result.count].range(of: two ++ dos))
       XCTAssertNotNil(result[arrayHeader.count + 37 ..< result.count].range(of: three ++ tres))
       
   }
   
   //MARK: - Dictionary of data structures to external tests
   //Dict outer container
   func testDictOfArraysToExt(){
       
       let uno = Data([Byte(97),Byte(1)])
       let dos = Data([Byte(97),Byte(2)])
       let tres = Data([Byte(97),Byte(3)])
       
       let dictHeader = Data([116]) ++ Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray)
       let arrayHeader = Data([Byte(108)]) ++ Data(UInt32(2).toErlangInterchangeByteOrder.toByteArray)
       let arrayTail = Data([Byte(106)])
       
       let array =  arrayHeader ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(97), Byte(1)]) ++ arrayTail//lists have a termination indicator
       
       let dictHeaderLength = dictHeader.count
       let arrayLength = array.count
       let keyLength = 2
       
       let totalLength = dictHeaderLength + 3*(keyLength+arrayLength)
       
       let testDict = [1:[1,1],2:[1,1],3:[1,1]]
       
       let result = toMapExt(testDict)!
       
       XCTAssertEqual(totalLength, result.count)
       XCTAssertEqual(dictHeader, result.prefix(dictHeaderLength))
       XCTAssertNotNil(result[dictHeaderLength ..< totalLength].range(of: uno ++ array))
       XCTAssertNotNil(result[dictHeader.count ..< totalLength].range(of: dos ++ array))
       XCTAssertNotNil(result[dictHeader.count ..< totalLength].range(of: tres ++ array))
       
   }
   
   func testDictOfTuplesToExt(){
       
       let uno = Data([Byte(97),Byte(1)])
       let dos = Data([Byte(97),Byte(2)])
       let tres = Data([Byte(97),Byte(3)])
       
       let dictHeader = Data([116]) ++ Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray)
       
       let tuple = Data([Byte(104)]) ++ Data([Byte(2)])//small tuple
       ++ Data([Byte(97), Byte(1)]) ++ Data([Byte(97), Byte(1)])
       
       
       let dictHeaderLength = dictHeader.count
       let tupleLength = tuple.count
       let keyLength = 2
       
       let totalLength = dictHeaderLength + 3*(keyLength+tupleLength)
       
       let testDict = [1:(1,1),2:(1,1),3:(1,1)]
       
       let result = toMapExt(testDict)!
       
       XCTAssertEqual(totalLength, result.count)
       XCTAssertEqual(dictHeader, result.prefix(dictHeaderLength))
       XCTAssertNotNil(result[dictHeaderLength ..< totalLength].range(of: uno ++ tuple))
       XCTAssertNotNil(result[dictHeader.count ..< totalLength].range(of: dos ++ tuple))
       XCTAssertNotNil(result[dictHeader.count ..< totalLength].range(of: tres ++ tuple))
   }
   
   func testDictOfDictsToExt(){
       
       let dictHeader = Data([116]) ++ Data(UInt32(3).toErlangInterchangeByteOrder.toByteArray)
       let subDictHeader = Data([116]) ++ Data(UInt32(1).toErlangInterchangeByteOrder.toByteArray)
       let oneSevenPair = Data([Byte(97),Byte(1),Byte(97),Byte(7)])
       let threeNinePair = Data([Byte(97),Byte(3),Byte(97),Byte(9)])
       let fiveElevenPair = Data([Byte(97),Byte(5),Byte(97),Byte(11)])
       
       let oneDict = Data([Byte(97),Byte(1)]) ++ subDictHeader ++ oneSevenPair
       let twoDict = Data([Byte(97),Byte(2)]) ++ subDictHeader ++ threeNinePair
       let threeDict = Data([Byte(97),Byte(3)]) ++ subDictHeader ++ fiveElevenPair
       
       let totalLength = dictHeader.count + 3 * oneDict.count
       
       let testDict = [1:[1:7],2:[3:9],3:[5:11]]
       let result = toMapExt(testDict)!
       
       XCTAssertEqual(totalLength, result.count)
       XCTAssertEqual(dictHeader, result.prefix(dictHeader.count))
       XCTAssertNotNil(result[dictHeader.count ..< totalLength].range(of: oneDict))
       XCTAssertNotNil(result[dictHeader.count ..< totalLength].range(of: twoDict))
       XCTAssertNotNil(result[dictHeader.count ..< totalLength].range(of: threeDict))
   }
}

