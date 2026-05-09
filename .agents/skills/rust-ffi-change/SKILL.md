---
name: rust-ffi-change
description: Guide Rust wallet, FFI, flutter_rust_bridge, bridge contract, Cargo dependency, and cross-language changes in Genesix. Use when touching rust/src, Rust public APIs, FFI signatures, generated bridge output, or Dart call sites for Rust APIs.
---

# Rust FFI Change

Use this skill before changing Rust code or bridge-facing Dart code.

## Workflow

1. Read the affected Rust modules and Dart call sites.
2. Check `Cargo.toml` before using crate APIs.
3. Identify whether public Rust APIs or FFI signatures change.
4. Keep `rust/src/lib.rs` focused on bridge-facing exports.
5. Keep wallet/domain logic under `rust/src/api/**`.
6. Regenerate bridge output when signatures change.

## Rules

- Do not manually edit generated bridge files.
- Preserve native and wasm constraints.
- Respect feature flags such as `network_handler` and `xswd`.
- Return explicit error context in FFI-facing paths.
- Avoid panics unless unrecoverable.
- Do not define named functions inside other functions.

## Validation

For Rust-only changes, run `cd rust && cargo check`. For FFI signature changes, run bridge generation, build_runner, `cargo check`, and `dart analyze` as listed in `AGENTS.md`.
