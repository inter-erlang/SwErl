//
//  ErlangTypes.swift
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
//  Created by Lee Barney on 3/14/23.
//

///All documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation
import BigInt


/// Defines a typealias for an Erlang process identifier (PID), crucial for identifying and interacting with processes in Erlang systems.
/// This typealias enables Swift applications to seamlessly work with Erlang PIDs by encapsulating the necessary components of a PID: the node name, an identifier, a serial number, and a creation number. PIDs are fundamental to Erlang's process-based concurrency model, allowing for precise identification and communication with processes across distributed systems.
///
/// - `nodeName`: A `String` representing the name of the Erlang node where the process resides. Node names are essential in distributed Erlang environments for locating processes across different machines.
/// - `id`: A `UInt32` serving as a unique identifier for the process within its node. This ID distinguishes the process from others on the same node.
/// - `serial`: A `UInt32` used to differentiate between instances of processes that may have had the same `id` over time. This helps in managing PID recycling and ensuring uniqueness.
/// - `creation`: A `UInt32` indicating the "creation" of the node that the process belongs to. This is used to distinguish between processes on different incarnations of the same node, further ensuring the global uniqueness of the PID.
///
/// This structured approach to representing Erlang PIDs in Swift facilitates the development of systems and applications that require interoperability between Swift and Erlang, especially in the context of distributed computing and messaging.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
typealias ErlPid = (nodeName: String, id: UInt32, serial: UInt32, creation: UInt32)


/// Defines a typealias for an Erlang port, which represents a communication endpoint within an Erlang system.
/// This typealias simplifies the representation of Erlang ports in Swift, encapsulating the essential attributes needed to identify and work with ports. Ports in Erlang are used for communication with external programs and the outside world, making them fundamental to Erlang's concurrency and messaging model.
///
/// - `nodeName`: A `String` indicating the name of the Erlang node to which the port belongs. This helps in identifying the specific instance of an Erlang system, especially in distributed environments.
/// - `id`: A `UInt64` representing the unique identifier of the port on the node. This ID is used to distinguish between different ports within the same Erlang node.
/// - `creation`: A `UInt32` providing an additional layer of uniqueness, which can be used to differentiate ports created at different times or in different incarnations of the node.
///
/// This typealias is particularly useful for Swift applications that need to interface with Erlang systems, allowing for clear and type-safe handling of port identifiers in inter-language communication scenarios.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
typealias ErlPort = (nodeName: String, id: UInt64, creation: UInt32)


/// Defines a typealias for an Erlang reference, which represents a unique identifier for objects or processes within an Erlang system.
/// This typealias is crucial for working with Erlang references in Swift, as it allows for the representation of Erlang's complex reference structures. These structures are used to uniquely identify distributed objects or processes and consist of the node name on which the reference was created, the length of the reference, an array of integers making up the reference itself, and a creation identifier.
///
/// - `nodeName`: A `String` representing the name of the Erlang node where the reference was created. This is essential for ensuring that references are unique across distributed systems.
/// - `len`: A `UInt32` indicating the length of the reference. Erlang references can vary in length, and this field specifies how many integers (`n`) are used to form the reference.
/// - `n`: An array of `UInt32` values that make up the reference. The size of this array is indicated by `len`, and each element contributes to the uniqueness of the reference.
/// - `creation`: A `UInt32` used to differentiate references created at different times or on different incarnations of the same node. This further ensures the uniqueness of the reference across reboots and restarts.
///
/// This typealias facilitates the handling of Erlang references in Swift applications, particularly those that need to interact with Erlang systems or require interoperability between Swift and Erlang for distributed computing.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
typealias ErlRef = (nodeName: String, len: UInt32, n: [UInt32], creation: UInt32)


/// Defines a typealias for an Erlang trace token, which encapsulates information used for tracing message passing and function calls within Erlang systems.
/// This typealias is essential for debugging and monitoring Erlang applications, providing a way to track the flow of execution across processes and functions by capturing serial numbers, previous trace information, originating process identifiers, trace labels, and specific flags used for tracing.
///
/// - `serial`: A `UInt32` representing the serial number of the trace token, used to order trace events chronologically.
/// - `prev`: A `UInt32` indicating the serial number of the previous trace event, enabling the reconstruction of the trace's path through the system.
/// - `from`: An `ErlPid` identifying the process from which the trace event originated.
/// - `label`: A `UInt32` used for additional categorization or identification of the trace event, which can be used to filter or group trace events during analysis.
/// - `flags`: A `UInt32` containing flags that provide additional information about the trace event, such as whether it is a send or receive event, call event, or other types of traceable events.
///
/// This structured approach to tracing facilitates comprehensive insights into the behavior of concurrent and distributed Erlang applications, aiding in the detection and resolution of issues.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
typealias ErlTrace = (serial: UInt32, prev: UInt32, from: ErlPid, label: UInt32, flags: UInt32)


/// Defines a typealias for an Erlang message, encapsulating the essential elements required for message passing in Erlang systems.
/// This typealias provides a structured way to represent messages in Erlang, including the message type, sender and receiver process identifiers (PIDs), the name of the receiving process, a "cookie" for authentication or session management, and a trace token for debugging or tracing message flow.
///
/// - `type`: A `UInt32` representing the type of the message. This could indicate whether the message is a call, a reply, or another form of communication.
/// - `from`: An `ErlPid` identifying the sending process.
/// - `to`: An `ErlPid` identifying the intended receiving process.
/// - `toName`: A `String` specifying the registered name of the receiving process, providing an alternative way to address messages in systems where processes are named.
/// - `cookie`: A `String` used for authentication or authorization, ensuring that messages are accepted only by intended and authorized recipients.
/// - `token`: An `ErlTrace` object, used for tracing the flow of messages through the system, aiding in debugging and monitoring.
///
/// This typealias is designed to facilitate the construction, sending, and processing of messages in applications that interact with Erlang, or in mixed-language systems that leverage Erlang's powerful concurrency and messaging features.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
typealias ErlMsg = (type: UInt32, from: ErlPid, to: ErlPid, toName: String, cookie: String, token: ErlTrace)


