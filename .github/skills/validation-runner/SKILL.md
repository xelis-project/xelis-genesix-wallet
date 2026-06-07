---
name: validation-runner
description: Select and run the right Genesix validation commands. Use after edits, before delivery, when checks fail, when generated output may be stale, or when deciding which Dart, Flutter, Rust, or documentation-only checks are required.
---

# Validation Runner

Use this skill to validate only the relevant changed surface while preserving confidence.

## Workflow

1. Inspect the diff and touched files.
2. Map files to the validation matrix in `AGENTS.md`.
3. Run required checks first.
4. If a check fails, summarize the failing command, key error, likely cause, and next fix.
5. Do not run broad expensive checks when a focused check gives enough confidence unless risk justifies it.

## Common Commands

- Dart analysis: `dart analyze`
- Dart generators: `dart run build_runner build -d`
- Rust check: `cd rust && cargo check`
- Rust formatting when appropriate: `cd rust && cargo fmt`
- Flutter/Dart formatting when appropriate: `dart format .`
- FFI regeneration: `flutter_rust_bridge_codegen generate`

## Delivery

Report commands run, pass/fail status, skipped checks, and why skipped checks were not needed.
