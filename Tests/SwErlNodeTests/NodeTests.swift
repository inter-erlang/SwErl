//
//  NodeTests.swift
//  
//
//  Created by yenrab on 12/23/23.
//

import XCTest
import Logging
@testable import SwErl
import Network

//final class NodeTests: XCTestCase {
//    
//    override func setUpWithError() throws {
//    }
//    
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//    func testSilly() throws{
//        var logger = Logger(label: "epmdLogger")
//        logger.logLevel = .trace
//        logger.trace("working")
//        startEPMD(logger:logger)//use defaults
//        var nodeLogger = Logger(label: "nodeLogger")
//        nodeLogger.logLevel = .trace
//        startNode(name: "bob@Admins-MacBook-Pro.local", cookie: "cook",logger: nodeLogger)
//        RunLoop.current.run()
//    }
//    func testNames() throws{
//        startEPMD()//use defaults
//        startNode(name: "bob", cookie: "cook")
//        startNode(name: "fred", cookie: "cook")
//        startNode(name: "sue", cookie: "cook")
//        print(NetADM.names()!)
//        RunLoop.current.run()
//    }
//    
//    func testInitializeHandshake() throws{
//        //first, start up an Erlang shell with name 'sue' and cookie 'cook'. Then...
//        
//        var logger = Logger(label: "epmdLogger")
//        logger.logLevel = .trace
//        logger.trace("working")
//        startEPMD(logger:logger)//use defaults
//        var nodeLogger = Logger(label: "nodeLogger")
//        nodeLogger.logLevel = .trace
//        startNode(name: "bob@Admins-MacBook-Pro.local", cookie: "cook",logger: nodeLogger)
//        "toNodeHandshake" ! ("bob@Admins-MacBook-Pro.local","sue@Admins-MacBook-Pro.local","cook")
//        RunLoop.current.run()
//    }
//}


    

