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
//  Created by Lee Barney on 12/4/23.
//

///Documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation
import BigInt


/*
 * Swift to Erlang External representations. These
 * are sent to a node over tcp
 */

// MARK: Bool to Atom External

/// An extension for `Bool` to convert boolean values to their equivalent SwErl atom representation in external format.
///
/// This extension on the `Bool` type provides a convenient way to convert boolean values (`true` or `false`) into their
/// respective `SwErlAtom` representations as `Data` in an external format. This is particularly useful for interoperability
/// with systems that use Erlang's external term format to encode and decode boolean values as atoms.
///
/// - Properties:
///   - toBoolExt: A computed property that converts the boolean value to its corresponding `SwErlAtom` external representation
///     as `Data`. It returns "true" or "false" atoms based on the boolean value.
///
/// This extension uses the `toAtomExt` property of `SwErlAtom` that returns an optional `Data` representing the atom in external format.
///
/// Example Usage:
/// ```swift
/// let trueAtomData = true.toBoolExt  // Converts true to its SwErlAtom external representation
/// let falseAtomData = false.toBoolExt // Converts false to its SwErlAtom external representation
/// ```
///
/// - Complexity: The complexity of converting a boolean to its atom external representation depends on the implementation
///   of `SwErlAtom`'s `toAtomExt` property.
///
/// - Author: Lee Barney
/// - Version: 0.1
extension Bool {
    var toBoolExt: Data {
        if self == true {
            return SwErlAtom("true").toAtomExt!
        }
        return SwErlAtom("false").toAtomExt!
    }
}


// MARK: Byte to SwErlAtomCacheReference External

/// An extension for `UInt8` to convert byte values to their SwErl atom cache reference external representation.
///
/// This extension on the `UInt8` type enables the conversion of a byte (an unsigned 8-bit integer) into its corresponding
/// external representation as a SwErl atom cache reference. The external format is defined to start with a byte indicating
/// the type (82 for atom cache reference), followed by the actual byte value representing the atom cache reference.
///
/// - Properties:
///   - toAtomCacheRef: A computed property that constructs the external representation of the SwErl atom cache reference as `Data`.
///     It combines a header byte (`82`) with the `UInt8` value itself to form the external representation.
///
/// This method is useful when working with systems that require the use of Erlang's external term format, particularly for
/// referencing atoms that are cached to save space in message passing between Erlang nodes.
///
/// Example Usage:
/// ```swift
/// let atomCacheRef = myUInt8.toAtomCacheRef  // Converts a UInt8 to its SwErlAtomCacheReference external representation
/// ```
///
/// - Complexity: O(1) - The operation performs a fixed sequence of steps regardless of the input value.
///
/// - Author: Lee Barney
/// - Version: 0.1
extension UInt8 {
    var toAtomCacheRef: Data? {
        let header = Data([UInt8(82)]) // Header byte for SwErlAtomCacheReference
        let num = Data([self]) // The UInt8 value itself
        return header + num // Combine header and number to form the external representation
    }
}



// MARK: Integers to External
/*
    The format of the external representation is
             __________________________
      bytes |   1  |     1             |
             __________________________
      value |   97 |    Int            |
             --------------------------
      
      for any standard type that can be represented in one byte.
      For any standard type up through 32 bit unsigned integers,
      the format of the external representation is
             __________________________
      bytes |   1  |     4             |
             __________________________
      value |   98 |    Int            |
             --------------------------
 */
// MARK: Integers to External

