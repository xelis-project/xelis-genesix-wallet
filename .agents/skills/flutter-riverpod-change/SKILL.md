---
name: flutter-riverpod-change
description: Guide Genesix Dart and Flutter application-behavior changes across state, Riverpod providers, routing, repositories, models, serializers, generated annotations, and behavior-bearing widgets. Use when changing these surfaces under lib/features or lib/shared; pair with flutter-forui-ux-design only when user-facing workflow, layout, or interaction also changes.
---

# Flutter Riverpod Change

Use this skill before changing Flutter application code.

## Workflow

1. Read relevant local files and neighboring patterns.
2. Identify the affected state, provider, routing, repository, model, serializer, and widget boundaries.
3. Check `pubspec.yaml` before using third-party package APIs.
4. Identify whether annotations require `dart run build_runner build -d`.
5. Reuse patterns aligned with the target architecture; treat nearby legacy providers or Material-era code as behavior evidence, not automatic precedent.
6. Keep widgets presentation-focused; move business decisions out of UI.

## Rules

- Prefer `@riverpod` generator patterns when they match the feature and installed version.
- Do not introduce Hook-based or alternate state management unless already used or requested.
- Reuse shared widgets and utilities before creating new ones.
- Never manually edit generated `*.g.dart` or `*.freezed.dart` files; change the source annotations or models and regenerate the affected output.

## Validation

Run checks from `AGENTS.md` based on the changed surface. Use `dart run build_runner build -d` before `dart analyze` when generator annotations changed.
