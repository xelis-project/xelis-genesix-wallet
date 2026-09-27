---
name: repo-onboarding
description: Build task-relevant context about the Genesix repository. Useful when starting work in this repo, onboarding an agent, locating architecture boundaries, finding validation commands, or answering broad questions about project structure.
---

# Repo Onboarding

Use targeted exploration to build the context needed for the task.

- Start with `AGENTS.md` and the affected source, rather than reading every guide.
- Consult domain vocabulary for ambiguous terms and project notes for relevant
  platform, storage, or dependency constraints.
- Inspect neighboring patterns and shared helpers before choosing an approach.
- Verify relevant dependency versions and the resolved wallet package API.
- Identify generated output and likely validation needs when applicable.
- Return concise findings, useful file references, and material unknowns.

## Repository Map

- Features: `lib/features`; shared services and UI: `lib/shared`.
- Routing: `lib/features/router`.
- Native adapter: `lib/features/wallet/data/native_wallet_repository.dart`.
- Rust and generated bridge: the external `xelis_wallet_flutter` package.
