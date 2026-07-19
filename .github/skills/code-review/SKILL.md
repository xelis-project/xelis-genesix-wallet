---
name: code-review
description: Perform a risk-first code review for Genesix changes. Use when asked to review a diff, PR, branch, recent changes, generated code impact, validation gaps, regressions, security issues, or maintainability risks.
---

# Code Review

Use this skill for review stance, not implementation stance.

## Workflow

1. Inspect the request, plan or acceptance criteria, diff, and relevant surrounding code.
2. Review request compliance: confirm that the intended behavior and full requested scope are implemented without unsupported claims or omissions.
3. Review engineering quality: evaluate correctness, regressions, security, lifecycle ordering, generated artifacts, API compatibility, validation, and maintainability.
4. Evaluate whether the change has a clearly positive net impact compared with simpler alternatives.
5. Reference concrete files and lines, and state the user-visible or contract impact of each finding.
6. Avoid style-only comments unless they hide a real maintenance or correctness issue.
7. If no issues are found, say so clearly and mention residual risk, unverified outcomes, or test gaps.

## Output

- Findings first, ordered by severity.
- Use concise bullets with file references.
- Combine findings from both review axes into one severity-ordered list; name the axis when it clarifies the issue.
- Add open questions only when they affect correctness.
- Keep summary brief and secondary.

## Review Checklist

### Request Compliance

- Requested behavior, scope, and acceptance criteria are covered.
- The implementation matches the stated plan or explains intentional deviations.
- Validation claims demonstrate the relevant outcome instead of only reporting successful commands.
- Required generated, mirrored, localized, or cross-language artifacts are included.
- Architecture, workflow, or public contract changes state their AI-guidance impact and update the relevant knowledge when required.

### Engineering Quality

- Generated files edited manually.
- Dependency APIs used without version compatibility.
- Rust FFI signatures changed without regeneration.
- Riverpod/Freezed annotations changed without build_runner.
- Wallet lifecycle, storage, routing, or session ordering regressions.
- New or materially refactored UI copies legacy Material or provider patterns without justification.
- Complexity or API surface added without enough benefit.
- Missing validation for the changed surface.
