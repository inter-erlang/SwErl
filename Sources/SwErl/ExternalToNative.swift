//
//  NativeToExternal.swift
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

///All documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation
import BigInt


/*
 * Erlang External representations to Swift. These
 * are recieved from a node over tcp
 */

// MARK:    Each of the extensions converting the Erlang external representation to native Swift expects to have the initial indicator not included in the data representation.


// MARK: External to Atom Cache Reference
/// Extends the `Data` type with a property to parse an external representation of an atom cache reference.
/// This extension provides a convenient way to decode data that follows a specific format used in Erlang's external term format, particularly for atom cache references. Atom cache references are a part of Erlang's optimization for sending atoms across nodes.
///
/// The expected format is a single byte indicating the tag (82 for atom cache references) followed by the actual atom cache reference data. This property allows for easy extraction of both the tag and the subsequent data, facilitating interaction with Erlang systems or protocols that utilize atom cache references.
/// The format of the external representation is
/// __________________________
/// bytes |   1  |     1             |
/// __________________________
/// value |   82 |AtomCacheReference |
/// --------------------------
///
/// - Returns: A tuple containing the tag as `UInt8` and the remaining data as `Data` if the data starts with a valid tag; otherwise, `nil` if the data is empty or does not conform to the expected format.
///
/// This addition to the `Data` type simplifies the handling of Erlang's external term format within Swift, making it easier to parse and work with data received from Erlang nodes or sent to them.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
extension Data {
    var fromAtomCacheRef: (UInt8, Data)? {
        guard let result = self.first else {
            return nil
        }
        let reduced = self.dropFirst()
        return (result, Data(reduced))
    }
}


// MARK: External to Atom
/// Extends the `Data` type with properties to parse Erlang's external term representations for small and regular atoms using UTF-8 encoding.
/// This extension adds two properties, `fromSmallAtomUTF8Ext` and `fromAtomUTF8Ext`, which facilitate the decoding of atom names from Erlang's SMALL_ATOM_UTF8_EXT and ATOM_UTF8_EXT formats, respectively. These properties help in interpreting Erlang atoms encoded in data streams or files, adjusting the data by removing the bytes used for the atom's representation.
///
/// Note: The `toMachineByteOrder` used in `fromAtomUTF8Ext` is an extension for converting a sequence of bytes to a UInt32 value according to the machine's byte order.

extension Data {
    /// Decodes an atom from its SMALL_ATOM_UTF8_EXT representation and adjusts the `Data` by removing the used bytes.
    /// - Returns: A tuple of `SwErlAtom` representing the decoded atom and the remaining `Data`, or `nil` if decoding fails.
    /// The format of the external representation is
    /// ___________________________
    /// bytes |   1  |   1    | length    |
    /// ___________________________
    /// value |  119 | length | AtomName  |
    /// ---------------------------
    /// where length is the number of bytes in .utf8.
    
    var fromSmallAtomUTF8Ext: (SwErlAtom, Data)? {
        get {
            guard let byteCount = self.first else {
                return nil
            }
            let numBytes = Int(byteCount)
            var reduced = self.dropFirst()
            guard reduced.count >= numBytes, let result = String(bytes: reduced.prefix(numBytes), encoding: .utf8) else {
                return nil
            }
            reduced = reduced.dropFirst(numBytes)
            return (SwErlAtom(result), Data(reduced))
        }
    }
    
    /// Decodes an atom from its ATOM_UTF8_EXT representation and adjusts the `Data` by removing the used bytes.
    /// - Returns: A tuple of `SwErlAtom` representing the decoded atom and the remaining `Data`, or `nil` if decoding fails.
    /// The format of the external representation is
    /// ___________________________
    /// bytes |   1  |   4    | length    |
    /// ___________________________
    /// value |   118 | length | AtomName |
    /// ---------------------------
    /// where length is the number of bytes in .utf8.
    var fromAtomUTF8Ext: (SwErlAtom, Data)? {
        get {
            guard self.count >= 4 else {
                return nil
            }
            let nameLength = Int(self.prefix(4).toMachineByteOrder.toUInt32)
            var reduced = self.dropFirst(4)
            guard reduced.count >= nameLength, let result = String(bytes: reduced.prefix(nameLength), encoding: .utf8) else {
                return nil
            }
            reduced = reduced.dropFirst(nameLength)
            return (SwErlAtom(result), Data(reduced))
        }
    }
}


// MARK: External to Integer
/// Extends the `Data` type with properties to parse integers from Erlang's external term format representations: INTEGER_EXT and SMALL_INTEGER_EXT.
/// These extensions provide convenient ways to decode integers encoded in data streams or files following Erlang's external term formats, specifically for INTEGER_EXT and SMALL_INTEGER_EXT. The properties also adjust the `Data` by removing the bytes used in the integer's representation.
///
/// Note: The `toMachineByteOrder` used in `fromAtomUTF8Ext` is an extension for converting a sequence of bytes to a UInt32 value according to the machine's byte order.

extension Data {
    /// Decodes an integer from its INTEGER_EXT representation and adjusts the `Data` by removing the used bytes.
    /// The INTEGER_EXT format consists of a single byte indicating the tag ('98') followed by 4 bytes representing the integer in big-endian format.
    /// - Returns: A tuple of `Int` representing the decoded integer and the remaining `Data`, or `nil` if decoding fails or if the data is insufficient.
    ///
    /// The format of the external representation is
    /// __________________________
    /// bytes |   1  |     4      |
    /// __________________________
    /// value |   98 |    Int     |
    /// --------------------------
    var fromIntegerExt: (Int, Data)? {
        get {
            let blah = Array(self)
            let blif = self.count
            guard self.count >= 4 else {
                return nil
            }
            var value: Int = 0
            let asUnsigned = self.prefix(4).toMachineByteOrder.toUInt32
            
            if asUnsigned > Int32.max {
                value = Int(~(asUnsigned - 1)) * -1 // Handle negative numbers
            } else {
                value = Int(asUnsigned)
            }
            let reduced = self.dropFirst(4)
            return (value, Data(reduced))
        }
    }
    
