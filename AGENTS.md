# Genesix AI Agent Guidelines

This file is the canonical AI guidance for this repository. It is intentionally the central source for Codex, Claude, GitHub Copilot, and compatible coding agents.

## Instruction Priority

1. Direct system, developer, and user instructions.
2. This root `AGENTS.md`.
3. Tool adapters such as `CLAUDE.md` and `.github/copilot-instructions.md`.
4. More specific nested instruction files, when present, as long as they do not conflict with this file.

If any tool adapter conflicts with this file, follow `AGENTS.md` and update the stale adapter when the task is about AI guidelines.

## Repository Context

- Genesix is a Flutter wallet application with Rust wallet logic exposed through `flutter_rust_bridge`.
- Flutter feature code lives under `lib/features/<feature>/...`.
- Shared services, storage adapters, utilities, and reusable UI primitives live under `lib/shared/...`.
- Rust bridge-facing wallet code lives under `rust/src/api/**`; `rust/src/lib.rs` stays focused on public bridge exports.
- Main integration points:
  - Flutter entrypoint: `lib/main.dart`
  - Routing: `lib/features/router/routes.dart`, `lib/features/router/router.dart`
  - Native wallet repository: `lib/features/wallet/data/native_wallet_repository.dart`
  - Rust FFI entry: `rust/src/lib.rs`
- Source of truth for dependency versions:
  - Dart/Flutter: `pubspec.yaml`
  - Rust: `Cargo.toml`
- Generated files must be regenerated, not patched manually:
  - `**/*.g.dart`
  - `**/*.freezed.dart`
  - `lib/src/generated/**`
- Durable project notes for agents live in `.agents/knowledge/PROJECT_NOTES.md`.
  Read them during onboarding and before dependency, storage, security,
  platform, or migration work.

## Engineering Rules

- Keep changes tightly scoped to the user request.
- Reuse local architecture, helpers, providers, widgets, and patterns before adding new abstractions.
- Do not introduce broad refactors unless explicitly requested.
- Do not invent APIs, symbols, file paths, or dependency behavior; verify them from source first.
- Preserve backward compatibility unless the task explicitly allows a breaking change.
- Update documentation when behavior, workflow, architecture, or AI guidance changes.
- Do not declare named functions inside other functions in Dart or Rust. Use private file-level helpers, private methods, or small private widgets/classes instead.
- Anonymous closures are acceptable only for short callback glue. Extract non-trivial or reused logic.
- Do not hand-edit generated files.
- Before using a third-party package or crate API, read the installed version from `pubspec.yaml` or `Cargo.toml` and use compatible APIs.
- If a requested solution requires a dependency upgrade, migration, or generated output refresh, state that explicitly.
- `justfile` targets are developer shortcuts only. They are not the authoritative workflow for agents.

## Net Impact Discipline

- Before a non-trivial code change, evaluate the tradeoff: expected benefit, negative impact, complexity cost, regression risk, and simpler alternatives.
- Proceed only when the change has a clearly positive net impact for the requested goal.
- For small mechanical fixes, this evaluation may stay implicit.
- For architectural, security-sensitive, UX, dependency, lifecycle, storage, FFI, generated-code, or public API changes, state the tradeoff explicitly before or during implementation.
- If the tradeoff is unclear or negative, prefer a smaller change, a reversible step, or a plan/question before editing.

## Dart And Flutter

- Follow the feature-first structure under `lib/features`.
- Keep widgets lean; move business and persistence decisions into application, domain, or data layers.
- Reuse Riverpod patterns already established in the touched feature.
- Prefer `riverpod_generator` with `@riverpod` when it fits the local pattern and installed version.
- Do not introduce a second state-management style inside a feature.
- Prefer immutable typed models and Freezed-style unions when they improve correctness and match local code.
- When model, provider, serializer, or route annotations change, regenerate builders and verify call sites.
- Use typed GoRouter patterns already defined under `lib/features/router/**`.
- Keep route extras and codecs consistent when adding transfer objects.
- Prefer Forui for Flutter UI when it fits the existing feature.
- For Forui API details and migration work, consult `.agents/references/forui/llms.txt` and `.agents/references/forui/llms-full.txt`; refresh them with `dart run tool/sync_forui_docs.dart` when the API may have changed.
- Reuse `lib/shared` components and utilities before creating variants.
- Preserve responsive behavior across desktop, mobile, web, and native targets.
- Use modern Dart and Flutter idioms when they improve clarity and are supported by the installed SDK and package versions.

