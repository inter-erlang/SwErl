//
//  GlobalConstants.swift
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
//  Created by Lee Barney on 3/13/23.
//

///Documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation

/// Defines the maximum limitations for various Erlang external term formats within Swift implementations.
///
/// This structure specifies constants representing the upper limits on the sizes of various elements,
/// such as atoms, when working with Erlang's external term format. These constants ensure that Swift
/// implementations adhere to the constraints imposed by Erlang and the external term format specifications,
/// facilitating compatibility and preventing issues related to exceeding these limits.
///
/// - `AtomLen`: The maximum length of an atom name in bytes. Set to 256 to align with Erlang's limitations
/// on atom name lengths, ensuring that atom names are correctly handled within the constraints of Erlang systems.
///
/// Usage of these limitations within your Swift code helps to maintain compatibility with Erlang systems,
/// especially when encoding or decoding external terms, by preventing the creation of elements that exceed
/// Erlang's inherent size constraints.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
struct Max {
    static let AtomLen = 256
}


//// Defines the distribution capability flags used in Erlang node communication.
///
/// This structure contains static constants that represent various capabilities in the Erlang distribution protocol.
/// These flags are used during the initial handshake between Erlang nodes to agree on the supported features.
///
/// Capabilities include support for atom cache, extended references and pids/ports, distribution monitoring,
/// fun tags, and more. The presence of a flag indicates support for the corresponding feature by the node.
///
/// - `PUBLISHED`: Indicates the node is published under a name.
/// - `ATOM_CACHE`: Support for atom cache mechanism to optimize atom transmission.
/// - `EXTENDED_REFERENCES`: Support for extended reference formats.
/// - `DIST_MONITOR`: Support for distributed monitoring.
/// - `FUN_TAGS`: Support for fun tags.
/// - `NEW_FUN_TAGS`: Support for new fun tags with additional information.
/// - `EXTENDED_PIDS_PORTS`: Support for extended process identifiers and port identifiers.
/// - `EXPORT_PTR_TAG`: Support for export pointer tags.
/// - `BIT_BINARIES`: Support for bit-level binaries.
/// - `NEW_FLOATS`: Support for new float representation.
/// - `SMALL_ATOM_TAGS`: Support for small atom tags.
/// - `UTF8_ATOMS`: Support for UTF-8 encoded atom names.
/// - `MAP_TAG`: Support for map tag.
/// - `BIG_CREATION`: Support for big creation tags.
/// - `HANDSHAKE_23`: Indicates compatibility with handshake version 23.
/// - `UNLINK_ID`: Support for unlink identifier.
/// - `MANDATORY_25_DIGEST`: Indicates mandatory support for 25-digest.
/// - `RESERVED`: Reserved flags for future use.
/// - `NAME_ME`: Support for name registration.
/// - `V4_NC`: Support for version 4 node connections.
///
/// These flags are essential for ensuring compatibility and enabling advanced features in distributed Erlang applications.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
struct DFLAG {
    static let PUBLISHED:UInt64 =                   1
    static let ATOM_CACHE:UInt64 =                  2
    static let EXTENDED_REFERENCES:UInt64 =         4
    static let DIST_MONITOR:UInt64 =                8
    static let FUN_TAGS:UInt64 =                 0x10
    static let NEW_FUN_TAGS:UInt64 =             0x80
    static let EXTENDED_PIDS_PORTS:UInt64 =     0x100
    static let EXPORT_PTR_TAG:UInt64 =          0x200
    static let BIT_BINARIES:UInt64 =            0x400
    static let NEW_FLOATS:UInt64 =              0x800
    static let SMALL_ATOM_TAGS:UInt64 =        0x4000
    static let UTF8_ATOMS:UInt64 =            0x10000
    static let MAP_TAG:UInt64 =               0x20000
    static let BIG_CREATION:UInt64 =          0x40000
    static let HANDSHAKE_23:UInt64 =        0x1000000
    static let UNLINK_ID:UInt64 =           0x2000000
    static let MANDATORY_25_DIGEST:UInt64 = 0x4000000
    static let RESERVED:UInt64 =           0xf8000000
    static let NAME_ME:UInt64 =             0x2 << 32
    static let V4_NC:UInt64 =               0x4 << 32
}


