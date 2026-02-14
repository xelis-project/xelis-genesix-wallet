# Project Context

## Big Picture
- Flutter app organized by feature modules in `lib/features` (authentication, wallet, settings, router).
- Shared utilities and UI primitives live in `lib/shared`.
- Wallet core logic is Rust-based and exposed to Flutter through `flutter_rust_bridge`.
- Generated Rust bridge code is under `lib/src/generated/**` and must be treated as generated artifacts.

## Main Integration Points
- Rust FFI entry: `rust/src/lib.rs`
- Rust API modules: `rust/src/api/**`
- Flutter wrapper around Rust wallet: `lib/features/wallet/data/native_wallet_repository.dart`
- App initialization: `lib/main.dart`
- Typed routing: `lib/features/router/routes.dart`, `lib/features/router/router.dart`

## Tooling and Codegen
- Task aliases: `justfile` (optional developer shortcuts).
- Typical direct bootstrap: `flutter pub get`
- Typical direct full update: `flutter pub get`, `cargo install flutter_rust_bridge_codegen`, `cd rust && cargo update`, `flutter_rust_bridge_codegen generate`, `dart run build_runner build -d`, `cd rust && cargo fmt`, `dart format .`
- Rust bridge generation: `flutter_rust_bridge_codegen generate` (or `just gen_rust_bridge`)
- Dart build_runner generation: `dart run build_runner build -d` (or `just gen_flutter`)
- Optional bundled shortcuts: `just init`, `just update`

## Platform and Storage Notes
- Web and native storage paths differ; shared preferences and secure storage adapters exist under `lib/shared/storage/**`.
- Wallet lifecycle is stateful; active wallet close/open ordering matters.
