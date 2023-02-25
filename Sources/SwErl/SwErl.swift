//
//  SwErl.swift
//
//
//  Created by Lee Barney on 2/24/23.
//

import Foundation



/// <#Description#>
enum SwErlError: Error {
    case processAlreadyRegistered//there is a process currently registered with that name
    case missingRegistry
}


func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),function:@escaping @Sendable(UUID,Any)->Void)throws -> UUID {
    guard var registry = registry else{
        throw SwErlError.missingRegistry
    }
    var PID = UUID()
    PID = try registry.register(SwErlProcess(registrationID: PID, functionality: function),PID: PID)
    return PID
}
//spawn a process with an initial state.
//The state can be any valid Swift type, a tuple, a list, a dictionary, etc.
///
///The function or lambda passed will be run on a DispatchQueue. The default value is the global dispactch queue with a quality of service of .default.
func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),initialState:Any,function:@escaping @Sendable(UUID,Any,Any)-> Any)throws -> UUID {
    guard var registry = registry else{
        throw SwErlError.missingRegistry
    }
    var PID = UUID()
    PID = try registry.register(SwErlProcess(registeredPid: PID, initialState: initialState, functionality: function), PID: PID)
    return PID
}


func startLocalRegistry(){
    registry = Registrar()
}

//If a stateful process has nil as it's state, the stateful
//lambda will be passed an empty tuple as the state to use.
infix operator ! : ComparisonPrecedence
extension UUID{
    static func !( lhs: UUID, rhs: Any) {
        guard let registry = registry else{
            NSLog("no registry started")
            return
        }
        if var process = registry.getProcess(forID: lhs){
            if let statefulClosure = process.statefulLambda{
                do{
                    process.state = try process.queue.sync(execute:{()throws->Any in
                        return statefulClosure(process.registeredPid,process.state!,rhs)
                    })
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
}



internal struct SwErlProcess{
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
         registeredPid:UUID,
         initialState:Any,
         functionality: @escaping @Sendable (UUID,Any,Any) -> Any) throws {//the returned value is used as the next state.
        self.queue = queueToUse
        self.statefulLambda = functionality
        self.state = initialState
        self.registeredPid = registeredPid
        
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

internal struct Registrar{
    var registeredProcesses:[UUID:SwErlProcess] = [:]
    mutating func register(_ toBeAdded:SwErlProcess, PID:UUID)throws -> UUID{
        guard self.getProcess(forID: PID) == nil else{
            throw SwErlError.processAlreadyRegistered
        }
        registeredProcesses.updateValue(toBeAdded, forKey: PID)
        return PID
    }
    
    mutating func remove(_ registrationID:UUID){
        registeredProcesses.removeValue(forKey: registrationID)
    }
    func getProcess(forID:UUID)->SwErlProcess?{
        return registeredProcesses[forID]
    }
    func getAllPIDs()->Dictionary<UUID, SwErlProcess>.Keys{
        return registeredProcesses.keys
    }
}

///
///here is the single instance of Registrar that should be created.
///

internal var registry:Registrar? = nil

internal let statefulProcessDispatchQueue = DispatchQueue(label: "statefulDispatchQueue",qos: .default)

