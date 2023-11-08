//
//  SwErl.swift
//
//MIT License
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
//  Created by Lee Barney on 2/24/23.
//

import Foundation


/**
  Errors thrown within SwErl
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
public enum SwErlError: Error {
    case processAlreadyLinked//there is a process currently registered with that name
    case nameNotRegistered
    case notRegisteredByPid
    case notStatem_behavior
    case notEventHandler_behavior
    case notEventManager_behavior
    case statem_behaviorWithoutState
    case invalidCommand
    case invalidState
}
/**
 This struct implements a thread-safe counter for asyncronous process id's.
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
struct ProcessIDCounter {
    private var counterQueue = DispatchQueue(label: "process.counter")
    var value: UInt32 = 0
    var creation: UInt32 = 0
    /**
     This function is used to increment the count of the process ID's in a thread-safe manner. It executes syncronously on a DispatchQueue that only it uses.
       - Parameters: none
      - Value: a tuple consisting of 2 unsigned 32 bit itegers. For each of the second values, UInt32.MAX of the first numbers is used. This allows each application using SwErl to have UInt32.MAX \* UInt32.MAX total registered SwErl processes.
      - Author:
        Lee S. Barney
      - Version:
        0.1
     */
    mutating func next()->(UInt32,UInt32) {
        counterQueue.sync {
            value = value + 1
            if value == UInt32.max{
                value = 0
                creation = creation + 1
            }
        }
        return (value,creation)
    }
}
//The global thread-safe process counter for the entire application
var pidCounter = ProcessIDCounter()

