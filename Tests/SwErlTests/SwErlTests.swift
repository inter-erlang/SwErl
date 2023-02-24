import XCTest
@testable import SwErl

final class SwErlTests: XCTestCase {
    
    override func setUp() {
        // This is the setUp() instance method.
        // XCTest calls it before each test method.
        // Set up any synchronous per-test state here.
        registry = Registrar()
        for key in registry!.getAllPIDs(){
            registry!.remove(key)
        }
     }
    
    override func tearDown() {
        // This is the tearDown() instance method.
        // XCTest calls it after each test method.
        // Perform any synchronous per-test cleanup here.
        for key in registry!.getAllPIDs(){
            registry!.remove(key)
        }
        registry = nil
     }
    
    
    func testHappyPathSpawnStateless() throws {
        let Pid = try? spawn{(PID, message) in
            return true
        }
        XCTAssertNotNil(Pid)
        
    }
    
    
    func testHappyPathSpawnStateful() throws {
        let Pid = try? spawn(initialState: 3){(procName, message,state) in
            return (true,5)
        }
        XCTAssertNotNil(Pid)
        
    }
    
    func testSendMessage() throws {
        let anID = UUID()
        
        let stateless = try SwErlProcess(registrationID: anID){(name, message) in
            return false
        }
        XCTAssertNoThrow(try registry!.register(stateless, PID: anID))
        XCTAssertNoThrow(anID ! "hello")
        XCTAssertNotNil(registry!.registeredProcesses[anID])
        
        let stopperID = UUID()
        let stopper = try SwErlProcess(registrationID: stopperID){(name, message) in
            return true
        }
        XCTAssertNoThrow(try registry!.register(stopper, PID: stopperID))
        XCTAssertNoThrow(stopperID ! "hello")
        
        XCTAssertNotNil(registry!.registeredProcesses[stopperID])
    }
    
    func testStatelessSwerlProcessWithDefaults() throws {
        let bingo = UUID()
        let stateless = try SwErlProcess(registrationID: bingo){(name, message) in
            return true
        }
        XCTAssertNil(stateless.statefulLambda)
        XCTAssertNil(stateless.state)
        XCTAssertEqual(stateless.queue, DispatchQueue.global())
        XCTAssertEqual(stateless.registeredPid, bingo)
        XCTAssertNotNil(stateless.statelessLambda)
        XCTAssertTrue(stateless.statelessLambda!(bingo,3))
    }
    func testThrowingStatelessSwerlProcessWithDefaults() throws {
        let bingo = UUID()
        let stateless = try SwErlProcess(registrationID: bingo){(name, message) throws in
            if message as! Int == 4{
                throw SwErlError.missingRegistry
            }
            return true
        }
        XCTAssertNil(stateless.statelessLambda)
        XCTAssertNil(stateless.state)
        XCTAssertEqual(stateless.queue, DispatchQueue.global())
        XCTAssertEqual(stateless.registeredPid, bingo)
        XCTAssertNotNil(stateless.throwingStatelessLambda)
        XCTAssertTrue(try stateless.throwingStatelessLambda!(bingo,3))
        XCTAssertThrowsError(try stateless.throwingStatelessLambda!(bingo,4))
    }
    
    func testStatelessSwerlProcessNoDefaults() throws {
        let mainBingo = UUID()
        let stateless = try SwErlProcess(queueToUse:DispatchQueue.main, registrationID: mainBingo){(name, message) in
            return false
        }
        XCTAssertNil(stateless.statefulLambda)
        XCTAssertNil(stateless.state)
        XCTAssertEqual(stateless.queue, DispatchQueue.main)
        XCTAssertEqual(stateless.registeredPid, mainBingo)
        XCTAssertNotNil(stateless.statelessLambda)
        XCTAssertFalse(stateless.statelessLambda!(mainBingo,3))
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
        XCTAssertEqual(stateful.queue, DispatchQueue.global())
        XCTAssertEqual(stateful.registeredPid, hasState)
        XCTAssertNotNil(stateful.statefulLambda)
        XCTAssertTrue(stateful.statefulLambda!(hasState,"butter",["salt","water"]) as!(Bool,[String]) == (true,["salt","water","butter"]))
    }
    func testThrowingStatefulSwerlProcessWithDefaults() throws {
        let hasState = UUID()
        let stateful:SwErlProcess = try! SwErlProcess(registeredPid: hasState,initialState: ["eggs","flour"]){(procName, message ,state) throws in
            if message as! String == "oops"{
                throw SwErlError.missingRegistry
            }
            var updatedState:[String] = state as![String]
            updatedState.append(message as! String)
            return (true,updatedState)
        }
        XCTAssertNil(stateful.statefulLambda)
        XCTAssertNotNil(stateful.state)
         XCTAssertTrue(["eggs","flour"] == stateful.state as! [String])
        XCTAssertEqual(stateful.queue, DispatchQueue.global())
        XCTAssertEqual(stateful.registeredPid, hasState)
        XCTAssertNotNil(stateful.throwingStatefulLambda)
        XCTAssertTrue(try stateful.throwingStatefulLambda!(hasState,"butter",["salt","water"]) as!(Bool,[String]) == (true,["salt","water","butter"]))
        XCTAssertThrowsError(try stateful.throwingStatefulLambda!(hasState,"oops",["salt","water"]) as!(Bool,[String]) == (true,["salt","water","butter"]))
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
    
    func testRegistry() throws{
        let first = UUID()
        let second = UUID()
        let third = UUID()
        XCTAssertEqual(registry!.registeredProcesses.count, 0)
        let firstProc = try SwErlProcess(registrationID: first){(procName, message) in
            return true
        }
        let secondProc = try SwErlProcess(registrationID: second){(procName, message) in
            return true
        }
        let thirdProc = try SwErlProcess(registrationID: third){(procName, message) in
            return true
        }
        XCTAssertNil(registry!.registeredProcesses[first])
        XCTAssertNil(registry!.registeredProcesses[second])
        XCTAssertNil(registry!.registeredProcesses[third])
        
        XCTAssertNoThrow(try registry!.register(firstProc, PID: first))
        XCTAssertNoThrow(try registry!.register(secondProc, PID: second))
        XCTAssertNoThrow(try registry!.register(thirdProc, PID: third))
        
        
        XCTAssertNotNil(registry!.registeredProcesses[first])
        XCTAssertNotNil(registry!.registeredProcesses[second])
        XCTAssertNotNil(registry!.registeredProcesses[third])
        
        
        XCTAssertThrowsError(try registry!.register(thirdProc, PID: third))
        
        XCTAssertTrue(registry!.getAllPIDs().contains(first))
        XCTAssertTrue(registry!.getAllPIDs().contains(second))
        XCTAssertTrue(registry!.getAllPIDs().contains(third))
        XCTAssertFalse(registry!.getAllPIDs().contains(UUID()))
        
        XCTAssertNotNil(registry!.getProcess(forID: second))
        XCTAssertNil(registry!.getProcess(forID: UUID()))
        
        XCTAssertNoThrow(registry!.remove(second))
        XCTAssertNil(registry!.getProcess(forID: second))
        XCTAssertEqual(2, registry!.getAllPIDs().count)
    }
}
