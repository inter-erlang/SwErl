//
//  GenStateM.swift
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
//  Created by Lee Barney on 9/25/23.
//
import Foundation

///Documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

///This protocol enforces the types of behaviors required of every state machine in SwErl. It extends the OTPActor behavior like all non-process SwErl actors.
public protocol GenStatemBehavior:OTPActor_behavior{
    
    
    ///     This hook function is called if the ! operator is used to send a message to a _statem\_behavior_.
    ///     - Parameters:
    ///      - message: any data type sent as a message to the PID's state machine
    ///      - state: the current state of the state machine
    ///     - Value: none
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    
    static func notify(message: SwErl.SwErlMessage, state: SwErl.SwErlState)
    
    ///     This hook function is used to create the first state of this state machine subtype's occurance.
    ///     - Parameters:
    ///     - initialData: the data used to generate an initial state.
    ///     - Value: The state to be used as the initial state of the state machine subtype's occurance
    ///     - Throws: any exception thrown by the code implementation of this function
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    static func initialize(initialData:Any) ->SwErlState
    
    ///    This hook function is used to react to a request to unlink request. At this point, when this function executes, the machine sub-type's occurance has already been unlinked.
    ///     - Parameters:
    ///     - reason: the reason given in the request to unlink the occurance
    ///     - current_state:
    ///     - Value: void
    ///     - Throws: any exception thrown by the code implementation of this function
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    static func unlinked(message:SwErlMessage,current_state:SwErlState)
    
    ///    This hook function is used to deal with the results of using the _gen\_statem.cast_ function. The logic it executes calculates an updated state for the state machine.
    ///     - Parameters:
    ///     - message: any data or data structure
    ///     - current_state: the existing state of the state machine
    ///     - Value: an updated state that is the result of receiving the message or nil
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    static func handleCast(message:SwErlMessage,current_state:SwErlState)->SwErlState
    static func handleCall(message:SwErlMessage,current_state:SwErlState)->(SwErlResponse,SwErlState)
    
    
    
    
}

/// This enumeration has, as elements, a set of generic functions that conduct
/// the communication required of all statem behaviors. These functions ensure
/// that the hook functions in each custom state machine are executed in the
/// correct order and store updated states correctly.
///
/// These functions also ensure that each custom state machine is registered
/// properly so it can be used from anywhere in the application's code base.
public enum GenStateM:OTPActor_behavior{
    
