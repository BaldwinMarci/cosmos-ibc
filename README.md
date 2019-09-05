# Interchain Standards

![banner](./assets/interchain-standards-image.jpg)

## Synopsis

This repository is the canonical location for development and documentation of inter-chain standards utilised by the Cosmos network & interchain ecosystem.

It shall be used to consolidate design rationale, protocol semantics, and encoding descriptions for the inter-blockchain protocol (IBC), including both the core transport, authentication, & ordering layer (IBC/TAO) and the application layers describing packet encoding & processing semantics (IBC/APP).

Contributions are welcome.

The rendered, ordered set of all interchain standards written so far can be read as [a single PDF](./spec.pdf).

## Standardisation

Please see [ICS 1](spec/ics-001-ics-standard) for a description of what a standard entails.

To propose a new standard, [open an issue](https://github.com/cosmos/ics/issues/new). To start a new standardisation document, copy the [template](spec/ics-template.md) and open a PR.

See [PROCESS.md](PROCESS.md) for a description of the standardisation process.

## IBC Quick References

If you are planning to review inter-blockchain communication protocol specifications, the following are required reading:

- [IBC Architecture](./ibc/1_IBC_ARCHITECTURE.md)
- [IBC Design Principles](./ibc/2_IBC_DESIGN_PRINCIPLES.md)
- [IBC Terminology](./ibc/3_IBC_TERMINOLOGY.md)
- [IBC Usecases](./ibc/4_IBC_USECASES.md)
- [IBC Design Patterns](./ibc/5_IBC_DESIGN_PATTERNS.md)

## Interchain Standards

All standards at or past the "Draft" stage are listed here in order of their ICS numbers, sorted by category.

### Meta

| Interchain Standard Number     | Standard Title             | Stage |
| ------------------------------ | -------------------------- | ----- |
| [1](spec/ics-001-ics-standard) | ICS Specification Standard | Draft |

### IBC/TAO

| Interchain Standard Number                          | Standard Title                     | Stage |
| --------------------------------------------------- | ---------------------------------- | ----- |
| [2](spec/ics-002-client-semantics)                | Validity Predicate                 | Draft |
| [3](spec/ics-003-connection-semantics)              | Connection Semantics               | Draft |
| [4](spec/ics-004-channel-and-packet-semantics)      | Channel & Packet Semantics         | Draft |
| [5](spec/ics-005-port-allocation)                   | Port Allocation                    | Draft |
| [18](spec/ics-018-relayer-algorithms)               | Relayer Algorithms                 | Draft |
| [23](spec/ics-023-vector-commitments)               | Vector Commitments                 | Draft |
| [24](spec/ics-024-host-requirements)                | Host Requirements                  | Draft |
| [25](spec/ics-025-handler-interface)                | Handler Interface                  | Draft |
| [26](spec/ics-026-relayer-module)                   | Relayer Module                     | Draft |

### IBC/APP

| Interchain Standard Number                 | Standard Title          | Stage |
| ------------------------------------------ | ----------------------- | ----- |
| [20](spec/ics-020-fungible-token-transfer) | Fungible Token Transfer | Draft |

## Standard Dependency Visualisation

Directed arrows indicate a dependency relationship (that origin depends on destination).

![deps](assets/deps.png)
