# Rust and FFI Guidelines

## Dependency Compatibility
- Read crate versions and features from `Cargo.toml` before suggesting code that depends on third-party crates.
- Use APIs compatible with the installed crate versions and enabled features.
- Do not silently use newer crate APIs if the project is pinned to older versions.
- If a requested solution requires a crate upgrade or migration, state it explicitly.

## Rust Module Boundaries
- Keep Rust wallet/domain logic in `rust/src/api/**`.
- Keep `rust/src/lib.rs` focused on public bridge-facing exports.
- Prefer small, testable modules over large monolithic files.
- Do not define functions inside other functions.
- Use private module-level helpers for readability and testability.
- Anonymous closures are allowed only for short callback or adapter usage.
- If closure logic becomes non-trivial or reused, extract a private helper function.

## Error and Logging
- Return explicit error contexts; avoid opaque failures.
- Use existing logging patterns and levels consistently.
- Avoid panics in FFI-facing paths unless unrecoverable.

## Feature Flags and Platform Paths
- Respect existing cargo feature flags such as `network_handler` and `xswd`.
- Keep wasm and native compatibility constraints explicit when changing dependencies.

## Flutter Rust Bridge Contract
- Any Rust API signature change must be mirrored through regenerated bridge code.
- Do not manually patch generated bridge files in Dart or Rust outputs.
- After FFI changes, run generation and verify Dart call sites compile.

## Reuse and Simplicity
- Avoid over-engineering.
- Prefer the simplest change that preserves clarity and safety.
- Reuse existing patterns in neighboring modules before introducing new abstractions.