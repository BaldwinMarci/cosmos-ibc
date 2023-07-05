## Synopsis

This standard document specifies batched execution of packets,
with purpose to allow execute callbacks when all packets from batch succeed and/or after each packet from batch until final packet.

### Motivation

Basic use case execute some transaction after multiple ICS-20 and ICS-721 packets succeed.

Extended use case are other packets, like governance and swap extensions.


## Technical Specification

### Data structures

```typescript
interface Packet {
  sourceChannel: string
  sourceSequence: uint64
}

interface AtomicBatchPacketData {  
  tracking: Packet[] 
  memo: string
}
```

### Good

#### 1. Sender chain

`Batch` packet is sent. `Batch` has ordered list of all `channels` and `sequences` within batch.

`App` packets are sent with `batch` to be `sequence` of `Batch` packet.

#### 2. Receiver chain

`Batch` received.

`App` packets are all received.

On final packet, each of `App` packet is executed in one atomic transaction in order defined in `batch tracking` of packets.

`Batch` and `App` packets are `ACK` success.

#### 3. Sender chain

Receives all results for each `App` packet.

After all results for `App` packets received, `Batch` packet callbacks configured functions.

#### Bad

In case of `App` received before `Batch` or `Batch` received not in single relayer message with all relevant `Apps`, the all always error ACK.

`Batch` received, but one of `App` packets timeout is less than `Batch` one. All `App` packets and `Batch` timeout.

If any `App` packet error `ACK`, all packets are errored. That means that all `App` packets executed in one atomic transaction.

If some `App` does nor timeouts not `ACK`, `Batch` packet also not timeouts nor `ACK`.

## Backwards Compatibility

`Batch` aware `App` packet will fail until `Batch` transferred. Relayer will burn gas and have to be aware of batches.

`Batch` packet holds off execution of ICS-100 until all packets arrived.  