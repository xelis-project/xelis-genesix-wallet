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
- For complex prompts, ask Copilot to read `AGENTS.md` first and select the relevant skill or custom agent.
- Do not edit generated files directly; follow the validation matrix in `AGENTS.md`.
