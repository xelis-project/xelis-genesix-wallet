# Codex-Specific Notes

## Operating Style
- Start from local repository context, then implement directly.
- Keep edits practical, minimal, and verifiable.
- Communicate assumptions when requirements are ambiguous.

## Command Strategy
- Prefer fast repo search (`rg`); `justfile` aliases are optional shortcuts, not a preferred path for agents.
- Run only checks that match the changed surface area.
- If a check cannot run, state it explicitly in delivery notes.

## UI/UX Defaults
- For Flutter UI/UX work, use Forui as the primary library by default.
- Reuse existing components in `lib/shared` before creating new UI building blocks.

## Collaboration Expectations
- Keep summaries concise and file-referenced.
- Call out risks, regressions, and missing validation early.
