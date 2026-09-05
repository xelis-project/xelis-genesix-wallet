# Genesix Project Notes

Persistent notes for future agents and maintainers. Use this file for durable
technical context that is easy to forget, risky to rediscover by trial and
error, and too specific for the general rules in `AGENTS.md`.

This is not a glossary, architecture overview, task log, or general repository
map. Put stable domain terminology in `DOMAIN_VOCABULARY.md`; keep ordinary
workflow rules in `AGENTS.md` or the relevant skill.

## How To Use

- Read this file when onboarding or before dependency, storage, security,
  platform, or migration work.
- Keep entries short, dated, and tied to concrete files or packages.
- Prefer facts, constraints, and migration warnings over meeting-style notes.
- Add an entry only when rediscovering the fact would be costly or risky.
- Remove or update entries when the underlying constraint no longer applies.

## Architecture Transition

### 2026-07-18 - Material-to-Forui modernization

Genesix is actively moving from an experimental Material-era UI and provider
architecture toward a production-oriented Forui architecture.

Guidance:

- Classify a touched surface as legacy, transitional, or aligned with the target
  architecture before treating nearby code as precedent.
- Existing Material code documents current behavior but is not automatically the
  preferred pattern for new or materially refactored UI.
- Prefer Forui and current shared wrappers for new work while keeping migrations
  scoped to the requested surface. Do not turn a focused change into an
  unrelated application-wide rewrite.
- Preserve behavior, accessibility, localization, and mobile/desktop/web/native
  constraints while modernizing a surface.

Invalidation:

- Update or remove this note when the Material-era migration is complete and
  the target UI architecture is consistently represented across the repository.

## Multisig

### 2026-07-19 - Confidential multisig transfer review

Every amount displayed for a confidential multisig transfer must be bound to
the exact sender ciphertext and source public key by a canonical
`BalanceProof`. Parsing must reject a missing, reordered, non-canonical, or
invalid proof; source attestation alone is not sufficient for cosigner review.

The signing envelope must not serialize plaintext `extra_data`. Cosigners can
verify and display its presence and the public destination, but encrypted
contents remain private to the sender and destination.

Source: the multisig contract owned by `xelis_wallet_flutter` and
`docs/multisig-signing.md` in Genesix.

Invalidation:

- Re-evaluate this rule if the upstream transaction proof format or ciphertext
  transcript changes.

## Shared Wallet Integration

### 2026-09-05 - Lossless XSWD transaction review on Web

XWF 0.3 delivers an immutable typed XSWD tree with exact `BigInt` integers.
Genesix adapts it directly to SDK 0.36 without `jsonEncode`/`jsonDecode`.
Do not introduce ordinary JSON decoding between these layers: on Web it can
round wide numeric tokens before SDK parsing. The canonical policy, regression
tests and evidence limits are in [the XSWD policy](../../docs/xswd.md).

Invalidation:

- Revalidate this path when XWF, SDK, FRB or Flutter changes affect projection,
  review binding or lifecycle. Typed DTO tests alone cannot replace the real
  browser integration; the proof targets Flutter JavaScript plus Rust/WASM.

### 2026-08-03 - Integrated destination identity and disclosure

AddressBook entries use the package-owned v2 store and opaque entry ID. The
complete canonical destination is the only send/copy authority. Several
integrated destinations may share one base address, especially exchange deposit
references; never key, deduplicate, filter, or choose them by base alone.
AddressBook-to-transfer navigation carries only the opaque entry ID; the
transfer screen resolves the complete destination in memory. Do not place the
complete integrated address in router extras, route arguments, or URLs because
restoration and debug observers may serialize or log it.

History lists and passive events expose attached-data metadata only. A contact
history filter passes the parsed complete destination so native Rust compares
base plus canonical `DataElement` before pagination. A transaction detail may
then fetch its typed payload by hash and use only an exact AddressBook match.
Base-only and ambiguous results must not silently name or replace a destination.

Integrated-address content and prepared attached data are revealed only after
an explicit user action. The former is visibly embedded in the address and has
no transaction plaintext flag. The latter is read only through the exact
prepared-object capability. Neither payload belongs in route persistence,
standard logs, analytics, crash reports, or support-reference metadata.

Invalidation:

- Re-evaluate the scan cost if upstream wallet storage gains a native
  integrated-data index or filtered cursor. Do not weaken exact semantics while
  optimizing it.
- Remove the non-destructive legacy AddressBook tree only in a separately
  reviewed storage migration after real wallet backups and rollback are proven.

### 2026-08-02 - Prepared transaction ownership

Transfer, burn, and multisig transaction flows use the authored
`xelis_wallet_flutter` contract. The exact prepared object is a single-attempt
capability and must remain attached to the Genesix review state; its hash is not
sufficient authority to broadcast or discard it. Broadcast recovery and the
five package outcomes are documented in `docs/error-handling.md`.

### 2026-08-02 - Apple lock regeneration

Genesix no longer owns a Rust crate or Flutter Rust Bridge codegen. Native
wallet code, generated bindings, and native build tooling are owned by
`xelis_wallet_flutter`.

The existing iOS and macOS `Podfile.lock` files still contain the historical
`rust_builder` pod. Do not hand-edit CocoaPods checksums. Regenerate both locks
with `pod install` on macOS after `flutter pub get`, then verify that they no
longer contain `rust_builder` before the next Apple distribution. XWF 0.3 uses
Native Assets, not a CocoaPods FFI plugin: do not require an
`xelis_wallet_flutter` pod or add one manually. Verify its native library in a
real Apple consumer build instead.

Invalidation:

- Remove this entry after both Apple locks have been regenerated and validated
  on macOS.

## Secure Storage

### 2026-05-21 - `flutter_secure_storage` Android namespace migration

Do not directly replace `AndroidOptions.sharedPreferencesName` with
`AndroidOptions.storageNamespace` in
`lib/shared/storage/secure_storage/secure_storage_repository.dart` as a
mechanical dependency-migration cleanup.

Context:

- `flutter_secure_storage` 10.1.0 deprecated `sharedPreferencesName` and added
  `storageNamespace`.
- `storageNamespace` isolates more than the data SharedPreferences; it also
  isolates config, wrapped-key storage, and Android KeyStore aliases.
- The plugin documentation describes automatic migration for cipher algorithm
  changes via `migrateOnAlgorithmChange`, and crash-resistant backup support
  via `migrateWithBackup`, but it does not document automatic migration from
  an existing `sharedPreferencesName` namespace to a `storageNamespace`.
- Upstream issue
  `juliansteenbakker/flutter_secure_storage#1126` reports Android data loss
  after replacing `sharedPreferencesName` with `storageNamespace`, with data
  still unavailable after reverting to `sharedPreferencesName`.

Implication:

- A direct replacement may make existing secure values unreadable on Android.
- If this migration is needed, implement it as a dedicated wallet/storage
  migration with explicit legacy read, new namespace write, rollback/fallback
  behavior, Android upgrade testing, and security review.
