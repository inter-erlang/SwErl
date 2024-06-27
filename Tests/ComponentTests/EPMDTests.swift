import XCTest
import Logging
import Network
import Foundation
@testable import SwErl

final class EPMDTests: XCTestCase {
    
    //this test is used to run the EPMD so other nodes can exercise it.
    func testEPMDKill() throws{

        var logger = Logger(label: "EPMDLog")
        logger.logLevel = .trace
        logger.trace("working")
        let anExpectation = XCTestExpectation(description: "killed")
        EPMD.start(logger:logger){
            DispatchQueue.global().async {
                let port: UInt16 = 4369//EPMD default port
                let killBytes:[UInt8] = [1,107]
                mimicNodeCall(port: port, data: Data(killBytes)) { receivedData in
                    if let data = receivedData, let responseString = String(data: data, encoding: .utf8) {
                        XCTAssertEqual(responseString, "OK")
                        anExpectation.fulfill()
                    } else {
                        XCTFail()
                    }
                }
            }
        }
        wait(for: [anExpectation], timeout: 2.0)
    }
    
    func testPortPlease() throws{
        let logger:Logger? = nil
//        var logger = Logger(label: "PortPleaseLog")
//        logger.logLevel = .trace
        
        //startup a named Erlang shell on some machine before running this test.
        guard let (Port,Version) = EPMD.portPlease(name: "joe", host: "testing.domain", logger: logger) else{
            XCTFail()
            return
        }
        XCTAssertTrue(Port > 0)
        XCTAssertTrue(Version == 6)
        
        XCTAssertNil(EPMD.portPlease(name: "invalid_name", host: "22STC320G180886.local", logger: logger))
        XCTAssertNil(EPMD.portPlease(name: "joe", host: "invalid_host", logger: logger))
        XCTAssertNil(EPMD.portPlease(name: "invalid_name", host: "invalid_host", logger: logger))
        
    }
    
    func testNoEPMDRunning() throws{
        XCTAssertNil(EPMD.portPlease(name: "joe", host: "testing.domain", logger: nil))
    }
}

/// Mimics an Erlang node call by sending data to a specified port and receiving a response.
///
/// This function establishes a TCP connection to the specified port on the localhost, sends the provided data,
/// and receives a response. The received data is passed to the completion closure. If an error occurs during
/// the send or receive operations, the connection is canceled, and the completion closure is called with `nil`.
///
/// Example usage:
/// ```swift
/// mimicNodeCall(port: 1234, data: requestData) { responseData in
///     if let data = responseData {
///         print("Received response: \(data)")
///     } else {
///         print("Failed to receive response")
///     }
/// }
/// ```
///
/// - Parameters:
///   - port: The port number to connect to.
///   - data: The data to be sent.
///   - completion: A closure that is called with the received data, or `nil` if none is received.
///
/// - Complexity: O(1) for connection setup, O(n) for sending and receiving data, where n is the length of the data.
///
/// - Author: Lee Barney
/// - Version: 0.9
func mimicNodeCall(port: UInt16, data: Data, completion: @escaping (Data?) -> Void) {
    // Define host
    let host = "localhost"

    // Create the connection
    let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)

    // Set up the state update handler
    connection.stateUpdateHandler = { state in
        switch state {
        case .ready:
            print("Connection ready")
            connection.send(content: data, completion: .contentProcessed { sendError in
                if let error = sendError {
                    print("Send error: \(error)")
                    connection.cancel()
                    completion(nil)
                    return
                }
                print("Data sent")

                // Receive the response
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { receivedData, _, isComplete, error in
                    if let error = error {
                        print("Receive error: \(error)")
                        connection.cancel()
                        completion(nil)
                        return
                    }
                    
                    if isComplete {
                        connection.cancel()
                    }

                    // Pass the received data to the completion closure
                    completion(receivedData)
                }
            })
        case .failed(let error):
            print("Connection failed with error: \(error)")
            connection.cancel()
            completion(nil)
        default:
            break
        }
    }

    // Start the connection
    connection.start(queue: .global())
}