/// An extension for all `FixedWidthInteger` types to convert integer values to their external representation.
///
/// This extension provides a mechanism for converting integer values of various sizes (`Int`, `UInt`, `Int8`, `UInt8`, `Int16`, `UInt16`, `Int32`, `UInt32`) into a format suitable for external representation, adhering to Erlang's external term format. The function dynamically determines the appropriate representation based on the integer's size and value, optimizing for the smallest possible representation.
/// The format of the external representation is
/// __________________________
/// bytes |   1  |     1             |
/// __________________________
/// value |   97 |    Int            |
/// --------------------------
///
/// for any standard type that can be represented in one byte.
/// For any standard type up through 32 bit unsigned integers,
/// the format of the external representation is
/// __________________________
/// bytes |   1  |     4             |
/// __________________________
/// value |   98 |    Int            |
/// --------------------------
///
/// - Properties:
///   - toIntegerExt: A computed property that generates the external representation of the integer as `Data`. The representation varies depending on the integer's size and range, using a single byte for `Int8` and `UInt8` values that fit within `Int8`'s range, and four bytes for larger integers up to `Int32` and `UInt32`. Larger integers are converted using a separate `BigInt` conversion method.
///
/// This approach ensures that integers are encoded efficiently, using the minimum amount of space required for their representation. It supports the full range of `FixedWidthInteger` types, including those larger than 32 bits through fallback to a `BigInt` representation.
///
/// - Complexity: The complexity varies based on the integer's type and value. It ranges from O(1) for small integers that fit within a single byte to potentially higher for larger integers requiring conversion to `BigInt`.
///
/// - Author: Lee Barney
/// - Version: 0.1
extension FixedWidthInteger{
    var toIntegerExt:Data?{
        if self is Int || self is UInt{
            if Int8.min <= self && self <= Int8.max {
                return Int8(self).toIntegerExt
            } else if Int16.min <= self && self <= Int16.max {
                return Int16(self).toIntegerExt
            } else if Int32.min <= self && self <= Int32.max {
                return Int32(self).toIntegerExt
            } else {
                return BigInt(self).toBigExt
            }
        }
        if self is Int8{
            let header = Data([UInt8(97)])
            let num = Data([UInt8(self)])
            return header ++ num
        }
        else if self is UInt8{
            if self > UInt8(Int8.max) {
                return UInt16(self).toIntegerExt
            }
            let header = Data([UInt8(97)])
            let num = Data([UInt8(self)])
            return header ++ num
        }
        else if self is Int16 || self is UInt16 {
            return Int32(self).toIntegerExt
        }
        else if self is Int32{
            let header = Data([UInt8(98)])
            let num = Data(self.toErlangInterchangeByteOrder.toByteArray)
            return header ++ num
        }
        else if self is UInt32, self <= UInt32(Int32.max){
            let num = Data(self.toErlangInterchangeByteOrder.toByteArray)
            let header = Data([UInt8(98)])
            return header ++ num
        }
        //Must be 64 bit or greater
        return BigInt(self).toBigExt
    }
}


// MARK: BigInt to External

/// An extension for `BigInt` to convert large integer values to their external representation.
///
/// This extension on the `BigInt` type facilitates the conversion of large integer values into either a SMALL_BIG_EXT or a LARGE_BIG_EXT format, depending on the size of the `BigInt`. The chosen format is determined by the byte count of the integer's magnitude plus its sign byte.
///
/// The format of the external representation is
/// _______________________________________________________
/// bytes |      1    |      1/4   |   1  |      byteCount      |
/// _______________________________________________________
/// value |   110/111 |  byteCount | sign | d(0)...d(byteCount-1) |
/// -------------------------------------------------------
/// where the number of bytes for the byteCount is either 1 or 4 and
/// the value of the first byte is either 110 or 111 depending on if
/// a SMALL or LARGE BIG_EXT is being generated. The bytes, d(0)...d(byteCount-1).
///
/// - Properties:
///   - toBigExt: A computed property that generates the external representation of the `BigInt` as `Data`. The external format includes a type indicator (110 for SMALL_BIG_EXT or 111 for LARGE_BIG_EXT), a byte count (either 1 or 4 bytes long), a sign byte, and the magnitude bytes. The magnitude bytes are not in 2's complement form.
///
/// This method is critical for encoding large integers in a format that can be understood by systems expecting Erlang's external term format, ensuring compatibility with Erlang and Elixir systems that use large integers.
///
/// Example Usage:
/// ```swift
/// let bigIntValue = BigInt(someLargeNumber)
/// let bigIntExternalRepresentation = bigIntValue.toBigExt
/// ```
///
/// - Complexity: The complexity of converting a `BigInt` to its external representation depends on the size of the integer being converted.
///
/// - Author: Lee Barney
/// - Version: 0.1