    /// Decodes an integer from its SMALL_INTEGER_EXT representation and adjusts the `Data` by removing the used byte.
    /// The SMALL_INTEGER_EXT format consists of a single byte indicating the tag ('97') followed by 1 byte representing the integer.
    /// - Returns: A tuple of `Int` representing the decoded integer and the remaining `Data`, or `nil` if decoding fails or if the data is insufficient.
    ///
    /// The format of the external representation is
    /// __________________________
    /// bytes |   1  |     1             |
    /// __________________________
    /// value |   97 |    Int            |
    /// --------------------------
    ///
    var fromSmallIntegerExt: (Int, Data)? {
        get {
            guard let asUnsigned = self.first else{
                return nil
            }
            var value: Int = 0
            
            if asUnsigned > Int8.max {
                value = Int(~(asUnsigned - 1)) * -1 // Handle negative numbers
            } else {
                value = Int(asUnsigned)
            }
            return (value, self.dropFirst(1))
        }
    }
}

// MARK: External to BigInt

/// Extends the `Data` type with properties to parse big integers from Erlang's external term formats: SMALL_BIG_EXT and LARGE_BIG_EXT.
/// These extensions provide methods to decode large integer values encoded in data streams or files, adhering to Erlang's external term format for large integers. The methods also adjust the `Data` by removing the bytes used in the big integer's representation.

extension Data {
    /// Decodes a big integer from its SMALL_BIG_EXT representation and adjusts the `Data` by removing the used bytes.
    /// The SMALL_BIG_EXT format consists of a byte indicating the number of magnitude bytes, followed by a sign byte, and the magnitude bytes themselves.
    /// - Returns: A tuple of `BigInt` representing the decoded big integer and the remaining `Data`, or `nil` if decoding fails or if the data is insufficient.
    ///
    /// The format of the external representation is
    /// _______________________________________________________
    /// bytes |      1    |      1     |   1  |       byteCount       |
    /// _______________________________________________________
    /// value |     110   |  byteCount | sign | d(0)...d(byteCount-1) |
    /// -------------------------------------------------------
    ///The bytes, d(0)...d(byteCount-1) are NOT 2's compliment.
    ///
    var fromSmallBigExt: (BigInt, Data)? {
        get {
            guard let byteCount = self.first else {
                return nil
            }
            let byteCountInt = Int(byteCount)
            var reduced = self.dropFirst()
            guard reduced.count >= 1 + byteCountInt else { // Including the sign byte
                return nil
            }
            let result = BigInt(reduced.prefix(1 + byteCountInt)) // Includes the sign byte and magnitude
            reduced = reduced.dropFirst(1 + byteCountInt)
            return (result, Data(reduced))
        }
    }
    
    /// Decodes a big integer from its LARGE_BIG_EXT representation and adjusts the `Data` by removing the used bytes.
    /// The LARGE_BIG_EXT format consists of 4 bytes indicating the number of magnitude bytes, followed by a sign byte, and the magnitude bytes themselves.
    /// - Returns: A tuple of `BigInt` representing the decoded big integer and the remaining `Data`, or `nil` if decoding fails or if the data is insufficient.
    ///
    /// The format of the external representation is
    /// _______________________________________________________
    /// bytes |      1    |         4          |    1   |       byteCount       |
    /// _______________________________________________________
    /// value |     111   |  byteCount | sign | d(0)...d(byteCount-1) |
    /// -------------------------------------------------------
    /// The bytes, d(0)...d(byteCount-1) are NOT 2's compliment.
    ///
    var fromLargeBigExt: (BigInt, Data)? {
        get {
            guard self.count >= 5 else { // 4 bytes for length + at least 1 byte for data
                return nil
            }
            let byteCount = Int(self.prefix(4).toMachineByteOrder.toUInt32)
            var reduced = self.dropFirst(4)
            let result = BigInt(reduced.prefix(byteCount)) // Includes the sign byte and magnitude
            reduced = reduced.dropFirst(byteCount)
            return (result,reduced)
        }
    }
}


// MARK: External Floats to Double

extension Data{
    /// Decodes a `Double` from Erlang's `FLOAT_EXT` format, designed for backward compatibility.
    /// This property enables decoding of floating-point numbers formatted as a 31-byte ASCII string,
    /// following the `FLOAT_EXT` external representation used by older Erlang systems.
    /// The format is based on C's `sprintf` function, using "%.20e" to generate the float string.
    ///
    /// - Returns: A tuple containing the decoded `Double` and the remaining `Data` if the decoding is successful;
    /// `nil` if the data is insufficient or the float string cannot be converted to a `Double`.
    /// The method ensures compatibility with systems that utilize this older format for representing floating-point numbers.
    ///
    /// The external representation format:
    /// | Bytes |              Value                          |
    /// |--------|-----------------------------------|
    /// |    1     |    99 (Tag for `FLOAT_EXT`)  |
    /// |   31    | Float string in ASCII encoding |
    ///
    /// Note: The float string is not stored in 2's complement form.
    ///
    /// ### Complexity:
    /// O(1), as the operation involves a fixed sequence of steps regardless of the input data size.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromFloatExt: (Double, Data)? {
        get {
            guard self.count >= 31 else {
                return nil
            }
            var dataCount = 26 // Base count for float data
            guard let firstByte = self.first else {
                return nil
            }
            if "-" == Character(UnicodeScalar(firstByte)) {
                dataCount += 1 // Adjust for negative sign
            }
            let floatData = self.prefix(dataCount)
            guard let floatString = String(bytes: floatData, encoding: .utf8),
                  let result = Double(floatString) else {
                return nil
            }
            let reduced = Data(self[31..<self.count]) // Remaining data after extracting the float
            return (result, reduced)
        }
    }
    
    /// Decodes a `Double` from the `NEW_FLOAT_EXT` representation, adhering to the IEEE 754 standard for floating-point numbers.
    /// This property is essential for decoding floating-point numbers encoded in Erlang's newer external format,
    /// which uses an 8-byte sequence to represent the number in IEEE 754 format. The bytes are expected to be in big-endian order.
    ///
    /// - Returns: A tuple containing the decoded `Double` and the remaining `Data` if the decoding is successful;
    /// `nil` if the data is insufficient for decoding. This method is designed to support the precise and efficient
    /// representation of floating-point numbers in communication with Erlang systems.
    ///
    /// The external representation format:
    /// | Bytes |                      Value                       |
    /// |--------|--------------------------------------|
    /// |    1     | 99 (Tag for `NEW_FLOAT_EXT`) |
    /// |    8     |  IEEE 754 floating-point number  |
    ///
    /// Note: The method assumes the floating-point bit pattern is stored in big-endian order, consistent with the Erlang documentation.
    ///
    /// ### Complexity:
    /// O(1), as the operation involves a fixed sequence of steps regardless of the input data size.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromNewFloatExt: (Double, Data)? {
        get {
            guard self.count >= 8 else {
                return nil
            }
            // Extract the 8-byte IEEE 754 floating-point number in big-endian order
            let patternBytes = self.prefix(8).toMachineByteOrder
            let bitPattern = patternBytes.toUInt64
            let result = Double(bitPattern: bitPattern)
            let reduced = self.dropFirst(8) // Remaining data after extracting the float
            return (result, reduced)
        }
    }
}


