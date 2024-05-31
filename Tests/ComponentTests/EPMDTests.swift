import XCTest
import Logging
@testable import SwErl
import Foundation

final class EPMDTests: XCTestCase {
    
    func testEPMDComponent() throws{

        var logger = Logger(label: "play")
        logger.logLevel = .trace
        logger.trace("working")
        startEPMD(logger:logger)//use defaults
        RunLoop.current.run()
    }
}

