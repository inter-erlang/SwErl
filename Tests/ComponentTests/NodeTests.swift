//
//  NodeTests.swift
//  
//
//  Created by Barney, Lee on 5/3/24.
//

import XCTest
import Logging
import SystemConfiguration
@testable import SwErl

func getLocalHostName() -> String {
    // Buffer to hold the hostname
    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

    // Get the hostname using POSIX function
    gethostname(&hostname, hostname.count)

    // Convert C-style string to Swift String
    return String(cString: hostname)
}
final class NodeTests: XCTestCase {
    
    func testReceiver() throws{
        var logger = Logger(label: "epmdLogger")
        logger.logLevel = .trace
        startEPMD(logger:logger)//use defaults
        var nodeLogger = Logger(label: "nodeLogger")
        nodeLogger.logLevel = .trace
        startReceiver(name: "bob@\(getLocalHostName()).local", cookie: "cook",logger: nodeLogger)
        RunLoop.current.run()
    }
    func testLocalNetADMNames() throws{
        startEPMD()//use defaults
        startReceiver(name: "bob)", cookie: "cook")
        startReceiver(name: "fred)", cookie: "cook")
        startReceiver(name: "sue)", cookie: "cook")
        print(NetADM.names()!)
        RunLoop.current.run()
    }

}
