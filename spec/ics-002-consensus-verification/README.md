---
ics: 2
title: Consensus Verification
stage: draft
category: ibc-core
requires: 23, 24
required-by: 3
author: Juwoon Yun <joon@tendermint.com>, Christopher Goes <cwgoes@tendermint.com>
created: 2019-02-25
modified: 2019-05-28
---

## Synopsis

This standard specifies the properties that consensus algorithms of chains implementing the interblockchain
communication protocol are required to satisfy. These properties are necessary for efficient and safe
verification in the higher-level protocol abstractions. The algorithm utilized in IBC to verify the
consensus transcript & state subcomponents of another chain is referred to as a "light client verifier",
and pairing it with a state that the verifier trusts forms a "light client" (often shortened to "client").

This standard also specifies how the clients will be stored, registered, and updated in the
canonical IBC handler. The stored client instances will be verifiable by a third party actor,
such as a user inspecting the state of the chain and deciding whether or not to send an IBC packet.

### Motivation

In the IBC protocol, a chain needs to be able to verify updates to the state of another chain
which the other chain's consensus algorithm has agreed upon, and reject any possible updates
which the other chain's consensus algorithm has not agreed upon. A light client is the algorithm
with which a chain can do so. This standard formalizes the light client model and requirements,
so that the IBC protocol can easily connect with new chains which are running new consensus algorithms,
as long as associated light client algorithms fulfilling the requirements are provided.

### Definitions

* `get`, `set`, `Key`, and `Identifier` are as defined in [ICS 24](../ics-024-host-requirements).

* `CommitmentRoot` is as defined in [ICS 23](../ics-023-vector-commitments).

* `ConsensusState` is an opaque type representing the verification state of a light client.
  `ConsensusState` must be able to verify state updates agreed upon by the associated consensus algorithm,
  and must provide an inexpensive way for downstream logic to verify whether key-value pairs are present
  in the state or not.

* `ClientState` is a structure representing the state of a client, defined in this ICS.
  A `ClientState` contains the latest `ConsensusState` and a map of heights to previously
  verified state roots which can be utilized by downstream logic to verify subcomponents
  of state at particular heights.

* `createClient`, `queryClient`, `updateClient`, `freezeClient`, and `deleteClient` function signatures are as defined in [ICS 25](../ics-025-handler-interface).
  The function implementations are defined in this standard.

### Desired Properties

Light clients must provide a secure algorithm to verify other chains' canonical headers,
using the existing `ConsensusState`. The higher level abstractions will then be able to verify
subcomponents of the state with the `CommitmentRoot`s stored in the `ConsensusState`, which are
guaranteed to have been committed by the other chain's consensus algorithm.

`ValidityPredicate`s are expected to reflect the behaviour of the full nodes which are running the  
corresponding consensus algorithm. Given a `ConsensusState` and `[Message]`, if a full node
accepts the new `Header` generated with `Commit`, then the light client MUST also accept it,
and if a full node rejects it, then the light client MUST also reject it.

Light clients are not replaying the whole message transcript, so it is possible under cases of
consensus equivocation that the light clients' behaviour differs from the full nodes'.
In this case, an equivocation proof which proves the divergence between the `ValidityPredicate`
and the full node can be generated and submitted to the chain so that the chain can safely deactivate the
light client and await higher-level intervention.

## Technical Specification

### Data Structures

#### ConsensusState

`ConsensusState` is a type defined by each consensus algorithm, used by the validty predicate to
verify new commits & state roots. Likely the strucutre will contain the last commit, including
signatures and validator set metadata, produced by the consensus process.

A `ConsensusState` MUST have a function `Height() int64`. The function returns the height of the
last verified commit. A `ConsensusState` can verify a `Header` only if it has a
higher height than itself.

`ConsensusState` MUST be generated from an instance of `Consensus`, which assigns unique heights
for each `ConsensusState`. Two `ConsensusState`s on the same chain SHOULD NOT have the same height
if they do not have equal commitment roots. Such an event is called an "equivocation", and should one occur,
a proof should be generated and submitted so that the client can be frozen.

The `ConsensusState` of a chain is stored by other chains in order to verify the chain's state.

```typescript
interface ConsensusState {
  height: uint64
  validityPredicate: ValidityPredicate
  equivocationPredicate: EquivocationPredicate
}
```

#### ClientState

