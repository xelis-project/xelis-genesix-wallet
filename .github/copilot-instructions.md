# GitHub Copilot Instructions - Genesix

Use this file as the Copilot entrypoint and follow the shared AI rule set.

## Priority Order
1. `.github/copilot-instructions.md`
2. `docs/ai/tools/github-copilot.md`
3. `docs/ai/shared/core-rules.md`
4. `docs/ai/shared/workflow.md`
5. `docs/ai/languages/dart-flutter.md`
6. `docs/ai/languages/rust-ffi.md`
7. `docs/ai/project-context.md`

## Critical Rules
- Treat `docs/ai/shared/core-rules.md` as the authoritative engineering rule set (`MUST`/`SHOULD`/`MAY`).
- Treat `docs/ai/shared/workflow.md` as the authoritative validation and delivery checklist.
- Apply Copilot-specific behavior from `docs/ai/tools/github-copilot.md`.
- If Rust API or annotated Dart models/providers change, include required regeneration and validation steps from `docs/ai/shared/workflow.md`.
- `just` tasks from `justfile` are optional developer shortcuts, not a required or preferred path for agents.

## Full Guide
- Shared source of truth: `docs/ai/README.md`
