//
//  events.swift
//
//
//Copyright (c) 2024 Lee Barney
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
//  Created by Lee Barney on 10/13/23.
//


///All documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation


/// Enumeration containing a set of generic functions responsible for managing communication within _EventManager_s. These functions are designed to:
/// - Ensure the correct sequential execution of hook functions in custom event handlers.
/// - Properly store updated states after each event handling.
/// - Notify all event handlers associated with the manager upon receiving an event notification.
/// - Register each custom event manager appropriately for global accessibility within the application's code base.
///
/// These mechanisms are fundamental to maintaining the integrity and order of event handling and state management across different parts of the application, facilitating a consistent and reliable event-driven architecture.

public enum EventManager:OTPActor_behavior{
    
    /// Registers and prepares a specified event manager with a given name, associating it with a list of SwErl process IDs. These processes act as handlers for events managed by the event manager. Post-registration, the occurrence can be utilized for event handling, with all related function executions occurring on either the main or a specified thread based on the provided `DispatchQueue`. By default, operations use the global queue, but specifying `DispatchQueue.main()` directs execution to the main/UI thread.
    ///
    /// - Parameters:
    ///   - queueToUse: The dispatch queue on which the processes will execute. Defaults to the global queue.
    ///   - name: A unique name to associate with an occurrence of the state management subtype.
    ///   - initialHandlers: An array of SwErl stateful or stateless process IDs that will handle events.
    /// - Returns: A `Pid` that uniquely identifies the occurrence of the state management subtype linked to the given name.
    ///
    /// - Complexity: O(1) for registration and setup. Actual complexity for event handling will depend on the implementation of the handlers.
    ///
    /// - Author: Lee Barney
    /// - Version: 0.1
    @discardableResult public static func link(queueToUse:DispatchQueue = .global(),name:String,intialHandlers:[SwErlStatelessHandler]) throws -> Pid{
        //register the actor by name.
        let PID = Registrar.generatePid()
        let queueToUse = DispatchQueue(label: Pid.to_string(PID) ,target: queueToUse)
        let process = SwErlProcess(queueToUse:queueToUse,registrationID: PID, eventHandlers: intialHandlers)
        try Registrar.link(process, name: name, PID: PID)
        return PID
    }
    /// Unlinks the information of an occurrence of an event manager. This operation does not affect other occurrences of the sub-type registered under different names. If the specified name does not match any linked occurrence of an event manager, the application's state remains valid, and no exceptions are thrown, resulting in a quiet failure.
    ///
    /// - Parameters:
    ///   - name: The name of a registered occurrence of a state management (statem) sub-type.
    ///
    /// - Complexity: O(1), as unlinking is a direct operation involving lookup and removal from the registry.
    ///
    /// - Author: Lee Barney
    /// - Version: 0.1
    public static func unlink(name:String){
        
        guard let PID = Registrar.getPid(forName: name) else{
            return//Quiely fail since the statem was not registered
        }
        guard let linkedProcess:SwErlProcess = Registrar.getProcess(forID: PID)else{
            return//Quiely fail since the manager was not registered
        }
        guard let _ = linkedProcess.eventHandlers else{
            return//Quiely fail since the name is not associate with an event manager
        }
        Registrar.unlink(name)
    }
    
    /// Sends a concurrent, non-blocking message to a registered occurrence of an event manager. This function does not perform any updates to the state machine's state.
    ///
    /// - Parameters:
    ///   - name: The name of a registered occurrence of an event manager.
    ///   - message: The data expected by the event manager's handler functions. Can be of any type.
    ///
    /// - Complexity: O(1), as sending a message is a direct operation that does not involve state manipulation.
    ///
    /// - Author: Lee Barney
    /// - Version: 0.1
    public static func notify(name:String,message:SwErlMessage){
        guard let PID = Registrar.getPid(forName:name) else{
            return//silently fail. No such event manager
        }
        notify(PID: PID,message: message)
    }
    public static func notify(PID:Pid,message:SwErlMessage){
        guard let eventManagerProcess = Registrar.getProcess(forID: PID) else{
            return//silently fail. No such event manager registered
        }
        
        guard let handlers = eventManagerProcess.eventHandlers else{
            return//silently fail. Not an event handler
        }
        for handler in handlers {
            eventManagerProcess.queue.async {
                handler(PID,message)
            }
        }
        
    }
    
}
