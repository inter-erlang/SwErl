//
//  notifyTests.swift
//
//
//  Created by Sylvia Deal on 2/18/24.
//

import Foundation
import XCTest
@testable import SwErl

final class NotifyTests : XCTestCase {
    let invertedExpectation = XCTestExpectation(description: "process recieved message")
    override func setUp() {
        resetRegistryAndPIDCounter()
        invertedExpectation.isInverted = true
    }
    override func tearDown() {
        resetRegistryAndPIDCounter()
    }
    /// description: GenServer.notify() should fail if an extant non-genserver process is provided
    func notifyNonGenServer() {
        _ = try! spawn(initialState: invertedExpectation){ _, invertedExpectation, _ in
            self.invertedExpectation.fulfill()
            return (self.invertedExpectation, self.invertedExpectation)
        }
        wait(for: [invertedExpectation], timeout: 4)
    }
}
