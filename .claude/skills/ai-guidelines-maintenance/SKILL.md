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

## Knowledge Promotion

- Let agents propose durable learning as a normal reviewable diff; never let a task silently rewrite its own instructions.
- Promote only source-backed knowledge that is reusable, repeatedly relevant, or costly or risky to rediscover.
- Put universal invariants in `AGENTS.md`, procedures in skills, stable terms in `DOMAIN_VOCABULARY.md`, and exceptional or temporary constraints in `PROJECT_NOTES.md`.
- Include the scope, evidence, and condition that would invalidate or retire the knowledge.
- Reject speculative one-off observations and remove or update stale guidance when the underlying contract changes.
- Apply normal human review, mirror synchronization, and validation before accepting promoted knowledge.

## Compatibility

- Codex reads `AGENTS.md`, `.agents/skills`, and `.codex/agents`.
- Claude reads `CLAUDE.md`, `.claude/skills`, and `.claude/agents`.
- Copilot reads `.github/copilot-instructions.md`, `AGENTS.md`, `.github/skills`, `.agents/skills`, and `.github/agents`.
- Do not assume one tool understands another tool's agent profile format.

## Validation

Run `dart tool/validate_ai_guidelines.dart`, then check Markdown readability and any tool-specific compatibility notes that cannot be validated mechanically.
