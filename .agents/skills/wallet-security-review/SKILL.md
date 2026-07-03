---
name: wallet-security-review
description: Review wallet and application security risks in Genesix. Use when touching wallet lifecycle, session state, key material, storage, signing, transaction construction, Rust FFI, XSWD, logs, clipboard, QR/deep links, networking, permissions, dependencies, or error handling around sensitive data.
---

# Wallet Security Review

Use this skill for security-sensitive planning, implementation review, and threat modeling.

## Sensitive Surfaces

- Key material, seed phrases, private keys, passwords, PINs, mnemonics, and derived secrets.
- Wallet open, close, unlock, session, disposal, and storage lifecycle.
- Transaction creation, signing, serialization, fee calculation, and submission.
- Rust FFI boundaries, generated bridge contracts, and cross-language error handling.
- XSWD and external app/request boundaries.
- Clipboard, QR code, URI/deep link, file import/export, and network inputs.
- Logs, analytics, crash reports, debug output, and user-visible error details.
- Platform permissions, storage backends, web/native differences, and dependency changes.

## Review Workflow

1. Identify the trust boundary and what input is untrusted.
2. Identify what sensitive data can be read, written, logged, cached, copied, serialized, or displayed.
3. Evaluate the security tradeoff: benefit, new attack surface, complexity, regression risk, and safer alternatives.
4. Check lifecycle ordering for wallet/session open, close, cancellation, and disposal races.
5. Verify failures are explicit and do not silently continue with unsafe fallback state.
6. Check Rust FFI paths for panics, opaque errors, invalid assumptions, and generated-code impact.
7. Check dependency APIs against `pubspec.yaml` or `Cargo.toml` before relying on security behavior.
8. Recommend validation from `AGENTS.md` plus targeted tests for sensitive behavior when feasible.

## High-Risk Wallet Checks

- Signing, finalization, and broadcast flows must bind user confirmation to decoded transaction details and the exact transaction/hash being submitted; reject blank, stale, or generic confirmations.
- Multisig pending transactions and collected signatures must be scoped by an expected transaction hash or id; reject mismatched or stale pending state.
- Hash-only signing is blind signing: require strict hash validation, explicit high-risk labeling, and strong confirmation; prefer decoded unsigned transaction review when available.
- Never log raw QR, deep link, XSWD, clipboard, file, or network payloads; parse first and log only redacted metadata.
- For security findings, trace source to sink through Dart state, Rust FFI, signing/finalization, and broadcast before assigning severity.

## Security Rules

- Never log secrets, seed material, private keys, passwords, tokens, raw signatures, or full sensitive payloads.
- Treat all external input as untrusted, including clipboard, QR, URI/deep link, files, XSWD requests, and network responses.
- Prefer allowlists, typed parsing, and explicit validation over ad hoc string handling.
- Keep wallet lifecycle transitions deterministic; avoid double-open, stale session, and use-after-close paths.
- Do not expose lower-level cryptographic or storage errors with sensitive details in UI.
- Avoid broad catch-all recovery in signing, storage, or session code unless the resulting state is explicit and safe.
- Preserve web/native storage differences unless the task explicitly changes them.
- Do not introduce dependency upgrades, crypto changes, or permission expansion without calling out the security implication.
- Prefer smaller, auditable changes when a security benefit can be achieved without expanding attack surface.

## Output

Return findings with severity, affected surface, concrete file references, and a specific fix direction. If no issue is found, state the residual risk and validation gaps.