extension BigInt{
    var toBigExt:Data?{
        let asData = Data(self.serialize())//includes the sign byte and the magnitude bytes
        if asData.count <= 4{//SMALL_BIG_EXT
            return Data([UInt8(110),UInt8(asData.count-1)]) ++ asData
        }
        //LARGE_BIG_EXT
        return Data([UInt8(111)]) ++ Data(UInt32(asData.count-1).toByteArray).toErlangInterchangeByteOrder ++  asData
    }
}


// MARK: Double and Float to External
// MARK: Double to External

/// An extension for `Double` to convert floating-point values to their external representation.
///
/// This extension provides a mechanism for converting `Double` values into a standardized external representation
/// suitable for inter-system communication. The representation uses a single byte to indicate the type (`99` for a floating-point number),
/// followed by the floating-point number encoded as a 31-byte string. This string representation follows the C `sprintf` format "%.20e",
/// ensuring compatibility with systems expecting floating-point numbers in scientific notation.
///
/// The format of the external representation is
/// __________________________
/// bytes |   1  |         31            |
/// __________________________
/// value |   99 | Float string      |
/// --------------------------
///
///
/// - Properties:
///   - toFloatExt: A computed property that generates the external representation of the `Double` as `Data`. It combines a header byte with
///     the `Double` value formatted as a string in scientific notation, encoded in UTF-8.
///
/// This method is particularly useful for encoding `Double` values in a format recognizable by Erlang and other systems that use
/// Erlang's external term format for data interchange.
///
/// Example Usage:
/// ```swift
/// let floatValue = 123.456
/// let floatExternalRepresentation = floatValue.toFloatExt
/// ```
///
/// - Complexity: O(n), where n is the length of the string representation of the floating-point number. This takes into account
///   the conversion of the double to a string and the subsequent encoding to UTF-8.
///
/// - Author: Lee Barney
/// - Version: 0.1
extension Double{
    var toFloatExt:Data?{
        let header = Data([UInt8(99)])
        let genericFloatingPoint: any FloatingPoint = self
        var str = String(format: "%.20e", genericFloatingPoint.magnitude  as! CVarArg)
        if genericFloatingPoint.sign == .minus{
            str = "-".appending(str)
        }
        guard let num = str.data(using: .utf8) else{
            return nil
        }
        return header ++ num
    }
}

// MARK: Float to New Float External Representation

/// An extension for `Float` to convert to a new external floating-point representation.
///
/// This extension converts `Float` values to a standardized external representation by first casting them to `Double`,
/// and then applying the `Double` extension method `toNewFloatExt`. The conversion aims to maintain precision while
/// adhering to external data format standards, specifically the IEEE 754 64-bit double-precision format, marked with
/// a specific header byte for identification.
///
/// - Properties:
///   - toNewFloatExt: A computed property that leverages the `toNewFloatExt` property of `Double` to generate the external
///     representation of the `Float` value. This involves casting the `Float` to `Double` to ensure it fits the expected
///     64-bit data format, then prefixing it with the appropriate header byte.
///
/// This method is useful for encoding `Float` values in a binary format that can be easily transmitted or stored, then
/// accurately reconstructed in another system or at a later time.
///
/// The format of the external representation is
/// __________________________
/// bytes |   1  |          8               |
/// __________________________
/// value |   99 | IEE 36bit float   |
/// --------------------------
///
/// Example Usage:
/// ```swift
/// let myFloat: Float = 123.456
/// let externalRepresentation = myFloat.toNewFloatExt
/// ```
///
/// - Complexity: O(1) - The conversion process is straightforward, involving a type cast and the application of the
///   `Double` extension's conversion logic.
///
/// Note: Ensure the `Double` extension is implemented with the `toNewFloatExt` property correctly handling the conversion
/// to the external format.
extension Float{
    var toNewFloatExt:Data?{
        Double(self).toNewFloatExt
    }
}

// MARK: Double to New Float External Representation

