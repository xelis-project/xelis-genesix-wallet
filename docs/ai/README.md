# AI Guidelines - Shared Source of Truth

This folder defines one harmonized rule set for Codex and GitHub Copilot.

## Design Goal
- Keep one shared standard for architecture, quality, and conventions.
- Keep tool-specific behavior minimal and explicit.
- Reduce drift by referencing the same files from both entrypoints.

## File Layout
- `docs/ai/project-context.md`: repository-specific context and integration points.
- `docs/ai/shared/core-rules.md`: mandatory cross-cutting engineering rules.
- `docs/ai/shared/workflow.md`: delivery checklist and validation commands.
- `docs/ai/languages/dart-flutter.md`: Dart/Flutter conventions.
- `docs/ai/languages/rust-ffi.md`: Rust and FFI conventions.
- `docs/ai/tools/codex.md`: Codex-specific behavior.
- `docs/ai/tools/github-copilot.md`: Copilot-specific behavior.

## Precedence
1. Tool entrypoint (`AGENTS.md` for Codex, `.github/copilot-instructions.md` for Copilot)
2. Tool-specific file under `docs/ai/tools/`
3. Shared rules under `docs/ai/shared/`
4. Language-specific rules under `docs/ai/languages/`
5. `docs/ai/project-context.md`

## Maintenance
- Update shared files first, then keep both entrypoints aligned.
- Keep examples command-oriented and repo-accurate.
- Prefer additive, reviewed updates over large rewrites.

