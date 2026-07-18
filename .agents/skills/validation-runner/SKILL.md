---
name: validation-runner
description: Select and run the right Genesix validation commands, then verify completion evidence for the requested outcome. Use after edits, before delivery, when checks fail, when generated output may be stale, or when deciding which checks and completion evidence are required.
---

# Validation Runner

Use this skill to validate the relevant changed surface and determine whether the requested outcome is actually demonstrated.

## Workflow

1. Inspect the final diff, touched files, and repository status.
2. Extract the material acceptance criteria from the request or plan. For a bugfix, include the original failure signal.
3. Map the changed files to the validation matrix in `AGENTS.md` and run required checks first.
4. Verify that generated output, skill mirrors, bridge artifacts, localization output, or other coupled artifacts are current when the changed surface requires them.
5. If a check fails, report the command, key error, relation to the change, likely cause, and next fix. Separate unrelated or pre-existing failures from regressions caused by the change.
6. Run a completion gate against each material acceptance criterion using the strongest available evidence. Record the verdict as `satisfied`, `not satisfied`, or `not verified`, and label supporting evidence as `automated` or `manual` when available.
7. Do not treat a successful command as proof of user-visible or contract behavior unless it directly exercises that outcome.
8. Do not run broad expensive checks when a focused check gives enough confidence unless risk justifies it.

## Common Commands

- Dart analysis: `dart analyze`
- Dart generators: `dart run build_runner build -d`
- Rust check: `cd rust && cargo check`
- Rust formatting when appropriate: `cd rust && cargo fmt`
- Flutter/Dart formatting when appropriate: `dart format .`
- FFI regeneration: `flutter_rust_bridge_codegen generate`

## Delivery

Report:

- Final changed surface and repository status.
- Commands run with pass/fail outcomes.
- Acceptance criteria with a `satisfied`, `not satisfied`, or `not verified` verdict and the `automated` or `manual` evidence supporting it.
- Skipped checks, unrelated failures, unverified outcomes, and residual risk.
