//
//  Codec.swift
//
//
//  Created by Lee Barney on 12/15/22.
//

import Foundation
import CryptoKit
import BigInt

typealias Byte = UInt8

///
///Value is a new Data consisting of the second Data appended to the first Data.
///
infix operator ++ :  AssignmentPrecedence
extension Data{
    static func ++( lhs: Data, rhs: Data)->Data {
        var prepended = lhs
        prepended.append(contentsOf: rhs)
        return prepended
    }
}

//These extentions are added to make the handshake protocol easier to deal with
extension UInt32{
    var data:Data{
        return withUnsafeBytes(of: self) { Data($0) }
    }
}

@available(macOS 10.15, *)
extension String {
    var MD5: String {
        let computed = Insecure.MD5.hash(data: self.data(using: .utf8)!)
        return computed.map { String(format: "%02hhx", $0) }.joined()
    }
}
@available(macOS 10.15, *)
extension Data{
    var MD5: String{
        return Insecure.MD5.hash(data: self).map { String(format: "%02hhx", $0) }.joined()
    }
}



extension UInt16 {
    var bigendian_bytes: [Byte] {
        var value:UInt16 = 0
        //either a mutable byte switched version is needed
        //or a mutable value without the bytes being switched
        if CFByteOrderGetCurrent() == CFByteOrderLittleEndian.rawValue{
            value = self.bigEndian
        }
        else{
            value = self*1
        }
        let count = MemoryLayout<UInt16>.size
        let bytePtr = withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: Byte.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        return Array(bytePtr)
    }
}

///
///All Erlang inter-node messages use the big-endian
///representation for numbers. This function
///switches the representation of those numbers to match
///the machine's number representation type.
///
extension UInt16{
    var toMessageByteOrder:UInt16{
        if CFByteOrderGetCurrent() == CFByteOrderLittleEndian.rawValue {
            return self
        }
        return self.bigEndian
    }
}
extension UInt32{
    var toMessageByteOrder:UInt32{
        if CFByteOrderGetCurrent() == CFByteOrderLittleEndian.rawValue {
            return self
        }
        return self.bigEndian
    }
}

extension UInt64{
    var toMessageByteOrder:UInt64{
        if CFByteOrderGetCurrent() == CFByteOrderLittleEndian.rawValue {
            return self
        }
        return self.bigEndian
    }
}
extension Data{
    var toMessageByteOrder:Data{
        if CFByteOrderGetCurrent() == CFByteOrderLittleEndian.rawValue {
            return self
        }
        return Data(self.reversed())
    }
}

///
///All Erlang inter-node messages use the big-endian
///representation for numbers. This function
///switches the representation of the machine's numbers to be big-endian.
///
extension UInt16{
    var toMachineByteOrder:UInt16{
        if CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue {
            return self
        }
        return self.littleEndian
    }
}
extension UInt32{
    var toMachineByteOrder:UInt32{
        if CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue {
            return self
        }
        return self.littleEndian
    }
}

extension UInt64{
    var toMachineByteOrder:UInt64{
        if CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue {
            return self
        }
        return self.littleEndian
    }
}
extension Data{
    var toMachineByteOrder:Data{
        if CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue {
            return self
        }
        return Data(self.reversed())
    }
}
///
///converts an UInt16 to an array of two bytes
///
extension UInt16{
    var toByteArray:[Byte]{
        return withUnsafeBytes(of: self) {
            Array($0)
        }
    }
}

extension UInt32 {
    var toByteArray:[Byte]{
        return withUnsafeBytes(of: self) {
            Array($0)
        }
    }
}


extension UInt64 {
    var toByteArray:[Byte]{
        return withUnsafeBytes(of: self) {
            Array($0)
        }
    }
}

///
///Converts an array of two bytes to a UInt16
///
extension Data {
    var toUInt16: UInt16 {
        let asBytes = self.bytes
        return UInt16(asBytes[0]) |        //<< (0*8))  // shift 0 bits
              (UInt16(asBytes[1]) * 256)    //<< (1*8))   // shift 8 bits
    }
}
//this extension uses multiplication rather than bit-shifting
//to give the compiler every chance to maximize optimization.
extension Data {
    var toUInt32: UInt32 {
        return UInt32(self[0])            | //<< (0*8)) | // shift 0 bits
        UInt32(self[1]) * 256      | // << (1*8)) | // shift 8 bits
        UInt32(self[2]) * 65536    | // << (2*8)) | // shift 16 bits
        UInt32(self[3]) * 16777216   // << (3*8))   // shift 24 bits
        
    }
}

//this extension uses multiplication rather than bit-shifting
//to give the compiler every chance to maximize optimization.
extension Data {
    var toUInt64: UInt64 {
        return UInt64(self[0])            | //<< (0*8)) | // shift 0 bits
        UInt64(self[1]) * 256      | // << (1*8)) | // shift 8 bits
        UInt64(self[2]) * 65536    | // << (2*8)) | // shift 16 bits
        UInt64(self[3]) * 16777216 |  // << (3*8))   // shift 24 bits
        UInt64(self[4]) * 4294967296 | // << (4*8))   // shift 32 bits
        UInt64(self[5]) * 1099511627776 | // << (5*8))   // shift 40 bits
        UInt64(self[6]) * 281474976710656 | // << (6*8))   // shift 48 bits
        UInt64(self[7]) * 72057594037927936 // << (7*8))   // shift 56 bits
    }
}

extension Data {
    var bytes: [Byte] {
        var byteArray = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &byteArray, count: self.count)
        return byteArray
    }
}



extension Data{
    /// Write an array of bytes to a Data instance
    /// - Parameter bytes: the array of bytes to write at Data's current write postion. The write postion is updated by each write.
    /// - Returns: the modified Data instance
    /// - Complexity: O(n), where n is the number of bytes
    mutating func write(_ bytes:[Byte]){
        self.append(contentsOf: bytes)
    }
}

extension Data{
    /// Writes an array of an array of bytes in order, from first to last. Writting begins at the Data instance's current write location. The write location is updated to the end of the last written byte array.
    /// - Parameter list: an array of an array of bytes, [Byte] to be written to the Data instance
    /// - Returns: the modified data instance
    /// - Complexity: O(n), where n is the sum of the number of bytes in each byte array.
    mutating func writeAll(in list:[[Byte]]){
        list.forEach{
            self.write($0)//write each byte array
        }
    }
}


