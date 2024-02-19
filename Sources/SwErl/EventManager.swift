//
//  events.swift
//
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
//  Created by Lee Barney on 10/13/23.
//

import Foundation


/**
 This enumeration has, as elements, a set of generic functions that conduct
 the communication required of all _EventManager_s. These functions ensure
 that the hook functions in each custom event handler are executed in the
 correct order and store updated states correctly.
 
 These functions also ensure that all event handlers added to this manager are notified
 each time the manager receives an notification of an event.
 
 These functions also ensure that each custom event manager is registered
 properly so it can be used from anywhere in the application's code base.
 */
public enum EventManager:OTPActor_behavior{
    
    /**
     This function registers, by name, and prepares a specified event manager using a list, possibly empty, of SwErl stateful or stateless process' IDs. These processes are the handlers for the event managed by the manager. Once this function completes, the occurrance can be used. All functions applied to the occurrance will execute on the main or any other thread depending on the DispatchQueue stated. By default, the global queue will be used, but if the main() queue is passed as a parameter, the occurrance's functions will all run on the main/UI thread.
     - Parameters:
     - queueToUse: the desired queue the processes should use. Default:global()
     - name: a name to link to an occurrance of the statem sub-type.
     - initial_data: any desired data used to initialize the statem sub-type occurrance's state
     - Value: a Pid that uniquely identifies the occurrance of the sub-type of gen\_statem the name is linked to
     - Author:
     Lee S. Barney
     - Version:
     0.1
     */
    static func link(queueToUse:DispatchQueue = .global(),name:String,intialHandlers:[SwErlStatelessHandler]) throws -> Pid{
        //register the actor by name.
        let PID = Registrar.generatePid()
        let queueToUse = DispatchQueue(label: Pid.to_string(PID) ,target: queueToUse)
        let process = SwErlProcess(queueToUse:queueToUse,registrationID: PID, eventHandlers: intialHandlers)
        try Registrar.link(process, name: name, PID: PID)
        return PID
    }
    /**
     This function unlinks the information of an occurrance of an event manager. Other occurrances of the sub-type registered under other names are unaffected.
     
     
     If the name does not match a linked occurrance of an event manager, nothing needs to be unlinked and the state of the application is still valid. Therefore, no exceptions are thrown.
     - Parameters:
     - name: a name of a registered occurrance of a statem sub-type occurrance.
     - Value: void
     - Author:
     Lee S. Barney
     - Version:
     0.1
     */
    static func unlink(name:String){
        
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
    
    /**
     This function sends a concurrent, non-blocking message to a registered occurance of an event manager. No updates to the state machine's state are done.
     - Parameters:
      - name: a name of a registered occurance of an event manager occurance.
      - message: any type of data expected by the manager's event handler functions.
     - Value: Void
     - Author:
     Lee S. Barney
     - Version:
     0.1
     */
    static func notify(name:String,message:SwErlMessage){
        guard let PID = Registrar.getPid(forName:name) else{
            return//silently fail. No such event manager
        }
        notify(PID: PID,message: message)
    }
    static func notify(PID:Pid,message:SwErlMessage){
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
