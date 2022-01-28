<!-- omit in toc -->
# CCV: Overview and Basic Concepts
[&uparrow; Back to main document](./README.md)

<!-- omit in toc -->
## Outline
- [Security Model](#security-model)
- [Motivation](#motivation)
- [Definitions and Overview](#definitions-and-overview)
  - [Channel Initialization](#channel-initialization)
  - [Validator Set Update](#validator-set-update)



# Security Model
[&uparrow; Back to Outline](#outline)

We consider chains that use a proof of stake mechanism based on the model of [weak subjectivity](https://blog.ethereum.org/2014/11/25/proof-stake-learned-love-weak-subjectivity/) 
in order to strengthen the assumptions required by the underlying consensus engine 
(e.g., [Tendermint](https://arxiv.org/pdf/1807.04938.pdf) requires that less than a third of the voting power is Byzantine). 

> **Background**: The next block in a blockchain is *validated* and *voted* upon by a set of pre-determined *full nodes*; these pre-determined full nodes are also known as *validators*. 
We refer to the validators eligible to validate a block as that block's *validator set*. 
To be part of the validator set, a validator needs to *bond* (i.e., lock, stake) an amount of tokens for a (minimum) period of time, known as the *unbonding period*. 
The amount of tokens bonded gives a validator's *voting power*. 
When a validator starts unbonding some of its tokens, its voting power is reduced immediately, 
but the tokens are unbonded (i.e., unlocked) only after the unbonding period has elapsed. 
If a validator misbehaves (e.g., validates two different blocks at the same height), then the system can slash the validator's bonded tokens that gave its voting power during the misbehavior.
This prevents validators from misbehaving and immediately exiting with their tokens, 
i.e., the unbonding period enables the system to punish misbehaving validators after the misbehaviors are committed.
For more details, take a look at the [Tendermint Specification](https://github.com/tendermint/spec/blob/master/spec/core/data_structures.md) 
and the [Light Client Specification](https://github.com/tendermint/spec/blob/master/spec/light-client/verification/verification_002_draft.md#part-i---tendermint-blockchain).

In the context of CCV, the validator sets of the consumer chains are chosen based on the tokens validators bonded on the provider chain, 
i.e., are chosen from the validator set of the provider chain. 
When validators misbehave on the consumer chains, their tokens bonded on the provider chain are slashed. 
As a result, the security gained from the value of the tokens bonded on the provider chain is shared with the consumer chains. 

Similarly to the single-chain approach, when a validator starts unbonding some of its bonded tokens, its voting power is reduced on all chains (i.e., provider chain and consumer chains); 
yet, due to delays in the communication over the IBC protocol (e.g., due to relaying packets), the voting power is not reduced immediately on the consumer chains. 
A further consequence of CCV is that the tokens are unbonded only after the unbonding period has elapsed on all chains starting from the moment the corresponding voting power was reduced. 
Thus, CCV may delay the unbonding of tokens validators bonded on the provider chain.
For more details, take a look at the [Interchain Security light paper](https://github.com/cosmos/gaia/blob/main/docs/interchain-security.md).

# Motivation
[&uparrow; Back to Outline](#outline)

CCV is a primitive (i.e., a building block) that enables arbitrary shared security models: The security of a chain can be composed of security transferred from multiple provider chains including the chain itself (a consumer chain can be its own provider). As a result, CCV enables chains to borrow security from more established chains (e.g., Cosmos Hub), in order to boost their own security, i.e., increase the cost of attacking their networks. 
> **Intuition**: For example, for chains based on Tendermint consensus, a variety of attacks against the network are possible if an attacker acquire 1/3+ or 2/3+ of all bonded tokens. Since the market cap of newly created chains could be relatively low, an attacker could realistically acquire sufficient tokens to pass these thresholds. As a solution, CCV allows the newly created chains to use validators that have stake on chains with a much larger market cap and, as a result, increase the cost an attacker would have to pay. 

Moreover, CCV enables *hub minimalism*. In a nutshell, hub minimalism entails keeping a hub in the Cosmos network (e.g., the Cosmos Hub) as simple as possible, with as few features as possible in order to decrease the attack surface. CCV enables moving distinct features (e.g., DEX) to independent chains that are validated by the same set of validators as the hub. 

> **Versioning**: Note that CCV will be developed progressively. 
> - The V1 release will require the validator set of a consumer chain to be entirely provided by the provider chain. In other words, once a provider chain agrees to provide security to a consumer chain, the entire validator set of the provider chain MUST validate also on the consumer chain.
> - The V2 release will allow the provider chain validators to opt-in to participate as validators on the consumer chain. It is up to each consumer chain to establish the benefits that provider chain validators receive for their participation.
> 
> For more details on the planned releases, take a look at the [Interchain Security light paper](https://github.com/cosmos/gaia/blob/main/docs/interchain-security.md#the-interchain-security-stack).

# Definitions and Overview
[&uparrow; Back to Outline](#outline)

This section defines the new terms and concepts introduced by CCV and provides an overview of CCV.

**Provider Chain**: The blockchain that provides security, i.e., manages the validator set of the consumer chain.

**Consumer Chain**: The blockchain that consumes security, i.e., enables the provider chain to manage its validator set.

> Note that in the current version the validator set of the consumer chain is entirely provided by the provider chain.

Both the provider and the consumer chains are [application-specific blockchains](https://docs.cosmos.network/v0.44/intro/why-app-specific.html), 
i.e., the state-machine is typically connected to the underlying consensus engine via an interface called the [ABCI](https://docs.tendermint.com/v0.34/spec/abci/). 
Thus, we refer to the state-machine as an ABCI application. 
For ease of presentation, this specification considers a modular paradigm, 
i.e., the functionality of the ABCI application is separated into multiple modules, like the approach adopted by [Cosmos SDK](https://docs.cosmos.network/v0.44/basics/app-anatomy.html#modules).  

**CCV Module**: The module that implements the CCV protocol. Both the provider and the consumer chains have each their own CCV module. 
Furthermore, the functionalities provided by the CCV module differ between the provider chain and the consumer chains. 
For brevity, we use *provider CCV module* and *consumer CCV module* to refer to the CCV modules on the provider chain and on the consumer chains, respectively. 

**CCV Channel**: A unique, ordered IBC channel that is used by the provider CCV module to exchange IBC packets with a consumer CCV module. 
Note that there is a separate CCV channel for every consumer chain.

> Note that the IBC handler interface, the IBC relayer module interface, and both IBC channels and IBC packets are as defined in [ICS 25](../../core/ics-025-handler-interface), [ICS 26](../../core/ics-026-routing-module), and [ICS 4](../../core/ics-004-channel-and-packet-semantics), respectively.

**Validator Set Change (VSC)**: A change in the validator set of the provider chain that must be reflected in the validator sets of the consumer chains. 
A VSC consists of a batch of validator updates, i.e., changes in the voting power granted to validators on the provider chain and, due to CCV, also on the consumer chains.

> **Background**: In the context of single-chain validation, the changes of the validator set are triggered by the *Staking module*, 
> i.e., a module of the ABCI application that implements the proof of stake mechanism needed by the [security model](#security-model). 
> For more details, take a look at the [Staking module documentation](https://docs.cosmos.network/master/modules/staking/) of Cosmos SDK.

Every VSC consists of a batch of validator updates, some of which can decrease the voting power granted to validators. 
These decreases may be a consequence of unbonding operations (e.g., unbonding delegations) on the provider chain.
which MUST NOT complete before reaching maturity on both the provider and all the consumer chains,
i.e., the *unbonding period* (denoted as `UnbondingPeriod`) has elapsed on both the provider and all the consumer chains.
Thus, a *VSC reaching maturity* on a consumer chain means that all the unbonding operations that resulted in validator updates included in that VSC have matured on the consumer chain.

> **Background**: An *unbonding operation* is any operation of unbonding an amount of the tokens a validator bonded. Note that the bonded tokens correspond to the validator's voting power. Unbonding operations have two components: 
> - The *initiation*, e.g., a delegator requests their delegated tokens to be unbonded. The initiation of an operation of unbonding an amount of the tokens a validator bonded results in a change in the voting power of that validator.
> - The *completion*, e.g., the tokens are actually unbonded and transferred back to the delegator. To complete, unbonding operations must reach *maturity*, i.e., `UnbondingPeriod` must elapse since the operations were initiated.

> **Note**: Time periods are measured in terms of the block time, i.e., `currentTimestamp()` (as defined in [ICS 24](../../core/ics-024-host-requirements)). 
> As a result, a consumer chain MAY start the unbonding period for every VSC that it applies in a block at any point during that block.

CCV must handle the following types of operations:
- **Channel Initialization**: Create unique, ordered IBC channels between the provider chain and every consumer chain.
- **Validator Set Update**: It is a two-part operation, i.e., 
  - update the validator sets of all the consumer chains based on the information obtained from the *provider Staking module* (i.e., the Staking module on the provider chain) on the amount of tokens bonded by validators on the provider chain;
  - and enable the timely completion (cf. the unbonding periods on the consumer chains) of unbonding operations (i.e., operations of unbonding bonded tokens).

## Channel Initialization
[&uparrow; Back to Outline](#outline)

The following Figure shows an overview of the CCV Channel initialization. 

![Channel Initialization Overview](./figures/ccv-init-overview.png?raw=true)

Consumer chains are created through governance proposals. For details on how governance proposals work, take a look at the [Governance module documentation](https://docs.cosmos.network/master/modules/gov/) of Cosmos SDK.

The channel initialization consists of four phases:
- **Create clients**: The provider CCV module handles every passed proposal to spawn a new consumer chain. 
  Once it receives a proposal, it creates a client of the consumer chain (as defined in [ICS 2](../../core/ics-002-client-semantics)). 
  Then, the operators of validators in the validator set of the provider chain must each start a full node (i.e., a validator) of the consumer chain. 
  Once the consumer chain starts, the application receives an `InitChain` message from the consensus engine 
  (for more details, take a look at the [ABCI documentation](https://docs.tendermint.com/v0.34/spec/abci/abci.html#initchain)). 
  The `InitChain` message triggers the call to the `InitGenesis()` method of the consumer CCV module, which creates a client of the provider chain.
  For client creation, both a `ClientState` and a `ConsensusState` are necessary (as defined in [ICS 2](../../core/ics-002-client-semantics));
  both are contained in the `GenesisState` of the consumer CCV module.
  The `GenesisState` is distributed to all operators that need to start a full node of the consumer chain 
  (the mechanism of distributing the `GenesisState` is outside the scope of this specification).
  > Note that although the mechanism of distributing the `GenesisState` is outside the scope of this specification, 
  a possible approach would entail the creator of the proposal to spawn the new consumer chain to distribute the `GenesisState` via the gossip network 
  and to add the hash of `GenesisState` in the proposal. 
  >  
  > Note that at genesis, the validator set of the consumer chain matches the validator set of the provider chain.
- **Connection handshake**: A relayer (as defined in [ICS 18](../../relayer/ics-018-relayer-algorithms)) is responsible for initiating the connection handshake (as defined in [ICS 3](../../core/ics-003-connection-semantics)). 
- **Channel handshake**: A relayer is responsible for initiating the channel handshake (as defined in [ICS 4](../../core/ics-004-channel-and-packet-semantics)). 
  The channel handshake must be initiated on the consumer chain. 
  The handshake consists of four messages that need to be received for a channel built on top of the expected clients. 
  We omit the `ChanOpenAck` message since it is not relevant for the overview. 
  - *OnChanOpenInit*: On receiving the *FIRST* `ChanOpenInit` message, the consumer CCV module sets the status of its end of the CCV channel to `INITIALIZING`.
  - *OnChanOpenTry*: On receiving the *FIRST* `ChanOpenTry` message, the provider CCV module sets the status of its end of the CCV channel to `INITIALIZING`.
  - *OnChanOpenConfirm*: On receiving the *FIRST* `ChanOpenConfirm` message, the provider CCV module sets the status of its end of the CCV channel to `VALIDATING`.
- **Channel completion**: Once the provider chain sets the status of the CCV channel to `VALIDATING`, 
  it provides a VSC (i.e., validator set change) to the consumer chain (see [next section](#validator-set-update)). 
  On receiving the *FIRST* `VSCPacket`, the consumer CCV module sets the status of its end of the CCV channel to `VALIDATING`. 

> **Discussion**: As long as the [assumptions required by CCV](./system_model_and_properties.md#assumptions) hold (e.g., *Correct Relayer*), every governance proposal to spawn a new consumer chain that passes on the provider chain eventually results in a CCV channel being created. Furthermore, the "*FIRST*" keyword in the above description ensures the uniqueness of the CCV channel, i.e., all subsequent attempts to create another CCV channel to the same consumer chain will fail.

For a more detailed description of Channel Initialization, take a look at the [technical specification](./technical_specification.md#initialization).

## Validator Set Update
[&uparrow; Back to Outline](#outline)

In the context of VSCs, the CCV module enables the following functionalities:
  - On the provider chain, 
    - **provide** VSCs to the consumer chains, for them to update their validator sets according to the validator set of the provider chain;
    - **register** VSC maturity notifications from the consumer chain.
  - On every consumer chain,
    - **apply** the VSCs provided by the provider chain to the validator set of the consumer chain; 
    - **notify** the provider chain that the provided VSCs have matured on this consumer chain.

These functionalities are depicted in the following Figure that shows an overview of the Validator Set Update operation of CCV. 

![Validator Set Update Overview](./figures/ccv-vsc-overview.png?raw=true)

For a more detailed description of Validator Set Update, take a look at the [technical specification](./technical_specification.md#validator-set-update).