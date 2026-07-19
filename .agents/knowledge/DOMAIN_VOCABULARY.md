# Genesix Domain Vocabulary

This is a compact glossary, not an architecture document or API reference.
Keep only distinctions that prevent recurring ambiguity. Source code remains
authoritative; update or remove an entry when its linked contract changes.

Status labels:

- `current`: preferred term in the current architecture.
- `historical`: legacy name retained only to recognize stale code or history.

## Current Terms

- **Wallet session** (`current`): the application identity of an opened wallet,
  represented by its name and `NativeWalletRepository`. It may be absent.
  Sources: [model](../../lib/features/authentication/domain/wallet_session.dart),
  [provider](../../lib/features/authentication/application/wallet_session_providers.dart).
- **Wallet runtime** (`current`): the `WalletRuntime` Riverpod controller attached
  to the active session. Use this term for orchestration and lifecycle behavior,
  not for the native wallet itself. Source:
  [provider](../../lib/features/wallet/application/wallet_runtime_provider.dart).
- **Wallet runtime state** (`current`): the immutable `WalletRuntimeState`
  projection exposed to the Dart application. It is not the authoritative native
  wallet database. Source:
  [state](../../lib/features/wallet/domain/wallet_runtime_state.dart).
- **Wallet effect** (`current`): an ephemeral typed UI event, distinct from
  persistent runtime state. Source:
  [model](../../lib/features/wallet/domain/wallet_effect.dart).
- **XSWD** (`current`): the domain term for connections between external
  applications and the wallet. In Genesix, distinguish the local XSWD server,
  relay connections, and application lifecycle state; verify current platform
  and feature support from source. Sources:
  [Dart lifecycle](../../lib/features/wallet/application/xswd_lifecycle_provider.dart),
  [Rust routing](../../rust/src/api/xswd/mod.rs).
- **Network / node / daemon** (`current`): network selects the XELIS chain
  environment; node is the configured name and URL; daemon is the service at
  that URL. Do not use the three terms interchangeably. Sources:
  [node model](../../lib/features/wallet/domain/node_address.dart),
  [runtime connection](../../lib/features/wallet/application/wallet_runtime_provider.dart).
- **Native wallet repository / Rust bridge** (`current`):
  `NativeWalletRepository` is the authored Dart adapter; `rust/src/api/**` is the
  authored Rust API; `flutter_rust_bridge` output under `lib/src/generated/**`
  and `rust/src/frb_generated.rs` is generated. Sources:
  [repository](../../lib/features/wallet/data/native_wallet_repository.dart),
  [Rust entry](../../rust/src/lib.rs).
- **Storage** (`current`): qualify the surface instead of saying only “storage”:
  native wallet data, wallet metadata/path persistence, secure storage, or
  non-secret preferences. These surfaces have different migration constraints.
  Sources: [wallet metadata](../../lib/features/authentication/application/wallets_provider.dart),
  [secure storage](../../lib/shared/storage/secure_storage/secure_storage_repository.dart).

## Historical Aliases

- **WalletSnapshot** (`historical`): former name associated with the wallet state
  projection, now represented by `WalletRuntimeState`. Do not introduce this name
  in new code. Treat remaining `walletSnapshot` identifiers as migration relics,
  not evidence of a current `WalletSnapshot` type.
