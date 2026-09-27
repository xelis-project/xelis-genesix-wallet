---
name: systematic-diagnosis
description: Diagnose Genesix bugs and unexplained behavior through evidence, reproduction, data-flow tracing, and falsifiable hypotheses before corrective changes. Useful when investigating failures, regressions, flaky or runtime-only behavior, lifecycle races, state/cache/remote precedence, platform differences, networking, or FFI boundaries.
---

# Systematic Diagnosis

Match investigation depth to uncertainty. A clear local mistake can be corrected
without a formal hypothesis list; intermittent or cross-layer failures need more evidence.

- Establish the symptom, expected behavior, and smallest reliable failure signal.
- Inspect the relevant data/control path and support the cause before correcting it.
- For uncertain failures, compare plausible causes and test a discriminating
  observation at a time. Trace cache, state, network, FFI, or platform boundaries
  only where relevant.
- Distinguish observations from assumptions. If evidence remains insufficient,
  report the uncertainty and next useful check instead of guessing.
- A diagnosis-only request does not authorize a fix.
- Keep temporary instrumentation narrow and free of secrets or sensitive payloads.
- Apply the smallest supported fix, replay the failure signal where possible,
  and remove temporary instrumentation. Reassess after repeated failed attempts.

Summarize the cause or remaining uncertainty, the change, and verification limits.
A focused test, runtime observation, log, or manual reproduction can provide evidence.
