# Project Context

## Repository Shape
- Genesix is a Flutter application organized with a feature-first structure under `lib/features`.
- Cross-feature utilities, services, storage adapters, and reusable UI primitives live under `lib/shared`.
- The app targets multiple platforms; some integrations differ between web and native environments.

## Core Stack
- Flutter and Dart power the app layer.
- Riverpod is the main state-management approach used across the project.
- For Flutter UI, Forui is the preferred design/component library when it fits the existing feature.
- Wallet core logic is Rust-based and exposed to Flutter through `flutter_rust_bridge`.
- Dart code generation is part of the repository workflow, including generated outputs such as `*.g.dart`, `*.freezed.dart`, and Rust bridge outputs under `lib/src/generated/**`.

## Main Integration Points
- Flutter entrypoint: `lib/main.dart`
- Typed routing: `lib/features/router/routes.dart`, `lib/features/router/router.dart`
- Flutter wrapper around the Rust wallet: `lib/features/wallet/data/native_wallet_repository.dart`
- Rust FFI entry: `rust/src/lib.rs`
- Rust API modules: `rust/src/api/**`

## Source of Truth for Versions
- Dart/Flutter dependency versions are defined in `pubspec.yaml`.
- Rust crate versions and features are defined in `Cargo.toml`.
- Agents should treat these manifests as the source of truth before using external package or crate APIs.

## Generated and Sensitive Areas
- Changes to Rust public APIs or FFI signatures can require bridge regeneration and Dart-side updates.
- Changes to annotated Dart models, providers, or serializers can require build_runner regeneration.
- Changes to typed routing must stay consistent across route definitions and call sites.
- Wallet lifecycle, session state, and storage-related code are sensitive because initialization and close/open ordering matter.

## Platform and Storage Notes
- Web and native storage paths differ; storage adapters exist under `lib/shared/storage/**`.
- Platform-specific behavior should be preserved unless the task explicitly requires changing it.
- Wallet state is lifecycle-sensitive; avoid changing ordering or disposal behavior without checking existing flows.

## Developer Tooling
- The repository uses `flutter_rust_bridge`, `build_runner`, and Rust/Cargo tooling as part of normal development.
- `justfile` contains optional developer shortcuts, but it is not the authoritative source of workflow rules.
- Validation and generation steps are defined in `docs/ai/shared/workflow.md`.