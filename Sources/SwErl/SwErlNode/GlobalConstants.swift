//
//  Capabilities.swift
//  
//
//  Created by Lee Barney on 3/13/23.
//

import Foundation

/* Maximum limitations*/
struct Max {
    static let AtomLen = 256
    
}

/* Distribution capability flags */
struct DFLAG {
    static let PUBLISHED =                   1
    static let ATOM_CACHE =                  2
    static let EXTENDED_REFERENCES =         4
    static let DIST_MONITOR   =              8
    static let FUN_TAGS  =                0x10
    static let NEW_FUN_TAGS =             0x80
    static let EXTENDED_PIDS_PORTS =     0x100
    static let EXPORT_PTR_TAG =          0x200
    static let BIT_BINARIES  =           0x400
    static let NEW_FLOATS  =             0x800
    static let SMALL_ATOM_TAGS =        0x4000
    static let UTF8_ATOMS =            0x10000
    static let MAP_TAG  =              0x20000
    static let BIG_CREATION  =         0x40000
    static let HANDSHAKE_23  =       0x1000000
    static let UNLINK_ID  =          0x2000000
    static let MANDATORY_25_DIGEST = 0x4000000
    static let RESERVED =           0xf8000000
    static let NAME_ME  =            0x2 << 32
    static let V4_NC    =            0x4 << 32
}

/* Mandatory flags for distribution in OTP 25. */
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

/* Mandatory flags for distribution in OTP 26. */
let DIST_MANDATORY_26 = DFLAG.V4_NC
| DFLAG.UNLINK_ID

/*Mandatory flags for distribution.*/
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
    static let HIGHEST_OTP_VERSION = UInt16(6).toMessageByteOrder.toByteArray
    static let LOWEST_OTP_VERSION = HIGHEST_OTP_VERSION
}

struct ERL {
    static let UNLINK_ID =         35
    static let UNLINK_ID_ACK =     36
    
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

