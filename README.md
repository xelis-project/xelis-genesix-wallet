# Genesix Wallet

[![CI (main)](https://github.com/xelis-project/xelis-genesix-wallet/actions/workflows/ci_checks_main.yml/badge.svg)](https://github.com/xelis-project/xelis-genesix-wallet/actions/workflows/ci_checks_main.yml)
[![CI (dev)](https://github.com/xelis-project/xelis-genesix-wallet/actions/workflows/ci_checks_dev.yml/badge.svg)](https://github.com/xelis-project/xelis-genesix-wallet/actions/workflows/ci_checks_dev.yml)
[![Latest release](https://img.shields.io/github/v/release/xelis-project/xelis-genesix-wallet?display_name=tag)](https://github.com/xelis-project/xelis-genesix-wallet/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Genesix is a cross-platform wallet application for XELIS, built to deliver a smooth and secure experience on desktop and mobile.

It reuses the same [`xelis_wallet`](https://github.com/xelis-project/xelis-blockchain) core library as the XELIS Wallet CLI, so both clients share the same wallet primitives and core security model while offering different user experiences.

## Why Genesix

- Cross-platform app for desktop and mobile environments.
- Rust-backed wallet logic bridged to Flutter.
- Focused UX for core wallet actions: create/import, send/receive, history, and balance.
- Open source and community-driven.

## Platform Support

| Platform | Build from source | Release assets |
| --- | --- | --- |
| Android | Yes | Yes |
| Windows | Yes | Yes |
| Linux | Yes | Yes |
| macOS | Yes | Not in current release draft pipeline |
| iOS | Yes | Not in current release draft pipeline |
| Web | Yes (special build flow) | No |

Download prebuilt artifacts from the [GitHub Releases page](https://github.com/xelis-project/xelis-genesix-wallet/releases).

## Quick Start (Developers)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Rust toolchain](https://www.rust-lang.org/tools/install)
- [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) :

```bash
cargo install flutter_rust_bridge_codegen
```

Linux build dependencies vary by distro. On Ubuntu/Debian, common packages include:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev libsecret-1-dev libjsoncpp-dev
```

### Clone

```bash
git clone https://github.com/xelis-project/xelis-genesix-wallet.git
cd xelis-genesix-wallet
```

### Bootstrap

```bash
flutter pub get
flutter_rust_bridge_codegen generate
dart run build_runner build -d
```

### Run

```bash
flutter run
```

### Build

```bash
flutter build <platform>
```

Examples: `flutter build windows`, `flutter build linux`, `flutter build apk`.

## Optional `just` Shortcuts

If you use [just](https://just.systems/), helper commands are available:

- `just init`
- `just gen`
- `just update`
- `just run_web`

These are optional convenience commands, not required.

## Architecture (Short Version)

- Flutter app code: `lib/`
- Rust wallet core and APIs: `rust/`
- Generated Flutter/Rust bridge code: `lib/src/generated/`

## Security Notes

- Back up your seed/recovery phrase before using real funds.
- Never share your seed phrase with anyone.
- Consider using a dedicated device profile for wallet operations.

If you discover a vulnerability, report it privately via [GitHub Security Advisories](https://github.com/xelis-project/xelis-genesix-wallet/security/advisories/new).

## Contributing

- Open bugs and feature requests in [GitHub Issues](https://github.com/xelis-project/xelis-genesix-wallet/issues).
- For usage questions and community support, join [XELIS Discord](https://discord.gg/z543umPUdj).

## License

This project is licensed under the [GNU GPL v3.0](LICENSE).
