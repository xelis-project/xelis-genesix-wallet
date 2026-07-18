---
name: ai-guidelines-maintenance
description: Maintain Genesix AI instructions, AGENTS.md, Claude/Copilot adapters, skills, and subagent profiles. Use when editing AI guidelines, adding workflows, syncing skills, changing agent behavior, or checking compatibility across Claude, Codex, and GitHub Copilot.
---

# AI Guidelines Maintenance

Use this skill when maintaining the repository AI guidance system.

## Source Of Truth

- `AGENTS.md` is canonical.
- `CLAUDE.md` and `.github/copilot-instructions.md` are adapters.
- `.agents/skills` is the canonical skill source.
- `.claude/skills` and `.github/skills` mirror canonical skills.
- Native subagent profiles differ by tool and must remain behaviorally aligned.

## Workflow

1. Update `AGENTS.md` first for shared rules.
2. Update adapters only for tool-specific discovery or compatibility.
3. Keep skill frontmatter concise and trigger-focused.
4. Keep skill bodies short, procedural, and free of duplicated `AGENTS.md` content.
5. Sync mirrored skills after canonical skill changes.
6. Keep subagent roles narrow and explicit.

## Compatibility

- Codex reads `AGENTS.md`, `.agents/skills`, and `.codex/agents`.
- Claude reads `CLAUDE.md`, `.claude/skills`, and `.claude/agents`.
- Copilot reads `.github/copilot-instructions.md`, `AGENTS.md`, `.github/skills`, `.agents/skills`, and `.github/agents`.
- Do not assume one tool understands another tool's agent profile format.

## Validation

Run `dart tool/validate_ai_guidelines.dart`, then check Markdown readability and any tool-specific compatibility notes that cannot be validated mechanically.
