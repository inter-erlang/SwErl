//
//  SwErl.swift
//
//
//  Created by Lee Barney on 2/24/23.
//

import Foundation

/// <#Description#>
public enum SwErlError: Error {
    /// there is a process currently registered with that name
    case processAlreadyRegistered
}

/// <#Description#>
struct ProcessIDCounter {
    private var queue = DispatchQueue(label: "process.counter")
    var value: UInt32 = 0
    var creation: UInt32 = 0
    
    mutating func next() -> (UInt32, UInt32) {
        queue.sync {
            value = value + 1
            if value == UInt32.max{
                value = 0
                creation = creation + 1
            }
        }
        return (value, creation)
    }
}

/// <#Description#>
var pidCounter = ProcessIDCounter()

/// <#Description#>
public struct Pid: Hashable, Equatable {
    /// <#Description#>
    let id: UInt32
    /// <#Description#>
    let serial: UInt32
    /// <#Description#>
    let creation: UInt32
}
//typealias Pid = (id:UInt32,serial:UInt32,creation:UInt32)

/// <#Description#>
public func spawn(queueToUse: DispatchQueue = DispatchQueue.global(),
                  name: String? = nil,
                  function: @escaping @Sendable(Pid, Any) -> Void) throws -> Pid {
    let (aSerial, aCreation) = pidCounter.next()
    let PID = Pid(id: 0, serial: aSerial, creation: aCreation)
    guard let name = name else{
        try Registrar.register(SwErlProcess(registrationID: PID, functionality: function), PID: PID)
        return PID
    }
    try Registrar.register(SwErlProcess(registrationID: PID, functionality: function), name: name, PID: PID)
    return PID
}
//spawn a process with an initial state.
//The state can be any valid Swift type, a tuple, a list, a dictionary, etc.

/// The function or lambda passed will be run on a DispatchQueue. The default value is the global dispatch queue with a quality of service of .default.
public func spawn(queueToUse: DispatchQueue = DispatchQueue.global(),
                  name: String? = nil,
                  initialState: Any,
                  function: @escaping @Sendable(Pid, Any, Any) -> Any) throws -> Pid {
    let (aSerial,aCreation) = pidCounter.next()
    let PID = Pid(id: 0, serial: aSerial, creation: aCreation)
    guard let name = name else{
        try Registrar.register(SwErlProcess(registrationID: PID, initialState: initialState, functionality: function), PID: PID)
        return PID
    }
    try Registrar.register(SwErlProcess(registrationID: PID, initialState: initialState, functionality: function), name: name, PID: PID)
    return PID
}


// If a stateful process has nil as it's state, the stateful
// lambda will be passed an empty tuple as the state to use.
infix operator ! : ComparisonPrecedence
extension Pid {
    /// <#Description#>
    public static func !(lhs: Pid, rhs: Any) {
        guard var process = Registrar.getProcess(forID: lhs) else {
            return
        }
        if let statefulClosure = process.statefulLambda{
            do {
                process.state = try process.queue.sync { () throws -> Any in
                    statefulClosure(lhs, process.state!, rhs)
                }
                Registrar.instance.processesRegisteredByPid[lhs] = process
            }
            catch {
                print("PID \(process.registeredPid) threw an error. SwErl processes are to deal with any throws that happen within themselves.")
            }
            
        }
        else {
            if let statelessClosure = process.statelessLambda{
                process.queue.async {
                    statelessClosure(process.registeredPid, rhs)
                    
                }
            }
        }
    }
}

extension String {
    /// this is a facade function that uses the pid-based function
    public static func !(lhs: String, rhs: Any) {
        guard let pid = Registrar.getPid(forName: lhs) else {
            return
        }
        pid ! rhs
    }
}


struct SwErlProcess {
    /// <#Description#>
    var queue: DispatchQueue
    
    /// this lambda has three parameters, self(the process' registered name), state and message.
    var statefulLambda: ((Pid, Any, Any) -> Any)? = nil

    /// this lambda has two parameters. The first is the registered
    /// name, self, and the second is the message
    var statelessLambda: ((Pid, Any) -> Void)? = nil
    var state: Any?
    let registeredPid: Pid
    
    
    /// <#Description#>
    /// - Parameter functionality: the returned value is used as the next state.
    init(queueToUse:DispatchQueue = statefulProcessDispatchQueue,
         registrationID: Pid,
         initialState: Any,
         functionality: @escaping @Sendable (Pid, Any, Any) -> Any) throws {
        self.queue = queueToUse
        self.statefulLambda = functionality
        self.state = initialState
        self.registeredPid = registrationID
    }
    
    /// <#Description#>
    init(queueToUse: DispatchQueue = DispatchQueue.global(),
         registrationID: Pid,
         functionality: @escaping @Sendable (Pid,Any) -> Void ) throws {
        self.queue = queueToUse
        self.statelessLambda = functionality
        self.state = nil
        self.registeredPid = registrationID
    }
}

/// <#Description#>
@dynamicMemberLookup
struct Registrar {
    var processesRegisteredByPid: [Pid:SwErlProcess] = [:]
    var processesRegisteredByName: [String:Pid] = [:]
    
    static var instance: Registrar = Registrar()
    
    /// Looks up a PID by its name
    subscript(dynamicMember name: String) -> Pid {
        guard let pid = processesRegisteredByName[name] else {
            fatalError("PID by name: \(name) does not exist")
        }
        return pid
    }
    
    /// <#Description#>
    static func register(_ toBeAdded:SwErlProcess, PID: Pid) throws {
        guard Registrar.getProcess(forID: PID) == nil else {
            throw SwErlError.processAlreadyRegistered
        }
        instance.processesRegisteredByPid.updateValue(toBeAdded, forKey: PID)
    }
    
    /// <#Description#>
    static func register(_ toBeAdded: SwErlProcess, name: String, PID: Pid) throws {
        guard Registrar.getProcess(forID: name) == nil else {
            throw SwErlError.processAlreadyRegistered
        }
        instance.processesRegisteredByPid.updateValue(toBeAdded, forKey: PID)
        instance.processesRegisteredByName.updateValue(PID, forKey: name)
    }
    
    /// <#Description#>
    static func remove(_ registrationID: Pid){
        instance.processesRegisteredByPid.removeValue(forKey: registrationID)
    }
    
    /// <#Description#>
    static func getProcess(forID: Pid) -> SwErlProcess? {
        instance.processesRegisteredByPid[forID]
    }
    
    /// <#Description#>
    static func getProcess(forID: String) -> SwErlProcess? {
        guard let pid = instance.processesRegisteredByName[forID] else {
            return nil
        }
        return instance.processesRegisteredByPid[pid]
    }
    
    /// <#Description#>
    static func getPid(forName: String) -> Pid? {
        instance.processesRegisteredByName[forName]
    }
    
    /// <#Description#>
    static func getAllPIDs() -> Dictionary<Pid, SwErlProcess>.Keys {
        instance.processesRegisteredByPid.keys
    }
    
    /// <#Description#>
    static func getAllNames() -> Dictionary<String, Pid>.Keys {
        instance.processesRegisteredByName.keys
    }
}

///
/// here is the single instance of Registrar that should be created.
///

/// <#Description#>
public let statefulProcessDispatchQueue = DispatchQueue(label: "statefulDispatchQueue", qos: .default)

