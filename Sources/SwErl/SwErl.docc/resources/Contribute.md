# Contribute

for prospective contributors

## Overview

Explained in this document is SwErl's Unit Testing philosophy, how concurrency is implemented, and how SwErl's registrar is built. Further contributions here are welcome.

## Unit tests
Existing SwErl Code is well-tested. Unit tests are written not only for quality control, but to demonstrate the usage and construction of SwErl code. Where possible, unit tests should be verbose and clear.
## Concurrency Structure

SwErl is built on Grand Central Dispatch. Every process spawns with a private serial dispatch queue which by default points to one of the global concurrent queues. The registrar maintains a single private concurrent queue which is used as a readers/writer lock by implementing the .barrier flag when writing.

Sending a message to a single active process looks like this:

1. The process is fetched from the Registrar by Name/Pid
2. The state of the fetched process is checked for validity (This is included to prevent silent cascading failures before Supervisors are implemented)
3. A function is placed on the queue of the fetched process which, in order:
   1. Fetches the state of the process
   2. calls the appropriate functionality from the process with the state and message. e.g. a cast will apply `GenServer.cast`  process will call the closure provided on spawn etc.
   3. The process's state is updated in the registrar.
   4. If the signal is one that expects a reply, the reply is sent.

Each fetch from the registrar executes on the registrar's private readers/writers queue. Presented as a Sequence diagram, where participants are the queues/execution-contexts involved:
![A sequence diagram demonstrating the process of sending a message](ConcurrencySequence)

## The Registrar
The registrar is implemented with three dictionaries. Swift Dictionaries are not-thread safe, even where thread-safety would be expected in other similar dictionary implementations. Reads concurrent with any write to the dictionary will cause unrecoverable memory errors, even to different keys with statically sized keys and values.
