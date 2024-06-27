//
//  NetKernel.swift

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
//  Created by Barney, Lee on 6/20/24.
//

import Foundation
import Network
import Logging


public enum NetKernel{
    static func connectNode(named:String, epmdPort:UInt8, logger:Logger?)->Bool{
        //check for valid input string
        let uuid = UUID().uuidString
        guard named.filter({ $0 == "@" }).count == 1  else{
            logger?.error("\(uuid) invalid node name \(named)")
            return false
        }
        logger?.trace("\(uuid) connecting to \(named)")
        let parts = named.components(separatedBy: "@")
        
        //do a PORT_PLEASE request on the EPMD for the named machine to get the port number for the node
        
         
        //build normal message
        
        //send the connection data
        
        //read any response
        
        //store the connection information so we don't connect again when connection is still valid
        
        return true
    }
}
