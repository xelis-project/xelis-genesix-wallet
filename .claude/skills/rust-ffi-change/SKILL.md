---
name: rust-ffi-change
description: Guide cross-repository native wallet, FFI, bridge-contract, and Dart integration changes between xelis-wallet-flutter and Genesix. Use when changing the shared package contract or its Genesix call sites.
---

# Rust FFI Change

Use this skill before changing the shared native-wallet contract or its
Genesix-facing Dart integration.

## Workflow

1. Read both repositories' `AGENTS.md` files and the affected Dart call sites.
2. Inspect the resolved `xelis_wallet_flutter` public contract before changing
   Genesix.
3. Make Rust, Cargo, authored package API, and bridge changes only in the
   package repository.
4. Regenerate the package bridge with its supported generator script.
5. Update Genesix adapters/providers atomically with the package signature.
6. Validate the package first and Genesix as a consumer second.

## Rules

- Do not add a local Rust crate or generated bridge to Genesix.
- Do not manually edit generated package bridge files.
- Preserve native and wasm constraints.
- Return explicit error context in FFI-facing paths.
- Avoid panics unless unrecoverable.
- Do not define named functions inside other functions.

## Validation

Run the package's bridge generation, Rust checks, analysis, and tests. Then run
Genesix analysis/tests and at least one relevant consumer build as listed in
both repositories' `AGENTS.md` files.
