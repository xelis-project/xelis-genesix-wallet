# Rust and FFI Guidelines

## Rust Module Boundaries
- Keep Rust wallet/domain logic in `rust/src/api/**`.
- Keep `rust/src/lib.rs` focused on public bridge-facing exports.
- Prefer small, testable modules over large monolithic files.

## Error and Logging
- Return explicit error contexts; avoid opaque failures.
- Use existing logging patterns and levels consistently.
- Avoid panics in FFI-facing paths unless unrecoverable.

## Feature Flags and Platform Paths
- Respect existing cargo feature flags (`network_handler`, `xswd`).
- Keep wasm and native compatibility constraints explicit when changing dependencies.

## Flutter Rust Bridge Contract
- Any Rust API signature change must be mirrored through regenerated bridge code.
- Do not manually patch generated bridge files in Dart or Rust outputs.
- After FFI changes, run generation and verify Dart call sites compile.