    ///    This function registers, by name, and prepares an occurance of a specified sub-type of a generic state machine using the specified data. Once this function completes, the sub-type occurance can be used. All functions applied to the occurance will execute on the main or any other thread depending on the DispatchQueue stated. By default, the global queue will be used, but if the main() queue is passed as a parameter, the sub-type's functions will all run on the main/UI thread.
    ///     - Parameters:
    ///      - queueToUse: the desired queue for the processes should use. Default:main()
    ///      - name: a name to link to an occurance of the statem sub-type.
    ///      - statem: the sub-type of statem being linked to.
    ///      - initialData: any desired data used to initialize the statem sub-type occurance's state. This data is passsed to the statem sub-type's initialize function.
    ///     - Value: a Pid that uniquely identifies the occurance of the sub-type of gen\_statem the name is linked to
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    @discardableResult public static func startLink<T:GenStatemBehavior>(queueToUse:DispatchQueue = DispatchQueue.global(),name:String,statem:T.Type,initialData:Any) throws -> Pid{
        
        //generate the pid prior to the pids for the behavior closures
        let OTP_Pid = Registrar.generatePid()
        
        //the state machine will consume all requests serially in the order they were received
        let serialQueue = DispatchQueue(label: Pid.to_string(OTP_Pid) ,target: queueToUse)
        
        let handleCall = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return statem.handleCall(message: message, current_state: state)
        }
        let handleCast = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),statem.handleCast(message: message, current_state: state))
        }
        
        let unlinked = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            statem.unlinked(message: message, current_state: state)
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        let notify = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            statem.notify(message: message, state: state)
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        let statemProcess = SwErlProcess(queueToUse:serialQueue, registrationID: OTP_Pid, OTP_Wrappers: (handleCall,handleCast,unlinked,notify))
        
        let state = statem.initialize(initialData: initialData)
        try Registrar.link(statemProcess, initState:state, name: name, PID: OTP_Pid)
        return OTP_Pid
    }
    
    ///    This function registers, by name, and prepares an occurance of a specified sub-type of a generic state machine using the specified data. Once this function completes, the sub-type occurance can be used. All functions applied to the occurance will execute on the main or any other thread depending on the DispatchQueue stated. By default, the global queue will be used, but if the main() queue is passed as a parameter, the sub-type's functions will all run on the main/UI thread.
    ///     - Parameters:
    ///      - queueToUse: the desired queue for the processes should use. Default:main()
    ///      - name: a name to link to an occurance of the statem sub-type.
    ///      - statem: the sub-type of statem being linked to.
    ///      - initialData: any desired data used to initialize the statem sub-type occurance's state. This data is passsed to the statem sub-type's initialize function.
    ///     - Value: a Pid that uniquely identifies the occurance of the sub-type of gen\_statem the name is linked to
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    @discardableResult public static func startLinkGlobally<T:GenStatemBehavior>(queueToUse:DispatchQueue = DispatchQueue.global(),name:String,statem:T.Type,initialData:Any) throws -> Pid{
        
        //generate the pid prior to the pids for the behavior closures
        let (id, aSerial) = pidCounter.next()
        let OTP_Pid = Pid(id: id, serial: aSerial, creation: 0)
        
        //the state machine will consume all requests serially in the order they were received
        let serialQueue = DispatchQueue(label: Pid.to_string(OTP_Pid) ,target: queueToUse)
        
        let handleCall = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return statem.handleCall(message: message, current_state: state)
        }
        let handleCast = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            return ((SwErlPassed.ok,nil),statem.handleCast(message: message, current_state: state))
        }
        
        let unlinked = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            statem.unlinked(message: message, current_state: state)
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        let notify = {(message:SwErlMessage,state:SwErlState)->(SwErlResponse,SwErlState) in
            statem.notify(message: message, state: state)
            return ((SwErlPassed.ok,nil),"")//this is ignored
        }
        
        let statemProcess = SwErlProcess(queueToUse:serialQueue, registrationID: OTP_Pid, OTP_Wrappers: (handleCall,handleCast,unlinked,notify))
        let state = statem.initialize(initialData: initialData)
        
        try Registrar.link(statemProcess, .global, initState:state, name: name, PID: OTP_Pid)
        return OTP_Pid
    }
    
    ///    This function unlinks the information of an occurance of a generic state machine's sub-type. When the state machine is unlinked, all data memory for the state machine is freed. Other occurances of the sub-type registered under other names are unaffected.
    ///
    ///     After the name and Pid have been unlinked, the state machine sub-type's unlink function is called.
    ///
    ///     If the name parameter does not match a linked occurance of a state machine sub-type, nothing needs to be unlinked and the state of the application is still valid. Therefore, no exceptions are thrown.
    ///     - Parameters:
    ///      - name: a name of a registered occurance of a GenSatemBehavior sub-type occurance.
    ///      - message: any data to be logged, printed, or used in the state machine's unlink function.
    ///     - Value: SwErlResponse indicating success, ok, or failure, fail, and a failure reason.
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    public static func unlink(name:String, message:SwErlMessage)->SwErlResponse{
        guard let PID = Registrar.getPid(forName: name) else{
            return (SwErlPassed.fail,SwErlError.notRegisteredByName)
        }
        guard let process = Registrar.getProcess(forID: PID) else{
            return (SwErlPassed.fail,SwErlError.notRegisteredByPid)
        }
        guard let (_,_,unlinked,_) = process.GenStatemProcessWrappers else{
            return (SwErlPassed.fail," \(name) has no unlinked function")
        }
        Registrar.unlink(name)
        guard let state = Registrar.getProcessState(forID: PID) else{
            return (SwErlPassed.fail,SwErlError.invalidState)
        }
        Registrar.removeState(forID: PID)
        let(response,_) = unlinked(message,state)
        return response
    }
    
    ///    This function sends a concurrent message to a registered occurance of a generic state machine sub-type. Messages are used to update the state of the state machine as defined in the state machine sub-type's handleCast function.
    ///     - Parameters:
    ///     - name: a name of a registered occurance of a statem sub-type occurance.
    ///     - message: any type of data expected by the handleCast function of the generic state machine's sub-type.
    ///     - Value: Void
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    
    //being a cast-type call, no value is expected and all no failures throw
    //directly from these functions.
    public static func cast(name:String,message:SwErlMessage){
        guard let PID = Registrar.getPid(forName: name) else{
            return
        }
        cast(PID:PID,message: message)
    }
    
    public static func cast(PID:Pid,message:SwErlMessage){
        //don't wait for a return
        //it doesn't matter which queue is used here. This is not the queue
        //on which the processing will happen
        DispatchQueue.global().async {
            //if the pid hasn't been registered correctly, return.
            guard let process = Registrar.getProcess(forID: PID) else{
                return
            }
            guard let state = Registrar.getProcessState(forID: PID) else{
                return
            }
            guard let (_,handleCast,_,_) = process.GenStatemProcessWrappers else{
                return
            }
            //execute the handleCast function
            let (_,updatedState) = handleCast(message,state)
            Registrar.setProcessState(forID: PID, value: updatedState)
        }
    }
    
    
    ///    This function sends a concurrent, non-blocking message to a registered occurance of a generic state machine sub-type. No updates to the state machine's state are done.
    ///     - Parameters:
    ///      - name: a name of a registered occurance of a statem sub-type occurance.
    ///      - message: any type of data expected by the handleCast function of the generic state machine's sub-type.
    ///     - Value: Void
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    public static func notify(name:String,message:SwErlMessage){
        guard let PID = Registrar.getPid(forName: name) else{
            return
        }
        notify(PID:PID,message: message)
    }
    public static func notify(PID:Pid,message:SwErlMessage){
        DispatchQueue.global().async {
            //if the pid hasn't been registered correctly, return.
            guard let process = Registrar.getProcess(forID: PID) else{
                return
            }
            process.queue.sync {
                guard let state = Registrar.getProcessState(forID: PID) else{
                    return
                }
                guard let (_,_,_,notify) = process.GenStatemProcessWrappers else{
                    return
                }
                let _ = notify(message,state)
            }
        }
    }
    
    ///    This function sends a message to a registered occurance of a generic state machine sub-type and waits for a response. Messages are used to update the state of the state machine as defined in the state machine sub-type's handleCall function.
    ///     - Parameters:
    ///     - name: a name of a registered occurance of a statem sub-type occurance.
    ///     - message: any type of data expected by the handleEvent function of the generic state machine's sub-type.
    ///     - Value: A SwErlResponse, (SwErlSuccess.ok,Data) or (SwErlSuccess.fail,Data), which is returned from the state machine sub-type's handleCall function.
    ///     - Author:
    ///     Lee S. Barney
    ///     - Version:
    ///     0.1
    public static func call(name:String,message:SwErlMessage)->SwErlResponse{
        guard let PID = Registrar.getPid(forName: name) else{
            return (SwErlPassed.fail,SwErlError.notRegisteredByName)
        }
        return call(PID:PID,message: message)
    }
    public static func call(PID:Pid, message:SwErlMessage)->SwErlResponse{
        //if the pid hasn't been registered correctly, throw an exception.
        guard let process = Registrar.getProcess(forID: PID) else{
            return (SwErlPassed.fail,SwErlError.notRegisteredByPid)
        }
        return process.queue.sync{//blocks until complete 😕
            //state machines always have a stored state.
            //if this one doesn't, do nothing.
            guard let state = Registrar.getProcessState(forID: PID) else{
                return (SwErlPassed.fail,SwErlError.statem_behaviorWithoutState)
            }
            guard let (handleCall,_,_,_) = process.GenStatemProcessWrappers else{
                return (SwErlPassed.fail,"no handleCall function found")
            }
            let (response,updatedState) = handleCall(message,state)
            Registrar.setProcessState(forID: PID, value: updatedState)
            return response
        }
    }
}


