---
name: ai-guidelines-maintenance
description: Maintain Genesix AI instructions, AGENTS.md, Claude/Copilot adapters, skills, and subagent profiles. Useful when editing AI guidelines, adding workflows, syncing skills, changing agent behavior, or checking compatibility across Claude, Codex, and GitHub Copilot.
---

# AI Guidelines Maintenance

`AGENTS.md` is canonical. Keep tool adapters short and compatible with it.

- Put shared rules in `AGENTS.md`, reusable procedures in skills, domain terms in
  the vocabulary, and exceptional technical constraints in project notes.
- Keep guidance proportionate: preserve concrete safety and correctness contracts
  without adding routine plans, delegation, or reporting requirements.
- Update `.agents/skills` first and keep `.claude/skills` and `.github/skills`
  mirrors identical. Keep native agent roles behaviorally aligned across tools.
- Preserve tool-specific discovery and profile formats; no tool is assumed to
  understand another tool's agent configuration.
- Add durable knowledge only as an authorized, reviewable change, not a silent
  self-update. Keep source-backed facts with clear scope and retirement conditions.
- Remove duplication and update stale guidance when its underlying contract changes.

Run `dart tool/validate_ai_guidelines.dart`, inspect changed links and the diff,
and review readability. No application checks are needed for documentation alone.
