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

Message passing to asynchronous processes are unidirectional. This means the caller does not wait for a response before continuing. There is no promise, handle, or anything of the sort required in SwErl. Once a message is sent to an asynchrounous process, the next line of code executes. If you want to request further computation, a named process can be used and sent the results of the async process' computation. You 'cast' messages to async processes. 

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

Here is contrived example using the .main DispatchQueue. In it, a function spawns two processes that interact with each other. The first process, "go", is stateful, asynchronous, and runs using the .global() background DispatchQueue. The "go" process keeps a numerical state that was initialized to 0. 

When sent a message, "go" increments its state and sends this incremented value to an asynchronous, stateless process named "show". The "show" process uses the main thread to update a SwiftUI state variable. Updating this variable causes the screen to display the current count.

```swift
func spawnAll(){
    do{
        try spawnasysf(name:"go",initialState: 0){Pid,_,state in
            guard let state = state as? Int else{
                
                return
            }
            let count = state + 1
            "show" ! count
            return count
        }
        try spawnasysl(queueToUse:.main, name:"show"){Pid,count in
            message = "\(count)"
        }
    }
    catch{
        message = error.localizedDescription
    }
}
```
Here is the SwiftUI Button code that sends the incrementation message to the "go" process.
```swift
Button("Go Go SwiftUI!"){
    "go" ! ()//empty tuple
}
```

