//
//  NodeCommunicationValues.swift
//
//Copyright (c) 2024 Lee Barney
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
//  Created by Lee Barney on 3/21/24.
//


//All documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation

/// Defines the types of distribution headers for network messages.
///
/// The `DistHeaderType` enumeration categorizes network message headers into different types based on their characteristics:
/// normal, fragmented, and compressed. Each type is associated with a specific `
/// Byte` value that represents its header type
/// in the inter-node protocol.
///
/// - Cases:
///   - normal: Represents a normal message header, indicated by the `Byte` value `68`.
///   - fragmented: Represents a fragmented message header, allowing for the transmission of messages that exceed the size limit of a single packet, indicated by `69`.
///   - compressed: Represents a compressed message header, facilitating the efficient transmission of data by reducing its size, indicated by `80`.
///
/// This enumeration is crucial for handling different types of inter-node messages, ensuring that the messaging system can
/// accommodate messages of varying sizes and optimize for network efficiency through compression.
///
/// - Complexity: O(1) for accessing any of the cases.
///
/// - Author: Lee Barney
/// - Version: 0.1
enum DistHeaderType: Byte {
    case normal = 68
    case fragmented = 69
    case compressed = 80
}
/// Delineates the visibility classifications for Erlang nodes within an Erlang network.
///
/// `NodeType` enumeration articulates two primary categories of node visibility within distributed systems, denoted by specific `Byte` values for clear identification and protocol compliance:
/// - Cases:
///   - normalNode: Represents a standard, openly visible Erlang node that can be discovered and interacted with by other Erlang and SwErl nodes in the network. Assigned the `Byte` value `77`, it signifies the default mode of operation for most nodes, promoting connectivity and interaction. All SwErl nodes are normal nodes.
///   - hiddenNode: Designates a node that, while capable of initiating connections and participating in the network, remains unadvertised and invisible to standard discovery mechanisms. With a `Byte` value of `72`, this type supports scenarios where non-safe, other language code is executed by a specific Erlang node.
///
/// This classification enables nuanced network topology configurations, catering to a variety of operational requirements and security considerations by clearly differentiating node types based on their intended visibility and interaction level.
///
/// - Complexity: O(1) for accessing any of the cases.
///
/// - Author: Lee Barney
/// - Version: 0.9

enum NodeType: Byte {
    /// A normal node type, which is typically visible to other nodes. Byte value: `77`.
    case normalNode = 77
    /// A hidden node type, which is not advertised but can connect to other nodes. Byte value: `72`.
    case hiddenNode = 72
}

/// Extends `Byte` with a computed property to convert its value to a `NodeType` enumeration case.
///
/// This extension equips the `Byte` type with a computed property, providing a seamless method to interpret byte values as `NodeType` cases. It leverages the enum's raw value initializer, enabling direct conversion without the need for explicit checks or mappings.
///
/// - Returns: A `NodeType` instance corresponding to the `Byte` value, or `nil` if the value does not match any `NodeType` case.
///
/// - Complexity: O(1), as it involves a straightforward enum initialization with a raw value.
///
/// - Author: Lee Barney
/// - Version: 0.9
extension Byte {
    var toNodeType: NodeType? {
        return NodeType(rawValue: self)
    }
}


/// Defines the types of network connections supported, focusing by the Erlang protocol.
///
/// The `ConnectionProtocol` enumeration separates network connections into categories based on protocol (TCP or UDP) and network layer (IPv4 or IPv6). Each type is associated with a specific `Byte` value that represents its connection type:
/// - TCP over IPv4 and IPv6 is available for reliable, connection-oriented communication.
/// - UDP over IPv4 and IPv6 is available for connectionless, faster communication.
///
/// This classification is essential for configuring network connections appropriately between Erlang nodes, ensuring compatibility and optimizing communication strategies based on protocol strengths.
///
/// - Complexity: O(1) for accessing any of the cases.
///
/// - Author: Lee Barney
/// - Version: 0.9

enum ConnectionProtocol: Byte {
    /// TCP connection over IPv4. Byte value: `0`.
    case tcpIPv4 = 0
    /// TCP connection over IPv6. Byte value: `1`.
    case tcpIPv6 = 1
    /// UDP connection over IPv4. Byte value: `2`.
    case udpIPv4 = 2
    /// UDP connection over IPv6. Byte value: `3`.
    case udpIPv6 = 3
}


