# Genesix AI Agent Guidelines

Canonical repository guidance for Codex, Claude, GitHub Copilot, and compatible agents.
Direct system, developer, and user instructions take precedence, followed by this
file, tool adapters, and compatible nested instructions.

## Repository Context

- Genesix is a Flutter wallet consuming the authored `xelis_wallet_flutter` API.
- Features live under `lib/features`; shared services and UI under `lib/shared`.
- Entry point: `lib/main.dart`; routing: `lib/features/router`; native adapter:
  `lib/features/wallet/data/native_wallet_repository.dart`.
- Check `pubspec.yaml` and the resolved package source for dependency APIs.
  Rust, Cargo, and bridge sources belong to the wallet package repository.

## Working Principles

- Work directly by default. Use a plan, skill, or subagent when it helps with
  complexity, uncertainty, or an independent review; none is a routine prerequisite.
- Inspect the relevant source and existing changes. Preserve unrelated work,
  stay within the request, and avoid incidental refactors or formatting churn.
- Prefer the simplest coherent change using existing helpers and local patterns.
  Preserve compatibility unless the requested change allows otherwise.
- Explain meaningful tradeoffs, dependency upgrades, and migrations. Routine
  implementation choices do not need a formal impact assessment.
- For bugs, establish a supported cause and use the smallest reliable reproduction
  or check. Investigate uncertain failures more deeply; reassess when attempts fail.
  A diagnosis-only request does not authorize a fix.
- Prefer feature-local Riverpod patterns, typed GoRouter routes, lean widgets,
  and immutable models where they fit. Keep route extras and codecs consistent.
- Prefer Forui and shared components for UI changes; existing Material surfaces
  can remain. Use `package:material_ui/material_ui.dart` for Material widgets
  and `package:flutter/widgets.dart` for shared primitives.
- Prefer readable functions and small widgets. Local functions and closures are
  fine when clear; extract complex or reused logic when that improves readability.
- Preserve responsive behavior and use APIs compatible with installed versions.
- Consult the resources below for the subject being changed. Update documentation
  when a durable behavior or developer procedure changes; no routine guidance report.
- Summarize the change, checks performed, and important limitations. Distinguish
  passing checks from behavior actually verified; no fixed verdict format is needed.
- Commit only when authorized, using a concise Conventional Commit message.
  Push only when requested.

## Essential Protections

- Never expose secrets or sensitive wallet payloads in logs, analytics, crash
  reports, navigation persistence, or support messages. Treat external input as untrusted.
- Consume only the package-root authored wallet API; never import
  `xelis_wallet_flutter/src/**` or add a local Rust crate or FRB copy.
  Make package changes in its own repository under its guidance.
- Preserve `XelisWalletException` metadata unchanged. Application failures use
  stable identifiers owned by the recovery boundary; see the error contract below.
- Preserve Rust `u64` values as `BigInt`. Transfer/burn amounts and fees remain
  atomic through parsing, preparation, review, and display; fee multipliers use
  integer basis points. Use `parseAtomicAmount` and `formatBigInt`.
  Do not pass `BigInt` to pinned `intl 0.20.3` `NumberFormat` or narrow values
  beyond JavaScript's safe integer range; recheck this on an `intl` upgrade.
- Keep runtime and business events on their separate authored typed subscriptions.
  Preserve session ownership, cancellation ordering, and stale-consumer checks;
  do not recreate the removed JSON stream or local event union.
- Bind XSWD actions to the originating wallet and exact opaque session reference,
  never an application ID. Restored routes cannot regain live session authority.
- Keep the exact prepared transaction from preparation through authenticated
  confirmation, broadcast, or discard. A hash alone never grants authority.
- Use the complete canonical destination for send/copy and the opaque AddressBook
  entry ID for state and navigation. Base-address matches are not contact identity.
- Keep passive reads metadata-only and reveal attached data only on explicit
  user action through the appropriate authored capability.
- Regenerate `*.g.dart`, `*.freezed.dart`, and `lib/src/generated/l10n/**`;
  do not patch generated output manually. Regenerate package bridges in their owner.
- Update every locale ARB when localization keys change and preserve key parity.
- In wallet copy, use “attached data” for the embedded value and “integrated
  address” for the complete destination; use “payment ID” only for a proven schema.

## Proportionate Validation

Choose checks for the changed behavior and its risk, rather than a fixed matrix.

- Documentation: inspect links, consistency, and the diff. For AI guidance run
  `dart tool/validate_ai_guidelines.dart` to check entrypoints, profiles, and mirrors.
- Dart: analyze the affected scope and format touched files. Use broader
  `dart analyze` when changes span shared code or multiple features.
- Behavior fixes: use a focused test or reliable reproduction where possible.
- Changed generator annotations: run `dart run build_runner build`; changed ARBs:
  run `flutter gen-l10n`. Inspect generated output and relevant call sites.
- Shared or sensitive changes: expand tests based on actual risks to signing,
  session lifecycle, storage, permissions, or other affected behavior.
- Native contract changes: follow the owning package's generation and validation
  requirements, then verify affected Genesix consumers. Consumer-only edits do
  not automatically require the package suite, full Flutter suite, or a build.
- Use a full suite or platform build when the affected behavior warrants it.
  Report important unverified outcomes without cataloguing every omitted command.
- Before delivery, inspect the final diff and status for unintended changes.

## Resources

Read the relevant contract when changing its behavior; these are not a general
reading checklist.

| Subject | Reference |
| --- | --- |
| Failures, logging, prepared transaction recovery and disclosure | [Error handling](docs/error-handling.md) |
| Typed events, connection rotation, lag and session lifecycle | [Runtime events](docs/runtime-events.md) |
| XSWD session authority, permissions and platform capabilities | [XSWD](docs/xswd.md) |
| Integrated destinations and platform/storage constraints | [Project notes](.agents/knowledge/PROJECT_NOTES.md) |
| Ambiguous domain terms | [Domain vocabulary](.agents/knowledge/DOMAIN_VOCABULARY.md) |

Skills live in `.agents/skills`; identical mirrors live in `.claude/skills` and
`.github/skills`. Select only those useful to the task:

- `repo-onboarding`: targeted repository orientation.
- `implementation-planning`: complex or ambiguous implementation planning.
- `systematic-diagnosis`: evidence-based bug investigation.
- `flutter-riverpod-change`: state, routing, models, and application behavior.
- `flutter-forui-ux-design`: UI workflows, Forui APIs, and responsive design.
- `wallet-security-review`: sensitive wallet boundaries and security review.
- `rust-ffi-change`: shared wallet contracts and consumer integration.
- `validation-runner`: choosing checks and reporting their limits.
- `code-review`: concrete correctness and regression findings.
- `ai-guidelines-maintenance`: canonical guidance and mirror consistency.

Optional profiles are available in `.codex/agents`, `.claude/agents`, and
`.github/agents`: `codebase-explorer`, `quick-implementer`, `implementation-worker`,
`ui-ux-designer`, `security-reviewer`, `validation-runner`, `code-reviewer`, and
`guidelines-maintainer`. Keep their names and behavior aligned across tools.

When delegating, assign a bounded task and file ownership, preserve others' edits,
and consolidate results. Keep tightly coupled work together and avoid redundant
or recursive delegation unless explicitly useful and requested.
