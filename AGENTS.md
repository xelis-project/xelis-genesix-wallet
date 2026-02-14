# Codex Guidelines - Genesix

This file is the Codex entrypoint for this repository.

## Priority Order
1. `AGENTS.md`
2. `docs/ai/tools/codex.md`
3. `docs/ai/shared/core-rules.md`
4. `docs/ai/shared/workflow.md`
5. `docs/ai/languages/dart-flutter.md`
6. `docs/ai/languages/rust-ffi.md`
7. `docs/ai/project-context.md`

## Critical Rules
- Treat `docs/ai/shared/core-rules.md` as the authoritative engineering rule set (`MUST`/`SHOULD`/`MAY`).
- Treat `docs/ai/shared/workflow.md` as the authoritative validation and delivery checklist.
- Apply Codex-specific behavior from `docs/ai/tools/codex.md`.
- When Rust API surface changes, run required regeneration and validation steps from `docs/ai/shared/workflow.md`.
- `just` tasks from `justfile` are optional shortcuts for developers, not a required or preferred path for agents.

## Full Guide
- Shared source of truth: `docs/ai/README.md`
