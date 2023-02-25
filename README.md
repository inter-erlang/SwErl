# SwErl


## Why SwErl?
Parallel and concurrent computing should not be hard! SwErl is a small package that reduces not only the difficulty of thinking about concurrency, but also how much code you have to write.

Async-await and promises are both attempts at linearizing asynchronous code. Both approaches still require understanding what is happening outside of the current thread. SwErl takes a different approach. It is designed embrace multi-core machines rather than hide those cores.

SwErl is based on a spawn-send pattern. You spawn a closure. Then somewhere else in your code you send the spawned closure messages. Each time a closure recieves a message, it is assigned to be processed by a DispatchQueue. When the process finishes, the closure stops using any threads or threading resources. This keeps threads from being blocked while waiting for responses to requests.

The spawn-send pattern also frees you from worrying about shared states between threads. That way you never have to worry about race conditions. Ever! Being freed from race conditions means you don't ever have to create semiphores or locks. Being freed from these means your code can never experience a cross-lock. These pain-points of parallel and concurrent programming are now gone! 

## Brief Usage Introduction
Here is a simple example. It uses the main DispatchQueue. When executed, the closure prints out the SwErl process ID, not thread id, and whatever message is sent. Messages can be any valid Swift type. It could be a tuple, struct instance, class instance, string, Int, or any custom type in your application. It could even be another closure if you wanted. 
```swift
let examplePid = try spawn{(procPid, message) in
    print("process: \(procPid) message: \(message)")
    return SwErlProc.continue
}
```
The <code>spawn</code> function registers your closure in a local registry. The value of this function is a process ID. A pid. Once registered, the pid can be used to send messages to the closure from <bold>anywhere</bold> in your code.

Let's send a simple <code>String</code>-type message to the example closure above. 
```swift    
examplePid ! "Hi there."
```
The <code>!</code> send operator is all that's needed. Now let's send a tuple.
```swift
examplePid ! (7,3.5,"Sue")
```

You can send a message that includes any valid Swift type, including Pids. That means not only can you capture pids in a closure, you can pass them as part of a message. This gives you an ultimate way of chainging closures without using any callbacks!

## Detailed Usage Explanation


Simple examples like the one above often don't show the strengths of what can be done with SwErl. With SwErl processes, you can leverage every thread available on your device by composing your application, or package, using many SwErl processes. While you can create SwErl processes on the fly, they are best leveraged by creating all, or at least nearly all, when your code begins its execution. 

By having all SwErl processes available at the end of launch-time, you application can now consist of processes that pass each other messages. Since the <code>!</code> operator can be used anywhere in your code, you can use it to pass messages directly from one process to another, without blocking the current process. This means it is very easy to chain SwErl processes in order to accomplish effectual computation. 

You can even include SwErl process ID's, PID's, in the messages you send. This means you can write processes that determine which process(es) to send messages to at runtime.

Also, since the <code>spawn</code> function accepts both functions and closures, if you use closures you can capture values that are used by each and every execution of a SwErl process without passing those values in messages.

I look forward to seeing how you leverage this dynamic parallelism and concurrency library in your products.

### SwErl Process Types 

There are two types of SwErl processes you can spawn, stateless and stateful.
### Stateless SwErl Processes

Stateless processes should be the default type you use in your code. They provide the greatest flexibility and speed. All stateless processes are executed asynchronously. They will use the threads available to your process as efficiently as possible. By default, all of your stateless processes are run on the global <code>DispatchQueue</code> with the <code>.default</code> quality of service. When you spawn a SwErl process, you can specify a dispatch queue of your choice. All stateless SwErl processes are executed asynchronously.
### Stateful SwErl Processes
Use stateful processes with care. Stateful processes should only be used when it is not possible to engineer a solution that uses only stateless processes. All stateful SwErl processes are executed synchronously. Therefore they can block threads. Using stateful SwErl processes introduces a bottleneck into your code.
By default, all stateful SwErl processes are run on a global, custom serial dispatch queue with the <code>.default</code> quality of service. This choice of dispatch queue ensures that the states of each stateful SwErl process behave rationally and without race conditions. 
You can specify a dispatch queue of your choice. Be careful when you do so. Apple's documentation states that if you create too many dispatch queues that block threads, your device will experience thread starvation. Thread starvation causes devices to crash, not just apps. 


### SwErl Processes are Lightweight
Each SwErl process is only 88 Bytes in size. Work is ongoing to reduce this size even further. Both stateful and stateless SwErl processes can be spawned quickly. On the deverloper's first-generation MacStudio, it took less than 0.0002 milliseconds to spawn individual processes. A test exists in the unit tests that allows you to see the speed with which your device spawns SwErl processes.


## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/yenrab/SwErl.git",  from: "0.9.5"),

```

Also add `"SwErl"` to the target's dependencies.
