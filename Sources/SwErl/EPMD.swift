//
//  File.swift
//  
//
//  Created by yenrab on 11/20/23.
//

import Foundation


//
//This is temporary. Replace it with a GenServer
//
struct EPMDRegistrar{
    static var instance:EPMDRegistrar = EPMDRegistrar()
    var processesLinkedToPid:[Pid:SwErlProcess] = [:]
    var processesLinkedToName:[String:Pid] = [:]
    var processStates:[Pid:Any] = [:]
    
    /*
     The EPMD's link functions should only be used from within the spawn function. They should not be called directly.
     */
    static func link(_ toBeAdded:SwErlProcess, PID:Pid)throws{
        guard EPMDRegistrar.getProcess(forID: PID) == nil else{
            throw SwErlError.processAlreadyLinked
        }
        instance.processesLinkedToPid[PID] = toBeAdded
    }
    static func link(_ toBeAdded:SwErlProcess, name:String, PID:Pid)throws{
        guard EPMDRegistrar.getProcess(forID: name) == nil else{
            throw SwErlError.processAlreadyLinked
        }
        try EPMDRegistrar.link(toBeAdded, PID: PID)
        instance.processesLinkedToName[name] = PID
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
        EPMDRegistrar.unlink(PID)
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
    
}