## Rust And FFI

- Read crate versions and enabled features from `Cargo.toml` before using third-party Rust APIs.
- Keep Rust modules small, testable, and consistent with neighboring modules.
- Respect cargo feature flags such as `network_handler` and `xswd`.
- Keep wasm and native constraints explicit when changing dependencies or platform paths.
- Return explicit error context and avoid opaque failures.
- Avoid panics in FFI-facing paths unless the condition is unrecoverable.
- Any Rust API or FFI signature change must be mirrored through regenerated bridge code and Dart call-site updates.
- Do not patch generated bridge files manually.

## Workflow

### Before Coding

- Confirm target files and current behavior from source.
- Evaluate the net impact of non-trivial changes using the rules above.
- Inspect whether generated output is impacted.
- Inspect relevant dependency versions when external package or crate APIs are involved.
- Check for existing user changes and do not revert unrelated work.

### During Coding

- Keep the change set logically coherent.
- Avoid unrelated formatting churn.
- Keep public methods, providers, DTOs, models, and route contracts explicit and consistent across layers.
- Use the simplest implementation that fits the current feature and architecture.

### Validation Matrix

| Change Surface | Must Inspect | Must Run | Should Run |
| --- | --- | --- | --- |
| Dart/Flutter UI, state, repository, routing without generated output impact | Affected files and package versions if external APIs are involved | `dart analyze` | `dart format .` |
| Riverpod generators, Freezed models, JSON/build_runner annotations | Affected annotations, generated output impact, package versions | `dart run build_runner build -d`, `dart analyze` | `dart format .` |
| Rust changes without FFI signature impact | Affected modules and crate dependencies if relevant | `cd rust && cargo check` | `cd rust && cargo fmt` |
| Rust FFI signature or bridge contract changes | Rust API surface, generated bridge impact, Dart call sites | `flutter_rust_bridge_codegen generate`, `dart run build_runner build -d`, `cd rust && cargo check`, `dart analyze` | `cd rust && cargo fmt`, `dart format .` |
| Dependency version changes | Manifests, impacted docs, affected call sites | Relevant analyze/check/build command for impacted area | Formatting commands |
| Security-sensitive wallet changes | Trust boundaries, sensitive-data handling, lifecycle ordering, storage/signing/FFI/XSWD/logging impact | Relevant analyze/check/build command for impacted area, plus `wallet-security-review` | Focused tests or security review subagent when risk justifies it |
| AI guideline/docs-only changes | Instruction entrypoints and links | Markdown/readability review and stale-reference search | No Dart/Rust checks unless code changed |

### Delivery Notes

- Summarize what changed and why.
- List validation commands run and outcomes.
- Call out skipped checks and why.
- Mention dependency/version assumptions when they materially affect the solution.

### Commit Messages

- When creating commits, use Conventional Commits (`type(scope): summary`).
- Prefer a single-line summary that reads like a concise sentence; it should be short, specific, and focused on the essential change without becoming cryptic.
- Use a commit body only when the motivation, tradeoff, or follow-up risk is not obvious from the diff.

## Agent Workflows

### Feature Or Change

1. Use `codebase-explorer` for non-blocking research when multiple areas need inspection.
2. Use `implementation-planning` before broad or multi-layer changes.
3. Implement in the smallest coherent slice.
4. Use `validation-runner` to select and run checks.
5. Use `code-reviewer` before delivery when the diff is non-trivial.

### Bugfix

1. Reproduce or identify the failing behavior from source, logs, tests, or user evidence.
2. Isolate the root cause before editing.
3. Apply the minimal fix that addresses the root cause.
4. Add or update focused tests when the risk justifies it.
5. Validate the changed surface.

### Review