// MARK: External to String
extension Data {
    /// Decodes a `String` from the `STRING_EXT` representation used in Erlang's external term format.
    /// This format is designed to encode strings as a sequence of UTF-8 characters preceded by their length.
    ///
    /// The `STRING_EXT` format specifies the string length as a 4-byte integer followed by the actual UTF-8 encoded characters.
    ///
    /// - Returns: A tuple containing the decoded `String` and the remaining `Data` if the decoding is successful;
    /// `nil` if the data is insufficient for decoding or if the string cannot be decoded as UTF-8. This method facilitates
    /// the handling of Erlang-formatted string data within Swift applications, ensuring compatibility with Erlang's
    /// external term format for strings.
    ///
    /// The external representation format:
    /// | Bytes |                       Value                  |
    /// |--------|-----------------------------------|
    /// |    1     | 107 (Tag for `STRING_EXT`) |
    /// |    4     |   Length of the string in bytes  |
    /// |    n     |    UTF-8 encoded characters   |
    ///
    /// Note: The length is specified as a big-endian 4-byte integer, and the method accounts for endianness differences
    /// between the encoding system and the current system.
    ///
    /// ### Complexity:
    /// O(n), where n is the length of the string. The operation involves copying bytes to create the string and the reduced data.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromStringExt: (String, Data)? {
        get {
            guard self.count >= 4 else { // At least 5 bytes needed: 1 for tag + 4 for length
                return nil
            }
            var countBytes = self.prefix(4)
            if SwErlDevice.isLittleEndian() {
                countBytes = Data(countBytes.reversed())
            }
            let byteCount = Int(countBytes.toUInt32)
            var reduced = self.dropFirst(4)
            guard reduced.count >= byteCount else {
                return nil
            }
            
            guard let result = String(bytes: reduced.prefix(byteCount), encoding: .utf8) else {
                return nil
            }
            
            reduced = reduced.dropFirst(byteCount)
            return (result, reduced)
        }
    }
}



// MARK: External to Pid and Node Name

extension Data {
    /// Decodes a `Pid` and node name from the `NEW_PID_EXT` representation used in Erlang's external term format.
    /// This format is specifically designed to encode process identifiers (PIDs) with additional information
    /// about the node on which the process is running. The `NEW_PID_EXT` format includes the external representation
    /// of the node name followed by the PID's ID, Serial, and Creation values.
    ///
    /// The external representation format:
    /// | Bytes |                           Value                                            |
    /// |--------|---------------------------------------------------------|
    /// |    1     |                88 (Tag for `NEW_PID_EXT`)                |
    /// |    ?     | Node (External representation of the node name) |
    /// |    4     |        ID (A 32-bit big endian unsigned integer)       |
    /// |    4     |     Serial (A 32-bit big endian unsigned integer)     |
    /// |    4     |   Creation (A 32-bit big endian unsigned integer)  |
    ///
    /// The node name is either in `SMALL_ATOM_UTF8_EXT` or `ATOM_UTF8_EXT` format. The Creation field helps to differentiate identifiers from different incarnations of the same node, with zero reserved for non-normal operations.
    ///
    /// - Returns: A tuple containing a `Pid` and the node name as a `String`, along with the remaining `Data`, or `nil` if the data is insufficient or decoding fails. This method enables the decoding of process identifiers and their associated node names from data streams conforming to Erlang's external term format.
    ///
    /// ### Complexity:
    /// O(n), where n is the length of the external representation of the node name. The operation involves parsing the node name and extracting the PID's components.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromNewPidExt: ((Pid, String), Data)? {
        get {
            // First, decode the node name from its external representation.
            guard let (atom, reducedResult) = consumeExternal(rep: self),
                  let node = atom as? SwErlAtom,
                  let nodeName = node.string,
                  reducedResult.count >= 12 // Ensure enough data for ID, Serial, and Creation
            else {
                return nil
            }
            var reduced = reducedResult
            
            // Decode the ID, Serial, and Creation fields.
            let id = reduced.prefix(4).toMachineByteOrder.toUInt32
            reduced = reduced.dropFirst(4)
            
            let serial = reduced.prefix(4).toMachineByteOrder.toUInt32
            reduced = reduced.dropFirst(4)
            
            let creation = reduced.prefix(4).toMachineByteOrder.toUInt32
            reduced = reduced.dropFirst(4)
            
            // Return the decoded PID, node name, and the remaining data.
            return ((Pid(id: id, serial: serial, creation: creation), nodeName), reduced)
        }
    }
    
}