`ClientState` is the light client state, which contains the latest `ConsensusState` along with
a map of heights to `CommitmentRoot`s, used to verify presence or absence of particular key-value pairs
in state at particular heights.

```typescript
interface ClientState {
  consensusState: ConsensusState
  verifiedRoots: Map<uint64, CommitmentRoot>
  frozen: bool
}
```

where
  * `consensusState` is the `ConsensusState` used by `Consensus.ValidityPredicate` to verify `Header`s.
  * `verifiedRoots` is a map of heights to previously verified `CommitmentRoot` structs, used to prove presence or absence of key-value pairs in state at particular heights.
  * `frozen` is a boolean indicating whether the client has been frozen due to a detected equivocation.

Note that instead of `ClientState` being stored directly, the consensus state, roots, and frozen boolean are stored at separate keys.

#### Header

A `Header` is a blockchain header which provides information to update a `ConsensusState`.
Headers can be submitted to an associated client to update the stored `ConsensusState`.

```typescript
interface Header {
  height: uint64
  proof: HeaderProof
  predicate: Maybe[ValidityPredicate]
  root: CommitmentRoot
}
```
where
  * `height` is the height of the the consensus instance.
  * `proof` is the commit proof used by `Consensus.ValidityPredicate` to verify the header.
  * `predicate` is the new (or partially new) consensus state.
  * `root` is the new `CommitmentRoot` which will replace the existing one.

#### ValidityPredicate

A `ValidityPredicate` is a light client function to verify `Header`s depending on the current `ConsensusState`.
Using the ValidityPredicate SHOULD be far more computationally efficient than replaying `Consensus` logic
for the given parent `Header` and the list of network messages, ideally in constant time
independent from the size of message stored in the `Header`.

The `ValidityPredicate` type is defined as

```typescript
type ValidityPredicate = (ConsensusState, Header) => Error | ConsensusState
```

The detailed specification of `ValidityPredicate` can be found in [CONSENSUS.md](./CONSENSUS.md).

#### EquivocationPredicate

An `EquivocationPredicate` is a light client function used to check if two headers
constitute a violation of the consensus protocol (consensus equivocation) and should
freeze a light client.

The `EquivocationPredicate` type is defined as

```typescript
type EquivocationPredicate = (ConsensusState, Header, Header) => bool
```

More details about `EquivocationPredicate`s can be found in [CONSENSUS.md](./CONSENSUS.md)

### Subprotocols

IBC handlers MUST implement the functions defined below.

#### Preliminaries

Clients are stored under a unique `Identifier` prefix. The generation of the `Identifier` MAY
depend on the `Header` of the `Client` that will be registered under that `Identifier`.
This ICS does not require that client identifiers be generated in a particular manner,
only that they be unique.

`frozenKey` takes an `Identifier` and returns a `Key` under which to store whether or not a client is frozen.

```typescript
function frozenKey(id: Identifier): Key {
  return "clients/{id}/frozen"
}
```

`consensusStateKey` takes an `Identifier` and returns a `Key` under which to store the consensus state of a client.

Consensus state MUST be stored separately so it can be verified independently.

```typescript
function consensusStateKey(id: Identifier): Key {
  return "clients/{id}/consensusState"
}
```

`rootKey` takes an `Identifier` and a height (as `uint64`) and returns a `Key` under which to store a particular state root.

Roots MUST be stored under separate keys, one per height, for efficient retrieval.

Roots for old heights MAY be periodically cleaned up.

```typescript
function rootKey(id: Identifier, height: uint64): Key {
  return "clients/{id}/roots/{height}"
}
```

##### Utilizing past roots

To avoid race conditions between client updates (which change the state root) and proof-carrying
transactions in handshakes or packet receipt, many IBC handler functions allow the caller to specify
a particular past root to reference, which is looked up by height. IBC handler functions which do this
must ensure that they also perform any requisite checks on the height passed in by the caller to ensure
logical correctness.

#### Create

Calling `createClient` with the specified identifier & initial consensus state creates a new client.

```typescript
function createClient(id: Identifier, consensusState: ConsensusState) {
  assert(get(clientKey(id)) === null)
  client = ClientState{consensusState, empty, false}
  set(clientKey(id), client)
}
```

#### Query

Client frozen state, consensus state, and previously verified roots can be queried by identifier.

```typescript
function queryClientFrozen(id: Identifier): bool {
  return get(frozenKey(id))
}
```

