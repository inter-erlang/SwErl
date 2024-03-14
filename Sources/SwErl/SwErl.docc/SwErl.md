# ``SwErl``

Concurrency and cross-device communication for Swift made easy

## Overview

SwErl is a concurrency and inter-app communication library conforming to the design patterns and principles found in the world renowned Erlang Programming Language. It provides primatives that allows Swift apps to easily and efficiently leverage all the CPU's on a device. SwErl primatives also allows apps to communicate between devices of different types across networks.

## Topics

### Getting Started
Here is a quick-start document
- <doc:GettingStarted>

### Processes
Here are some quick links to how to spawn lightweight, fast, SwErl processes.
Here is how to spawn a synchrnous, stateful process.
- ``spawnsysf(_:queueToUse:name:initialState:function:)``

### GenServer - Generic Servers
- ``GenServer``
- ``GenServerBehavior``

### GenStateM - Generic State Machines
- ``GenStateM``
- ``GenStatemBehavior``

### GenEvent - Generic Events
- ``EventManager``

### Contribute to SwErl
- <doc:Contribute>
