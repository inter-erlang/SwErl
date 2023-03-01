//
//  SwErl.swift
//
//
//  Created by Lee Barney on 2/24/23.
//

import Foundation



/// <#Description#>
public enum SwErlError: Error {
    case processAlreadyRegistered//there is a process currently registered with that name
}



public func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),name:String?=nil,function:@escaping @Sendable(UUID,Any)->Void)throws -> UUID {
    
    let PID = UUID()
    guard let name = name else{
        try Registrar.register(SwErlProcess(registrationID: PID, functionality: function), PID: PID)
        return PID
    }
    try Registrar.register(SwErlProcess(registrationID: PID, functionality: function), name: name, PID: PID)
    return PID
}
//spawn a process with an initial state.
//The state can be any valid Swift type, a tuple, a list, a dictionary, etc.
///
///The function or lambda passed will be run on a DispatchQueue. The default value is the global dispactch queue with a quality of service of .default.
public func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),name:String?=nil,initialState:Any,function:@escaping @Sendable(UUID,Any,Any)-> Any)throws -> UUID {
    let PID = UUID()
    guard let name = name else{
        try Registrar.register(SwErlProcess(registrationID: PID, initialState: initialState, functionality: function), PID: PID)
        return PID
    }
    try Registrar.register(SwErlProcess(registrationID: PID, initialState: initialState, functionality: function), name: name, PID: PID)
    return PID
}


//If a stateful process has nil as it's state, the stateful
//lambda will be passed an empty tuple as the state to use.
infix operator ! : ComparisonPrecedence
extension UUID{
    public static func !( lhs: UUID, rhs: Any) {
        guard var process = Registrar.getProcess(forID: lhs) else{
            return
        }
        if let statefulClosure = process.statefulLambda{
            do{
                process.state = try process.queue.sync(execute:{()throws->Any in
                    return statefulClosure(lhs,process.state!,rhs)
                })
                Registrar.instance.processesRegisteredByPid[lhs] = process
            }
            catch{
                print("PID \(process.registeredPid) threw an error. SwErl processes are to deal with any throws that happen within themselves.")
            }
        
        }
        else{
            if let statelessClosure = process.statelessLambda{
                process.queue.async {
                    statelessClosure(process.registeredPid,rhs)
                    
                }
            }
        }
    }
}

//this is a facade function that uses the pid-based function
extension String{
    public static func !( lhs: String, rhs: Any) {
        guard let pid = Registrar.getPid(forName: lhs) else{
            return
        }
        pid ! rhs
    }
}


struct SwErlProcess{
    var queue: DispatchQueue
    
    ///
    ///this lambda has three parameters, self(the process' registered name), state and message.
    ///
    var statefulLambda:((UUID, Any,Any)->Any)? = nil
    ///
    ///this lambda has two parameters. The first is the registered
    ///name, self, and the second is the message
    var statelessLambda:((UUID, Any)->Void)? = nil
    var state:Any?
    let registeredPid:UUID
    
    init(queueToUse:DispatchQueue = statefulProcessDispatchQueue,
         registrationID:UUID,
         initialState:Any,
         functionality: @escaping @Sendable (UUID,Any,Any) -> Any) throws {//the returned value is used as the next state.
        self.queue = queueToUse
        self.statefulLambda = functionality
        self.state = initialState
        self.registeredPid = registrationID
        
    }
    
    init(queueToUse:DispatchQueue = DispatchQueue.global(),
         registrationID:UUID,
         functionality: @escaping @Sendable (UUID,Any) -> Void ) throws{
        self.queue = queueToUse
        self.statelessLambda = functionality
        self.state = nil
        self.registeredPid = registrationID
    }
}

struct Registrar{
    static var instance:Registrar = Registrar()
    var processesRegisteredByPid:[UUID:SwErlProcess] = [:]
    var processesRegisteredByName:[String:UUID] = [:]
    static func register(_ toBeAdded:SwErlProcess, PID:UUID)throws{
        guard Registrar.getProcess(forID: PID) == nil else{
            throw SwErlError.processAlreadyRegistered
        }
        instance.processesRegisteredByPid.updateValue(toBeAdded, forKey: PID)
    }
    static func register(_ toBeAdded:SwErlProcess, name:String, PID:UUID)throws{
        guard Registrar.getProcess(forID: name) == nil else{
            throw SwErlError.processAlreadyRegistered
        }
        instance.processesRegisteredByPid.updateValue(toBeAdded, forKey: PID)
        instance.processesRegisteredByName.updateValue(PID, forKey: name)
    }
    
    static func remove(_ registrationID:UUID){
        instance.processesRegisteredByPid.removeValue(forKey: registrationID)
    }
    static func getProcess(forID:UUID)->SwErlProcess?{
        return instance.processesRegisteredByPid[forID]
    }
    static func getProcess(forID:String)->SwErlProcess?{
        guard let pid =  instance.processesRegisteredByName[forID] else { return nil
        }
        return instance.processesRegisteredByPid[pid]
    }
    static func getPid(forName:String)->UUID?{
        return instance.processesRegisteredByName[forName]
    }
    static func getAllPIDs()->Dictionary<UUID, SwErlProcess>.Keys{
        return instance.processesRegisteredByPid.keys
    }
    static func getAllNames()->Dictionary<String, UUID>.Keys{
        return instance.processesRegisteredByName.keys
    }
}

///
///here is the single instance of Registrar that should be created.
///



public let statefulProcessDispatchQueue = DispatchQueue(label: "statefulDispatchQueue",qos: .default)

