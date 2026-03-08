# Shared Workflow Checklist

## Normative Language
- This file uses `MUST` / `SHOULD` / `MAY` as defined in `docs/ai/shared/core-rules.md`.

## 1) Before Coding
- Agents MUST confirm target files and current behavior from source.
- Agents MUST inspect whether code generation outputs are impacted.
- Agents MUST inspect relevant dependency versions when the task relies on external packages or crates.
- Agents SHOULD prefer reproducible project commands.
- `just` targets are optional shortcuts for developers, not a required path for agents.

## 2) During Coding
- Keep change sets logically coherent.
- Agents SHOULD avoid unrelated formatting churn.
- Public method, provider, DTO, and model changes MUST stay explicit and consistent across layers.
- Prefer local consistency with the existing feature over introducing a new style.
- Reuse existing shared components and helpers before creating new ones.

## 3) Validation
- Agents MUST run relevant checks for changed areas. Typical commands:
  - `dart format .`
  - `dart analyze`
  - `cd rust && cargo fmt`
  - `cd rust && cargo check`
- If codegen is required, agents MUST run:
  - `flutter_rust_bridge_codegen generate` (or `just gen_rust_bridge` as a developer shortcut)
  - `dart run build_runner build -d` (or `just gen_flutter` as a developer shortcut)

## 4) Validation Matrix

| Change Surface | MUST Inspect | MUST Run | SHOULD Run |
| --- | --- | --- | --- |
| Dart/Flutter UI, state, repository, routing (no generated output impact) | affected files and package versions if external API is involved | `dart analyze` | `dart format .` |
| Riverpod generators, Freezed models, json/build_runner annotations | affected files, generated output impact, package versions | `dart run build_runner build -d`, `dart analyze` | `dart format .` |
| Rust changes not affecting FFI signatures | affected Rust modules and crate dependencies if relevant | `cd rust && cargo check` | `cd rust && cargo fmt` |
| Rust FFI signature or bridge contract changes | Rust API surface, generated bridge impact, Dart call sites | `flutter_rust_bridge_codegen generate`, `dart run build_runner build -d`, `cd rust && cargo check`, `dart analyze` | `cd rust && cargo fmt`, `dart format .` |
| Dependency version changes in `pubspec.yaml` or `Cargo.toml` | impacted docs/changelog and affected call sites | relevant analyze/check/build command for impacted area | formatting commands |

## 5) Delivery Notes
- Delivery notes MUST summarize what changed and why.
- Delivery notes MUST list validation commands run and their results.
- Delivery notes MUST call out skipped checks and why they were skipped.
- Delivery notes SHOULD mention dependency/version assumptions when they materially affect the solution.