/// An extension for `Double` that provides the capability to convert to a new external floating-point representation.
///
/// This extension allows `Double` values to be converted into a specific external representation suitable for storage
/// or communication. The representation consists of a single header byte (`70`), indicating the type of data following,
/// and the 64-bit IEEE 754 binary representation of the `Double` value.
///
/// The format of the external representation is
/// __________________________
/// bytes |   1  |          8               |
/// __________________________
/// value |   99 | IEE 36bit float   |
/// --------------------------
///
/// - Properties:
///   - toNewFloatExt: A computed property that generates the external representation of the `Double` as `Data`.
///     The representation starts with the header byte, followed by the 8 bytes representing the `Double` in IEEE 754 format.
///
/// This method is particularly useful for encoding `Double` values in a binary format that can be easily transmitted
/// or stored, and then accurately reconstructed in another system or at a later time.
///
/// Example Usage:
/// ```swift
/// let myDouble = 123.456
/// let externalRepresentation = myDouble.toNewFloatExt
/// ```
///
/// - Complexity: O(1) - The conversion involves fixed operations and is independent of the `Double` value's magnitude.
///
/// This implementation directly accesses the bit pattern of the `Double`, ensuring that the floating-point value is
/// precisely represented in the external format.
extension Double{
    var toNewFloatExt:Data?{
        let header = Data([UInt8(70)])
        let data = Data(bytes: [self.bitPattern], count: MemoryLayout<UInt64>.size)
        return header ++ data
    }
}

// MARK: String to STRING_EXT External Representation

/// An extension for `String` to convert to the STRING_EXT external representation.
///
/// This extension provides a method to encode `String` values into a binary format suitable for external systems,
/// particularly those expecting Erlang's external term format. The format includes a header byte (`107`), a 4-byte
/// integer representing the length of the string in UTF-8 characters, followed by the string's UTF-8 encoded data.
///
///
/// The format of the external representation is
/// ____________________________
/// bytes |   1   |     4     |    length     |
/// ____________________________
/// value |  107 | length | characters |
/// ----------------------------
///
/// - Properties:
///   - toStringExt: A computed property that generates the STRING_EXT representation of the `String` as `Data`.
///     The conversion includes prepending the data with the appropriate header and length bytes, ensuring the string
///     is accurately represented and can be decoded by receiving systems.
///
/// This method is especially useful for applications that need to serialize string data for communication with Erlang
/// systems or other environments that utilize Erlang's external term format for data interchange.
///
/// Example Usage:
/// ```swift
/// let myString = "Hello, world!"
/// let externalRepresentation = myString.toStringExt
/// ```
///
/// - Complexity: O(n), where n is the length of the string. The primary cost comes from encoding the string to UTF-8.
///
/// Note: This method assumes that the string's UTF-8 encoded length does not exceed `UInt32.max`, aligning with Erlang's
/// limitations on string length in the STRING_EXT format.
extension String{
    var toStringExt:Data?{
        var header = Data([UInt8(119)])
        let asUTF8 = self.utf8
        if asUTF8.count > UInt32.max{
            return nil
        }
        header = Data([UInt8(107)])
        return header ++ Data(UInt32(asUTF8.count).toByteArray).toErlangInterchangeByteOrder ++ Data(asUTF8)
    }
}

// MARK: SwErlAtom to Atom External Representation

/// An extension for `SwErlAtom` to convert atom names to their external representation.
///
/// This extension encodes atom names into a binary format suitable for Erlang's external term format,
/// choosing between SMALL_SwErlAtom_UTF8_EXT and SwErlAtom_UTF8_EXT based on the UTF-8 byte length of the atom name.
/// SMALL_SwErlAtom_UTF8_EXT is used for names within 255 UTF-8 bytes, using a single byte for the length.
/// SwErlAtom_UTF8_EXT is used for longer names, with a four-byte length field.
///
/// The format of the external representation is
/// ___________________________
/// bytes |   1  | 1 or 4 |        length            |
/// ___________________________
/// value |   id | length | SwErlAtomName  |
/// ---------------------------
///
/// - Properties:
///   - toAtomExt: A computed property that generates the external representation of the `SwErlAtom` as `Data`.
///     It includes the appropriate header byte, the length of the atom name in UTF-8 bytes, and the atom name itself.
///
/// This method facilitates the serialization of atom names for communication with Erlang systems,
/// ensuring compatibility with Erlang's expectations for atom representation in messages.
///
/// Example Usage:
/// ```swift
/// let atomName = SwErlAtom(name: "example_atom")
/// let externalRepresentation = atomName.toAtomExt
/// ```
///
/// - Complexity: O(n), where n is the length of the atom name in UTF-8 bytes.
///
/// Note: The implementation assumes that the UTF-8 encoded length of the atom name does not exceed `UInt32.max`,
/// if it does, `nil` is returned.
extension SwErlAtom{
    var toAtomExt:Data?{
        guard let asUTF8 = self.utf8 else {
            return nil
        }
        if asUTF8.count > UInt32.max, asUTF8.count == 0{
            return nil
        }
        if asUTF8.count < 255{//max value of byte
            return Data([UInt8(119)]) ++ Data([UInt8(asUTF8.count)]) ++ asUTF8
        }
        return Data([UInt8(118)]) ++ Data(UInt32(asUTF8.count).toByteArray).toErlangInterchangeByteOrder ++ asUTF8
    }
}