/**
 This struct implements an Erlang-style process ID. The _id_ element is a unique incremented identifier for the node the process runs on. On the node indicated by _id_, _serial_ is the unique, incremented identifier for the process on that node. Each time _serial_ on the indicated node exceeds UInt32.MAX, the _creation_ counter increments by 1.
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
public struct Pid:Hashable,Equatable {
    let id:UInt32
    let serial:UInt32
    let creation:UInt32
    
    static func to_string(_ PID:Pid) -> String {
        "\(PID.id),\(PID.serial),\(PID.creation)"
    }
}
/**
 This enum contains the two locations a process where the process is linked. If the process is accessed only within the node where it is linked, then _local_ is the appropriate linking indicator. If the process is available to be used from other nodes, _global_ is the appropriate linking indicator.
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
enum RegistrationType{
    case local
    case global
}

/**
 This enum is used in the values of some SwErl functions.
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
public enum SwErlPassed{
    case ok
    case fail
}

/**
 This function is used to link a unique name to a stateless function or closure that is executed asynchronously. Any DispatchQueue desired for running the function or closure can be passed as the first parameter. The default is the _global_ background queue.
   - Parameters:
    - queueToUse: any DispatchQueue, custom or built-in.   
    - name: a unique string used as an identifier.
    - function: the function or closure to execute using the DispatchQueue
  - Value: a SwErl Pid
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
public func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),name:String?=nil,function:@escaping @Sendable(Pid,Any)->Void)throws -> Pid {
    let (aSerial,aCreation) = pidCounter.next()
    let PID = Pid(id: 0,serial: aSerial,creation: aCreation)
    guard let name = name else{
        try Registrar.link(SwErlProcess(registrationID: PID, functionality: function), PID: PID)
        return PID
    }
    try Registrar.link(SwErlProcess(registrationID: PID, functionality: function), name: name, PID: PID)
    return PID
}
/**
 This function is used to link a unique name to a stateful function or closure that is executed asynchronously. Any DispatchQueue desired for running the function or closure can be passed as the first parameter. The default is the _global_ background queue. The state can be any valid Swift type, a tuple, a list, a dictionary, optional, closure, etc.
   - Parameters:
    - queueToUse: any DispatchQueue, custom or built-in.
    - name: a unique string used as an identifier.
    - function: the function or closure to execute using the DispatchQueue
  - Value: a SwErl Pid
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
public func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),name:String?=nil,initialState:Any,function:@escaping @Sendable(Pid,Any,Any)-> Any)throws -> Pid {
    let (aSerial,aCreation) = pidCounter.next()
    let PID = Pid(id: 0, serial: aSerial, creation: aCreation)
    guard let name = name else{
        try Registrar.link(SwErlProcess(registrationID: PID, initialState: initialState, functionality: function), PID: PID)
        return PID
    }
    try Registrar.link(SwErlProcess(registrationID: PID, initialState: initialState, functionality: function), name: name, PID: PID)
    return PID
}



/**
 An infix operator used to send messages to an already spawned process. The left-hand side can be either a SwErl Pid or the unique string previously passed as an identifier to the spawn function.
  - Value: none
  - Note:If a stateful process has nil as it's state, the stateful lambda will be passed an empty tuple as the state to use.
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
infix operator ! : LogicalConjunctionPrecedence//this is left associative. That's why it has been chosen.
extension Pid{
    
    
    @discardableResult public static func !( lhs: Pid, rhs: Any)->(SwErlPassed,Any?){
        //!!!!!!!!!!!!!!!! modify this so it can work with a gen_server or a state_machine or an event manager.
        if let (type,_,_) = Registrar.instance.OTPActorsLinkedToPid[lhs] as? (Messageable.Type,DispatchQueue,Any?){
            do{
                try type.notify(PID: lhs, message: rhs)
            }
            catch{
                return (SwErlPassed.fail,error)
            }
            return (SwErlPassed.ok,nil)
        }
        guard let process = Registrar.getProcess(forID: lhs) else{
            return (SwErlPassed.fail,SwErlError.notRegisteredByPid)
        }
        do{
            try Registrar.executeProcess(process, lhs, rhs)
        }
        catch{
            return (SwErlPassed.fail,error)
        }
        return (SwErlPassed.ok,nil)
    }
}

//this is a facade function that uses the pid-based function
extension String{
    @discardableResult public static func !( lhs: String, rhs: Any)->(SwErlPassed,Any?){
        guard let pid = Registrar.getPid(forName: lhs) else{
            return (SwErlPassed.fail,SwErlError.nameNotRegistered)
        }
        return pid ! rhs
    }
}

/**
 This struct represents a SwErl process.
 
  - Note: Each occurance of this struct is the data and metadata portion of the _modad_ pattern. The struct's metadata consists of a stateless or stateless closure, the queue it is to run on, and it's associated Pid. It's data is its current state if any. The functions that are part of the monad includes the SwErl ! infix operator among others.
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
struct SwErlProcess{
    var queue: DispatchQueue
    
    ///
    ///this lambda has three parameters, self(the process' registered name), state and message.
    ///
    var statefulLambda:((Pid,Any,Any)throws->Any)? = nil
    ///
    ///this lambda has two parameters. The first is the registered
    ///name, self, and the second is the message
    var statelessLambda:((Pid, Any)->Void)? = nil
    var state:Any?
    let registeredPid:Pid
    
    //
    //stateful lambdas have a serial dispatch queue unique to themselves that,
    //by default, feeds the global async dispatch queue. Since there is no
    //serial queue shared by all stateful processes, no process is required to
    //wait for all the other stateful process requests to complete before it can
    //complete. Yet each state is serially maintained.
    init(queueToUse:DispatchQueue = DispatchQueue.global(),
         registrationID:Pid,
         initialState:Any,
         functionality: @escaping @Sendable (Pid,Any,Any)throws -> Any) throws {//the returned value is used as the next state.
        //self.queue = queueToUse
        self.queue = DispatchQueue(label: Pid.to_string(registrationID) ,target: queueToUse)
        self.statefulLambda = functionality
        self.state = initialState
        self.registeredPid = registrationID
        
    }
    
    init(queueToUse:DispatchQueue = DispatchQueue.global(),
         registrationID:Pid,
         functionality: @escaping @Sendable (Pid,Any) -> Void ) throws{
        self.queue = queueToUse
        self.statelessLambda = functionality
        self.state = nil
        self.registeredPid = registrationID
    }
}


// This could have been done with dynamic member lookup.
// I have chosen not to do so for potential slowness due to
// interpretation at runtime rather than at compile time.
/**
 This struct represent retains all mappings of names and Pids to SwErl process.
  - Author:
    Lee S. Barney
  - Version:
    0.1
 */
struct Registrar{
    static var instance:Registrar = Registrar()
    var processesLinkedToPid:[Pid:SwErlProcess] = [:]
    var processesLinkedToName:[String:Pid] = [:]
    var OTPActorsLinkedToPid:[Pid:(OTPActor_behavior.Type,DispatchQueue,Any?)] = [:]
    
