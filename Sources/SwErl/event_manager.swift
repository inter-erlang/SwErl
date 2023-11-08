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
 the communication required of all _gen_event_managers_. These functions ensure
 that the hook functions in each custom event handler are executed in the
 correct order and store updated states correctly. 
 
 These functions also ensure that all event handlers added to this manager are notified
 each time the manager receives an notification of an event.
 
 These functions also ensure that each custom event manager is registered
 properly so it can be used from anywhere in the application's code base.
 */
public enum event_manager:Messageable{
    
    
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
    static func start_link(queueToUse:DispatchQueue = DispatchQueue.global(),name:String,intialHandlers:[Pid]) throws->Pid{
        //register the actor by name.
        let (aSerial,aCreation) = pidCounter.next()
        let PID = Pid(id: 0,serial: aSerial,creation: aCreation)
        let queueToUse = DispatchQueue(label: Pid.to_string(PID) ,target: queueToUse)
        try Registrar.link((event_manager.self,queueToUse,intialHandlers), name: name, PID: PID)
        return PID
    }
    /**
     This function unlinks the information of an occurrance of an event manager. Other occurrances of the sub-type registered under other names are unaffected.
     
     
     If the name does not match a linked occurrance of an event manager, nothing needs to be unlinked and the state of the application is still valid. Therefore, no exceptions are thrown.
     - Parameters:
     - name: a name of a registered occurrance of a statem sub-type occurrance.
     - Value: Void
     - Author:
     Lee S. Barney
     - Version:
     0.1
     */
    static func unlink(name:String, reason:String){
        guard let PID = Registrar.instance.processesLinkedToName[name] else{
            return//Quiely fail since the statem was not registered
        }
        guard let (type,_,_) = Registrar.instance.OTPActorsLinkedToPid[PID] else{
            return//Quiely fail since the statem was not registered
        }
        guard let _ = type as? event_manager.Type else{
            return//Quiely fail since the statem was not registered
        }
        Registrar.unlink(name)
    }
    /**
     This function associates a stateless SwErl process with named event manager.
     
     If the manager name does not match a linked occurrance of an event manager, nothing needs to be unlinked and the state of the application is still valid. Therefore, no exceptions are thrown.
     - Parameters:
     - to: a name of a registered occurrance of a  sub-type occurrance.
     - closure: any function or closure that has as parameters a process ID and an Any. The Any is used to receive the message being sent to the handler. This closure has a Void return type.
     - Value: Void
     - Author:
     Lee S. Barney
     - Version:
     0.1
     */
    static func add(to:String, handler:@Sendable @escaping (Pid,SwErlMessage)->()) throws{
        try link(to: to){(dispQueue) in
            try spawn(queueToUse:dispQueue, function: handler)
        }
    }
    
    /**
     This function associates a stateful SwErl process with named event manager.
     
     If the manager name does not match a linked occurrance of an event manager, nothing needs to be unlinked and the state of the application is still valid. Therefore, no exceptions are thrown.
     - Parameters:
     - to: a name of a registered occurrance of a  sub-type occurrance.
     - closure: any function or closure that has as parameters a process ID and an Any. The Any is used to receive the message being sent to the handler. This closure has a Void return type.
     - Value: Void
     - Author:
     Lee S. Barney
     - Version:
     0.1
     */
    static func add(to:String, initialState:SwErlState, handler:@Sendable @escaping (Pid,SwErlState,SwErlMessage)->(SwErlResponse,SwErlState)) throws{
        try link(to: to){(dispQueue) in
            try spawn(queueToUse:dispQueue, initialState: initialState, function: handler)
        }
    }
    
//TODO: create addHandler functions that allow a handler to use a defined dispatch queue
    
    
    /**
     This function sends a message to a registered occurrance of a generic state machine sub-type. Messages are used to update the state of the state machine as defined in the state machine sub-type's handleEvent function.
     - Parameters:
     - name: a name of a registered occurrance of a statem sub-type occurrance.
     - message: any type of data expected by the handleEvent function of the generic state machine's sub-type.
     - Value: Void
     - Throws: SwErlError when the name isn't registered/linked, a Pid was not previously associated with the state machine sub-type's occurrance, the name is not linked to a sub-type of gen\_statem, or the sub-type occurrance has no state to track.
     - Author:
     Lee S. Barney
     - Version:
     0.1
     */
    //if there is no pid associated with that name, throw an exception
    public static func notify(PID:Pid,message:Any)throws{
        //if the pid hasn't been registered correctly, throw an exception.
        //this function only works on enums with the statem behavior.
        //if the type is anything except a statem_behavior, throw an exception.
        guard let (_,_,handlers) = Registrar.instance.OTPActorsLinkedToPid[PID] as? (event_manager.Type,DispatchQueue,[Pid]) else{
            throw SwErlError.notEventManager_behavior
        }
        //send the data to all processes in the manager's list of handlers
        for handlerPid in handlers{
            guard let handlerProcess = Registrar.instance.processesLinkedToPid[handlerPid] else{
                throw SwErlError.notRegisteredByPid
                }
            _ = executeSwErlProcess(handlerProcess, handlerPid, message)
        }
    }
}
//working function behind the facade functions
//this is private to this file and is never to be used from anywhere but
//from within the two existing addHandler facade functions.
private func link(to:String, closure:(DispatchQueue)throws -> Pid) throws{
    //find the Pid of the event_manager occurance
    guard let PID = Registrar.instance.processesLinkedToName[to] else{
        throw SwErlError.invalidState
    }
    guard let (type,dispQueue,storedState) = Registrar.instance.OTPActorsLinkedToPid[PID] else{
        throw SwErlError.notRegisteredByPid
    }
    //the event_manager's state is the list of handler Pids
    guard var currentHandlers = storedState as? [Pid] else{
        throw SwErlError.invalidState
    }
    //the closure is a facade over spawn, not the handler itself
    let handlerPID = try closure(dispQueue)
    currentHandlers.append(handlerPID)
    //update the state of the event_manager by associating the occurance with the event_manager's updated Pid list
    Registrar.instance.OTPActorsLinkedToPid[PID] = (type,dispQueue,currentHandlers)
}
