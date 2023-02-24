# SwErl

Parallel and concurrent computing should not be hard! SwErl is a small package that reduces not only the difficulty of thinking about concurrency, but also how much code you have to write.

Async-await and promises are both attempts at linearizing asynchronous code. Both approaches still require understanding what is happening outside of the current thread. SwErl takes a different approach. It is designed embrace multi-core machines rather than hide those cores.

SwErl is based on a spawn-send pattern. You spawn a closure. Then somewhere else in your code you send the spawned closure messages. Each time a closure recieves a message, it is assigned to be processed by a DispatchQueue. When the process finishes, the closure stops using any threads or threading resources. This keeps threads from being blocked while waiting for responses to requests.

The spawn-send pattern also frees you from worrying about shared states between threads. That way you never have to worry about race conditions. Ever! Being freed from race conditions means you don't ever have to create semiphores or locks. Being freed from these means your code can never experience a cross-lock. These pain-points of parallel and concurrent programming are now gone! 

Here is a simple example. It uses the main DispatchQueue. When executed, the closure prints out the SwErl process ID, not thread id, and whatever message is sent. Messages can be any valid Swift type. It could be a tuple, struct instance, class instance, string, Int, or any custom type in your application. It could even be another closure if you wanted. 

            let examplePid = try spawn{(procPid, message) in
                print("process: \(procPid) message: \(message)")
                return SwErlProc.continue
            }
The <code>spawn</code> function registers your closure in a local registry. The value of this function is a process ID. A pid. Once registered, the pid can be used to send messages to the closure from <bold>anywhere</bold> in your code.

Let's send a simple <code>String</code>-type message to the example closure above. 
    
    examplePid ! "Hi there."

The <code>!</code> send operator is all that's needed. Now let's send a tuple.

    examplePid ! (7,3.5,"Sue")

Simple examples like this often don't show the strengths of what can be done with libraries. You can send a message that includes any valid Swift type, including Pids. That means not only can you capture pids in a closure, you can pass them as part of a message. This gives you an ultimate way of chainging closures. Yet none of them every block any other closure from executing.