// MARK: Pid to External

/// Converts a process id (PID) and a node name into the external representation of a new process identifier (PID_EXT).
/// This method is used to generate a `NEW_PID_EXT` format for Erlang inter-nodeal communication.
/// The `NEW_PID_EXT` consists of a header and the external representations of the node name, and the PID's id, serial, and creation values.
///
/// The format of the external representation is:
/// ```
///  _______________________________________
/// | bytes |   1  | ?    | 4   | 4      | 4      |
/// |_______|______|______|_____|________|________|
/// | value |  88  | Node | ID  | Serial | Creation|
///  ---------------------------------------
/// ```
/// Where `Node` is a placeholder for the external representation of the node name and `?` is the size of that representation. The node name is either a `SMALL_SwErlAtom_UTF8_EXT` or an `SwErlAtom_UTF8_EXT`.
///
/// - Parameters:
///   - PID: The process identifier (`Pid`) to be converted.
///   - nodeName: The `SwErlAtom` representing the name of the node.
/// - Returns: A `Data` object containing the external representation of the new PID if conversion is successful; otherwise, `nil`.
/// - Throws: This method does not throw any errors but returns `nil` if the `nodeName` cannot be converted to its external representation.
///
///
/// - Complexity: O(1).
///
/// - Author: Lee Barney
/// - Version: 0.1
func toNewPidExt(_ PID:Pid,_ nodeName:SwErlAtom)->Data?{
    let header = Data([UInt8(88)])
    guard let name = nodeName.toAtomExt else{
        return nil
    }
    return header ++ name ++ Data(PID.id.toErlangInterchangeByteOrder.toByteArray) ++ Data(PID.serial.toErlangInterchangeByteOrder.toByteArray) ++ Data(PID.creation.toErlangInterchangeByteOrder.toByteArray)
}


// MARK: Tuple to External

/// Generates the external representation of a tuple as either `SMALL_TUPLE_EXT` or `LARGE_TUPLE_EXT`, depending on the number of elements.
/// This function reflects on a tuple to count its elements (`arity`) and then constructs its external representation accordingly.
///
/// - Parameter tuple: The tuple to be converted into its external representation.
/// - Returns: A `Data` object containing the external representation of the tuple if successful; otherwise, `nil`.
/// - Throws: This function propagates errors thrown by `buildExternalRep` for each element of the tuple. If an error occurs or the tuple cannot be converted, `nil` is returned.
///
/// The format of the external representation is:
/// ```
///  _________________________________
/// | bytes |   1  |1 or 4 |  arity  |
/// |_______|______|_______|__________
/// | value |  id  | arity | Elements|
///  ---------------------------------
/// ```
/// Where `arity` is the number of elements in the tuple and `id` is `104` for tuples with an arity less than 256, and `105` otherwise.
///
/// - Complexity: O(n), where n is the number of elements in the tuple. This considers the time to iterate over the tuple elements and construct their external representations to be O(1).
///
/// - Author: Lee Barney
/// - Version: 0.1
func toTupleExt<T>(_ tuple:T)->Data?{
    let children = Mirror(reflecting: tuple).children
    let arity = children.count
    let childIter = children.makeIterator()
    var result:Data? =  Data([UInt8(104)])
    if arity > 255 {
        result = Data([UInt8(105)])
        result = result? ++ Data(UInt32(arity).toErlangInterchangeByteOrder.toByteArray)
    }
    else{
        result = result? ++ Data([UInt8(arity)])
    }
    result = childIter.reduce(result){(accum,child) in
        do{
            //each child is a 2-tuple. The first element
            //of the 2-tuple is the value's index as a string.
            //the second element of the tuple is the element at
            //that index.
            let (_,element) = child
            //if the accumulator is nil, make no further calls
            //to buildExternalRep
            return try accum? ++ buildExternalRep(element)
        }
        catch{
            return nil
        }
    }
    return result
}

