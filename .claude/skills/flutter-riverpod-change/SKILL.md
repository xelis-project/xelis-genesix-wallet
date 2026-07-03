---
name: flutter-riverpod-change
description: Guide Dart, Flutter, Riverpod, Forui, routing, model, serializer, and UI-state changes in Genesix. Use when touching lib/features, lib/shared, providers, widgets, routes, generated Dart annotations, or Flutter package APIs.
---

# Flutter Riverpod Change

Use this skill before changing Flutter application code.

## Workflow

1. Read relevant local files and neighboring patterns.
2. Check `pubspec.yaml` before using third-party package APIs.
3. Identify whether annotations require `dart run build_runner build -d`.
4. Keep feature code under `lib/features/<feature>/...` and shared code under `lib/shared/...`.
5. Reuse Riverpod and UI patterns already present in the feature.
6. Keep widgets presentation-focused; move business decisions out of UI.

## Rules

- Prefer `@riverpod` generator patterns when they match the feature and installed version.
- Do not introduce Hook-based or alternate state management unless already used or requested.
- Prefer Forui when it fits existing UI.
- Reuse shared widgets and utilities before creating new ones.
- Do not declare named nested functions; extract private methods, helpers, or widgets.
- Do not manually patch `*.g.dart` or `*.freezed.dart`.

## Validation

Run checks from `AGENTS.md` based on the changed surface. Use `dart run build_runner build -d` before `dart analyze` when generator annotations changed.
