---
name: rust-ffi-change
description: Guide cross-repository native wallet, FFI, bridge-contract, and Dart integration changes between xelis-wallet-flutter and Genesix. Useful when changing the shared package contract or its Genesix call sites.
---

# Rust FFI Change

Distinguish a Genesix consumer edit from a change to the shared wallet contract.

- Inspect the resolved `xelis_wallet_flutter` authored public API and relevant call sites.
- Consume the package-root API only; never add a local Rust crate, generated bridge,
  or import of package internals in Genesix.
- For package changes, follow that repository's guidance, regenerate there using
  its supported script, and validate there before checking Genesix consumers.
- Update affected adapters/providers consistently with changed signatures.
- Preserve native/Web constraints, exact integers, capabilities, and authored
  failure metadata. Keep FFI failures explicit and avoid recoverable-path panics.

Use focused analysis/tests for consumer-only changes. Expand to a relevant native
or Web build when the boundary being changed needs it; a build and full package
suite are not automatic requirements for every call-site edit.
