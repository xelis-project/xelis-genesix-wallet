---
name: repo-onboarding
description: Understand the Genesix repository before making changes. Use when starting work in this repo, onboarding an agent, locating architecture boundaries, finding validation commands, or answering broad questions about project structure.
---

# Repo Onboarding

Use this skill to build accurate local context before planning or editing.

## Workflow

1. Read `AGENTS.md` first.
2. Read `.agents/knowledge/DOMAIN_VOCABULARY.md` when the task crosses layers or uses ambiguous wallet, runtime, node, daemon, storage, transaction, FFI, or XSWD terms.
3. Read `.agents/knowledge/PROJECT_NOTES.md` before dependency, storage, security, platform, or migration work; treat it as exceptional durable context, not a repository overview.
4. For UI or provider work, classify the touched surface as legacy, transitional, or target architecture before using neighboring code as precedent.
5. Inspect task-relevant files instead of relying on the knowledge documents as API references.
6. Check dependency versions in `pubspec.yaml` or `Cargo.toml` before using third-party APIs.
7. Identify generated-file impact before proposing edits.
8. Map the likely validation surface from the matrix in `AGENTS.md`.

## Repository Map

- Flutter application code: `lib/`
- Feature code: `lib/features/<feature>/...`
- Shared code: `lib/shared/...`
- Routing: `lib/features/router/**`
- Rust bridge entry: `rust/src/lib.rs`
- Rust API modules: `rust/src/api/**`
- Generated bridge output: `lib/src/generated/**`
- Stable domain terms: `.agents/knowledge/DOMAIN_VOCABULARY.md`
- Exceptional durable constraints: `.agents/knowledge/PROJECT_NOTES.md`

## Output

Return concise findings with file references and call out unknowns that still require source inspection.