    /*
     The Registrar's link functions should only be used from within the spawn function. They should not be called directly.
     */
    static func link(_ toBeAdded:SwErlProcess, PID:Pid)throws{
        guard Registrar.getProcess(forID: PID) == nil else{
            throw SwErlError.processAlreadyLinked
        }
        instance.processesLinkedToPid.updateValue(toBeAdded, forKey: PID)
    }
    static func link(_ toBeAdded:SwErlProcess, name:String, PID:Pid)throws{
        guard Registrar.getProcess(forID: name) == nil else{
            throw SwErlError.processAlreadyLinked
        }
        try Registrar.link(toBeAdded, PID: PID)
        instance.processesLinkedToName.updateValue(PID, forKey: name)
    }
    static func link<T:OTPActor_behavior>(_ toBeAdded:(T.Type,DispatchQueue,Any?), name:String, PID:Pid)throws{
        guard Registrar.getProcess(forID: name) == nil else{
            throw SwErlError.processAlreadyLinked
        }
        instance.OTPActorsLinkedToPid.updateValue(toBeAdded, forKey: PID)
        instance.processesLinkedToName.updateValue(PID, forKey: name)
    }
    /**
     This function is used to remove the link between a Pid and a SwErl process. The process is also removed.
       - Parameters:
        - registrationID: the Pid of the process
      - Value: none
      - Author:
        Lee S. Barney
      - Version:
        0.1
     */
    static func unlink(_ registrationID:Pid){
        instance.processesLinkedToPid.removeValue(forKey: registrationID)
        instance.OTPActorsLinkedToPid.removeValue(forKey: registrationID)
    }
    /**
     This function is used to remove the link between a unique identifier string, aPid, and the SwErl process linked to these identifiers. The process is also removed.
       - Parameters:
        - name: the unique string identifier of the SwErl or OTP process
      - Value: none
      - Author:
        Lee S. Barney
      - Version:
        0.1
     */
    static func unlink(_ name:String){
        guard let PID = instance.processesLinkedToName[name] else{
            return
        }
        instance.processesLinkedToName.removeValue(forKey: name)
        Registrar.unlink(PID)
    }
    /**
     This function provides access to a process by Pid.
       - Parameters:
        - forID: the Pid of the desired process
      - Value: the associated process or _nil_ if there is no process linked to the Pid
      - Author:
        Lee S. Barney
      - Version:
        0.1
     */
    static func getProcess(forID:Pid)->SwErlProcess?{
        return instance.processesLinkedToPid[forID]
    }
    
    /**
     This function provides access to a process by name.
       - Parameters:
        - forID: the unique string identifier of the desired process
      - Value: the associated process or _nil_ if there is no process linked to the identifier
      - Author:
        Lee S. Barney
      - Version:
        0.1
     */
    static func getProcess(forID:String)->SwErlProcess?{
        guard let pid =  instance.processesLinkedToName[forID] else { return nil
        }
        return instance.processesLinkedToPid[pid]
    }
    /**
     This function provides access to a PId linked to a name.
       - Parameters:
        - forName: the unique string identifier of the desired Pid
      - Value: the associated process or _nil_ if there is no Pid linked to the identifier
      - Author:
        Lee S. Barney
      - Version:
        0.1
     */
    static func getPid(forName:String)->Pid?{
        return instance.processesLinkedToName[forName]
    }
    /**
     This function provides a list of all linked Pids.
       - Parameters: none
      - Value: the list of all linked Pids
      - Author:
        Lee S. Barney
      - Version:
        0.1
     */
    static func getAllPIDs()->Dictionary<Pid, SwErlProcess>.Keys{
        return instance.processesLinkedToPid.keys
    }
    /**
     This function provides a list of all unique identifier strings linked to Pids and SwErl or OTP processes.
       - Parameters: none
      - Value: the list of all linked unique identifiers
      - Author:
        Lee S. Barney
      - Version:
        0.1
     */
    static func getAllNames()->Dictionary<String, Pid>.Keys{
        return instance.processesLinkedToName.keys
    }
    static func executeProcess(_ process: SwErlProcess, _ lhs: Pid, _ rhs: Any)throws{
        if let statefulClosure = process.statefulLambda{
            var mutableProcess = process
            mutableProcess.state = try mutableProcess.queue.sync{()throws ->Any in
                try statefulClosure(lhs,mutableProcess.state!,rhs)
            }
            Registrar.instance.processesLinkedToPid[lhs] = mutableProcess
            
        }
        else{
            if let statelessClosure = process.statelessLambda{
                process.queue.async{()->Void in
                    statelessClosure(process.registeredPid,rhs)
                }
            }
        }
    }
}



