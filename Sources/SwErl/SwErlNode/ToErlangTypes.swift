//
//  ToErlangTypes.swift
//  
//
//  Created by Lee Barney on 3/13/23.
//

import Foundation
import BigInt



///
///Converts a Swift string to a portable byte representation
///for an Erlang atom. Any uppercase character is converted
///to lowercase to conform with the tuple-naming requirement
///in Erlang. The maximum length of an atom is 255 characters.
///If the length of the string is greater than 255 characters,
///it is truncated to 255 characters
///
///The representation is [string_length]++[utf8_type]++[string]
///where string_length is 2 bytes utf8_type is 1 byte and string
///is string_length bytes.
extension String{
    var toErlAtom:Data{
        guard self.count > 0 else{
            return Data()
        }
        var asString = self
        if self.count >= Max.AtomLen{
            asString = String(self.prefix(Max.AtomLen - 1))
            
        }
        var asData = Data(asString.lowercased().utf8)
        if asString.count <= 256{
            return Data([ERL.SMALL_ATOM_UTF8_EXT]) ++ Data([UInt8(asString.count)]) ++ asData
        }
        asData = Data([ERL.ATOM_UTF8_EXT])++Data(UInt16(asString.count).toMessageByteOrder.toByteArray) ++ asData
        return asData
    }
}
///
///Converts a Swift Bool to a portable byte representation
///for an Erlang atom.
///
///The representation is [string_length]++[utf8_type]++[string]
///where string_length is 2 bytes utf8_type is 1 byte and string
///is string_length bytes.
extension Bool{
    var toErlBool:Data{
        if self == true{
            return "true".toErlAtom
        }
        return "false".toErlAtom
    }
}

//These treat the elements of the Datas as individual digits
extension Data{
    var toBigUInt:BigUInt?{
        let str = self.reduce(""){accum,element in
            return accum + String(element)
        }
        return BigUInt(str)
    }
}
extension Data{
    var toBigInt:BigInt?{
        let str = self.reduce(""){accum,element in
            return accum + String(element)
        }
        return BigInt(str)
    }
}
