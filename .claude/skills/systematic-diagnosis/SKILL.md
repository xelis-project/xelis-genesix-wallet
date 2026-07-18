---
name: systematic-diagnosis
description: Diagnose Genesix bugs and unexplained behavior through evidence, reproduction, data-flow tracing, and falsifiable hypotheses before corrective changes. Use when investigating failures, regressions, flaky or runtime-only behavior, lifecycle races, state/cache/remote precedence, platform differences, networking, or FFI boundaries.
---

# Systematic Diagnosis

Use a proportionate investigation: a known mechanical mistake needs less ceremony than an intermittent wallet lifecycle, networking, or FFI failure.

## Guardrails

- Separate observed facts, source-derived facts, hypotheses, and assumptions.
- Do not change behavior until the root cause is supported by evidence. Narrow diagnostic instrumentation is allowed when needed.
- If the user asks only for a diagnosis, report the cause and evidence without implementing a fix.
- Never log secrets, keys, seeds, credentials, full sensitive payloads, or unnecessary wallet identifiers.
- Tests are one possible signal, not a prerequisite. Use the tightest reliable command, log, manual reproduction, runtime observation, or focused check available.

## Workflow

1. State the observed behavior, expected behavior, relevant environment, frequency, and last known good state when available.
2. Establish the smallest reliable failure signal. Distinguish what source inspection proves from what must be observed at runtime.
3. Trace the real data and control path end to end. Follow ownership and precedence across local files, generated output, active state, caches, remote sources, networking, FFI, and platform-specific paths as applicable.
4. Build a short ranked list of falsifiable hypotheses. For each, record supporting evidence, conflicting evidence, and the next observation that would distinguish it.
5. Test one discriminating variable at a time. Keep temporary logs or probes narrow, non-sensitive, and easy to remove.
6. Conclude with the supported root cause and confidence level. If evidence remains insufficient, state the uncertainty and the next evidence needed instead of guessing.
7. If a fix is requested, apply the smallest root-cause change. After three failed interventions, stop patching and revisit the assumptions, traced path, and architecture.
8. Replay the original failure signal, run validation proportional to the changed surface, and remove temporary instrumentation before delivery.

## Report

Summarize the symptom and reproduction signal, decisive evidence, root cause or remaining uncertainty, implemented fix or next diagnostic step, and verification status.
