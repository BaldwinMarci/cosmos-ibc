## Scope

IBC handles authentication, transport, and ordering of opaque data packets relayed between modules on separate machines — machines can be solo machines, ledgers, or any process whose state can be verified. The protocol is defined between modules on two machines, but designed for safe simultaneous use between any number of modules on any number of machines connected in arbitrary topologies.

## Interfaces

IBC sits between modules — smart contracts, other state machine components, or otherwise independently executed pieces of application logic on state machines — on one side, and underlying consensus protocols, blockchains, and network infrastructure (e.g. TCP/IP), on the other side.

IBC provides to modules a set of functions much like the functions which might be provided to a module for interacting with another module on the same state machine: sending data packets and receiving data packets on an established connection & channel, in addition to calls to manage the protocol state: opening and closing connections and channels, choosing connection, channel, and packet delivery options, and inspecting connection & channel status.

IBC requires certain functionalities and properties of the underlying chains, primarily finality (or thresholding finality gadgets), cheaply-verifiable consensus transcripts, and simple key/value store functionality. On the network side, IBC requires only eventual data delivery — no authentication, synchrony, or ordering properties are assumed (these properties are defined precisely later on).

## Operation

The primary purpose of IBC is to provide reliable, authenticated, ordered communication between modules running on independent host chains. This requires protocol logic in the areas of data relay, data confidentiality and legibility, reliability, flow control, authentication, statefulness, and multiplexing.

### Data relay

In the IBC architecture, modules are not directly sending messages to each other over networking infrastructure, but rather are creating messages to be sent which are then physically relayed from one chain to another by monitoring "relayer processes". IBC assumes the existence of a set of relayer processes with access to an underlying network protocol stack (likely TCP/IP, UDP/IP, or QUIC/IP) and physical interconnect infrastructure. These relayer processes monitor a set of chains implementing the IBC protocol, continuously scanning the state of each chain and executing transactions on another chain when outgoing packets have been committed. For correct operation and progress in a connection between two chains, IBC requires only that at least one correct and live relayer process exists which can relay between the chains.

### Data confidentiality & legibility

The IBC protocol requires only that the minimum data necessary for correct operation of the IBC protocol be made available & legible (serialised in a standardised format) to relayer processes, and the state machine may elect to make that data available only to specific relayers. This data consists of consensus state, client, connection, channel, and packet information, and any auxiliary state structure necessary to construct proofs of inclusion or exclusion of particular key/value pairs in state. All data which must be proved to another chain must also be legible; i.e., it must be serialised in a standardised format agreed upon by the two chains.

### Reliability

The network layer and relayer processes may behave in arbitrary ways, dropping, reordering, or duplicating packets, purposely attempting to send invalid transactions, or otherwise acting in a Byzantine fashion, without compromising the safety or liveness of IBC. This is achieved by assigning a sequence number to each packet sent over an IBC channel, which is checked by the IBC handler (the part of the state machine implementing the IBC protocol) on the receiving chain, and providing a method for the sending chain to check that the receiving chain has in fact received and handled a packet before sending more packets or taking further action. Cryptographic commitments are used to prevent datagram forgery: the sending chain commits to outgoing packets, and the receiving chain checks these commitments, so datagrams altered in transit by a relayer will be rejected. IBC also supports unordered channels, which do not enforce ordering of packet receives relative to sends but still enforce exactly-once delivery.

### Flow control

IBC does not provide specific protocol-level provisions for compute-level or economic-level flow control. The underlying chains are expected to have compute throughput limiting devices and flow control mechanisms of their own such as gas markets. Application-level economic flow control — limiting the rate of particular packets according to their content — may be useful to ensure security properties and contain damage from Byzantine faults. For example, an application transferring value over an IBC channel might want to limit the rate of value transfer per block to limit damage from potential Byzantine behaviour. IBC provides facilities for modules to reject packets and leaves particulars up to the higher-level application protocols.

### Authentication

All data sent over IBC are authenticated: a block finalised by the consensus algorithm of the sending chain must commit to the outgoing packet via a cryptographic commitment, and the receiving chain's IBC handler must verify both the consensus transcript and the cryptographic commitment proof that the datagram was sent before acting upon it.

### Statefulness

Reliability, flow control, and authentication as described above require that IBC initialises and maintains certain status information for each datastream. This information is split between three abstractions: clients, connections, and channels. Each client object contains information about the consensus state of the counterparty chain. Each connection object contains a specific pair of named identifiers agreed to by both chains in a handshake protocol, which uniquely identifies a connection between the two chains. Each channel, specific to a pair of modules, contains information concerning negotiated encoding & multiplexing options and state & sequence numbers. When two modules wish to communicate, they must locate an existing connection & channel between their two chains, or initialise a new connection & channel(s) if none yet exist. Initialising connections & channels requires a multi-step handshake which, once complete, ensures that only the two intended chains are connected, in the case of connections, and ensures that two modules are connected and that future datagrams relayed will be authenticated, encoded, and sequenced as desired, in the case of channels.

### Multiplexing

To allow for many modules within a single host chain to use an IBC connection simultaneously, IBC allows any number of channels to be associated with a single connection. Each channel uniquely identifies a datastream over which packets can be sent in order (in the case of an ordered channel), and always exactly once, to a destination module on the receiving chain. Channels are usually expected to be associated with a single module on each chain, but one-to-many and many-to-one channels are also possible. The number of channels is unbounded, facilitating concurrent throughput limited only by the throughput of the underlying chains with only a single connection & pair of clients necessary to track consensus information (and consensus transcript verification cost thus amortised across all channels using the connection).