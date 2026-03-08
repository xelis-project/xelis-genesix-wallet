# Shared Core Rules

## Normative Language
- `MUST`: mandatory requirement.
- `SHOULD`: strong default; deviations require explicit rationale.
- `MAY`: optional and context-dependent.

## Scope and Change Discipline
- Changes MUST stay tightly scoped to the request.
- Existing patterns SHOULD be reused before introducing new abstractions.
- Broad refactors MUST NOT be introduced unless explicitly requested.
- Agents SHOULD avoid over-engineering.
- Reusable elements SHOULD be extracted only when they provide clear value in readability, consistency, or maintenance.

## Dependency and Version Discipline
- Agents MUST read the exact dependency version from `pubspec.yaml` or `Cargo.toml` before suggesting code that depends on a third-party library.
- Suggested code MUST be compatible with the installed version.
- Agents MUST NOT default to latest online examples if the repository uses an older version.
- If the requested solution requires a dependency upgrade or migration, agents MUST say so explicitly instead of silently using newer APIs.

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
- UI concerns SHOULD stay in presentation layers.
- Business and data logic SHOULD stay in application/data/domain layers.

## Code Organization
- Agents MUST NOT declare named functions inside other functions.
- Prefer file-level/private helpers or class-level private methods/classes over inner function declarations.
- Anonymous closures MAY be used only for callback-style APIs when they stay short, local, and non-reused.
- If a closure grows beyond trivial callback glue, it SHOULD be extracted to a private helper.
- Reuse existing shared code before introducing new primitives, widgets, helpers, or abstractions.

## Modern Language Features
- Agents SHOULD use modern Dart and Flutter language/framework features when they improve clarity, safety, or conciseness.
- Agents SHOULD prefer current idiomatic language patterns over legacy style when compatible with the installed SDK and package versions.
- New language features MUST remain readable and appropriate for the local codebase.

## Safety and Correctness
- Agents MUST NOT invent APIs, symbols, or file paths; usage MUST be verified from current code.
- Backward compatibility MUST be preserved unless the task explicitly allows breaking changes.
- Error handling SHOULD remain explicit with actionable messages.

## Documentation and Traceability
- Docs MUST be updated when behavior, workflow, or architecture changes.
- Delivery notes MUST mention verification steps and their outcomes.