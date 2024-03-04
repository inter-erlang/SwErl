# GettingStarted

The most important features of SwErl

## Overview

Most SwErl apps will contain hundreds of independent processes communicating with messages. This will show you how to spawn and message processes, and teach you the basics of how to design and build apps built on processes.


## Processes

To spawn most SwErl processes, we simply provide `spawn()` a closure. Any time a message is sent to that process, the closure will execute. These closures must have two arguments. The first is the PID of the process associated with the closure, the second is the message provided by the caller. No need to worry about providing `pid`, SwErl does that automatically.

Once you have a process you pass it messages with the send operator: `!` .

Because messages can be any type, you will often need to cast message to expected types.

```swift
let myMessage = "Some message, any type is fine!"

let myProcess = try spawnsysf{(pid, message) in
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
_ = try spawnsysf(name: "my_process"){(pid, message) in
    print(message)
}

"my_process" ! "Hi there."
```

Message passing like this is unidirectional. The caller does not wait for a response before continuing, and does not receive a promise or a handle or anything of the sort. Once a message is sent, it is completely in the domain of the callee. If you want to get a response to your message, you'll have to provide a return address.

```swift
// This example is quite contrived, your architecture will often look quite different.

_ = try spawnsysf(name: "replier"){(pid, message) in
    switch message {
        case let (pid, str) as (Pid, String) :
            pid ! "\(procPid) received the following message: \(str)"
        case let str as String :
            print("no way to reply to message \(str)")
        default:
            break
    }
}

_ = try spawnsysf(name: "myProcess"){(pid, message) in
    switch message {
        case let str as String:
            // BUG THIS IS NOT HOW TO PATTERN MATCH IN THIS LANGUAGE
            // MUST FIND HOW TO DO THIS WITHOUT NESTING
            if (str == "start") {
                "replier" ! (procPid, "first message!")
            } else {
                print("A response: \(str)")
            }
        default :
            break
    }
}

"myProcess" ! "start"
```

## User I/O with SwErl
SwErl processes are implemented using the default system-selected global dispatch queue by default. You can easily create a process which runs on the main thread for IO operations, however:

```swift
let ioProcess = try spawnsysf(queueToUse: DispatchQueue.main){
	(procPid, message) in 
		// Do some UI things.
    }
```

The same for any concurrency in swift applies here. The main thread should be reserved for only the highest priority operations, such as those affecting the user interface.

## OTP Behaviors
Generally speaking, these primitives reflect the usage and design of their Erlang counterparts, though with only the most oft-used functionality implemented. If you are unfamiliar with Erlang/OTP, you may find the [Erlang OTP Design Principles Documentation](https://www.erlang.org/doc/design_principles/des_princ) of interest.
Behaviors are implemented as protocols in SwErl. Behaviors are 

### GenServer
GenServers, or Generic Servers are independent processes which act as servers in a client/server relationship. They have all the functionality of a normal SwErl process, including an internal state, with the added ability to accept and respond to synchronous requests via `GenServer.call(...)`. Other processes making a Call to a genServer will hang expecting a response. genServers in SwErl all have a uniform API accessible via `GenServer`. genServers are created by writing a static type conforming to `protocol GenServerBehavior` to establish the functionality of a genServer instance, then instantiated using`GenServer.link().`

To demonstrate, we will make an echo server.
```swift
///
/// echo.swift
/// Created by You, Today!
///

enum echoServer : GenServerBehavior {
//GenServerBehavior enforces five hooks, shown below.

//initialize data is called once on startup. Our simple echo server does not maintain any state, so we will simply leave any argument data as is.
static func initializeData(_ data: Any?) -> Any? {
	return data
}

//terminateCleanup is called once on termination, and would generally be used to clean up any messy resources Swift would be unable to automatically garbage collect. Our server has no such held resources.
static func terminateCleanup(reason: String, data: Any?) {

}

//handleCast is called whenever the server receives a message from another process via GenServer.call() and returns a tuple. the first item in the tuple is the response to the caller, the second is the updated state of the genServer, called data.
//Our echo server will reply with whatever request it receives.
static func handleCall(request: Any, data: Any?) -> (Any,Any) {
	return (request, data)
}

//handleCast is called whenever the server receives a message from another process via GenServer.cast(). Casts are asynchronous messages, the caster cannot receive any reply. the return value is the updated state of the genServer.

// Our echo server is not expecting any such messages, certainly not any that would mutate it's state. In response to a cast, we will do nothing.
static func handleCast(request: Any, data: Any?) -> Any? {
	return data
}

```

Now we register a gen server with these functions, and make a call!
```swift
GenServer.startlink("echo", [])
print(GenServer.call(echo, "hello SwErl!"))
```

```
hello SwErl!
```

Multiple different genServers can be initialized from the same behavior. SwErl ensures multiple local servers cannot share the same name, and automatically ensures unique pids.
### Gen StateM
Event-driven Generic State Machine. Briefly paraphrasing [the erlang design documentation](https://www.erlang.org/doc/design_principles/statem), Event-driven state machines wait for inputs, trigger some action(s) based on its current state and input, then trigger a state transition. Unlike a Gen server, a state machine's state is not arbitrary. state machines have a finite set of programmer defined states and pre-defined transitions between states. The Erlang design documentation provides several good heuristics for when a GenStateM should be used over a GenServer, one more is provided here: When the allowed functionality of a module varies dramatically depending on previous events.
 genServer. By way of example, an ATM can be effectively modeled as a state machine with two states. Of course, this example glosses over many security features the machine would need and is presented only for demonstrating the features of SwErl and Erlang.

![a simple ATM modeled as a state machine](StateMDesign)

If such a state machine were to receive a request to dispense cash when in idle state, the request would fail.

Note that the current implementation of SwErl GenStateM lack many of the specialized features found in Erlang's gen_statem module. Presently, they have the same functionality as GenServers.

### Gen Event
The Gen Event module has two distinct pieces. Event Managers and Event Handlers. Event Managers generally represent a single event. Event Handlers are actions taken as a result of that event. In Erlang, event Handlers are fully-fledged processes with an internal state and additional hooks.  Presently in SwErl Event Handlers are simply functions.

Event Handlers must have two parameters. The first is the PID of the event Manager they are attached to, the second is the `message` supplied in the notification.

Multiple Event handlers can be attached to one Event Manager. Whenever an Event Manager receives a notification via `EventManager.notify(name OR pid, message)`, it calls each attached Event Handler in sequence.