// MARK: External to Pid
extension Data {
    /// Decodes a `Pid` and node name from the `PID_EXT` representation used in Erlang's external term format.
    /// This format encodes process identifiers (PIDs) along with information about the node on which the process is running.
    /// The `PID_EXT` format includes the external representation of the node name followed by the PID's ID, Serial, and a Creation byte.
    ///
    /// The external representation format:
    /// | Bytes | Value        |
    /// |-------|--------------|
    /// | 1     | 103 (Tag for `PID_EXT`) |
    /// | ?     | Node (External representation of the node name) |
    /// | 4     | ID (A 32-bit big endian unsigned integer) |
    /// | 4     | Serial (A 32-bit big endian unsigned integer) |
    /// | 1     | Creation (A single byte representing the creation number) |
    ///
    /// The node name is decoded from either a `SMALL_ATOM_UTF8_EXT` or an `ATOM_UTF8_EXT` format, providing flexibility in encoding node names.
    ///
    /// - Returns: A tuple containing a `Pid` and the node name as a `String`, along with the remaining `Data`, or `nil` if the data is insufficient or decoding fails. This method enables the decoding of process identifiers and their associated node names from data streams conforming to Erlang's external term format, supporting interoperability with Erlang systems.
    ///
    /// ### Complexity:
    /// O(n), where n is the length of the external representation of the node name. The operation involves parsing the node name and extracting the PID's components.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromPidExt: ((Pid, String), Data)? {
        get {
            // Decode the node name from its external representation.
            guard let (atom, reducedResult) = consumeExternal(rep: self),
                  let node = atom as? SwErlAtom,
                  let nodeName = node.string,
                  reducedResult.count >= 9 // Ensure enough data for ID, Serial, and Creation
            else {
                return nil
            }
            var reduced = reducedResult
            
            // Decode the ID and Serial fields.
            let id = reduced.prefix(4).toMachineByteOrder.toUInt32
            reduced = reduced.dropFirst(4)
            
            let serial = reduced.prefix(4).toMachineByteOrder.toUInt32
            reduced = reduced.dropFirst(4)
            
            // Decode the Creation field.
            guard let creation = reduced.first else {
                return nil
            }
            reduced = reduced.dropFirst()
            
            // Return the decoded PID, node name, and the remaining data.
            return ((Pid(id: id, serial: serial, creation: UInt32(creation)), nodeName), reduced)
        }
    }
}


// MARK: External to Tuple
/*
 This generates a tuple or a list from a SMALL_TUPLE_EXT  depending on the number of elements in the tuple.
 The format of the external representation is
 ___________________________
 bytes |   1  |   1    |   arity   |
 ___________________________
 value |  104 | arity  | Elements  |
 ---------------------------
 where arity is the number of elements in the tuple
 representation. If the arity is greater than 30, an
 array is generated.
 */
extension Data {
    /// Decodes a small tuple from the Erlang `SMALL_TUPLE_EXT` representation.
    /// This method handles tuples by decoding each element and collecting them into an array or a tuple,
    /// depending on the arity (number of elements) of the tuple. Tuples with arity greater than 10 are treated
    /// as lists for decoding purposes.
    ///
    /// The method starts by extracting the arity from the first byte, then iteratively consumes each element
    /// using a generic `consumeExternal` function, which must be implemented to handle the decoding of various
    /// Erlang external term formats.
    ///
    /// - Returns: A tuple containing the decoded small tuple as `Any` (to accommodate the dynamic nature of tuples
    /// in Swift) and the remaining `Data` after the tuple's elements have been consumed. Returns `nil` if the initial
    /// arity byte is missing or if decoding fails at any step. For tuples with arity greater than 10, the method attempts
    /// to decode them using list decoding logic, due to the dynamic typing limitations in Swift.
    ///
    /// ### Complexity:
    /// O(n), where n is the arity of the tuple. The operation involves decoding each element in the tuple, which may vary
    /// in complexity depending on the element's type and size.
    ///
    /// ### Note:
    /// - The `consumeExternal` function is assumed to be a generic decoder for Erlang's external term formats, capable of
    /// returning a decoded element and the remaining `Data`.
    /// - The `toTuple` property or method on the array is assumed to be an extension that attempts to convert an array
    /// to a tuple. Since Swift does not natively support converting arrays to tuples or creating tuples dynamically, this
    /// would require custom implementation or approximation.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    
    var fromSmallTupleExt:(Any,Data)?{
        guard let arity = self.first else{
            return nil
        }
        var remainingData = self.dropFirst()
        if arity > 10{
            guard let (list,resultData) = consumeExternal(rep: Data([Byte(108)]) ++ remainingData) else{
                return ((),Data())
            }
            guard let list = list else{
                return ((),resultData)
            }
            return (list,resultData)
        }
        var accum:[Any] = []
        for _ in 0..<arity{
            guard let (result,resultData) = consumeExternal(rep: remainingData) else{
                continue
            }
            remainingData = resultData
            guard let result = result else{
                continue
            }
            accum.append(result)
        }
        
        return (accum.toTuple ?? (),remainingData)
    }
}

// MARK: External to LargeTuple
/*
 This generates an array from a LARGE_TUPLE_EXT.
 The format of the external representation is
 ___________________________
 bytes |   1  |   4    |   arity   |
 ___________________________
 value |  105 | arity  | Elements  |
 ---------------------------
 where arity is the number of elements in the tuple representation.
 */
extension Data {
    /// Transforms data representing a `LARGE_TUPLE_EXT` into an array by leveraging the decoding logic of `LIST_EXT`.
    /// Since Erlang's external term format for large tuples (`LARGE_TUPLE_EXT`) is similar to that of lists, this method
    /// appends a `NIL_EXT` byte (`106`) to the end of the data and uses the `fromListExt` property to decode it as a list.
    ///
    /// This approach assumes that the tuple's elements can be decoded using the same mechanism as list elements, with the
    /// primary difference being the tuple's representation does not inherently include a terminator like the `NIL_EXT` used
    /// in lists. By appending a `NIL_EXT`, it conforms to the expected list termination, allowing reuse of the list decoding logic.
    ///
    /// - Returns: A tuple containing an array of the decoded elements (`[Any?]`) and the remaining `Data`, or `nil` if the
    /// data cannot be decoded as a list. This method provides a convenient way to handle large tuples in data streams conforming
    /// to Erlang's external term format, facilitating interoperability with Erlang systems.
    ///
    /// ### Complexity:
    /// O(n), where n is the number of elements in the tuple. The complexity is inherited from the `fromListExt` property, as it
    /// involves decoding each element in the tuple.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromLargeTupleExt:([Any?],Data)?{
        return (self ++ Data([UInt8(106)])).fromListExt
    }
}
// MARK: External to Dictionary

