//
//  Codec.swift
//
//Copyright (c) 2022 Lee Barney
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
//  Created by Lee Barney on 12/15/22.
//


///All documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation
import CryptoKit
import BigInt

/// Type alias representing a byte in Swift, defined as an 8-bit unsigned integer.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: Byte
typealias Byte = UInt8

/// Concatenates two `Data` instances using the `++` operator.
///
/// - Parameters:
///   - lhs: The left-hand `Data` operand.
///   - rhs: The right-hand `Data` operand.
/// - Returns: A new `Data` instance resulting from the concatenation of `lhs` and `rhs`.
///
/// - Complexity: O(n + m), where n is the length of `lhs` and m is the length of `rhs`.
///   The time complexity is linear with respect to the total length of both input `Data` instances.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: ++ Operator
infix operator ++ : AssignmentPrecedence

extension Data {
    static func ++(lhs: Data, rhs: Data) -> Data {
        var prepended = lhs
        prepended.append(contentsOf: rhs)
        return prepended
    }
}


/// This extension provides a method to calculate the MD5 hash and represent it as a hexadecimal string.
///
/// - Note: The method `MD5` uses `Insecure.MD5.hash` to compute the MD5 hash of the data and then transforms it into a hexadecimal string. The formatting of the resulting string is "%02hhx". This formatting is used to present a byte (UInt8) as a two-digit hexadecimal string with leading zeros. Breaking it down:

/// - `%` signals the start of the format specifier.
/// - `0` specifies that leading zeros should be used for padding.
/// - `2` specifies the minimum width of the field.
/// - `hh` specifies that the argument is an unsigned char (UInt8).
/// - `x` specifies that the value should be represented in hexadecimal.

/// So, when applied to a UInt8 value, it ensures that the resulting hexadecimal string is always two characters long and includes leading zeros if necessary. For example, if the UInt8 value is 10, the formatted string will be "0a".
///
/// - Complexity: O(n), where n is the size of the Data in bytes.
///
/// - Invariant: Calling `MD5` on the same instance of `Data` will always produce the same MD5 hash, ensuring consistency. The `Data` remains unchanged.
///
/// - Returns: A hexadecimal string representation of the MD5 hash of the Data.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

//@available(macOS 10.15, *)
// MARK: MD5 Hash
extension Data{
//    var MD5: String{
//        return Insecure.MD5.hash(data: self).map { String(format: "%02hhx", $0) }.joined()
//    }
    var MD5:Data{
        return Data(Array(Insecure.MD5.hash(data: self)))
    }
}

extension UInt32{
    var MD5: Data{
        return Data(Array(Insecure.MD5.hash(data: Data(self.toByteArray))))
    }
}

extension String{
    var MD5: Data{
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return Data(hash)
    }
}


/// This extension provides a method to convert the Data to the Erlang interchange  byte order for byte arrays representing integers.
///
/// - Note: The method `toErlangInterchangeByteOrder` checks the current byte order using `CFByteOrderGetCurrent()` and returns
///   the original data if the machine is big-endian. Otherwise, it returns a new `Data` instance with the bytes reversed.
///
/// - Complexity: O(n), where n is the size of the Data in bytes when the machine is not big-endian.
///
/// - Returns: A `Data` instance in the Erlang interchange byte order.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: Erlang Interchange Byte Order
extension Data {
    var toErlangInterchangeByteOrder: Data {
        if CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue {
            return self
        }
        return Data(self.reversed())
    }
}


/// This extension provides a method to convert any `FixedWidthInteger` to the Erlang interchange  byte order, big-endian.
///
/// - Note: The method `toErlangInterchangeByteOrder` checks the current byte order using `CFByteOrderGetCurrent()` and returns
///   the original integer if the machine is big-endian. Otherwise, it returns a new `FixedWidthInteger` instance with the bytes reversed.
///
/// - Complexity: O(n), where n is the size of the integer in bytes when the machine is not big-endian.
///
/// - Returns: A `FixedWidthInteger` instance in the Erlang interchange byte order.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: Erlang Interchange Byte Order
extension FixedWidthInteger{
    var toErlangInterchangeByteOrder:any FixedWidthInteger{
        if CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue {
            return self
        }
        return self.bigEndian
    }
}



