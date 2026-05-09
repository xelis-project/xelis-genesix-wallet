---
name: repo-onboarding
description: Understand the Genesix repository before making changes. Use when starting work in this repo, onboarding an agent, locating architecture boundaries, finding validation commands, or answering broad questions about project structure.
---

# Repo Onboarding

Use this skill to build accurate local context before planning or editing.

## Workflow

1. Read `AGENTS.md` first.
2. Inspect task-relevant files instead of relying on memory.
3. Check dependency versions in `pubspec.yaml` or `Cargo.toml` before using third-party APIs.
4. Identify generated-file impact before proposing edits.
5. Map the likely validation surface from the matrix in `AGENTS.md`.

## Repository Map

- Flutter application code: `lib/`
- Feature code: `lib/features/<feature>/...`
- Shared code: `lib/shared/...`
- Routing: `lib/features/router/**`
- Rust bridge entry: `rust/src/lib.rs`
- Rust API modules: `rust/src/api/**`
- Generated bridge output: `lib/src/generated/**`

## Output

Return concise findings with file references and call out unknowns that still require source inspection.
