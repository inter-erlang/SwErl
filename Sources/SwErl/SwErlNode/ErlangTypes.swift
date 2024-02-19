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

import Foundation
import BigInt


typealias ErlPid = (nodeName:String,num:UInt32,serial:UInt32,creation:UInt32)
typealias ErlPort = (nodeName:String,id:UInt64,creation:UInt32)
typealias ErlRef = (nodeName:String,len:UInt32,n:[UInt32],creation:UInt32)
typealias ErlTrace = (serial:UInt32,prev:UInt32,from:ErlPid,label:UInt32,flags:UInt32)
typealias ErlMsg = (type:UInt32,from:ErlPid,to:ErlPid,toName:String,cookie:String,token:ErlTrace)
typealias ErlFunClosure = (arity:UInt32,module:String,MD5:String,index:UInt32,oldIndex:UInt32,unique:UInt32,freeVariableCount:UInt32,pid:ErlPid,freeVariablesLength:UInt32,freeVariables:String)
typealias ErlFunExport = (arity:UInt32,module:String,function:String,allocated:UInt32)

struct ei_term {
    let type:Byte
    let arity:UInt32
    let size:UInt32
    var integerValue:UInt32?
    var doubleValue:Double?
    var atomName:String?
    var pid:ErlPid?
    var port:ErlPort?
    var reference:ErlRef?
}

typealias ErlConnection = (ipAddress:String,nodeName:String)



