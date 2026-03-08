# Codex-Specific Notes

## Operating Style
- Start from local repository context, then implement directly.
- Keep edits practical, minimal, and verifiable.
- Communicate assumptions when requirements are ambiguous.

## Command Strategy
- Prefer fast repo search such as `rg`.
- Run only checks that match the changed surface area.
- If a check cannot run, state it explicitly in delivery notes.
- `justfile` aliases are optional shortcuts, not a preferred path for agents.

## Output Expectations
- Keep summaries concise and file-referenced.
- Report what changed, what was validated, and what was not validated.
- Call out risks, regressions, missing validation, or version assumptions early.