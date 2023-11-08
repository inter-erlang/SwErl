//
//  EPMDClient.swift
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
//  Created by Lee Barney on 10/10/23.
//

import Foundation
import Network

enum EPMDCommand{
    case findServer
    case connect
    case disconnect
    case sendState
}

enum EPMDConnectionManager:statem_behavior{
    ///
    ///API Functions
    ///
    static func link() throws -> Pid? {
        return try gen_statem.start_link(name:"EPMDConnectionManager", actor_type: EPMDConnectionManager.self, initial_data: [])
    }
    
    static func connectToServer() throws{
        try gen_statem.cast(name: "EPMDConnectionManager", message: EPMDCommand.findServer)
        try gen_statem.cast(name: "EPMDConnectionManager", message: EPMDCommand.connect)
    }
    
    static func breakConnection() throws{
        try gen_statem.cast(name: "EPMDConnectionManager", message: EPMDCommand.disconnect)
    }
    
    static func notifyResolver(receiver:String) throws{
        try gen_statem.cast(name: "EPMDConnectionManager", message: (EPMDCommand.sendState,receiver))
    }
    
    ///
    ///Required Hooks
    ///
    static func initializeState(initial_data: Any) throws -> Any {
        initial_data
    }
    
    static func unlinked(reason: String, current_state: Any) {
        //disconnect from the EPMD Server
        guard let connection_info = current_state as? [String:Any] else{
            return
        }
        guard let connection = connection_info["connection"] as? NWConnection else {
            return
        }
        connection.cancel()
    }
    
    static func handleEvent(message: Any, current_state: Any) -> Any? {
        guard let (command,Additional) = message as? (EPMDCommand,Any?)  else{
            return current_state
        }
        guard let state_dict = current_state as? [String:Any] else {
            return current_state
        }
        var updated_state:[String:Any]? = nil
        if command == EPMDCommand.findServer {
            updated_state = findOrSpawnEPMD(state:state_dict)
        }
        else if command == EPMDCommand.connect{
            updated_state = state_dict//add connection items here
        }
        else if command == EPMDCommand.disconnect{
            gen_statem.unlink(name: "EPMDConnectionManager", reason: "disconnect request")
            updated_state = nil
        }
        else if command == EPMDCommand.sendState{
            guard let receiver = Additional as? String, receiver == "EPMDResolver" else {
                return updated_state
            }
            EPMDResolver.completeInfoTransfer(state_dict)
        }
        else{//default
            updated_state = state_dict
        }
        /*
        let updatedState:[String:Any]? = switch command{
            case EPMDCommand.findServer:
                findOrSpawnEPMD(state:state_dict)
            case EPMDCommand.connect:
                state_dict//add connection items here
            case EPMDCommand.disconnect:
                unlinkAndClearState()
        }
         */
        return updated_state
    }
    
}

func findOrSpawnEPMD(state:[String:Any])-> [String:Any]{
    return state
}

func unlinkAndClearState()->[String:Any]?{
    gen_statem.unlink(name: "EPMDConnectionManager", reason: "disconnect request")
    return nil
}


//(EPMDPort:NWEndpoint.Port,
//                  EPMD_Host:NWEndpoint.Host,
//                  connection:NWConnection,
//                         nodeName:String, nodePort:UInt16)
