---
name: implementation-planning
description: Produce decision-complete implementation plans for Genesix changes. Use before broad edits, multi-layer feature work, migrations, generated-code changes, or any task where another agent should be able to implement from the plan.
---

# Implementation Planning

Use this skill to turn intent into a concrete implementation path.

## Plan Requirements

Include:

- Goal and success criteria.
- Net impact: expected benefit, negative impact, complexity cost, regression risk, and simpler alternatives.
- In-scope and out-of-scope behavior.
- Files or subsystems likely to change.
- Data flow or API/interface changes.
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
