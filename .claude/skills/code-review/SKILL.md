---
name: code-review
description: Perform a risk-first code review for Genesix changes. Useful when asked to review a diff, PR, branch, recent changes, generated code impact, validation gaps, regressions, security issues, or maintainability risks.
---

# Code Review

Review the request, diff, and relevant surrounding code. Match depth to the
change and its risk; an independent reviewer is useful when warranted, not mandatory.

- Look for incorrect behavior, omitted scope, regressions, sensitive-data exposure,
  lifecycle mistakes, compatibility issues, and unnecessary complexity.
- Check generated, localized, or cross-language artifacts only when affected.
- Assess whether validation supports the claimed outcome and identify material gaps.
- Prefer concrete fixes over stylistic preferences or speculative hardening.
- Check documentation when a durable behavior or developer procedure changed.

Lead with findings ordered by severity, with file references and concrete impact.
If none are found, say so briefly and mention important unverified outcomes, if any.
Keep the summary short; no formal compliance categories or impact report is needed.