/*
 This generates a Dictionary from MAP_EXT.
 The format of the external representation is
 ________________________
 bytes |   1  |   4   |    N    |
 ________________________
 value |  116 | arity |  pairs  |
 ------------------------
 where arity is the number of key-value pairs and N is
 the size of all the keys and all the values. The keys
 and values can be any valid Erlang external type.
 */
extension Data {
    /// Decodes a dictionary from the `MAP_EXT` external representation used in Erlang's external term format.
    /// This format is intended for representing maps, with a specified number of key-value pairs followed by the encoded data for each pair.
    ///
    /// The method iterates over the specified number of key-value pairs, attempting to decode each key and value using a generalized
    /// external term consumption function, `consumeExternal`, which must be implemented elsewhere in your codebase. Each decoded key-value
    /// pair is added to a dictionary, which is returned along with any remaining data after the map.
    ///
    /// - Returns: A tuple containing the decoded dictionary (`[AnyHashable: Any]`) and the remaining `Data`, or `nil` if the data is insufficient for
    /// decoding, if any key-value pair cannot be decoded, or if any key is not hashable (`AnyHashable`). This method enables the decoding of map structures
    /// from Erlang's external term format, facilitating the interaction with complex data structures in Erlang systems.
    ///
    /// ### Complexity:
    /// O(n), where n is the number of key-value pairs in the map. The operation involves decoding each key and value, which may vary in complexity
    /// depending on the types and sizes of keys and values.
    ///
    /// ### Note:
    /// The `consumeExternal` function used for decoding each key and value is a placeholder for your implementation that must handle various Erlang
    /// external term formats. Keys must be coercible to `AnyHashable` to be used in a Swift dictionary.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromMapExt:([AnyHashable:Any],Data)?{
        guard self.count >= 4 else{
            return nil
        }
        
        let countBytes = self.prefix(4).toMachineByteOrder
        let numPairs = countBytes.toUInt32
        var reduced = self.dropFirst(4)
        
        
        var dict = [AnyHashable: Any]()
        
        for _ in 0..<numPairs{
            guard let (key,remaining) = consumeExternal(rep: reduced) else{
                return nil
            }
            guard let (value,remaining) = consumeExternal(rep: remaining) else{
                return nil
            }
            guard let hashableKey = key as? AnyHashable else{
                return nil
            }
            dict[hashableKey] = value
            reduced = remaining
        }
        return (dict,reduced)
    }
}

// MARK: External to List

/*
 This generates an Array from a LIST_EXT  external representation.
 The format of the external representation is
 ____________________________________________
 bytes |    1  |    4    |  length  |      1        |
 ____________________________________________
 value |   108 |  length | elements | tail (nilExt) |
 --------------------------------------------
 where tail is always NIL_EXT.
 */
extension Data {
    /// Decodes an array from the `LIST_EXT` external representation used in Erlang's external term format.
    /// This format is intended for representing lists, with a specified number of elements followed by those elements' data,
    /// ending with a tail marker indicating the end of the list (typically `NIL_EXT`).
    ///
    /// The method iterates over the specified number of elements, attempting to decode each element using a generalized
    /// external term consumption function, `consumeExternal`, which must be implemented elsewhere in your codebase.
    /// Each decoded element is added to an accumulator array, which is returned along with any remaining data after the list.
    ///
    /// - Returns: A tuple containing the decoded array (`[Any?]`) of elements and the remaining `Data`, or `nil` if the data is
    /// insufficient for decoding, if any element cannot be decoded, or if the list does not terminate with a `NIL_EXT` marker.
    /// This method enables the decoding of list structures from Erlang's external term format, facilitating the interaction
    /// with complex data structures in Erlang systems.
    ///
    /// ### Complexity:
    /// O(n), where n is the number of elements in the list. The operation involves decoding each element in the list,
    /// which may vary in complexity depending on the element's type and size.
    ///
    /// ### Note:
    /// The tail of the list is expected to be a `NIL_EXT` (`106`), which validates the proper termination of the list format.
    /// The `consumeExternal` function used for decoding each element is a placeholder for your implementation that must handle
    /// various Erlang external term formats.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromListExt:([Any?],Data)?{
        guard self.count >= 4 else{
            return nil
        }
        
        let countBytes = self.prefix(4)
        let numElements = countBytes.toMachineByteOrder.toUInt32
        var reduced = self.dropFirst(4)
        
        var accum:[Any?] = []
        for _ in 0..<numElements{
            guard let (result,resultingData) = consumeExternal(rep: reduced) else{
                return nil
            }
            accum.append(result)
            reduced = resultingData
        }
        guard 106 == reduced.first else{
            return nil
        }
        return (accum,reduced.dropFirst())
    }
}

// MARK: External to BitString
extension Data {
    /// Decodes a `BitString` from the `BINARY_EXT` representation used in Erlang's external term format.
    /// This format is designed to encode binary data, which can include any arbitrary sequence of bytes.
    ///
    /// The method first extracts the length of the binary data as a 4-byte integer, followed by the actual
    /// binary data corresponding to this length. The `BitString` structure is then populated with the extracted
    /// binary data.
    ///
    /// - Returns: A tuple containing the decoded `BitString` and the remaining `Data` if the decoding is successful;
    /// `nil` if the data is insufficient for decoding, the length of binary data is zero, or the binary data cannot
    /// be decoded. This method enables the handling of binary data within Swift applications, facilitating
    /// interoperability with Erlang systems by correctly interpreting binary external term formats.
    ///
    /// ### Complexity:
    /// O(n), where n is the number of bytes specified by the length of the binary data. The operation involves
    /// copying the specified number of bytes to create the `BitString`.
    ///
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    
    var fromBinaryExt:(BitString,Data)?{
        guard self.count >= 4 else{
            return nil
        }
        
        let count = self.prefix(4).toMachineByteOrder
        let numBytes = Int(count.toUInt32)
        guard numBytes > 0 else{
            return nil
        }
        var reduced = self.dropFirst(4)
        guard let bitCount = self.first, bitCount > 0 else{
            return nil
        }
        reduced = reduced.dropFirst()
        let bString = reduced.prefix(numBytes)
        reduced = reduced.dropFirst(numBytes)
        
        return (BitString(bitCount: bitCount, internalBytes: bString), reduced)
    }
}


