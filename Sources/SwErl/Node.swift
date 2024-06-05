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



enum Node{
    static func spawn(using conduit:ExchangeProtocol = .tcp, name:String, cookie:String, epmdPort:UInt16 = 4369, EPMDLogger:Logger? = nil, interNodeLogger:Logger? = nil){
        //start EPMD if none exists
        startEPMD(using:conduit, on:epmdPort, logger:EPMDLogger)
        //start Atom Cache Map
        do{
            try buildSafe(dictionary: [String:NodePairAtomCache](), named: "atom_cache")
            try buildSafe(dictionary: [String:NWConnection](), named: "connection_cache")
            try buildSafe(dictionary: [String:Date](), named: "activity_cache")
        }
        catch{}
        //start Remote Proceedure Receiver
        startReceiver(using:conduit, name:name, cookie:cookie, epmdPort:epmdPort, logger:interNodeLogger)
        
    }
    static func sendData(_ data:Data, using connection:NWConnection, id:String, completion:NWConnection.SendCompletion){
        "activity_time_cache" ! (SafeDictCommand.add,id,Date().timeIntervalSince1970)
        connection.send(content: data, completion: completion)
        return
    }
}