/// Extends `Byte` to include a computed property that converts byte values to `ConnectionProtocol` enumeration cases.
///
/// This extension enhances `Byte` by adding a computed property that facilitates the direct interpretation of its value as a `ConnectionProtocol`, offering a type-safe way to handle connection type information encoded as raw bytes.
///
/// The property checks if the byte value falls within the range of defined `ConnectionProtocol` raw values, leveraging the `ConnectionProtocol` enumeration's `rawValue` initializer for conversion. This ensures that only valid `ConnectionProtocol` values are returned, enhancing robustness by gracefully handling out-of-range values.
///
/// - Complexity: O(1), due to a simple boundary check and enumeration raw value mapping.
///
/// - Author: Lee Barney
/// - Version: 0.9
extension Byte {
    var toConnectionProtocol: ConnectionProtocol? {
        guard self <= ConnectionProtocol.udpIPv6.rawValue else {
            return nil
        }
        return ConnectionProtocol(rawValue: self)
    }
}



/// Defines the commands used within the Erlang Port Mapper Daemon (EPMD) protocol.
///
/// The `EPMDCommand` enumeration classifies commands integral to the operation of the EPMD service, distinguishing each by a unique `Byte` value. These commands play varied roles in process lifecycle management, from registration to information requests:
/// - Alive2_Request, Alive2_Response, and Alive2_X_Response manage node registration and acknowledgment.
/// - PortPlease2_Request and Port2_Response relate to querying node information.
/// - Port2_ResponseSuccess and Port2_ResponseError handle responses to port inquiries, indicating success or errors.
/// - Names_Req and Dump_Req are used for service diagnostics, requesting registered names and service dumps.
/// - Kill_Req allows for the termination of the EPMD service for maintenance or shutdown procedures.
///
/// Employing these commands, the EPMD protocol supports robust service discovery and management within Erlang distributed systems.
///
/// - Complexity: O(1) for accessing any of the cases.
///
/// - Author: Lee Barney
/// - Version: 0.9

enum EPMDCommand: Byte {
    /// Request to register a node with EPMD. Byte value: `120`.
    case alive2Request = 120
    /// Response to `Alive2_Request` where both nodes support version 6. Byte value: `118`.
    case alive2XResponse = 118
    /// Response to `Alive2_Request` where at least one node does not support version 6. Byte value: `121`.
    case alive2Response = 121
    /// Request for the port of a specific node. Byte value: `122`.
    case portPlease2Request = 122
    /// Response to `PortPlease2_Request` with node information. Byte value: `119`.
    case port2Response = 119
    /// Indicates a successful `Port2_Response`. Byte value: `0`.
    case success = 0
    /// Error response for `Port2_Response`, represents non-zero failure code. Byte value: `255`.
    case error = 255
    /// Request for a list of all names registered with EPMD. Byte value: `110`.
    case namesReq = 110
    /// Request for a dump of EPMD's internal state. Byte value: `100`.
    case dumpReq = 100
    /// Request to kill the EPMD service. Byte value: `107`.
    case killReq = 107
    /// Placeholder for stop request, currently not used. Byte value: `200`.
    case stopReq = 200
}

/// Categorizes the stages of the Erlang protocol's handshake process between nodes.
///
/// The enumeration details each step of the handshake involved in establishing connections between Erlang nodes, encoded with specific `Byte` values for precise identification. These indicators facilitate the coordination and verification phases essential for efficient node communication:
/// - Identifiers such as `Old_Send_Name`, `Send_Name`, and `Status` track the initial stages of connection and identity verification.
/// - `Compliment`, `Challenge_Reply`, and `Challenge_Ack` manage the subsequent authentication and confirmation steps, ensuring that only authorized nodes establish communication.
///
/// This systematic approach to node handshake processes underscores the Erlang ecosystem's emphasis on robustness and reliability in distributed networking.
///
/// - Complexity: O(1) for accessing any of the stages.
///
/// - Author: Lee Barney
/// - Version: 0.9

enum Handshake: Byte {
    /// Old protocol for sending name. Byte value: `110`.
    case oldSendName = 110
    /// Current protocol for sending name. Byte value: `78`.
    case sendName = 78
    /// Status handshake signal. Byte value: `115`.
    case status = 115
    /// Compliment handshake signal. Byte value: `99`.
    case compliment = 99
    /// Reply to a challenge in the handshake process. Byte value: `114`.
    case challengeReply = 114
    /// Acknowledgment of the challenge reply. Byte value: `97`.
    case challengeAck = 97
}



