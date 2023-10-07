
To spawn most swerl processes, we simply provide spawn a closure. Any time a message is sent to that process, the closure will execute. These closures must have two arguments. The first is the PID of the process associated with the closure, the second is the message provided by the caller. No need to worry about providing procPid, SwErl does that automatically.

Once you have a process you pass it messages with the send operator: `!` .

Because messages can be any type, you will often need to cast message to expected types.

```swift
let myMessage = "Some message, any type is fine!"

let myProcess = try spawn{(procPid, message) in
	switch message {
		case let message as String :
			// The below simply demonstrating that the message argument is what's on the
			// RHS of the send operator. This assert throws if you pass in a
			// different message.
			assert(message == myMessage, "Did you pass in a different message?")
		default : 
			break
	}
}
myProcess ! myMessage
```

Processes can also be registered with names, which can then be used instead of the pid variable as a string literal in source code. If you're familiar with Erlang, these string literals are serving the roll of atoms.

```swift
_ = try spawn(name: "my_process"){(procPid, message) in
    print(message)
}

"my_process" ! "Hi there."
```

Message passing like this is unidirectional. The caller does not wait for a response before continuing, and does not receive a promise or a handle or anything of the sort. Once a message is sent, it is completely in the domain of the callee. If you want to get a response to your message, you'll have to provide a return address.

```swift
// This example is quite contrived, your architecture will often look quite different.

_ = try spawn(name: "replier"){(procPid, message) in
    switch message {
        case let (pid, str) as (Pid, String) :
            pid ! "\(procPid) recieved the following message: \(str)"
        case let str as String :
            print("no way to reply to message \(str)")
        default:
            break
    }
}

_ = try spawn(name: "myProcess"){(procPid, message) in
    switch message {
        case let str as String where str == "start":
            // BUG THIS IS NOT HOW TO PATTERN MATCH IN THIS LANGUAGE
            // MUST FIND HOW TO DO THIS WITHOUT NESTING
            "replier" ! (procPid, "first message!")
        default :
            break
    }
}

"myProcess" ! "start"
```

#### user I/O
SwErl processes are implemented using a background dispatch queue by default. You can easily create a process which runs on the main thread for IO operations, however:

```swift
let ioProcess = try spawn(queueToUse: DispatchQueue.main){
	(procPid, message) in 
		//Do something Silly!
		print(message)
		// Do some UI things.
    }

dispatchMain()
```


```mermaid

```