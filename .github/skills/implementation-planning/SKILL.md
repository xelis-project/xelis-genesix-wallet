---
name: implementation-planning
description: Produce decision-complete implementation plans for Genesix changes. Use before broad edits, multi-layer feature work, migrations, generated-code changes, or any task where another agent should be able to implement from the plan.
---

# Implementation Planning

Use this skill to turn intent into a concrete implementation path.

## Context

- Read `.agents/knowledge/DOMAIN_VOCABULARY.md` for cross-layer plans or ambiguous domain terms, then verify behavior in the linked source.
- Read `.agents/knowledge/PROJECT_NOTES.md` before dependency, storage, security, platform, or migration planning.
- Use vocabulary terms consistently and include a vocabulary update when a planned contract change makes a definition stale.

## Plan Requirements

Include:

- Goal and success criteria.
- Net impact: expected benefit, negative impact, complexity cost, regression risk, and simpler alternatives.
- In-scope and out-of-scope behavior.
- Files or subsystems likely to change.
- Architecture maturity for affected UI/provider surfaces: legacy, transitional, or target, with an explicit migration boundary.
- Data flow or API/interface changes.
- AI-guidance and knowledge impact for architecture, workflow, or public contract changes.
- Generated-code impact.
- Validation commands from `AGENTS.md`.
- Risks, compatibility concerns, and assumptions.

## Decision Rules

- Prefer local patterns over new abstractions.
- Keep the first implementation slice small and coherent.
- Proceed only when the planned change has a clearly positive net impact for the requested goal.
- Keep net-impact analysis implicit for small mechanical fixes, but state it explicitly for architectural, security-sensitive, UX, dependency, lifecycle, storage, FFI, generated-code, or public API changes.
- Do not plan dependency upgrades unless required.
- Do not plan generated-file edits by hand; plan regeneration.
- Ask only for product decisions that cannot be discovered from source.

## Output

Return a compact plan that is specific enough to execute without further architectural decisions.