/// Converts a `FixedWidthInteger` value to the machine byte order.
///
/// If the current byte order is big endian, the original value is returned.
/// Otherwise, the little endian representation of the value is returned.
///
/// - Returns: The value in the machine byte order.
///
/// - Complexity: O(1).
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: Machine Byte Order
extension FixedWidthInteger {
    var toMachineByteOrder: Self {
        if CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue {
            return self
        }
        return self.littleEndian
    }
}


/// Enumeration representing a device running SwErl. I has a utility method to determine if the device is using little-endian byte order.
///
/// - Note: The method `isLittleEndian/0` relies on `CFByteOrderGetCurrent()` to check the byte order of the device.
///
/// - Complexity: O(1)
///
/// - Returns: A boolean value indicating whether the device is using little-endian byte order.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: isLittleEndian
enum SwErlDevice {
    /// Utility method to determine if the device is using big-endian byte order.
    ///
    /// - Returns: `true` if the device is little-endian, `false` otherwise.
    static func isLittleEndian() -> Bool {
        CFByteOrderGetCurrent() == CFByteOrderLittleEndian.rawValue
    }
}

/// Extension on `Data` providing a method to convert the data representing any integer type to the machine's native byte order.
///
/// - Note: All Erlang inter-node messages use the big-endian representation for byte arrays. The method `toMachineByteOrder` checks the current byte order using `CFByteOrderGetCurrent()` and returns the original `Data` if the machine is big-endian. Otherwise, it returns the little-endian representation of the `Data`.
///
/// - Complexity: O(n), where n is the size of the `Data` in bytes when the machine is not big-endian.
///
/// - Returns: A `Data` instance representing an integer in the machine's native byte order.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

// MARK: toMachineByteOrder
extension Data{
    var toMachineByteOrder:Data{
        if CFByteOrderGetCurrent() == CFByteOrderBigEndian.rawValue {
            return self
        }
        return Data(self.reversed())
    }
}
/// This extension converts any integer value to a little-endian, least significant byte first, byte array.
///
/// - Complexity: O(n) , where n is the size of the integer in bytes.
///   The function processes each byte individually, resulting in a linear time complexity.
///
/// - Returns: A `[UInt8]` representing the little-endian byte order of the integer value.
///
/// - Author: Lee S. Barney
/// - Version: 0.1

// MARK: toByteArray
extension FixedWidthInteger{
    var toByteArray: [UInt8] {
        var value = self
        return (0..<MemoryLayout<Self>.size).reduce(into: []) { result, _ in
            result.append(UInt8(truncatingIfNeeded: value))
            value >>= 8
        }
    }
}

/// This extension converts a little-endian byte array represented as `Data` to a 16-bit unsigned integer (`UInt16`).
///
/// - Complexity: O(n) , where n is the size of the Array.
///   The function processes each element of the array individually, resulting in a linear time complexity.
///
/// - Returns: A little-endian `UInt16`.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: toUInt16
extension Data{
    var toUInt16: UInt16 {
        return self.enumerated().reduce(0) { $0 | UInt16($1.element) << (8 * $1.offset) }
    }
}

/// This extension converts a little-endian byte array represented as `Data` to a 32-bit unsigned integer (`UInt32`).
///
/// - Complexity: O(n) , where n is the size of the Array.
///   The function processes each element of the array individually, resulting in a linear time complexity.
///
/// - Returns: A little-endian `UInt32`.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: toUInt32
extension Data{
    var toUInt32: UInt32 {
        return self.enumerated().reduce(0) { $0 | UInt32($1.element) << (8 * $1.offset) }
    }
}



/// This extension converts a little-endian byte array represented as `Data` to a 64-bit unsigned integer (`UInt64`).
///
/// - Complexity: O(n) , where n is the size of the Array.
///   The function processes each element of the array individually, resulting in a linear time complexity.
///
/// - Returns: A little-endian `UInt64`.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: toUInt64
extension Data{
    var toUInt64: UInt64 {
        return self.enumerated().reduce(0) { $0 | UInt64($1.element) << (8 * $1.offset) }
    }
}


/// This extension provides a property to access the underlying`[Byte]` of a `Data`.
///
/// - Note: The `bytes` property returns an array containing the individual bytes of the `Data`.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: Converts to Bytes
extension Data {
    var bytes: [Byte] {
        Array(self)
    }
}




