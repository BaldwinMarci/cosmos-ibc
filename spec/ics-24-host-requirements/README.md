---
ics: 24
title: Host State Machine Requirements
stage: draft
category: ibc-core
required-by: 3, 18
author: Christopher Goes <cwgoes@tendermint.com>
created: 2019-04-16
modified: 2019-05-11
---

## Synopsis

This specification defines the minimal set of interfaces which must be provided and properties which must be fulfilled by a blockchain & state machine hosting an IBC handler (implementation of the interblockchain communication protocol; see [the architecture document](../../docs/ibc/1_IBC_ARCHITECTURE.md) for details).

### Motivation

IBC is designed to be a common standard which will be hosted by a variety of blockchains & state machines and must clearly define the requirements of the host.

### Definitions

`ConsensusState` is as defined in [ICS 2](../ics-2-consensus-requirements).

### Desired Properties

IBC should require as simple an interface from the underlying state machine as possible to maximize the ease of correct implementation.

## Technical Specification

### Keys, Identifiers, Separators

A `Key` is a bytestring used as the key for an object stored in state. Keys MUST contain only alphanumeric characters and the separator `/`.

An `Identifier` is a bytestring used as a key for an object stored in state, such as a connection, channel, or light client. Identifiers MUST consist of alphanumeric characters only.

Identifiers are not intended to be valuable resources — to prevent name squatting, minimum length requirements or pseudorandom generation MAY be implemented.

The separator `/` is used to separate and concatenate two identifiers or an identifier and a constant bytestring. Identifiers MUST NOT contain the `/` character, which prevents ambiguity.

Variable interpolation, denoted by curly braces, MAY be used as shorthand to define key formats, e.g. `client/{clientIdentifier}/consensusState`.

### Key/value Store

Host chains MUST provide a simple key-value store interface, with three functions which behave in the standard way:

```coffeescript
function get(Key key) -> Value | null
```

```coffeescript
function set(Key key, Value value)
```

```coffeescript
function delete(Key key)
```

`Key` is as defined above. `Value` is an arbitrary bytestring encoding of a particular data structure. Encoding details are left to separate ICSs.

These functions MUST be permissioned to the IBC handler module (the implementation of which is described in separate standards) only, so only the IBC handler module can `set` or `delete` the keys which can be read by `get`. This can possibly be implemented as a sub-store (prefixed keyspace) of a larger key-value store used by the entire state machine.

### Consensus State Introspection

Host chains MUST provide the ability to introspect their own consensus state, with `getConsensusState`:

```coffeescript
function getConsensusState() -> ConsensusState
```

`getConsensusState` MUST return the current consensus state for the consensus algorithm of the host chain.

### Module system

Host chains MUST implement a module system, where each module has a unique serializable identifier, which:
- can be read by the IBC handler in an authenticated manner when the module calls the IBC handler, e.g. to send a packet
- can be used by the IBC handler to look up a module, which it can then call into (e.g. to handle a received packet addressed to that module)

Host chains MUST provide the ability to read the calling module in the IBC handler with `getCallingModule`:

```coffeescript
function getCallingModule() -> string
```

Modules which wish to make use of particular IBC features MAY implement certain handler functions, e.g. to add additional logic to a channel handshake with an associated module on another chain.

### Datagram Submission

Host chains MAY define a unique `submitDatagram` function to submit [datagrams](../../docs/ibc/2_IBC_TERMINOLOGY.md) directly:

```coffeescript
function submitDatagram(Datagram datagram)
```

`submitDatagram` allows relayers to relay IBC datagrams directly to the host chain. Host chains MAY require that the relayer submitting the datagram has an account to pay transaction fees, signs over the datagram in a larger transaction structure, etc - `submitDatagram` MUST define any such packaging required.

## Backwards Compatibility

Not applicable.

## Forwards Compatibility

Key-value store functionality and consensus state type are unlikely to change during operation of a single host chain.

`submitDatagram` can change over time as relayers should be able to update their processes.

## Example Implementation

Coming soon.

## Other Implementations

Coming soon.

## History

29 April 2019 - Initial draft
11 May 2019 - Rename "RootOfTrust" to "ConsensusState"

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
