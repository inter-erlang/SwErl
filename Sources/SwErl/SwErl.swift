//
//  SwErl.swift
//
//
//  Created by Lee Barney on 2/24/23.
//

import Foundation

enum SwErlProc{
    static let `continue` = false
    static let stop = true
    static let nilMessage:String = "nil"
}

enum SwErlDef{
    case none
}

/// <#Description#>
enum SwErlError: Error {
    case processAlreadyRegistered//there is a process currently registered with that name
    case missingRegistry
}

//spawn a function that has no initial state
//if this is a lambda, the lambda will capture
//any variables from the containing scope.
/// <#Description#>
/// - Parameters:
///   - queueToUse: <#queueToUse description#>
///   - registrationName: the name under which this process is to be registered locally
///   - function: a closure to register by name
/// - Throws: <#description#>
/// - Returns: <#description#>
func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),function:@escaping @Sendable(UUID,Any?)->Bool)throws -> UUID {
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
func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),initialState:Any,function:@escaping @Sendable(UUID,Any?,Any?)-> (Bool,Any))throws -> UUID {
    guard var registry = registry else{
        throw SwErlError.missingRegistry
    }
    var PID = UUID()
    PID = try registry.register(SwErlProcess(registeredPid: PID, initialState: initialState, functionality: function), PID: PID)
    return PID
}

//spawn a function that has no initial state
//if this is a lambda, the lambda will capture
//any variables from the containing scope.
/// <#Description#>
/// - Parameters:
///   - queueToUse: <#queueToUse description#>
///   - registrationName: the name under which this process is to be registered locally
///   - function: a closure to register by name
/// - Throws: <#description#>
/// - Returns: <#description#>
func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),function:@escaping @Sendable(UUID,Any?) throws->Bool)throws -> UUID {
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
func spawn(queueToUse:DispatchQueue = DispatchQueue.global(),initialState:Any,function:@escaping @Sendable(UUID,Any?,Any?) throws -> (Bool,Any))throws -> UUID {
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
        guard var registry = registry else{
            NSLog("no registry started")
            return
        }
        if var process = registry.getProcess(forID: lhs){
            
            process.queue.async {
                
                var shouldStop = SwErlProc.stop
                if let stateful = process.statefulLambda{
                    let (possiblyStop,state) = stateful( process.registeredPid, process.state ?? (),rhs)
                    shouldStop = possiblyStop
                    process.state = state
                }
                else{
                    shouldStop = process.statelessLambda!(process.registeredPid, rhs)
                }
                //Only ephemeral processes would ever be
                //removed from the registrar. These would
                //be an exceptional, not default, behavior.
                if shouldStop == SwErlProc.stop{
                    registry.remove(process.registeredPid)
                }
            }
        }
    }
}



internal struct SwErlProcess{
    var queue: DispatchQueue
    
    ///
    ///this lambda has three parameters, self(the process' registered name), state and message.
    ///It has a value tuple of (should_stop, next_state).
    ///Should_stop is a Bool
    ///
    var statefulLambda:((UUID, Any?,Any?)->(Bool,Any))? = nil
    var throwingStatefulLambda:((UUID, Any?,Any?)throws->(Bool,Any))? = nil
    ///
    ///this lambda has two parameters. The first is the registered
    ///name, self, and the second is the message
    ///It has a value of should_stop that is a Bool.
    var statelessLambda:((UUID, Any?)->Bool)? = nil
    var throwingStatelessLambda:((UUID, Any?)throws->Bool)? = nil
    var state:Any?
    let registeredPid:UUID
    
    init(queueToUse:DispatchQueue = DispatchQueue.global(),
         registeredPid:UUID,
         initialState:Any? = nil,
         functionality: @escaping @Sendable (UUID,Any?,Any?) -> (Bool,Any) ) throws {//the returned value is used as the next state.
        self.queue = queueToUse
        self.statefulLambda = functionality
        self.state = initialState
        self.registeredPid = registeredPid
        
    }
    init(queueToUse:DispatchQueue = DispatchQueue.global(),
         registeredPid:UUID,
         initialState:Any? = nil,
         functionality: @escaping @Sendable (UUID,Any?,Any?) throws -> (Bool,Any) ) throws {//the returned value is used as the next state.
        self.queue = queueToUse
        self.throwingStatefulLambda = functionality
        self.state = initialState
        self.registeredPid = registeredPid
        
    }
    
    init(queueToUse:DispatchQueue = DispatchQueue.global(),
         registrationID:UUID,
         functionality: @escaping @Sendable (UUID,Any?) -> Bool ) throws{
        self.queue = queueToUse
        self.statelessLambda = functionality
        self.state = nil
        self.registeredPid = registrationID
    }
    init(queueToUse:DispatchQueue = DispatchQueue.global(),
         registrationID:UUID,
         functionality: @escaping @Sendable (UUID,Any?) throws -> Bool ) throws{
        self.queue = queueToUse
        self.throwingStatelessLambda = functionality
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