// MARK: Array to External
/// Provides an extension to `Array` to convert an array into its external representation for Erlang inter-nodal communication.
/// This external representation is denoted as `LIST_EXT` and includes a header, the length of the list, the elements, and a tail indicating the end of the list.
///
/// The format of the external representation is:
/// ```
///  ____________________________________________
/// | bytes |    1  |    4    |  length  |  1    |
/// |_______|_______|_________|__________|_______|
/// | value |  108  | length  | elements | tail  |
///  --------------------------------------------
/// ```
/// Where `tail` is always `NIL_EXT`.
///
/// - Returns: A `Data` object containing the external representation of the array if the conversion is successful; otherwise, `nil`.
/// - Throws: This method propagates errors thrown by `buildExternalRep` for each element of the array. If an error occurs or the array cannot be converted, `nil` is returned.
///
/// - Complexity: O(n), where n is the number of elements in the array assuming the conversion of each element of the array has a complexity of O(1).
///
/// - Note: This method ensures that the array's count does not exceed `UInt32.max` to fit the Erlang external format specification.
///
/// - Author: Lee Barney
/// - Version: 0.1
extension Array{
    var toListExt:Data?{
        guard self.count <= UInt32.max else{
            return nil
        }
        let representation = Data([UInt8(108)]) ++ Data(UInt32(self.count).toByteArray).toErlangInterchangeByteOrder
        var elements = Data()
        do{
            elements = try self.reduce(elements){(accum,element) in
                let externalRepresentaion = try buildExternalRep(element)
                return accum ++ externalRepresentaion
            }
        }
        catch{
            return nil
        }
        return representation ++ elements ++ nilExt
    }
}

let nilExt = Data([UInt8(106)])

// MARK: Dictionary to External

/// Generates the external representation of a `Dictionary` as a `MAP_EXT`.
/// This method reflects on a dictionary to construct its external representation, including the number of key-value pairs (arity) and the serialized pairs themselves.
///
/// - Parameter dict: The dictionary to be converted into its external representation.
/// - Returns: A `Data` object containing the external representation of the dictionary if successful; otherwise, `nil`.
/// - Throws: This function propagates errors thrown by `buildExternalRep` for each key and value in the dictionary. If an error occurs or the dictionary cannot be converted, `nil` is returned.
///
/// The format of the external representation is:
/// ```
///  ____________________________
/// | bytes |   1  |   4   |  N  |
/// |_______|______|_______|_____|
/// | value |  116 | arity |pairs|
///  ----------------------------
/// ```
/// Where `arity` is the number of key-value pairs and `N` is the size of all the keys and all the values combined. The keys and values can be any valid Erlang external type.
///
/// - Complexity: O(n), where n is the number of key-value pairs in the dictionary. This accounts for the time to iterate over the dictionary. It assumes the complexity of coverting each element is O(1)
///
/// - Note: This method ensures that the dictionary's size does not exceed `UInt32.max` to fit the Erlang external format specification.
///
/// - Author: Lee Barney
/// - Version: 0.1

func toMapExt<T>(_ dict:T)->Data?{
    let children = Mirror(reflecting: dict).children
    guard children.count <= UInt32.max else{
        return nil
    }
    var representation = Data([UInt8(116)]) ++ Data(UInt32(children.count).toByteArray).toErlangInterchangeByteOrder
    
    //the first element of the child tuple is an optional description
    //the second element of the child tuple is a 2-tuple containing the key-value pair in that order
    for (_,(data)) in children{
        guard let (key,value) = data as? (Any,Any) else{
            return nil
        }
        do{
            representation = representation ++ try buildExternalRep(key) ++ try buildExternalRep(value)
        }
        catch{
            return nil
        }
    }
    
    return representation
}