//// Specifies the mandatory distribution flags for OTP 25.
///
/// This constant aggregates all the distribution capability flags that are considered mandatory for nodes
/// operating under OTP 25. The aggregation ensures that Erlang nodes are compatible with the features and
/// enhancements introduced in OTP 25, including support for new data types, improved encoding formats, and
/// protocol enhancements.
///
/// The mandatory flags include:
/// - `EXTENDED_REFERENCES`: Support for extended reference formats.
/// - `FUN_TAGS`: Support for fun tags.
/// - `EXTENDED_PIDS_PORTS`: Support for extended process identifiers and port identifiers.
/// - `UTF8_ATOMS`: Support for UTF-8 encoded atom names.
/// - `NEW_FUN_TAGS`: Support for new fun tags with additional information.
/// - `BIG_CREATION`: Support for big creation tags.
/// - `NEW_FLOATS`: Support for new float representation.
/// - `MAP_TAG`: Support for map tag.
/// - `EXPORT_PTR_TAG`: Support for export pointer tags.
/// - `BIT_BINARIES`: Support for bit-level binaries.
/// - `HANDSHAKE_23`: Indicates compatibility with handshake version 23.
///
/// Ensuring these flags are supported and enabled on Erlang nodes guarantees compatibility with the features
/// and functionalities expected in OTP 25, facilitating seamless inter-node communication and feature utilization.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
let DIST_MANDATORY_25 = DFLAG.EXTENDED_REFERENCES
    | DFLAG.FUN_TAGS
    | DFLAG.EXTENDED_PIDS_PORTS
    | DFLAG.UTF8_ATOMS
    | DFLAG.NEW_FUN_TAGS
    | DFLAG.BIG_CREATION
    | DFLAG.NEW_FLOATS
    | DFLAG.MAP_TAG
    | DFLAG.EXPORT_PTR_TAG
    | DFLAG.BIT_BINARIES
    | DFLAG.HANDSHAKE_23


/// Specifies the mandatory distribution flags for OTP 26.
///
/// This constant defines the set of distribution capability flags that are mandatory for Erlang nodes
/// operating with OTP 26. It highlights the evolution of the Erlang/OTP distribution protocol by incorporating
/// new requirements to enhance node connectivity and communication capabilities in the latest version of OTP.
///
/// The mandatory flags for OTP 26 include:
/// - `V4_NC`: Support for version 4 node connections, indicating an advancement in the communication protocol
/// between Erlang nodes, potentially offering improvements in efficiency, security, or feature support.
/// - `UNLINK_ID`: Support for unlink identifiers, enhancing the process monitoring and linking mechanisms
/// by providing more robust and flexible control over inter-process communication and cleanup.
///
/// Adhering to these mandatory flags ensures that Erlang nodes are compliant with the latest protocol requirements
/// introduced in OTP 26, facilitating compatibility and leveraging the latest enhancements in the Erlang ecosystem.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
let DIST_MANDATORY_26 = DFLAG.V4_NC
    | DFLAG.UNLINK_ID


/// Specifies the combined mandatory distribution flags for the current Erlang/OTP release, incorporating requirements from both OTP 25 and OTP 26.
///
/// This constant aggregates all the distribution capability flags that are considered mandatory across the two major versions of Erlang/OTP, 25 and 26.
/// It ensures that Erlang nodes are compatible with a broad range of features and enhancements introduced across these versions, facilitating seamless
/// node communication and feature utilization in mixed-version environments.
///
/// By combining the mandatory flags from OTP 25 and OTP 26, this constant provides a comprehensive set of requirements that Erlang nodes must support
/// to ensure compatibility and leverage the latest advancements in the Erlang ecosystem.
///
/// The combined mandatory flags include:
/// - Extended references, fun tags, extended PIDs/ports, UTF-8 atoms, new fun tags, big creation tags, new floats, map tags, export pointer tags, bit binaries,
/// and handshake version 23 from OTP 25.
/// - Version 4 node connections and unlink identifiers from OTP 26, indicating enhancements in communication protocols and inter-process communication mechanisms.
///
/// Ensuring these flags are supported and enabled on Erlang nodes guarantees wide-ranging compatibility with the features and functionalities introduced
/// in the latest versions of OTP, promoting robustness and forward-compatibility in distributed Erlang applications.
///
/// - Author: Lee S. Barney
/// - Version: 0.1
let DIST_MANDATORY = DIST_MANDATORY_25
    | DIST_MANDATORY_26



