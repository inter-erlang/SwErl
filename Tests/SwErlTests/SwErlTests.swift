import XCTest
@testable import SwErl
final class SwErlTests: XCTestCase {
    
    override func setUp() {
        
        // This is the setUp() instance method.
        // XCTest calls it before each test method.
        // Set up any synchronous per-test state here.
        Registrar.instance.registeredProcesses = [:]
     }
    
    override func tearDown() {
        // This is the tearDown() instance method.
        // XCTest calls it after each test method.
        // Perform any synchronous per-test cleanup here.
        Registrar.instance.registeredProcesses = [:]
     }
    
    
    func testHappyPathSpawnStateless() throws {
        let Pid = try spawn{(PID, message) in
            print("hello \(message)")
            return
        }
        print("\(Registrar.instance.registeredProcesses.count)")
        XCTAssertNotNil(Pid)
        XCTAssertEqual(1,Registrar.instance.registeredProcesses.count)
    }
    
    
    func testHappyPathSpawnStateful() throws {
        let Pid = try? spawn(initialState: 3){(procName, message,state) in
            return (true,5)
        }
        XCTAssertNotNil(Pid)
        XCTAssertEqual(1,Registrar.instance.registeredProcesses.count)
        
    }
    
    func testSendMessageToStatelessProcess() throws {
        let anID = UUID()
        
        let stateless = try SwErlProcess(registrationID: anID){(name, message) in
            return
        }
        XCTAssertNoThrow(try Registrar.register(stateless, PID: anID))
        XCTAssertNoThrow(anID ! "hello")
        XCTAssertNotNil(Registrar.instance.registeredProcesses[anID])
        
        let stopperID = UUID()
        let stopper = try SwErlProcess(registrationID: stopperID){(name, message) in
            return
        }
        XCTAssertNoThrow(try Registrar.register(stopper, PID: stopperID))
        XCTAssertNoThrow(stopperID ! "hello")
        
        XCTAssertNotNil(Registrar.instance.registeredProcesses[stopperID])
        XCTAssertEqual(2, Registrar.instance.registeredProcesses.count)
    }
    
    func testStatelessSwerlProcessWithDefaults() throws {
        let bingo = UUID()
        let stateless = try SwErlProcess(registrationID: bingo){(name, message) in
            return
        }
        XCTAssertNil(stateless.statefulLambda)
        XCTAssertNil(stateless.state)
        XCTAssertEqual(stateless.queue, DispatchQueue.global())
        XCTAssertEqual(stateless.registeredPid, bingo)
        XCTAssertNotNil(stateless.statelessLambda)
        XCTAssertNoThrow(stateless.statelessLambda!(bingo,3))
    }
    
    func testStatelessSwerlProcessNoDefaults() throws {
        let mainBingo = UUID()
        let stateless = try SwErlProcess(queueToUse:DispatchQueue.main, registrationID: mainBingo){(name, message) in
            return
        }
        XCTAssertNil(stateless.statefulLambda)
        XCTAssertNil(stateless.state)
        XCTAssertEqual(stateless.queue, DispatchQueue.main)
        XCTAssertEqual(stateless.registeredPid, mainBingo)
        XCTAssertNotNil(stateless.statelessLambda)
        XCTAssertNoThrow(stateless.statelessLambda!(mainBingo,3))
    }
    
    func testStatefulSwerlProcessWithDefaults() throws {
        let hasState = UUID()
        let stateful:SwErlProcess = try! SwErlProcess(registeredPid: hasState,initialState: ["eggs","flour"]){(procName, message ,state) in
            var updatedState:[String] = state as![String]
            updatedState.append(message as! String)
            return (true,updatedState)
        }
        XCTAssertNil(stateful.statelessLambda)
        XCTAssertNotNil(stateful.state)
         XCTAssertTrue(["eggs","flour"] == stateful.state as! [String])
        XCTAssertEqual(stateful.queue, statefulProcessDispatchQueue)
        XCTAssertEqual(stateful.registeredPid, hasState)
        XCTAssertNotNil(stateful.statefulLambda)
        XCTAssertTrue(stateful.statefulLambda!(hasState,"butter",["salt","water"]) as!(Bool,[String]) == (true,["salt","water","butter"]))
    }
    
    func testStatefulSwerlProcessNoDefaults() throws {
        let hasState = UUID()
        let stateful:SwErlProcess = try! SwErlProcess(queueToUse:DispatchQueue.main,registeredPid: hasState,initialState: ["eggs","flour"]){(procName, message ,state) in
                var updatedState:[String] = state as![String]
                updatedState.append(message as! String)
                return (true,updatedState)
            }
        XCTAssertNil(stateful.statelessLambda)
        XCTAssertNotNil(stateful.state)
         XCTAssertTrue(["eggs","flour"] == stateful.state as! [String])
        XCTAssertEqual(stateful.queue, DispatchQueue.main)
        XCTAssertEqual(stateful.registeredPid, hasState)
        XCTAssertNotNil(stateful.statefulLambda)
        XCTAssertTrue(stateful.statefulLambda!(hasState,"butter",["salt","water"]) as!(Bool,[String]) == (true,["salt","water","butter"]))
    }
    