- Lead with findings ordered by severity.
- Reference concrete files and lines.
- Focus on bugs, regressions, security, correctness, missing validation, and maintainability risk.
- If no issues are found, say so and mention residual test gaps.

### Dart/Flutter UI Or State

- Use the `flutter-riverpod-change` skill.
- Inspect local provider, widget, and repository patterns first.
- Prefer existing shared UI and feature-local conventions.
- Regenerate builders when annotated Dart changes require it.

### Flutter UX/UI Design

- Use the `flutter-forui-ux-design` skill.
- Treat Forui as the primary component library when it fits the task.
- Start from the user workflow and information hierarchy before styling.
- Preserve mobile, desktop, web, and native ergonomics.
- Use the `ui-ux-designer` subagent for design critique, UI audits, or non-blocking exploration of complex screens.

### Security-Sensitive Change

- Use the `wallet-security-review` skill.
- Use the `security-reviewer` subagent for independent review of sensitive diffs or threat-modeling work.
- Treat wallet lifecycle, session state, key material, storage, signing, FFI, XSWD, logs, clipboard, QR/deep links, networking, and dependency changes as sensitive surfaces.
- Prefer explicit failures and conservative defaults over silent fallback in security-sensitive paths.

### Rust FFI

- Use the `rust-ffi-change` skill.
- Treat public Rust API and bridge signatures as cross-language contracts.
- Regenerate bridge output and verify Dart call sites after signature changes.

### AI Guidelines Maintenance

- Use the `ai-guidelines-maintenance` skill.
- Keep `AGENTS.md` canonical.
- Keep Claude, Codex, and Copilot adapters short and non-conflicting.
- Prefer skills for reusable workflows and subagents for isolated or parallel work.
- Update mirrors when canonical skills change.

## Skills

Project skills are workflow playbooks. The canonical cross-tool source is `.agents/skills/**/SKILL.md`.

Mirror policy:

- `.agents/skills` is the canonical repo skill location.
- `.claude/skills` mirrors skills for Claude Code.
- `.github/skills` mirrors skills for GitHub Copilot.
- Keep mirrored `SKILL.md` files identical unless a tool requires a small compatibility note.

Project skills:

- `repo-onboarding`: understand repository shape, dependencies, and validation entrypoints.
- `implementation-planning`: produce decision-complete implementation plans.
- `flutter-riverpod-change`: guide Flutter, Riverpod, routing, model, and UI changes.
- `flutter-forui-ux-design`: guide UX/UI design for Flutter screens using Forui as the primary UI library.
- `wallet-security-review`: review wallet, storage, signing, FFI, XSWD, logging, input, and dependency security risk.
- `rust-ffi-change`: guide Rust, FFI, and bridge regeneration changes.
- `validation-runner`: choose and run relevant checks.
- `code-review`: perform risk-first code review.
- `ai-guidelines-maintenance`: maintain this AI guidance system.

## Subagents

Use subagents when work benefits from isolated context, parallel research, tool restrictions, or concise summaries from noisy tasks. Keep tightly coupled implementation in the main thread unless delegation is explicitly useful.

Native project profiles:

- Claude: `.claude/agents/*.md`
- Codex: `.codex/agents/*.toml`
- Copilot: `.github/agents/*.agent.md`

Project profiles:

- `codebase-explorer`: read-only repository exploration and source mapping.
- `implementation-worker`: bounded implementation work in assigned files.
- `ui-ux-designer`: UX/UI critique and design guidance for Flutter/Forui screens.
- `security-reviewer`: independent wallet/application security review and threat modeling.
- `validation-runner`: checks, test failure triage, and concise validation summaries.
- `code-reviewer`: risk-first review of diffs and changed behavior.
- `guidelines-maintainer`: maintenance of `AGENTS.md`, adapters, skills, and agent profiles.

Subagent rules:

- Give each subagent a concrete, bounded task.
- Avoid duplicate work between the main agent and subagents.
- For implementation subagents, define file ownership and remind them not to revert unrelated changes.
- Prefer read-only explorers for broad inspection.
- Use validation subagents for noisy checks when they can run independently.
- Consolidate results before editing or delivering.
