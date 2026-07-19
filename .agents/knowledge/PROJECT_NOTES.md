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

Source: `rust/src/multisig.rs`.

Invalidation:

- Re-evaluate this rule if the upstream transaction proof format or ciphertext
  transcript changes.

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
