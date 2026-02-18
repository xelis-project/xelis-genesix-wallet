# GitHub Copilot-Specific Notes

## Prompt and Output Quality
- Prefer concrete, file-scoped requests over broad prompts.
- Ask Copilot to follow `docs/ai/shared/*` and the relevant language file explicitly in prompts for complex tasks.
- Request small diffs first, then iterate.

## Repository-Specific Expectations
- Reuse existing architecture under `lib/features` and `lib/shared`.
- For Flutter UI/UX tasks, prefer Forui as the primary UI library.
- Reuse existing UI elements from `lib/shared` before creating new components.
- Do not edit generated files directly.
- For Rust or model contract changes, include codegen steps in requested output.

## Suggested Prompt Pattern
- Context: target files and current behavior.
- Goal: expected behavior and constraints.
- Validation: commands to run (from `docs/ai/shared/workflow.md`).
- Output shape: patch/diff plus short rationale.
