![SwErl](Sources/SwErl/SwErl.docc/resources/logo_text.svg)
SwErl is a general purpose concurrency library conforming to the design patterns and principles found in the Erlang Programming Language. For Swift Developers with little to no Erlang experience, a quick primer for SwErl [is provided here](Sources/SwErl/SwErl.docc/GettingStarted.md).
## Why SwErl?

### Painless Concurrency
Parallel and concurrent computing should not be hard! SwErl is a small package that reduces not only the difficulty of thinking about concurrency, but also how much code you have to write.

coroutines (async/await parallelism) and promises both attempt to linearize asynchronous code. As long as everything goes well, both of these approaches can make concurrent and parallel code seem easier to write and read. They do this by localizing code placement. But when something goes wrong, both still require deep and significant understanding of what is happening outside of the current thread. This includes not just semaphores and locks, but also race conditions and cross-locks. SwErl takes a different approach. It is designed embrace multi-core machines rather than hide those cores. It also eliminates the need for semaphores and locks, by negating the possibility of race conditions. With no semaphores or locks, cross-locks become a thing of the past.These pain-points of parallel and concurrent programming are now gone from your code, your worries, and your product.

SwErl uses a spawn-send pattern. You spawn long-lived processes. Then elsewhere in your code you send messages to these spawned processes. Each process processes messages within it's own execution context, provided by Foundations dispatch queues. When processes aren't processing or receiving messages they do not use any threads or threading resources. By using long-lived processes, SwErl reduces the amount of computation time spent creating and destroying the many short-lived threads in applications that highly leverage the current hardware designs of devices.

SwErl also allows you to have processes spawn and terminate other processes. Such short-lived processes should be used sparingly since they use the same amount of computational effort to create and destroy as do long-lived processes.
### SwErl Processes are Lightweight
Each SwErl process is only 88 Bytes in size. Work is ongoing to reduce this size even further. Both stateful and stateless SwErl processes can be spawned quickly. On one developer's first-generation MacStudio, it took less than 0.0005 milliseconds to spawn individual processes and less than 0.00083 milliseconds per message sent. A test exists in the unit tests that allows you to see the speed of SwErl on your devices.

## Installation
SwErl is available via the Swift Package Manager.
```swift
.package(url: "https://github.com/yenrab/SwErl.git", from: "0.9.11"),
```
Manual installation is possible by built from source.
## Compatibility
SwErl Node requires networking primitives available only on Apple platforms. SwErl will not compile on other platforms.

## Contributing
SwErl welcomes contributions. If you don't know where to start, remember that this library aims to emulate Erlang's OTP features as closely as possible. Review Erlang's documentation for differences as a starting point.

To help jump-start would-be contributors, SwErl includes an overview of how the library is implemented.

![SwErl Logo](Sources/SwErl/SwErl.docc/resources/logo.svg)
Logo Credit: Jenna Ray
