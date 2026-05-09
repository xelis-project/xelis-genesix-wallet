---
name: code-review
description: Perform a risk-first code review for Genesix changes. Use when asked to review a diff, PR, branch, recent changes, generated code impact, validation gaps, regressions, security issues, or maintainability risks.
---

# Code Review

Use this skill for review stance, not implementation stance.

## Workflow

1. Inspect the diff and relevant surrounding code.
2. Evaluate whether the change has a clearly positive net impact compared with simpler alternatives.
3. Prioritize behavioral bugs, regressions, security, correctness, missing validation, and generated-file mistakes.
4. Reference concrete files and lines.
5. Avoid style-only comments unless they hide a real maintenance or correctness issue.
6. If no issues are found, say so clearly and mention residual risk or test gaps.

## Output

- Findings first, ordered by severity.
- Use concise bullets with file references.
- Add open questions only when they affect correctness.
- Keep summary brief and secondary.

## Review Checklist

- Generated files edited manually.
- Dependency APIs used without version compatibility.
- Rust FFI signatures changed without regeneration.
- Riverpod/Freezed annotations changed without build_runner.
- Wallet lifecycle, storage, routing, or session ordering regressions.
- Complexity or API surface added without enough benefit.
- Missing validation for the changed surface.
