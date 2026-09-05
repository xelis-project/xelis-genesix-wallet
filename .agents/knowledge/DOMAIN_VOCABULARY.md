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
  and feature support from the package contract and local source. Sources:
  [Dart lifecycle](../../lib/features/wallet/application/xswd_lifecycle_provider.dart),
  [native adapter](../../lib/features/wallet/data/native_wallet_repository.dart).
- **XSWD session reference / application ID** (`current`): a session reference
  is the package-owned opaque identity of one native XSWD application session
  within its originating wallet. An application ID is declared metadata and may be shared
  by distinct local or relayed connections. It cannot replace the session
  reference for permission changes, cancellation, or closure. Reconstructed
  references and restored navigation data carry no live authority. Source:
  [XSWD policy](../../docs/xswd.md). Revisit when the package's session contract
  changes.
- **Network / node / daemon** (`current`): network selects the XELIS chain
  environment; node is the configured name and URL; daemon is the service at
  that URL. Do not use the three terms interchangeably. Sources:
  [node model](../../lib/features/wallet/domain/node_address.dart),
  [runtime connection](../../lib/features/wallet/application/wallet_runtime_provider.dart).
- **Native wallet repository / shared wallet package** (`current`):
  `NativeWalletRepository` is the Genesix adapter for the authored
  `xelis_wallet_flutter` API. The package repository owns the Rust wallet
  integration, generated bridge, stable Dart contracts, and native build
  tooling; Genesix owns application orchestration and projections. Source:
  [repository](../../lib/features/wallet/data/native_wallet_repository.dart).
- **Atomic amount** (`current`): an integer count of an asset's smallest unit.
  Standard transfer and burn amounts and fees use `BigInt` end to end; decimal
  strings and localized display values exist only at input and presentation
  boundaries. Source:
  [parser](../../lib/shared/utils/atomic_amount.dart).
- **Prepared transaction** (`current`): the exact authored
  `XelisWalletPreparedTransaction` returned by `xelis_wallet_flutter`. For a
  standard transfer or burn it is an opaque, single-attempt capability owned by
  the review flow until broadcast or discard. Its hash identifies what is
  reviewed but cannot replace or reconstruct the capability. Sources:
  [review state](../../lib/features/wallet/domain/transaction_review_state.dart),
  [commands](../../lib/features/wallet/application/wallet_commands_provider.dart).
- **Complete destination / base address** (`current`): the complete destination
  is the canonical standard or integrated address used for send and copy. A
  base address identifies the same public key after removing integrated data;
  it is grouping metadata and cannot replace the complete destination. Source:
  [AddressBook provider](../../lib/features/wallet/application/address_book_provider.dart).
- **Integrated address** (`current`): a complete XELIS destination that embeds a
  typed `DataElement`. The embedded value is visible to anyone holding the
  address; it is not secret and is not synonymous with a payment ID. User copy
  describes the value as **attached data**. Sources:
  [Receive UI](../../lib/features/wallet/presentation/home/receive_address_dialog.dart),
  [typed presentation](../../lib/features/wallet/domain/parsed_extra_data.dart).
- **Exact destination match** (`current`): equality of the base public key and
  canonical typed data. It is distinct from a base-only match and from an
  ambiguous set of saved destinations sharing the base. Only an exact match can
  assert a saved contact identity. Sources:
  [detail provider](../../lib/features/wallet/application/transaction_entry_detail_provider.dart),
  [history filter](../../lib/features/wallet/application/contact_history_providers.dart).
- **Multisig signing request** (`current`): a canonical, source-attested envelope
  containing an unsigned transaction, its network, and review metadata. Rust
  reparses the transaction, recomputes its multisig hash, verifies public fields,
  and resolves the latest active participant configuration from the connected
  node before signing. Each confidential transfer amount is verified with a
  canonical `BalanceProof` binding it to the exact sender ciphertext and source
  public key; source attestation alone is not sufficient for amount review.
  Sources: [flow and security model](../../docs/multisig-signing.md),
  [Dart adapter](../../lib/features/wallet/data/native_wallet_repository.dart).
  The canonical wire contract and Rust verification live in the
  `xelis_wallet_flutter` package.
- **Storage** (`current`): qualify the surface instead of saying only “storage”:
  native wallet data, wallet metadata/path persistence, secure storage, or
  non-secret preferences. These surfaces have different migration constraints.
  Sources: [wallet metadata](../../lib/features/authentication/application/wallets_provider.dart),
  [secure storage](../../lib/shared/storage/secure_storage/secure_storage_repository.dart).