## OTP Behaviors
Behaviors reflect the usage and design of their Erlang counterparts, though with only the most oft-used functionality implemented. If you are unfamiliar with Erlang/OTP, you may find the [Erlang OTP Design Principles Documentation](https://www.erlang.org/doc/design_principles/des_princ) of interest.
Behaviors are implemented as protocols in SwErl. The available behaviors are 

### GenServer
GenServers, or Generic Servers are independent processes which act as servers in a client/server relationship within the app. They have all the functionality of a synchrounous-stateful SwErl process, including an internal state, with the added ability to accept messages via `GenServer.cast(...)`. Other processes making a Call to a genServer will not wait expecting a response. If `GenServer.call(...)` is used by some other process or processes, they will wait to receive a response.
genServers in SwErl all have a uniform API accessible via `GenServer`. genServers are created by writing a static type conforming to `protocol GenServerBehavior` to establish the functionality of a genServer instance, then instantiated using`GenServer.link().`

To demonstrate, we will make an server that is a lognormal random number stream. This could also be done with a named stateful process because of the simplicity of the example. For more complicated situations, stateful and stateless processes become unweildy.
```swift
import Foundation
import SwErl
import GameplayKit

enum LogNormal{
    case next
}

enum LogNormalServer:GenServerBehavior{
    
    //
    // API functions
    //

    //start up a named instance of LogNormalServer
    @discardableResult static func startLink(named:String, initialState:Any? = nil)->String?{
        do{
            return try GenServer.startLink(named, LogNormalServer.self, initialState)
        }
        catch{
            //no handling
        }
        return nil
    }
    //get the next log-normally distributed random Float from the stream
    static func next(from:String)->Float?{
        do{
            let (passed, result) = try GenServer.call(from,LogNormal.next)
            guard let result = result as? Float, passed == SwErlPassed.ok else{
                return nil
            }
            return result
        }
        catch{}
        return nil
    }


    //
    // Internal Functions
    //
    static func initializeData(_ data: Any?) -> Any? {
        guard let (mean,standardDeviation) = data as? (Float,Float) else{
            return nil
        }
        return GKGaussianDistribution(randomSource: GKRandomSource(), mean: mean, deviation: standardDeviation)
    }
    
    //handleCall is called when the server receives a synchronous message from another process via GenServer.call/2 (see the next API function above). The return value of handleCall is always the updated state of the GenServer instance. 

    static func handleCall(request: Any, data: Any) -> (Any, Any) {
        guard let command = request as? LogNormal, let distribution = data as? GKGaussianDistribution, command == LogNormal.next else{
            return (SwErlPassed.fail,data)
        }
        // Get next normally distributed random number
        let normalRandom = distribution.nextUniform()
        
        // Transform the normally distributed number to log-normal
        let logNormalRandom =  exp(normalRandom)
        return(logNormalRandom,distribution)
    }
    //
    //functions unused in this example
    //
    //terminateCleanup is called once on termination, and would generally be used to clean up any messy resources Swift would be unable to automatically garbage collect. Our server has no such held resources.
    static func terminateCleanup(reason: String, data: Any?) {
        return
    }
    
    //handleCast is called when the server receives an asynchronous message from another process via GenServer.cast/2. The return value of handleCast/2 is always the updated state of the GenServer instance.
    static func handleCast(request: Any, data: Any?) -> Any? {
        return data
    }
    
}


```


GenServers are started, spawned, linked,(all meaning the same thing) using the GenServer.startlink/2 function. In this example, a named instance of LogNormalServer is started/spawned/linked.
```swift
let mean:Float = 0.0
let sigma:Float = 0.4
LogNormalServer.startLink(named: "lnserver", initialState: (mean,sigma))
```
Here, the LogNormalServer named "lnserver" is asked for the next log-normally distributed random Float. Notice that naming instances allows for a theoretically unlimited number of instances of any GenServer type. SwErl ensures multiple local servers cannot share the same name, and automatically ensures unique PIDs.
```
guard let lnRand = LogNormalServer.next(from: "lnserver") else{
    return current_state
}
```


### Gen StateM
Event-driven Generic State Machine. Briefly paraphrasing [the erlang design documentation](https://www.erlang.org/doc/design_principles/statem), Event-driven state machines wait for inputs, trigger some action(s) based on its current state and input, then experience a state transition. Unlike a GenServer, a state machine's state is not arbitrary. state machines have a finite set of programmer defined states and pre-defined transitions between states. The Erlang design documentation provides several good heuristics for when a GenStateM should be used over a GenServer, one more is provided here: When the allowed functionality of a module varies dramatically depending on previous events.
 
By way of example, an ATM can be effectively modeled as a state machine with two states. Of course, this example glosses over many security features the machine would need and is presented only for demonstrating the features of SwErl and Erlang.

![a simple ATM modeled as a state machine](StateMDesign)

If such a state machine were to receive a request to dispense cash when in idle state, the request would fail. 

If the main purpose is to track state and react to data based on the current state, GenStateM should be considered as a valid solution rather than GenServer.

Here is a reduced handleCast/2 example from the DockSim demonstration app. The case statement switches on a tuple of the current state and the requested next state. Any request that doesn't match a valid pattern is ignored.

```swift
static func handleCast(message: SwErl.SwErlMessage, current_state: SwErl.SwErlState) -> SwErl.SwErlState {
    .
    .
    .
    guard let stateToChangeTo = message as? PersonStateM else{
        return current_state
    }
    
    .
    .
    .
    switch (currentWorkState,stateToChangeTo){
    case (.boxing, .loading), (.idle, .loading)://start going to the loading dock and begin loading boxed product
        .
        .
        .
    case (.loading,.continuing),(.continuing,.continuing),(.delivering,.loading)://start, or continue, loading boxed product onto a truck
        .
        .
        .
    case (.boxing, .idle)://ran out of work
        .
        .
        .
    case (.idle,.boxing), (.delivering,.boxing), (.returning, .boxing)://start boxing product
        .
        .
        .
    case (.boxing, .delivering)://start putting boxed product on loading dock
        .
        .
        .
        
    case (.continuing,.returning),(.loading,.returning)://start returning to the boxing station
        .
        .
        .
    default://invalid state change request type
        return current_state
    }
}
```

### Generic Events
Each SwErl generic event behavior has two distinct pieces. An event Manager and Event Handlers. The event manager responds to a single type of event. Event handlers are actions taken as a result of that event. In SwErl event handlers are functions or closures.

Event handlers are stateless and have two parameters. The first is the PID of the stateless SwErl process managing the event, the second is the `message` supplied to the manager for the event as data.

Multiple event handlers can be, and usually are, assigned to each event. When an event manager receives a notification via `EventManager.notify(name OR pid, message)`, it calls each attached Event Handler asynchronously.

Here is an example of one of the event handlers used in the DocSim demonstration app.

```swift
{(PID:Pid,message:SwErlMessage) in
    guard let (_,arrivalTime,_) = message as? (TruckStateM,Double,Double) else{
        return
    }
    //use delay the time of the next truck arrival.
    DispatchQueue.main.asyncAfter(deadline: .now() + arrivalTime) {
        // This block will be executed after a delay of arrivalTime seconds
        PersonStateM.changeState(for: "bob", to: PersonStateM.loading)
        PersonStateM.changeState(for: "camila", to: PersonStateM.loading)
    }
}
```
In this example, state changes are requested for the bob and camila PersonStateM instances to change to loading state after a time delay.

Below is an example from the DocSim demonstration app. In this example, a named manager, truckLeave, is started/spawned/linked and a list of handlers assigned to it.
```swift
do{
    try EventManager.link(name: "truckLeave", intialHandlers: truckLeaveHandlers)
}
catch{
    //ignore
}
```

Each time an event happens, the manager is notifed. Here, a truck is leaving a loading dock in the DocSim example app. EventManager is notified of the event and all event hadlers associated with the truckLeave event are executed.
```swift
EventManager.notify(name: "truckLeave", message: (TruckStateM.depart,nextArrivalTime,nextLeaveTime))
```


For full-code examples, please go to the [SwErlDemos](https://github.com/inter-erlang/SwErlDemos) GitHub repository. 
