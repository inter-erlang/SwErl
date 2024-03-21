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

import Foundation

/// Enumerates the types of network connections supported, including both protocol and node visibility types.
/// This includes distinctions between TCP and UDP protocols over IPv4 and IPv6, as well as node visibility types.
///
/// - Author: Lee Barney
/// - Version: 0.9
enum ConnectionType: Byte {
    /// TCP connection over IPv4. Byte value: `0`.
    case tcpIPv4 = 0
    /// TCP connection over IPv6. Byte value: `1`.
    case tcpIPv6 = 1
    /// UDP connection over IPv4. Byte value: `2`.
    case udpIPv4 = 2
    /// UDP connection over IPv6. Byte value: `3`.
    case udpIPv6 = 3
    /// A normal node type, which is typically visible to other nodes. Byte value: `77`.
    case normalNode = 77
    /// A hidden node type, which is not advertised but can connect to other nodes. Byte value: `72`.
    case hiddenNode = 72
}


/// Defines the commands used in the Erlang Port Mapper Daemon (EPMD) protocol, each associated with a specific byte value.
/// These commands facilitate various operations such as process registration, querying, and management within the EPMD service.
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
    case port2ResponseSuccess = 0
    /// Error response for `Port2_Response`, represents non-zero failure code. Byte value: `255`.
    case port2ResponseError = 255
    /// Request for a list of all names registered with EPMD. Byte value: `110`.
    case namesReq = 110
    /// Request for a dump of EPMD's internal state. Byte value: `100`.
    case dumpReq = 100
    /// Request to kill the EPMD service. Byte value: `107`.
    case killReq = 107
    /// Placeholder for stop request, currently not used. Byte value: `200`.
    case stopReq = 200
}


/// Represents the different portion indicators of the Erlang protocol's handshake between nodes encoded as bytes.
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

