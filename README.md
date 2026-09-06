# Genesix Wallet

[![CI Checks (Main)](https://github.com/xelis-project/xelis-genesix-wallet/actions/workflows/ci_checks_main.yml/badge.svg)](https://github.com/xelis-project/xelis-genesix-wallet/actions/workflows/ci_checks_main.yml)
[![CI Checks (Dev)](https://github.com/xelis-project/xelis-genesix-wallet/actions/workflows/ci_checks_dev.yml/badge.svg)](https://github.com/xelis-project/xelis-genesix-wallet/actions/workflows/ci_checks_dev.yml)
[![Latest release](https://img.shields.io/github/v/release/xelis-project/xelis-genesix-wallet?display_name=tag)](https://github.com/xelis-project/xelis-genesix-wallet/releases)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Genesix is a cross-platform wallet application for XELIS, built to deliver a smooth and secure experience on desktop and mobile.

It reuses the same [`xelis_wallet`](https://github.com/xelis-project/xelis-blockchain) core library as the XELIS Wallet CLI, so both clients share the same wallet primitives and core security model while offering different user experiences.

## Why Genesix

- Cross-platform app for desktop and mobile environments.
- Rust-backed wallet logic bridged to Flutter.
- Focused UX for core wallet actions: create/import, send/receive, history, and balance.
- Reusable standard and integrated destinations, with attached data disclosed
  only in explicit review/detail flows.
- Open source and community-driven.

## Platform Support

| Platform | Build from source | Release assets |
| --- | --- | --- |
| Android | Yes | Yes |
| Windows | Yes | Yes |
| Linux | Yes | Yes |
| macOS | Yes (Apple lock regeneration required; see below) | Not in current release draft pipeline |
| iOS 14+ | Yes (Apple lock regeneration required; see below) | Not in current release draft pipeline |
| Web | Yes (special build flow) | No |

Download prebuilt artifacts from the [GitHub Releases page](https://github.com/xelis-project/xelis-genesix-wallet/releases).

Platform support is not evidence that the current Genesix revision has passed
release validation. See [Native release validation](#native-release-validation)
for packaging checks and the outstanding Apple lock regeneration.

## Quick Start (Developers)

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.47 or later,
  with Dart 3.13 or later, within the constraints in `pubspec.yaml`.
- [Rustup](https://www.rust-lang.org/tools/install) to install the Rust
  toolchain selected by the resolved wallet package (Rust 1.94.1 for XWF 0.3).
- For Android: JDK 21. Set `JAVA_HOME` and your IDE's Gradle runtime to the same
  JDK, then run `flutter config --jdk-dir="<jdk-21-home>"`.

The Rust toolchain is used by the `xelis_wallet_flutter` dependency when it
builds the native XELIS wallet library through Flutter Native Assets. Rust
sources and Flutter Rust Bridge generation belong to that package, not Genesix.

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
dart run build_runner build
```

### Run

```bash
flutter run
```

### Test

```bash
flutter test
flutter test --platform chrome test/xswd_web_permission_review_test.dart
```

On Linux, point FRB's host-test loader at the native assets built by Flutter:

```bash
FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR="$PWD/build/native_assets/linux" flutter test
```

This uses the default build directory and requires no separate Cargo build.
The override is for Linux host tests only, not application packaging or Web.

The dedicated Chrome test verifies exact XSWD transaction amounts, gas, fees,
nonces and limits above JavaScript's safe integer range, plus fail-closed bounds.
With Flutter 3.47.1, run that short browser suite on Linux CI: the Windows test
host fails to serve CanvasKit because its path check mixes native separators
and URL slashes. The real `flutter drive` harness below passes on Windows and
does not require a Flutter SDK patch or relaxed browser isolation.

The real relayer integration harness is separate from the default unit suite:

```bash
# Start a ChromeDriver matching the installed Chrome (loopback connections only).
chromedriver --port=4444 --allowed-ips=127.0.0.1
# In another terminal, after resolving dependencies and generating Dart sources:
dart --packages=.dart_tool/package_config.json tool/run_xswd_web_e2e.dart
```

Set `CHROMEDRIVER_PORT` if the driver uses another port and `CHROME_EXECUTABLE`
to select a matching browser binary. The harness builds the
resolved XWF package's Rust/WASM bundle into `web/pkg`, then runs the official
Flutter Web integration driver with COOP/COEP isolation headers. It requires
the same Rust nightly and `wasm-pack` setup as a Web build. Two ephemeral wallets
remain offline and never receive funds; a loopback relayer exercises real typed
requests and Genesix decisions, including reject, allow reaching the offline
handler, session replacement, explicit close and malformed-session cleanup.
It does not broadcast or prove immediate peer-only close detection. The driver
is started and stopped by the caller, not by this script. The manual **XSWD Web
integration** workflow reproduces this path from the resolved dependency.

### Build

```bash
flutter build <platform>
```

Examples: `flutter build windows`, `flutter build linux`, `flutter build apk`.

### Native release validation

Before distributing a native build, validate the target's actual Genesix release
artifact, including its packaged wallet library. Dependency resolution and XWF's
own consumer checks do not prove Genesix packaging; this also applies to Linux
and Apple targets.

The iOS and macOS `Podfile.lock` files still reference the historical
`rust_builder` pod. On macOS, run `flutter pub get`, then `pod install` in each
of `ios/` and `macos/`. Review the regenerated locks and confirm that
`rust_builder` is absent before building and validating both Apple targets.
Do not hand-edit CocoaPods checksums or add a replacement XWF pod: XWF 0.3 uses
Native Assets. Keep this warning until both locks and Apple builds are validated.

## Optional `just` Helpers

If you use [just](https://just.systems/), `just init` bootstraps the project,
`just gen` regenerates Dart code, `just update` refreshes dependencies and
generated code, and `just run_web` prepares the web wallet package before
launching Chrome.

These helpers are optional. `just run_web` uses the Web build executable from
the resolved `xelis_wallet_flutter` dependency, then launches Chrome. It
requires `wasm-pack`, Rust nightly, and the WebAssembly target. A local
`pubspec_overrides.yaml` may select a local XWF checkout for cross-repository
development and is intentionally ignored by Git.

## Architecture (Short Version)

- Flutter app code: `lib/`
- Shared native XELIS wallet runtime, authored Flutter API, and private bridge:
  the [`xelis_wallet_flutter`](https://github.com/xelis-project/xelis-wallet-flutter)
  dependency
- Multisig request and cosigning flow: [`docs/multisig-signing.md`](docs/multisig-signing.md)
- Error, logging, localization, and support-reference flow: [`docs/error-handling.md`](docs/error-handling.md)
- Typed wallet runtime and business-event lifecycles: [`docs/runtime-events.md`](docs/runtime-events.md)
- XSWD support, security policy, and deferred-work register: [`docs/xswd.md`](docs/xswd.md)

## Security Notes

- Back up your seed/recovery phrase before using real funds.
- Never share your seed phrase with anyone.
- Data embedded in an integrated address is visible to anyone who receives that
  address; never put passwords, seeds, private keys, or authentication tokens in it.
- Consider using a dedicated device profile for wallet operations.

If you discover a vulnerability, report it privately via [GitHub Security Advisories](https://github.com/xelis-project/xelis-genesix-wallet/security/advisories/new).

## Contributing

- Open bugs and feature requests in [GitHub Issues](https://github.com/xelis-project/xelis-genesix-wallet/issues).
- For usage questions and community support, join [XELIS Discord](https://discord.gg/z543umPUdj).

## License

This project is licensed under the [GNU GPL v3.0](LICENSE).
