//
//  Node.swift
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
//  Created by Barney, Lee on 5/7/24.
//

import Foundation
import Logging
import Network


typealias NodePairAtomCache = [UInt8: SwErlAtom]

/// Starts a repeating network task that executes at regular intervals as long as the network connection is valid.
///
/// The task is scheduled to run initially and then again at the specified interval. If the network connection
/// is in a cancelled or failed state, the task will terminate.
///
/// Example usage:
/// ```swift
/// let connection: NWConnection = // initialize your network connection
/// startRepeatingNetworkTask(interval: 15, connection: connection) {
///     // Perform the network task here
///     print("Network task executed")
/// }
/// ```
///
/// - Parameters:
///   - interval: The time interval between each execution of the task.
///   - connection: The `NWConnection` instance representing the network connection.
///   - task: A closure that represents the network task to be executed repeatedly.
///
/// - Complexity: O(1) for each task scheduling.
///
/// - Author: Lee Barney
/// - Version: 0.9
func startRepeatingNetworkTask(interval: TimeInterval, connection:NWConnection, task: @escaping () -> Void) {
    func scheduleNext() {
        DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
            
            //terminate if there is no valid connection
            switch connection.state{
            case .cancelled,.failed:
                return
            default:
                task()
                scheduleNext()  // Recursively schedule the next execution
            }
        }
    }
    //schedule first task completion
    scheduleNext()
}


/// A namespace for node-related functions.
enum Node{
    /// Spawns a SwErl node with the provided configuration.
    ///
    /// This function starts the EPMD if none exists, initializes necessary caches, and starts the remote procedure receiver.
    ///
    /// Example usage:
    /// ```swift
    /// Node.spawn(using: .tcp, name: "silly@nodeName.something", cookie: "secretCookie", epmdPort: 4369, EPMDLogger: nil, interNodeLogger: nil)
    /// ```
    ///
    /// - Parameters:
    ///   - conduit: The communication protocol to use for the node. Defaults to `.tcp`.
    ///   - name: The name of the node.
    ///   - cookie: The cookie for the node.
    ///   - epmdPort: The port for the EPMD. Defaults to `4369`.
    ///   - EPMDLogger: An optional logger for the EPMD.
    ///   - interNodeLogger: An optional logger for inter-node communications.
    ///
    /// - Complexity: O(1).
    ///
    /// - Author: Lee Barney
    /// - Version: 0.9
    static func spawn(using conduit:ExchangeProtocol = .tcp, name:String, cookie:String, epmdPort:UInt16 = 4369, EPMDLogger:Logger? = nil, interNodeLogger:Logger? = nil){
        //start EPMD if none exists
        EPMD.start(using:conduit, on:epmdPort, logger:EPMDLogger)
        //start Cache Dictionaries
        do{
            try buildSafe(dictionary: [String:NodePairAtomCache](), named: "atom_cache")
            try buildSafe(dictionary: [String:NWConnection](), named: "connection_cache")
            try buildSafe(dictionary: [String:Date](), named: "activity_cache")
        }
        catch{
            return
        }
        //start Remote Proceedure Receiver
        startReceiver(using:conduit, name:name, cookie:cookie, epmdPort:epmdPort, logger:interNodeLogger)
        
    }
    /// Sends data using a specified network connection.
    ///
    /// This function updates the activity cache with the current time and sends the provided data over the given network connection.
    ///
    /// Example usage:
    /// ```swift
    /// let data = Data()
    /// let connection: NWConnection = // Initialize your NWConnection
    /// Node.sendData(data, using: connection, id: "connectionID") { error in
    ///     if let error = error {
    ///         print("Failed to send data: \(error)")
    ///     } else {
    ///         print("Data sent successfully")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - data: The data to be sent.
    ///   - connection: The network connection to use for sending the data.
    ///   - id: The identifier for the connection in the activity cache.
    ///   - completion: A closure to be executed when the send operation completes.
    ///
    /// - Complexity: O(1).
    ///
    /// - Author: Lee Barney
    /// - Version: 0.9
    static func sendData(_ data:Data, using connection:NWConnection, id:String, completion:NWConnection.SendCompletion){
        "activity_time_cache" ! (SafeDictCommand.add,id,Date().timeIntervalSince1970)
        connection.send(content: data, completion: completion)
        return
    }
}