/// Defines a typealias for an Erlang function closure, representing a detailed structure for capturing an Erlang function's closure environment.
/// This typealias is crucial for working with Erlang closures in Swift, especially when dealing with complex inter-language calls that require detailed knowledge of a function's environment. It includes the function's arity, module, unique MD5 signature, indexes, the number of free variables, and the process identifier (PID) associated with the closure, along with the length and actual values of the free variables.
///
/// - `arity`: A `UInt32` indicating the number of arguments the function accepts.
/// - `module`: A `String` representing the module name where the function is defined.
/// - `MD5`: A `String` providing the MD5 hash of the function, used for ensuring the integrity and uniqueness of the function definition.
/// - `index`: A `UInt32` used to specify the index of the function within the module, relevant for versioning and function identification.
/// - `oldIndex`: A `UInt32` representing an older index of the function, for backward compatibility.
/// - `unique`: A `UInt32` providing a unique identifier for the function closure, typically used for distinguishing between different versions or instances of closures.
/// - `freeVariableCount`: A `UInt32` indicating the number of free variables included in the closure.
/// - `pid`: An `ErlPid` identifying the Erlang process associated with the closure, crucial for understanding the execution context of the closure.
/// - `freeVariablesLength`: A `UInt32` specifying the total length of the free variables' data.
/// - `freeVariables`: A `String` containing the actual values of the free variables, encoded in a manner that is meaningful within the context of the function's execution environment.
///
/// This detailed representation is essential for accurately reconstructing or invoking Erlang function closures from Swift, ensuring that all aspects of the closure's environment are correctly accounted for.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
typealias ErlFunClosure = (arity: UInt32, module: String, MD5: String, index: UInt32, oldIndex: UInt32, unique: UInt32, freeVariableCount: UInt32, pid: ErlPid, freeVariablesLength: UInt32, freeVariables: String)


/// Defines a typealias for an Erlang function export, encapsulating the details necessary to identify and interact with an exported Erlang function.
/// This typealias provides a convenient way to represent the signature of an Erlang function that has been made available for external calls, including its arity, module name, function name, and the amount of memory allocated for the function. It is particularly useful in scenarios where Swift code needs to call Erlang functions, ensuring that all necessary details are readily available.
///
/// - `arity`: A `UInt32` indicating the number of arguments that the function expects.
/// - `module`: A `String` representing the name of the Erlang module in which the function is defined.
/// - `function`: A `String` indicating the name of the function.
/// - `allocated`: A `UInt32` specifying the amount of memory allocated for the function, which can be relevant for managing resources or understanding the function's footprint.
///
/// This typealias streamlines the integration of Erlang functions into Swift applications, facilitating the invocation of Erlang code from Swift by providing a clear and concise definition of function exports.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
typealias ErlFunExport = (arity: UInt32, module: String, function: String, allocated: UInt32)


/// Represents an Erlang term in Swift, encapsulating various possible types and values that can be encountered in Erlang inter-process communication.
/// This structure is designed to mirror the flexibility of Erlang terms, including simple types like integers and floats, as well as complex types such as atoms, PIDs (Process Identifiers), ports, and references.
///
/// - Properties:
///   - type: A `Byte` indicating the type of the Erlang term.
///   - arity: A `UInt32` representing the arity of the term, applicable for tuples and lists.
///   - size: A `UInt32` indicating the size of the term, which can be used for binaries and strings.
///   - integerValue: An optional `UInt32` for storing integer values. `nil` if the term is not an integer.
///   - doubleValue: An optional `Double` for storing floating-point values. `nil` if the term is not a float.
///   - atomName: An optional `String` representing the name of an atom. `nil` if the term is not an atom.
///   - pid: An optional `ErlPid` for Erlang process identifiers. `nil` if the term does not represent a PID.
///   - port: An optional `ErlPort` for Erlang ports. `nil` if the term is not a port.
///   - reference: An optional `ErlRef` for Erlang references. `nil` if the term is not a reference.
///
/// This structure allows for a versatile representation of Erlang terms, facilitating the translation between Erlang and Swift data structures for inter-process communication or interfacing with Erlang systems.
///
/// - Complexity: O(1) for accessing any of the properties.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
struct ei_term {
    let type: Byte
    let arity: UInt32
    let size: UInt32
    var integerValue: UInt32?
    var doubleValue: Double?
    var atomName: String?
    var pid: ErlPid?
    var port: ErlPort?
    var reference: ErlRef?
}


/// Defines a typealias for an Erlang connection, representing the connection details to an Erlang node.
/// This typealias simplifies the representation of an Erlang node's connection information, encapsulating the IP address and the node name in a single, easily understandable structure. It's particularly useful for managing connections in systems that interact with Erlang nodes, providing a clear and concise way to store and transmit this essential information.
///
/// - `ipAddress`: A `String` representing the IP address of the Erlang node.
/// - `nodeName`: A `String` representing the name of the Erlang node.
///
/// This typealias is designed to streamline the handling of Erlang connections in Swift code, making it easier to work with Erlang systems or applications that require interoperation between Swift and Erlang.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
typealias ErlConnection = (ipAddress: String, nodeName: String)




