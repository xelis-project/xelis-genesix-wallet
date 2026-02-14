# Shared Core Rules

## Normative Language
- `MUST`: mandatory requirement.
- `SHOULD`: strong default; deviations require explicit rationale.
- `MAY`: optional and context-dependent.

## Scope and Change Discipline
- Changes MUST stay tightly scoped to the request.
- Existing patterns SHOULD be reused before introducing new abstractions.
- Broad refactors MUST NOT be introduced unless explicitly requested.

## Generated and External Artifacts
- Agents MUST NOT hand-edit generated files:
  - `**/*.g.dart`
  - `**/*.freezed.dart`
  - `lib/src/generated/**`
- Generated output MUST be regenerated instead of patched manually.

## Architecture
- Feature-first boundaries MUST be respected:
  - Feature code in `lib/features/<feature>/...`
  - Shared code in `lib/shared/...`
- UI concerns SHOULD stay in presentation layers, and business/data logic SHOULD stay in application/data/domain layers.

## Safety and Correctness
- Agents MUST NOT invent APIs or file paths; usage MUST be verified from current code.
- Backward compatibility MUST be preserved unless the task explicitly allows breaking changes.
- Error handling SHOULD remain explicit with actionable messages.

## Documentation and Traceability
- Docs MUST be updated when behavior, workflow, or architecture changes.
- Delivery notes MUST mention verification steps and their outcomes.