```typescript
function queryClientConsensusState(id: Identifier): ConsensusState {
  return get(consensusStateKey(id))
}
```

```typescript
function queryClientRoot(id: Identifier, height: uint64): CommitmentRoot {
  return get(rootKey(id, height))
}
```

#### Update

Updating a client is done by submitting a new `Header`. The `Identifier` is used to point to the
stored `ClientState` that the logic will update. When the new `Header` is verified with
the stored `ClientState`'s `ValidityPredicate` and `ConsensusState`, then it SHOULD update the
`ClientState` unless an additional logic intentionally blocks the updating process (e.g.
waiting for the equivocation proof period.

```typescript
function updateClient(id: Identifier, header: Header) {
  frozen = get(frozenKey(id))
  assert(!frozen)
  consensusState = get(consensusStateKey(id))
  assert(consensusState !== nil)
  switch consensusState.validityPredicate(header) {
    case error:
      throw error
    case newState:
      set(consensusStateKey(id), newState)
      set(rootKey(id, newState.height), newState.root)
      return
  }
}
```

#### Freeze

A client can be frozen, in case when the application logic decided that there was a malicious
activity on the client. Frozen client SHOULD NOT be deleted from the state, as a recovery
method can be introduced in the future versions.

```typescript
function freezeClient(identifier: Identifier, firstHeader: Header, secondHeader: Header) {
  consensusState = get(consensusStateKey(identifier))
  assert(consensusState.equivocationPredicate(firstHeader, secondHeader))
  set(frozenKey(id), true)
}
```

### Example Implementation

An example blockchain `Op` runs on a single `Op`erator consensus algorithm,
where the valid blocks are signed by the operator. The operator signing Key
can be changed while the chain is running.

`Op` is constructed from the followings:
* `OpValidityPredicateBase`: Operator pubkey
* `OpValidityPredicate`: Signature ValidityPredicate
* `OpCommitmentRoot`: KVStore Merkle root
* `OpHeaderProof`: Operator signature

#### Consensus

`B` is defined as `(Op, Gen, [H])`. `B` satisfies `Blockchain`:

```typescript
type TX = RegisterLightClient | UpdateLightClient | ChangeOperator(Pubkey)

function commit(cs: State, txs: [TX]): H {
  newpubkey = c.Pubkey

  for (const tx of txs)
    switch tx {
      case RegisterLightClient:
        register(tx)
      case UpdateLightClient:
        update(tx)
      case ChangeOperator(pubkey):
        newpubkey = pubkey
    }

  root = getMerkleRoot()
  result = H(_, newpubkey, root)
  result.Sig = Privkey.Sign(result)
  return result
}

function verify(rot: CS, h: H): bool {
  return rot.Pubkey.VerifySignature(h.Sig)
}

type Op = (commit, verify)

type Gen = CS(InitialPubkey, EmptyLogStore)
```

The `[H]` is generated by `Op.commit`, recursively applied on the genesis and its successors.
The `[TX]` applied on the `Op.commit` can be any value, but when the `B` is instantiated
in the real world, the `[TX]` is fixed to a single value to satisfy consensus properties. In
this example, we assume that it is enforced by a legal authority.

#### ConsensusState

Type `CS` is defined as `(Pubkey, LogStore)`. `CS` satisfies `ConsensusState`:

```
function CS.base() returns CS.Pubkey
function CS.root() returns CS.LogStore
```

#### Header

Type `H` is defined as `(Sig, Maybe<Pubkey>, LogStore)`. `H` satisfies `Header`:

```
function proof(header: H): Signature {
  return H.Sig
}

function base(header: H): PubKey {
  return H.PubKey
}

function root(header: H): LogStore {
  return H.LogStore
}
```

### Properties & Invariants

- Client identifiers are first-come-first-serve: once a client identifier has been allocated, all future headers & roots-of-trust stored under that identifier will have satisfied the client's validity predicate.

## Backwards Compatibility

Not applicable.

## Forwards Compatibility

In a future version, this ICS will define a new function `unfreezeClient` that can be called 
when the application logic resolves an equivocation event.

## Example Implementation

Coming soon.

## Other Implementations

Coming soon.

## History

March 5th 2019: Initial draft finished and submitted as a PR
May 29 2019: Various revisions, notably multiple commitment-roots

## Copyright

All content herein is licensed under [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0).
