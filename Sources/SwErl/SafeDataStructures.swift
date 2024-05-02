//
//  SafeDataStructures.swift
//  
//Copyright (c) 2023 Lee Barney
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.
//
//  Created by Lee Barney on 2/26/24.
//



///Documentation within this file was enhanced with the aid of SwiftDoc Builder, an AI-powered documentation assistant available in the GPT Store.

import Foundation
import Logging

/// Defines commands for interacting with a thread-safe dictionary.
///
/// The `SafeDictCommand` enum specifies the set of operations that can be performed on the safe dictionary,
/// allowing for addition, removal, retrieval, and access to keys or values in a thread-safe manner.
///
/// - Cases:
///   - add: Adds a new key-value pair to the dictionary. If the key already exists, the value is updated.
///   - remove: Removes the key-value pair associated with the specified key from the dictionary.
///   - get: Retrieves the value associated with the specified key from the dictionary or nil if none is found.
///   - getKeys: Retrieves all keys from the dictionary.
///   - getValues: Retrieves all values from the dictionary.
///   - getRaw: Retrieves an unsafe copy of the raw dictionary object, including all key-value pairs.
///
/// This enumeration is utilized within the `buildSafe` function to define the type of operation
/// to be executed on the safe dictionary in response to messages received by the SwErl process.
///
/// - Complexity: add - O(1), remove - O(1), get - O(1), getKeys - O(k) where `k` is the number of keys, getValues - O(v) where `v` is the number of values, getRaw - O(1). Swift's 'copy-on-write' behavior allows the return of the raw, underlying dictionary without duplication.
///
/// - Author: Lee Barney
/// - Version: 0.1
public enum SafeDictCommand {
    case add
    case remove
    case get
    case getKeys
    case getValues
    case getRaw
    case clear
}


/// Constructs a thread-safe dictionary with specified initial state and processing logic.
/// The `buildSafe` function initializes a safe dictionary by creating a new SwErl process
/// with specific behaviors for adding, removing, and retrieving values based on commands received.
///
/// Example Safe Dictionary Use: "friends" ! (SafeDictCommand.add,"bob",3)
/// adds the key "bob" and matching value 3 to the 'friends' safe dictionary of type [String,Int].
///
/// - Parameters:
///   - dictionary: The initial state of the dictionary of type `[K: V]`, where `K` is the key type and `V` is the value type.
///   - named: The unique `String` identifier for the process associated with the safe dictionary.
/// - Throws: An error if the process creation encounters issues.
///
/// The safe dictionary supports various SafeDictCommands such as add, remove, get, getKeys, getValues, and getRaw,
/// allowing for dynamic interaction with the dictionary in a thread-safe manner.
///
/// - Complexity: O(1)
///
/// - Author: Lee Barney
/// - Version: 0.1
func buildSafe<K, V>(dictionary: [K: V], named: String) throws {
    try spawnsysf(name: named, initialState: dictionary) { Pid, message, state in
        guard var rawDictionary = state as? [K: V] else {
            return ((SwErlPassed.fail, SwErlError.invalidState), [K: V]())
        }
        var command:SafeDictCommand? = nil
        var key:K? = nil
        var value:V? = nil
        if let (aCommand, aKey, aValue) = message as? (SafeDictCommand, K, V) {
            command = aCommand
            key = aKey
            value = aValue
        }
        else if let (aCommand,aKey) = message as? (SafeDictCommand,K){
            command = aCommand
            key = aKey
        }
        else if let aCommand = message as? SafeDictCommand{
            command = aCommand
        }
        else{
            return ((SwErlPassed.fail, SwErlError.invalidMessage), state)
        }
        guard let command = command else{
            return ((SwErlPassed.fail, SwErlError.invalidMessage), state)
        }
        var returnValue: Any? = "done"
        let success = SwErlPassed.ok
        switch command {
        case SafeDictCommand.add:
            guard let key = key, let value = value else{
                return ((SwErlPassed.fail, SwErlError.invalidMessage), state)
            }
            rawDictionary[key] = value
        case SafeDictCommand.remove:
            guard let key = key else{
                return ((SwErlPassed.fail, SwErlError.invalidMessage), state)
            }
            rawDictionary.removeValue(forKey: key)
        case SafeDictCommand.get:
                guard let key = key else{
                    return ((SwErlPassed.fail, SwErlError.invalidMessage), state)
                }
            returnValue = rawDictionary[key]
        case SafeDictCommand.getKeys:
            returnValue = Array(rawDictionary.keys)
        case SafeDictCommand.getValues:
            returnValue = Array(rawDictionary.values)
        case SafeDictCommand.getRaw:
            returnValue = rawDictionary
        case SafeDictCommand.clear:
            rawDictionary.removeAll()
        }
    
        let result = ((success, returnValue), rawDictionary)
        return result
    }
}

