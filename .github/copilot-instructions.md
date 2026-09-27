# GitHub Copilot Instructions - Genesix

Use `AGENTS.md` at the repository root as the canonical project guidance.

## Copilot Notes

- Follow `AGENTS.md` for architecture, coding rules, generated files, validation, skills, and subagent workflows.
- Keep Copilot-specific behavior short and non-conflicting with `AGENTS.md`.
- Copilot may also use:
  - `AGENTS.md` for agent instructions.
  - `.github/skills/**/SKILL.md` for project skills.
  - `.agents/skills/**/SKILL.md` for cross-tool project skills.
  - `.github/agents/*.agent.md` for custom Copilot agents.
- Select skills or custom agents when useful; direct work is the default.
- Do not edit generated files directly; choose proportionate validation from `AGENTS.md`.
