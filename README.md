# Interchain Standards Development

## Synopsis

This repository is the canonical location for development and documentation of inter-chain standards utilized by the Cosmos network & interchain ecosystem. Initially it will be used to consolidate design documentation for the inter-blockchain communication protocol (IBC), encoding standards for Cosmos chains, and miscellaneous utilities such as off-chain message signing.

## Standardization

Please see [ICS 1](spec/ics-1-ics-standard) for a description of what a standard entails.

To propose a new standard, [open an issue](https://github.com/cosmos/ics/issues/new). To start a new standardization document, copy the [template](spec/ics-template.md) and open a PR.

See [PROCESS.md](PROCESS.md) for a description of the standardization process.

## IBC Quick References

The subject of most initial interchain standards is the inter-blockchain communication protocol, "IBC".

If you are diving in or planning to review specifications, the following are recommended reading:
- [IBC Architecture](./ibc/1_IBC_ARCHITECTURE.md)
- [IBC Design Principles](./ibc/2_IBC_DESIGN_PRINCIPLES.md)
- [IBC Terminology](./ibc/3_IBC_TERMINOLOGY.md)
- [IBC Usecases](./ibc/4_IBC_USECASES.md)
- [IBC specification progress tracking](https://github.com/cosmos/ics/issues/26)

## Interchain Standards

All standards in the "draft" stage are listed here in order of their ICS numbers, sorted by category.

### Meta

| Interchain Standard Number   | Standard Title             | Stage |
| ---------------------------- | -------------------------- | ----- |
| [1](spec/ics-1-ics-standard) | ICS Specification Standard | Draft |

### IBC (Core)

| Interchain Standard Number                          | Standard Title                     | Stage |
| --------------------------------------------------- | ---------------------------------- | ----- |
| [3](spec/ics-3-connection-semantics)                | Connection Semantics               | Draft |
| [18](spec/ics-18-relayer-algorithms)                | Relayer Algorithms                 | Draft |
| [23](spec/ics-23-vector-commitments)                | Vector Commitments                 | Draft |
| [24](spec/ics-24-host-requirements)                 | Host Requirements                  | Draft |

## Standard Dependency Visualization

Directed arrows indicate a dependency relationship (that origin depends on destination).

![deps](deps.png)
