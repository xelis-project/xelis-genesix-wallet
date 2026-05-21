# Genesix Project Notes

Persistent notes for future agents and maintainers. Use this file for durable
technical context that is easy to forget, risky to rediscover by trial and
error, and too specific for the general rules in `AGENTS.md`.

## How To Use

- Read this file when onboarding or before dependency, storage, security,
  platform, or migration work.
- Keep entries short, dated, and tied to concrete files or packages.
- Prefer facts, constraints, and migration warnings over meeting-style notes.
- Remove or update entries when the underlying constraint no longer applies.

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