// MARK: External to Reference
extension Data {
    /// Decodes a `SwErlRef` from the `REFERENCE_EXT` representation used in Erlang's external term format.
    /// This format is designed to encode distributed process references in Erlang, incorporating information about the
    /// node on which the reference was created, along with a unique identifier and a creation number to ensure the
    /// reference's uniqueness across different incarnations of the node.
    ///
    /// The method begins by attempting to read the external representation of the node name, either as a SMALL_ATOM_UTF8_EXT
    /// or ATOM_UTF8_EXT, followed by extracting the reference's ID and creation number.
    ///
    /// - Returns: A tuple containing the decoded `SwErlRef` and the remaining `Data` if the decoding is successful;
    /// `nil` if the data is insufficient for decoding or if the decoding process fails at any step. This method enables
    /// the handling of Erlang references within Swift applications, facilitating interoperability with Erlang systems.
    ///
    /// ### Complexity:
    /// O(n), where n is the length of the external representation of the node name. The operation involves parsing the
    /// node name and extracting the reference's ID and creation number.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromReferenceExt:(SwErlRef,Data)?{
        //first read the atom, small or regular
        guard self.count > 1 else{
            return nil
        }
        // Next, read the atom
        guard let (atom, reducedResult) = consumeExternal(rep: self),
              let node = atom as? SwErlAtom,
              node.string != nil,
              reducedResult.count >= 9
        else {
            return nil
        }
        var reduced = reducedResult
        
        let idBytes = reduced.prefix(4)
        let id = idBytes.toUInt32
        reduced = reduced.dropFirst(4)
        
        guard let creation = reduced.first else {
            return nil
        }
        return ((SwErlRef(node:node, id:id, creation: UInt32(creation))),reduced.dropFirst())
    }
}

// MARK: External to NewReference
extension Data {
    /// Attempts to decode a new reference from the `NEW_REFERENCE_EXT` representation used in Erlang's external term format.
    /// Due to the complex nature of new references in Erlang, which include multiple layers of information such as the node name,
    /// ID, and creation, this method currently does not implement decoding logic and always returns `nil`.
    ///
    /// The `NEW_REFERENCE_EXT` format is intended for representing distributed process references in a way that includes the node
    /// on which the reference was created, alongside a unique identifier and creation data to ensure the reference's uniqueness
    /// across different node incarnations.
    ///
    /// - Returns: Always returns `nil`, as the decoding of `NEW_REFERENCE_EXT` is not implemented.
    /// Implementing this functionality would require handling the specific structure of new references, including parsing
    /// the node name from its external representation and extracting the unique identifier and creation data.
    ///
    /// ### Complexity:
    /// O(1), as the method does not perform any operations on the data.
    ///
    /// - Author: Lee S. Barney
    /// - Version: 0.1
    var fromNewReferenceExt: (Any, Data)? {
        return nil
    }
}


// MARK: External to NewerReference
extension Data {
    /// This extension provides a property to deserialize binary data representing a newer Erlang reference.
    ///
    /// - Note: The `fromNewerReferenceExt` property attempts to deserialize a tuple containing a `SwErlNewerRef` instance and the remaining `Data`.
    ///   The binary data in the final, ID, field is not interpreted.
    ///
    ///
    /// The Erlang external format, NEWER_REFERENCE_EXT, is
    ///       _____________________________________________
    ///  bytes |    1  |      2    |    ?    |      4       |                      length                     |
    ///       _____________________________________________
    ///  value |   90 |  length | node | creation |   ID: UInt32(1)...UInt32(length)    |
    ///       ---------------------------------------------
    /// where length is 5 or less and read as a `UInt16`. The  node field is either an SMALL_ATOM_UTF8_EXT or an ATOM_UTF8_EXT of unknown lengh, and the last field is read as length number of `UInt32`s.
    ///
    /// - Complexity: O(n),where n is the size of the `Data`.
    ///
    /// - Returns: A tuple containing a `SwErlNewerRef` instance and the remaining `Data`, or `nil` if the deserialization fails.
    var fromNewerReferenceExt: (SwErlNewerRef, Data)? {
        
        guard self.count >= 2 else {
            return nil
        }
        let numIdUInt32s = Int(self.prefix(2).toMachineByteOrder.toUInt16)
        guard numIdUInt32s <= 5 else {
            return nil
        }
        var reduced = self.dropFirst(2)
        // Next, read the atom
        guard let (atom, reducedResult) = consumeExternal(rep: reduced),
              let node = atom as? SwErlAtom,
              node.string != nil,
              reducedResult.count >= 4
        else {
            return nil
        }
        reduced = reducedResult
        let creation = reduced.prefix(4).toMachineByteOrder.toUInt32
        reduced = reduced.dropFirst(4)
        let creationSize = numIdUInt32s * MemoryLayout<UInt32>.size
        let idData = reduced.prefix(creationSize)
        reduced = reduced.dropFirst(creationSize)
        
        return (SwErlNewerRef(node: node, creation: creation, id: idData), reduced)
    }
}


/// The Erlang external format, `NEW_FUN`,  partially described is
///       __________
///  bytes |    1  |      4      |
///       __________
///  value |   112 |  length |
///       ----------
// MARK: External to NewFun
extension Data{
    //for now, just consume the entirety of the message.
    //don't know if this will actually be needed.
    //if not, will have the value be an error so an error
    //can be in the response, if appropriate.
    var fromNewFunExt:(Any,Data)?{
        guard self.count >= 4 else{
            return nil
        }
        let size = Int(self.prefix(4).toMachineByteOrder.toUInt32)
        
        return (7,self.dropFirst(size))
    }
}


