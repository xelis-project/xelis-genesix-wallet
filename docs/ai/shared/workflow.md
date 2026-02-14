# Shared Workflow Checklist

## Normative Language
- This file uses `MUST` / `SHOULD` / `MAY` as defined in `docs/ai/shared/core-rules.md`.

## 1) Before Coding
- Agents MUST confirm target files and current behavior from source.
- Agents MUST check whether codegen outputs are impacted.
- Agents SHOULD prefer reproducible project commands; `just` targets are optional shortcuts for developers, not a required path for agents.

## 2) During Coding
- Keep change sets logically coherent (one concern per change set when possible).
- Agents SHOULD avoid unrelated formatting churn.
- Public method and DTO changes MUST stay explicit and consistent across layers.

## 3) Validation
- Agents MUST run relevant checks for changed areas. Typical commands:
  - `dart format .`
  - `dart analyze`
  - `cd rust && cargo fmt`
  - `cd rust && cargo check`
- If codegen is required, agents MUST run:
  - `flutter_rust_bridge_codegen generate` (or `just gen_rust_bridge` as a developer shortcut)
  - `dart run build_runner build -d` (or `just gen_flutter` as a developer shortcut)
- Validation matrix (minimum):

| Change Surface | MUST Run | SHOULD Run |
| --- | --- | --- |
| Dart/Flutter UI, state, repository, routing (no model annotation changes) | `dart analyze` | `dart format .` |
| Dart model annotations / providers affecting generated code | `dart run build_runner build -d`, `dart analyze` | `dart format .` |
| Rust changes not affecting FFI signatures | `cd rust && cargo check` | `cd rust && cargo fmt` |
| Rust FFI signature or bridge contract changes | `flutter_rust_bridge_codegen generate`, `dart run build_runner build -d`, `cd rust && cargo check`, `dart analyze` | `cd rust && cargo fmt`, `dart format .` |

## 4) Delivery Notes
- Delivery notes MUST summarize what changed and why.
- Delivery notes MUST list validation commands run and their results.
- Delivery notes MUST call out skipped checks and why they were skipped.
