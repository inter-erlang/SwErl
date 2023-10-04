//
//  File.swift
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
//  Created by Lee Barney on 9/25/23.
//
import Foundation

//This is the protocol is used to express the behavior of
public protocol statem_behavior:OTPActor_behavior{
    func start_link(queueToUse:DispatchQueue, name:String,actor_type:any statem_behavior,initial_state:Any)throws->Void
    func initialize_state(initial_data:Any)->Any
    func unlink(reason:String,current_state:Any,data:Any)
    //the value of handle_event_cast is the updated state
    func handle_event_cast(message:Any,current_state:Any)->Any
}

    

//These are the functions that mimic some of the gen_statem
//Erlang module's functions
/**
 This enumeration has, as properties, a set of generic functions that conduct
 the communication required of all statem behaviors. These functions ensure
 that the hook functions in each custom state machine are executed in the
 correct order and store updated states correctly.
 
 These functions also ensure that each custom state machine is registered
 properly so it can be used from anywhere in the application's code base.
  - Parameters:
    - name: the registered name of the statem actor to use
    - initial_state, if any, the statem actor should begin with
 
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
public enum gen_statem{
    public static let start_link:(DispatchQueue,String,any statem_behavior,Any) throws->Pid = {(queueToUse,name,actor_type,initial_data) in
        let initial_state = actor_type.initialize_state(initial_data: initial_data)
        //register the actor by name. name => (actor_type,initial_data)
        return try Registrar.register((actor_type,initial_state),name: name)
    }
    public static let  initialize_state:(Any?)->Any? = {initial_data in
        initial_data
    }
    public static let unlink:(String)->Void = { name in
        Registrar.remove(name)
    }
    //the value of handle_event_cast is the updated state
    public static let  cast:(String,Any)throws->Void = {(name,message) in
        guard let PID = Registrar.instance.OTPActorsRegisteredByName[name] else{
            return
        }
        try gen_statem.pid_cast(PID,message)
    }
    public static let pid_cast:(Pid,Any)throws->Void = {(PID,current_message) in
        //if the pid hasn't been registered correctly, do nothing.
        guard let (type,stored_state) = Registrar.instance.OTPActorsRegisteredByPid[PID] else{
            throw SwErlError.notOTPProcess
        }
        
        //this function only works on enums with the statem behavior.
        //if the type is anything except a statem_behavior, do nothing.
        guard let statem = type as? statem_behavior else{
            throw SwErlError.notStatem_behavior
        }
        //state machines always have a stored state.
        //if this one doesn't, do nothing.
        guard let state = stored_state else{
            throw SwErlError.statem_behaviorWithoutState
        }
        let updated_state = statem.handle_event_cast(message: current_message, current_state: state)
        Registrar.instance.OTPActorsRegisteredByPid.updateValue((statem,updated_state), forKey: PID)
    }
}

