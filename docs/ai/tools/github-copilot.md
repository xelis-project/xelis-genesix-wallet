# GitHub Copilot-Specific Notes

## Prompt and Output Quality
- Prefer concrete, file-scoped requests over broad prompts.
- For complex tasks, explicitly ask Copilot to follow `docs/ai/shared/*` and the relevant language file.
- Request small diffs first, then iterate.

## Repository Expectations
- Reuse existing architecture under `lib/features` and `lib/shared`.
- Prefer Forui for Flutter UI work when it fits the existing feature.
- Reuse existing UI elements from `lib/shared` before creating new components.
- Do not edit generated files directly.
- For Rust, Riverpod generator, Freezed, or model contract changes, include required regeneration steps in the expected output.

## Suggested Prompt Pattern
- Context: target files and current behavior
- Goal: expected behavior and constraints
- Version check: relevant package/crate versions to respect
- Validation: commands to run from `docs/ai/shared/workflow.md`
- Output shape: patch/diff plus short rationale