// MARK: Helper Functions


/// Converts a Swift value to its corresponding Erlang external representation.
/// This function handles conversion for various Swift types to their Erlang external types, including atoms, integers, floats, strings, tuples, arrays, sets, and dictionaries.
///
/// - Parameter element: The Swift value to be converted.
/// - Returns: A `Data` object representing the Erlang external format of the input value.
/// - Throws: `SwErlError.invalidExternalType` if the input value does not correspond to any known Erlang external type or cannot be converted.
///
/// This method utilizes multiple helper functions (`toAtomExt`, `toIntegerExt`, `toBoolExt`, `toNewFloatExt`, `toStringExt`, `toTupleExt`, `toMapExt`, `toListExt`) to perform the conversion for each specific type. It supports fixed-width integers, booleans, floating-point numbers, strings, tuples, dictionaries (as maps), arrays (as lists), sets (converted to lists), and arbitrary precision integers (`BigInt`).
///
/// - Complexity: The complexity depends on the specific type and size of the input value. It ranges from O(1) for simple types to O(n) for compound types like arrays, sets, and dictionaries where n is the number of elements or key-value pairs.
///
/// - Note: For compound types like tuples, dictionaries, and arrays, this function recursively converts each element or key-value pair to its corresponding Erlang external representation.
///
/// - Author: Lee Barney
/// - Version: 0.1
fileprivate func buildExternalRep(_ element: Any) throws -> Data {
    var ext = Data()
    if let element = element as? SwErlAtom{
        guard let SwErlAtomExt = element.toAtomExt else{
            throw SwErlError.invalidExternalType
        }
        ext = SwErlAtomExt
    }
    if let element = element as? any FixedWidthInteger{
        guard let intExt = element.toIntegerExt else{
            throw SwErlError.invalidExternalType
        }
        ext = intExt
    }
    else if let element = element as? Bool{
        ext = element.toBoolExt
    }
    else if let element = element as? Float{
        guard let intExt = element.toNewFloatExt else{
            throw SwErlError.invalidExternalType
        }
        ext = intExt
    }
    else if let element = element as? Double{
        guard let intExt = element.toNewFloatExt else{
            throw SwErlError.invalidExternalType
        }
        ext = intExt
    }
    else if let element = element as? String{
        guard let strExt = element.toStringExt else{
            throw SwErlError.invalidExternalType
        }
        ext = strExt
    }
    else if isTuple(element){
        guard let tupleExt = toTupleExt(element) else{
            throw SwErlError.invalidExternalType
        }
        ext = tupleExt
    }
    else if element is Dictionary<AnyHashable,Any>{
        guard let dictExt = toMapExt(element) else{
            throw SwErlError.invalidExternalType
        }
        ext = dictExt
    }
    else if element is Array<Any>{
        guard let listExt = (element as! Array<Any>).toListExt else{
            throw SwErlError.invalidExternalType
        }
        
        ext = listExt
    }
    else if element is Set<AnyHashable>{
        let asArray = Array(element as! Array<Any>)
        guard let listExt = asArray.toListExt else{
            throw SwErlError.invalidExternalType
        }
        
        ext = listExt
    }
    else if let element = element as? BigInt{
        guard let intExt = element.toBigExt else{
            throw SwErlError.invalidExternalType
        }
        ext = intExt
    }
    
    else{
        
        throw SwErlError.invalidExternalType
    }
    return ext
}


/// Determines whether the given value is a tuple.
/// This function uses reflection to inspect the value and determine if its display style corresponds to a tuple.
///
/// - Parameter value: The value to be checked.
/// - Returns: `true` if the value is a tuple; otherwise, `false`.
///
/// This method relies on the `Mirror` struct from Swift's standard library, which provides a way to inspect the type and properties of any value. By checking the `displayStyle` property of the `Mirror`, it can distinguish tuples from other collection or singular value types.
///
/// - Complexity: O(1). The function performs a constant-time operation by simply inspecting the type of the input value.
///
/// - Author: Lee Barney
/// - Version: 0.1
func isTuple(_ value:Any)->Bool{
    let mirror = Mirror(reflecting: value)
    return mirror.displayStyle == .tuple
}