/// A group of defined values used to produce
/// byte array messages for EPMD. The default node port number is 9090. To set a new port number it must be in bigendian bytes. Ex. UInt16(8888).be\_bytes for port number 8888
///
/// Both the Highest and Lowest versions of OTP suppported are 23 and higher. By default, there are no extras included. You can change this by adding them.
///
/// Make all changes to the static variables ***BEFORE*** using the other elements of EPMDMessageComponents. Some elements are calculated variables. The byte arrays are all bigendian.
typealias EPMDMessageComponent = [Byte]
extension EPMDMessageComponent{
    static let STATUS_INDICATOR: [Byte] = [Byte(73)]
    static let NAME_MESSAGE_INDICATOR:[Byte] = [Byte(78)]
    static let EPMD_NON_VARIABLE_SIZE = [Byte(13)]//the size of the non-variable fields as defined at https://www.erlang.org/doc/apps/erts/erl_dist_protocol.html
    static let PORT_PLEASE_REQ = [Byte(122)]
    static let EPMD_ALIVE2_REQ = [Byte(120)]
    static let NODE_TYPE = [Byte(72)]//native type node
    static let TCP_IPv4 = [Byte(0)]
    static let TCP_IPv6 = [Byte(1)]
    static let HIGHEST_OTP_VERSION = UInt16(6).toErlangInterchangeByteOrder.toByteArray
    static let LOWEST_OTP_VERSION = HIGHEST_OTP_VERSION
}

struct ERL {
    static let LINK:UInt8 =              1
    static let SEND:UInt8 =              2
    static let EXIT:UInt8 =              3
    static let UNLINK:UInt8 =            4//OBSOLETE
    static let NODE_LINK:UInt8 =         5
    static let REG_SEND:UInt8 =          6
    static let GROUP_LEADER:UInt8 =      7
    static let EXIT2:UInt8 =             8
    static let SEND_TT:UInt8 =           12
    static let EXIT_TT:UInt8 =           13
    static let REG_SEND_TT:UInt8 =       16
    static let EXIT2_TT:UInt8 =          18
    static let MONITOR_P:UInt8 =         19
    static let DEMONITOR_P:UInt8 =       20
    static let MONITOR_P_EXIT:UInt8 =    21
    static let SEND_SENDER:UInt8 =       22
    static let SEND_SENDER_TT:UInt8 =    23
    static let PAYLOAD_EXIT:UInt8 =      24
    static let PAYLOAD_EXIT_TT:UInt8 =   25
    static let PAYLOAD_EXIT2:UInt8 =     26
    static let PAYLOAD_EXIT2_TT:UInt8 =  27
    static let PAYLOAD_MONITOR_P_EXIT:UInt8 = 28
    static let SPAWN_REQUEST:UInt8 =     29
    static let SPAWN_REQUEST_TT:UInt8 =  30
    static let SPAWN_REPLY:UInt8 =       31
    static let SPAWN_REPLY_TT:UInt8 =    32
    static let ALIAS_SEND:UInt8 =        33
    static let ALIAS_SEND_TT:UInt8 =     34
    static let UNLINK_ID:UInt8 =         35
    static let UNLINK_ID_ACK:UInt8 =     36
    
    //Defining these this way ensures they are UTF8
    static let SMALL_INTEGER_EXT:Character = "a"
    static let INTEGER_EXT:Character = "b"
    static let FLOAT_EXT:Character = "c"
    static let NEW_FLOAT_EXT:Character = "F"
    static let ATOM_EXT:Character = "d"
    static let SMALL_ATOM_EXT:Character = "s"
    static let ATOM_UTF8_EXT:UInt8 = 118            //'v'
    static let SMALL_ATOM_UTF8_EXT:UInt8 = 119      
    static let REFERENCE_EXT:Character = "e"
    static let NEW_REFERENCE_EXT:Character = "r"
    static let NEWER_REFERENCE_EXT:Character = "Z"
    static let PORT_EXT:Character = "f"
    static let NEW_PORT_EXT:Character = "Y"
    static let PID_EXT:Character = "g"
    static let NEW_PID_EXT:Character = "X"
    static let SMALL_TUPLE_EXT:Character = "h"
    static let LARGE_TUPLE_EXT:Character = "i"
    static let NIL_EXT:Character = "j"
    static let STRING_EXT:Character = "k"
    static let LIST_EXT:Character = "l"
    static let BINARY_EXT:Character = "m"
    static let BIT_BINARY_EXT:Character = "M"
    static let SMALL_BIG_EXT:Character = "n"
    static let LARGE_BIG_EXT:Character = "o"
    static let NEW_FUN_EXT:Character = "p"
    static let MAP_EXT:Character = "t"
    static let FUN_EXT:Character = "u"
    static let EXPORT_EXT:Character = "q"
    static let V4_PORT_EXT:Character = "x"

     
    static let NEW_CACHE:Character = "N" /* c nodes don"t know these two */
    static let CACHED_ATOM:Character = "C"
}

