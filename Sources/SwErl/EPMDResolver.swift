////
////  EPMDResolver.swift
////
////
////Copyright (c) 2023 Lee Barney
////
////Permission is hereby granted, free of charge, to any person obtaining a copy
////of this software and associated documentation files (the "Software"), to deal
////in the Software without restriction, including without limitation the rights
////to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
////copies of the Software, and to permit persons to whom the Software is
////furnished to do so, subject to the following conditions:
////
////The above copyright notice and this permission notice shall be included in all
////copies or substantial portions of the Software.
////
////THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
////IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
////FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
////AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
////LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
////OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
////SOFTWARE.
////
////  Created by Lee Barney on 10/11/23.
////
//
//import Foundation
//import Network
//
//
//enum EPMDResolver:statem_behavior{
//    
//    ///
//    ///API Funcs
//    ///
//    static func completeInfoTransfer(connectionInfo:[String:Any]){
//        
//    }
//    
//    
//    ///
//    ///Required Hooks
//    ///
//    ///
//    static func handleCast(message: SwErlMessage, current_state: SwErlState) -> SwErlState? {
//        nil
//    }
//    
//    static func handleCall(message: SwErlMessage, current_state: SwErlState) -> (SwErlResponse, SwErlState) {
//        ((SwErlPassed.ok,3),3)//placeholder
//    }
//    
//    static func notify(PID: Pid, message: Any) {
////TODO: is there some behavior here that needs to be added?
//    }
//    static func initializeState(initialData: Any) throws -> Any {
//        initialData
//    }
//    
//    static func unlinked(reason: String, current_state: Any) {
//        
//    }
//    
//}