/// This extension provides a property to deserialize binary data representing an Erlang function registered globally in another node.
///
/// - Note: The `fromExportExt` property attempts to deserialize data in the Erlang Exchange format. The format is
///       ______________________
///  bytes |     1   |      ?      |       ?      |   1    |
///       ______________________
///  value |   113 |  module | function | arity |
///       ----------------------
///
///
/// - Complexity: The time complexity of this operation is O(n), where n is the size of the `Data`.
///
/// - Returns: A tuple containing a `SwErlExportFunc` instance and the remaining `Data`, or `nil` if the deserialization fails.
///
// MARK: External to Export
extension Data {
    var fromExportExt: (SwErlExportFunc, Data)? {
        guard self.count > 1 else {
            return nil
        }
        guard let (possibleModule, moduleReduced) = consumeExternal(rep: self),
              let module = possibleModule as? SwErlAtom
        else {
            return nil
        }
        guard let (possibleFunction, functionReduced) = consumeExternal(rep: moduleReduced),
              let function = possibleFunction as? SwErlAtom
        else {
            return nil
        }
        guard let (possibleArity, arityReduced) = consumeExternal(rep: functionReduced),
              let arity = possibleArity as? Int
        else {
            return nil
        }
        return (SwErlExportFunc(module: module, function: function, arity: arity), arityReduced)
    }
}


// MARK: External to BitBinary
/// This extension provides a property to deserialize deserialize binary data represented in the Erlang exchange format.
///
/// - Note: The `fromExportExt` property attempts to deserialize data in the Erlang exchange format. The format is
///       _________________________
///  bytes |     1   |     4     |       1       |   length   |
///       _________________________
///  value |    77  |  length | final bits |      data   |
///       -------------------------
///  where the final bits field is a value between 1 and 8.
/// - Complexity: The time complexity of this operation is O(n), where n is the size of the `Data`.
///
/// - Returns: A tuple containing a `SwErlBitBinary` instance and the remaining `Data`, or `nil` if the deserialization fails.
///
/// - Important: This extension is specifically designed to handle the deserialization of external representations of bit binaries.
///   It extracts information about the final bit count and the actual bit data from the provided binary data.
///
/// - Note: The `SwErlBitBinary` structure includes the final bit count and the information bits as its properties.
extension Data {
    var fromBitBinaryExt: (SwErlBitBinary, Data)? {
        guard self.count >= 5 else {
            return nil
        }
        let count = Int(self.prefix(4).toMachineByteOrder.toUInt32)
        var reduced = self.dropFirst(count)
        guard let finalBitUseCount = self.first else {
            return nil
        }
        reduced = reduced.dropFirst()
        let bits = reduced.prefix(count)
        reduced = reduced.dropFirst(count)
        return (SwErlBitBinary(finalBitCount: finalBitUseCount, bits: bits), reduced)
    }
}

/// This extension provides a function to deserialize an Erlang `LOCAL_EXT` representation.
///
/// - Note: The `fromLocal` function takes an optional decoder closure. This closure returns a tuple containing an optional value of type `Any` and the remaining `Data`.
///   It utilizes the provided decoder to transform the binary data into the desired type and extract the remaining data.
///
///   The format of `LOCAL_EXT` is
///       ________
///  bytes |     1   |    ...  |
///       ________
///  value |    121  | ...   |
///       --------
/// The number of bytes and the bytes are left undefined here since they will be determined and consumed using a custom decoder.
/// - Parameters:
///   - decoder: An optional closure that takes `Data` as input and returns a tuple containing an optional value of type `Any` and the remaining `Data`.
///              The closure is responsible for decoding the binary data and providing the remaining data after decoding.
///
/// - Returns: A tuple containing an optional value of type `Any` and the remaining `Data` obtained by applying the provided decoder to the input binary data.
///   Returns `nil` if the decoding process fails, if the decoder is `nil`, or if the decoder itself returns `nil` for the value.
///
/// - Complexity: The complexity of this operation depends on the implementation of the provided decoder closure.
///   It may vary based on the size and structure of the input data and the specific decoding logic applied.
///
/// - Important: This extension enables `Data` instances to conveniently use the `fromLocal` function for deserializing Erlang `LOCAL_EXT` representations.
///   It allows for flexibility by accepting an optional custom decoder closure containing the specific deserialization logic. This logic may use conditional branching based on the information in the `Data`.
///

// MARK: External to Local
extension Data {
    func fromLocal(decoder: ((Data) -> (Any?,Data)?)?) -> (Any?,Data)? {
        guard let decoder = decoder else{
            return nil
        }
        return decoder(self)
    }
}

/// Extracts a `SwErlPort` and the remaining data from the beginning of the `Data`.
///
/// - Returns: A tuple containing a `SwErlPort` and the remaining `Data` after extraction.
///            Returns `nil` if the extraction is unsuccessful.
///
/// - Complexity: O(n), where n is the length of the `Data`.
///
/// - Note:
///
///  The format of `PORT_EXT` is
///       __________________________
///  bytes |      1    |     ?    |      4    |         1          |
///       __________________________
///  value |    102  |  node |     ID    |    creatation |
///       --------------------------
///
/// - Author: Lee S. Barney
/// - Version: 0.1

// MARK: External to Port
extension Data {
    var fromPortExt: (SwErlPort, Data)? {
        // First, read the atom
        guard let (atom, reducedResult) = consumeExternal(rep: self),
              let node = atom as? SwErlAtom,
              node.string != nil,
              reducedResult.count >= 4
        else {
            return nil
        }
        
        var reduced = reducedResult
        let ID = reduced.prefix(4).toMachineByteOrder.toUInt32
        reduced = reduced.dropFirst(4)
        
        guard let creation = reduced.first else {
            return nil
        }
        reduced = reduced.dropFirst()
        
        let mask: UInt8 = 0b00000011 // only two bits are significant
        
        return (SwErlPort(node: node, ID: ID, creation: creation & mask), reduced)
    }
}




