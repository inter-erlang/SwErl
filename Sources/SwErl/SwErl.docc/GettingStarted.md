# GettingStarted

The most important features of SwErl

## Overview

Most SwErl apps will contain many of independent, light-weight SwErl processes communicating via message passing. This document shows how to spawn processes and send them messages. It also gives examples of how to design apps using SwErl.


## SwErl Processes

To spawn SwErl processes, all that is needed is to execute the appropriate `spawn` function and pass it a closure. Any time a message is sent to that process, the closure will execute. These closures have two arguments if they are stateless, three arguments if they are stateful. The first argument is the Process ID (PID) of the SwErl process spawned using the closure. The second is the message provided by the caller. For stateful processes, the third parameter of the closure is the current state of the process. SwErl provides the PID parameter for your optional use.

Once you have a spawned a process, pass it messages with the send operator: `!` .

Because messages can be any type, inside of the process the message must be cast message to expected types.

Here is an example of spawning an asynchronous, stateless process.

```swift

let printProcess = spawnasysl{(PID, message) in
    guard let message = message as? Int else{
        return
    }

    var response = ""
    switch message{
    case 1:
        response = "hello"
    case 2:
        response = "good to meet you"
    default:
        response = "goodbye"
    }
    print("\(response)")
    return
}
printProcess ! 3
```
Here is an example of spawning a synchronous, stateless process. Notice that a `SwErlPassed` enumeration is used to indicate success or failure. This allows for easy detection of success or failure without throwing exceptions.

```swift

let printProcess = spawnsysl{(PID, message) in
    guard let message = message as? Int else{
        return (SwErlPassed.fail,nil)
    }

    var response = ""
    switch message{
    case 1:
        response = "hello"
    case 2:
        response = "good to meet you"
    default:
        response = "goodbye"
    }
    return (SwErlPassed.ok,response)
}
guard let (worked,aMessage) = printProcess ! 3 as? (SwErlPassed,String), worked == SwErlProcess.ok else{
//error handling code here
    return
}
```

Two other types of processes are availaible. These are synchronous-stateful,`spawnsysf`, and asynchronous-statefull, `spawnasysf`.

Processes can also be registered by name. The name can then be used instead of the pid variable as a string literal in source code.

```swift
try spawnasysl(name: "printProcess"){(pid, message) in
    print(message)
}

"printProcess" ! "It's Me."
```

Message passing to asynchrounous processes are unidirectional. This means the caller does not wait for a response before continuing. Nor is there a promise, handle, or anything of the sort used. Once a message is sent to an asynchrounous process, the next line of code executes. If you want to request further computation, a named process can be used and sent the results of the async process' computation. You 'cast' messages to async processes. 

```swift
// This example is quite contrived, your architecture will often look quite different.
enum Command{
    case multiply
    case add
}
_ = try spawnasysl(name: "initializer"){(pid, message) in
    guard let (command,number) = message as? (Int,Int) else{
        return
    }
    switch command {
        case .multiply:
            "receivingProcess" ! number * number
        case .add:
            "receivingProcess" ! number + number
        default:
            return
    }
}

"initializer" ! (Command.add,2)
```
It is also possible to have the receiving process be the initializing process. This is referred to as 'casting back'.

## User I/O with SwErl
SwErl processes are implemented using the default system-selected global dispatch queue by default. You can easily create a process which runs on the main thread for IO operations. This example is asynchrounous and stateful but any type of process can be spawned using .main.

```swift
let ioProcess = try spawnasysf(queueToUse: DispatchQueue.main){
	(procPid, message,state) in 
		// Do some UI things and update the state.
        return updatedState
    }
```

The main thread should be reserved for short, high priority operations such as those affecting the user interface.

## OTP Behaviors
Behaviors reflect the usage and design of their Erlang counterparts, though with only the most oft-used functionality implemented. If you are unfamiliar with Erlang/OTP, you may find the [Erlang OTP Design Principles Documentation](https://www.erlang.org/doc/design_principles/des_princ) of interest.
Behaviors are implemented as protocols in SwErl. The available behaviors are 

### GenServer
GenServers, or Generic Servers are independent processes which act as servers in a client/server relationship within the app. They have all the functionality of a synchrounous-stateful SwErl process, including an internal state, with the added ability to accept messages via `GenServer.cast(...)`. Other processes making a Call to a genServer will not wait expecting a response. If `GenServer.call(...)` is used by some other process or processes, they will wait to receive a response.
genServers in SwErl all have a uniform API accessible via `GenServer`. genServers are created by writing a static type conforming to `protocol GenServerBehavior` to establish the functionality of a genServer instance, then instantiated using`GenServer.link().`

To demonstrate, we will make an echo server.
```swift
///
/// echo.swift
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
