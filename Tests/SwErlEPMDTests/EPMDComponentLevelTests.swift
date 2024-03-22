//
//  EPMDComponentLevelTests.swift
//
//
//  Created by Barney, Lee on 3/22/24.
//

import XCTest
import Logging
@testable import SwErl

//
// !!!!!!!!!!!!! WARNING !!!!!!!!!!!!!!!!!
// each these tests never exits
// these tests are not intended to be run as a suite
//

final class EPMDComponentLevelTests: XCTestCase {
    
    func testEPMDComponentOnly() throws{
        var logger = Logger(label: "play")
        logger.logLevel = .trace
        logger.trace("working")
        startEPMD(logger:logger)//use defaults
        RunLoop.current.run()
    }
    
}
