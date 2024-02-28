//
//  RPC.swift
//
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
//  Created by Lee Barney on 11/20/23.
//

///Documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation
import Network
import Logging

enum ERPC{
    static func cast(node:String,module:String,function:String,parameters:[Any]) {
    }
    static func multicast(nodes:[String],module:String,function:String,parameters:[Any]){
        
    }
    static func call(node:String,module:String,function:String,parameters:[Any])->Any{
        
        return 0
    }
    static func multicall(nodes:[String],module:String,function:String,parameters:[Any])->[Any]{
        
        return [0]
    }
}

//work this end to find out why the other end is failing. What is wrong with the challenge send when SwErl Node is sending challenge? Why does the ping of SwErlNode terminate when the challenge is sent?
                                                                   