    func testSwErlRegistry() throws{
        let first = UUID()
        let second = UUID()
        let third = UUID()
        XCTAssertEqual(Registrar.instance.registeredProcesses.count, 0)
        let firstProc = try SwErlProcess(registrationID: first){(procName, message) in
            return
        }
        let secondProc = try SwErlProcess(registrationID: second){(procName, message) in
            return
        }
        let thirdProc = try SwErlProcess(registrationID: third){(procName, message) in
            return
        }
        XCTAssertNil(Registrar.instance.registeredProcesses[first])
        XCTAssertNil(Registrar.instance.registeredProcesses[second])
        XCTAssertNil(Registrar.instance.registeredProcesses[third])
        
        XCTAssertNoThrow(try Registrar.register(firstProc, PID: first))
        XCTAssertNoThrow(try Registrar.register(secondProc, PID: second))
        XCTAssertNoThrow(try Registrar.register(thirdProc, PID: third))
        
        
        XCTAssertNotNil(Registrar.instance.registeredProcesses[first])
        XCTAssertNotNil(Registrar.instance.registeredProcesses[second])
        XCTAssertNotNil(Registrar.instance.registeredProcesses[third])
        XCTAssertEqual(3, Registrar.instance.registeredProcesses.count)
        
        
        XCTAssertThrowsError(try Registrar.register(thirdProc, PID: third))
        
        XCTAssertTrue(Registrar.getAllPIDs().contains(first))
        XCTAssertTrue(Registrar.getAllPIDs().contains(second))
        XCTAssertTrue(Registrar.getAllPIDs().contains(third))
        XCTAssertFalse(Registrar.getAllPIDs().contains(UUID()))
        
        XCTAssertNotNil(Registrar.getProcess(forID: second))
        XCTAssertNil(Registrar.getProcess(forID: UUID()))
        
        XCTAssertNoThrow(Registrar.remove(second))
        XCTAssertNil(Registrar.getProcess(forID: second))
        XCTAssertEqual(2, Registrar.getAllPIDs().count)
        
    }
    func testSequencingOfStatefulProcesses()throws{
        
        let pid = try spawn(initialState: ""){(procID,state,message) in
            Thread.sleep(forTimeInterval: message as! Double)
            guard let state = state as? String else{
                return ""
            }
            if state == ""{
                return "\(message as! Double)"
            }
            return "\(state),\(message as! Double)"
        }
        pid ! 5.0
        pid ! 2.0
        pid ! 0.0

        XCTAssertEqual("5.0,2.0,0.0", Registrar.getProcess(forID: pid)?.state as! String)
    }
    
    @available(macOS 13.0, *)
    func testSizeAndSpeed() throws{
        
        print("\n\n\n!!!!!!!!!!!!!!!!!!! \nsize of SwErlProcess: \(MemoryLayout<SwErlProcess>.size ) bytes")
        
        let stateless = {@Sendable(procName:UUID, message:Any) in
            return
        }
        let stateful = {@Sendable (pid:UUID,state:Any,message:Any)->Any in
            return 7
        }
        let timer = ContinuousClock()
        let count:Int64 = 1000000
        var time = try timer.measure{
            for _ in 0..<count{
                _ = try spawn(function: stateless)
            }
        }
        print("stateless spawning took \(time.components.attoseconds/count) attoseconds per instantiation")
        
        time = try timer.measure{
            for _ in 0..<count{
                _ = try spawn(initialState: 7, function: stateful)
            }
        }
        print("stateful spawning took \(time.components.attoseconds/count) attoseconds per instantiation\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        Registrar.instance.registeredProcesses = [:]//clear the million registered processes
        print("!!!!!!!!!!!!!!!!!!! \n Sending \(count) messages to stateful process")
        var Pid = try spawn(initialState: 7, function: stateful)
        time = timer.measure{
            for _ in 0..<count{
                Pid ! 3
            }
        }
        print(" Stateful message passing took \(time.components.attoseconds/count) attoseconds per message sent\n!!!!!!!!!!!!!!!!!!!\n\n\n")
        
        print("!!!!!!!!!!!!!!!!!!! \n Sending \(count) messages to stateless process")
        Pid = try spawn(function: stateless)
        time = timer.measure{
            for _ in 0..<count{
                Pid ! 3
            }
        }
        print(" Stateless message passing took \(time.components.attoseconds/count) attoseconds per message sent\n!!!!!!!!!!!!!!!!!!!\n\n\n")
    }
}