/// Extracts a `SwErlNewPort` and the remaining data from the beginning of the `Data`.
///
/// - Returns: A tuple containing a `SwErlNewPort` and the remaining `Data` after extraction.
///            Returns `nil` if the extraction is unsuccessful.
///
/// - Complexity: O(n), where n is the length of the `Data`.
///
/// - Note:
///
///  The format of `NEW_PORT_EXT` is
///       __________________________
///  bytes |      1    |     ?    |      4    |         4          |
///       __________________________
///  value |    89    |  node |     ID    |    creatation |
///       --------------------------
/// - Author: Lee S. Barney
/// - Version: 0.1

// MARK: External to NewPort
extension Data {
    var fromNewPortExt: (SwErlNewPort, Data)? {
        // First, read the atom
        guard let (atom, reducedResult) = consumeExternal(rep: self),
              let node = atom as? SwErlAtom,
              node.string != nil,
              reducedResult.count >= 4
        else {
            return nil
        }
        
        var reduced = reducedResult
        
        guard reduced.count >= 8 else {
            return nil
        }
        
        let ID = reduced.prefix(4).toMachineByteOrder.toUInt32
        reduced = reduced.dropFirst(4)
        
        let creation = reduced.prefix(4).toMachineByteOrder.toUInt32
        reduced = reduced.dropFirst(4)
        
        let mask: UInt32 = 0b00001111111111111111111111111111 // only 28 bits are significant
        
        return (SwErlNewPort(node: node, ID: ID, creation: creation & mask), reduced)
    }
}


/// Extracts a `SwErlV4Port` and the remaining data from the beginning of the `Data`.
///
/// - Returns: A tuple containing a `SwErlV4Port` and the remaining `Data` after extraction.
///            Returns `nil` if the extraction is unsuccessful.
///
/// - Complexity: O(n), where n is the length of the `Data`.
///
/// - Note:
///
///  The format of `V4_PORT_EXT` is
///       __________________________
///  bytes |      1    |     ?    |      4    |         1          |
///       __________________________
///  value |    102  |  node |     ID    |    creatation |
///       --------------------------
///
/// - Author: Lee S. Barney
/// - Version: 0.1
// MARK: External to V4Port
extension Data {
    var fromV4PortExt: (SwErlV4Port, Data)? {
        // First, read the atom
        guard let (atom, reducedResult) = consumeExternal(rep: self),
              let node = atom as? SwErlAtom,
              node.string != nil,
              reducedResult.count >= 4
        else {
            return nil
        }
        
        var reduced = reducedResult
        
        guard reduced.count >= 12 else {
            return nil
        }
        
        let ID = reduced.prefix(8).toMachineByteOrder.toUInt64
        reduced = reduced.dropFirst(8)
        
        let creation = reduced.prefix(4).toMachineByteOrder.toUInt32
        reduced = reduced.dropFirst(4)
        
        return (SwErlV4Port(node: node, ID: ID, creation: creation), reduced)
    }
}

/// Consumes Erlang external term representations and decodes them into the corresponding SwErl types.
///
/// - Parameters:
///   - rep: The `Data` containing one or more external term representations.
///   - customDecoder: A custom decoding closure to decode `LOCAL_EXT` messages. Default is `nil`.
/// - Returns: A SwErl type containing the decoded value of type  and the remaining `Data` after extraction.
///            Returns `nil` if the extraction is unsuccessful or the indicator is not recognized.
///
/// - Complexity: O(1).
///
/// - Author: Lee S. Barney
/// - Version: 0.1
///
/// - Note: The customDecoder parameter allows users to provide a custom decoding closure for handling specific `LOCAL_EXT` external types.
// MARK: consumeExternal
func consumeExternal(rep:Data, customDecoder:((Data)->(Any?,Data))? = nil)->(Any?,Data)?{
    guard rep.count > 0 else{
        return nil
    }
    guard let indicator = rep.first else{
        return nil
    }
    
    let remainingBytes = rep.dropFirst()
    switch indicator {
    case 82:
        return remainingBytes.fromAtomCacheRef
    case 97:
        return remainingBytes.fromSmallIntegerExt
    case 98:
        return remainingBytes.fromIntegerExt
    case 99:
        return remainingBytes.fromFloatExt
    case 102:
        return remainingBytes.fromPortExt
    case 89:
        return remainingBytes.fromNewPortExt
    case 120:
        return remainingBytes.fromV4PortExt
    case 103:
        return remainingBytes.fromPidExt
    case 88:
        return remainingBytes.fromNewPidExt
    case 104:
        return remainingBytes.fromSmallTupleExt
    case 105:
        return remainingBytes.fromLargeTupleExt
    case 116:
        return remainingBytes.fromMapExt
    case 106:
        return (nil,remainingBytes)//NIL_EXT
    case 107:
        return remainingBytes.fromStringExt
    case 108:
        return remainingBytes.fromListExt
    case 109:
        return remainingBytes.fromBinaryExt
    case 110:
        return remainingBytes.fromSmallBigExt
    case 111:
        return remainingBytes.fromLargeBigExt
    case 101:
        return remainingBytes.fromReferenceExt
    case 114:
        return remainingBytes.fromNewReferenceExt
    case 90:
        return remainingBytes.fromNewerReferenceExt
    case 112:
        return remainingBytes.fromNewFunExt
    case 113:
        return remainingBytes.fromExportExt
    case 77:
        return remainingBytes.fromBitBinaryExt
    case 70:
        return remainingBytes.fromNewFloatExt
    case 118:
        return remainingBytes.fromAtomUTF8Ext
    case 119:
        return remainingBytes.fromSmallAtomUTF8Ext
    case 100:
        return remainingBytes.fromAtomUTF8Ext//the consumption process for the deprecated ATOM_EXT is the same as for ATOM_UTF8_EXT
    case 115:
        return remainingBytes.fromSmallAtomUTF8Ext//the consumption process for the deprecated SMALL_ATOM_EXT is the same as for SMALL_ATOM_UTF8_EXT
    case 121:
        return (remainingBytes.fromLocal(decoder: customDecoder))
    default:
        // Handle other cases or provide a default value
        return nil
    }
}
