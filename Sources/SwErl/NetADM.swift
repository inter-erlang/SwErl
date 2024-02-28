//
//  NetADM.swift
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
//  Created by Lee Barney on 2/20/24.
//


///Documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation
import Logging


public enum NetADM{
    /// Retrieves the names and port numbers of all active nodes.
    ///
    /// This function queries the `nameNodeAliveTracker` of the local SwErl EPMD process to obtain a list of all currently active nodes along with their
    /// port numbers. It provides a convenient way to access the network information of all nodes in the local system for monitoring or
    /// connectivity purposes.
    ///
    /// - Parameter logger: An optional `Logger` instance for logging error messages.
    /// - Returns: A tuple containing a `SwErlPassed` indicating the success of the operation, and an array of tuples where each tuple
    ///   consists of a node's name (`String`) and its port number (`UInt16`). Returns `nil` if the operation fails.
    ///
    /// This function is particularly useful for services that need to dynamically discover and communicate with other nodes in a
    /// distributed system. It leverages the tracking capabilities of `nameNodeAliveTracker` to provide up-to-date information.
    ///
    /// - Complexity: The complexity of this operation is the same as the complexity of the safe dictionaries.
    ///
    /// - Author: Lee Barney
    /// - Version: 0.1
    static func names(logger:Logger? = nil)->(SwErlPassed,[(String,UInt16)])? {
        let nilInfo:Any? = nil
            let allValues = "nameNodeAliveTracker" ! (Tracker.getAll,nilInfo,nilInfo)
            guard let (_,allNodeAlives) = allValues as? (SwErlPassed,[NodeAlive]) else{
                logger?.error("names request failed. Incorrect request result \(allValues)")
                return nil
            }
        let namePortList:[(String,UInt16)] = allNodeAlives.map(){nodeAlive in
            (nodeAlive.nodeName.string!,nodeAlive.portNumber)
                
        }
        return (SwErlPassed.ok,namePortList)
    }
    /// Sends a ping request to the specified node to check its availability.
    ///
    /// This function sends a ping to a node identified by `nodeName`. It's a simple way to verify if a node is reachable
    /// and responding within the distributed system. The remote node can be a SwErl node or a standard Erlang node. This function needs to be expanded to include the actual ping implementation.
    ///
    /// - Parameter nodeName: The name of the node to ping.
    ///
    /// This basic implementation serves as a placeholder. To make it functional,  implement the logic for
    /// establishing a connection to the target node, sending a ping message, and waiting for a pong response to
    /// confirm availability.
    ///
    /// - Complexity: To Be Determined
    ///
    /// - Author: Lee Barney
    /// - Version: 0.1
    func ping(nodeName: String) {
        // Implementation of ping logic goes here.
    }

}
