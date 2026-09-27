---
name: flutter-riverpod-change
description: Guide Genesix Dart and Flutter application-behavior changes across state, Riverpod providers, routing, repositories, models, serializers, generated annotations, and behavior-bearing widgets. Useful when changing these surfaces under lib/features or lib/shared; UI guidance may also help when workflow, layout, or interaction changes.
---

# Flutter Riverpod Change

Use this guidance for application behavior changes when helpful.

- Inspect affected local state, provider, routing, repository, model, or widget paths.
- Reuse existing feature patterns and shared helpers. Prefer `@riverpod`, typed
  routes, and immutable models where they fit the feature and installed versions.
- Keep widgets presentation-focused and business decisions in the appropriate layer.
- Prefer the existing state-management approach; avoid incidental migrations.
- Verify third-party APIs against the installed version when relying on them.
- Preserve route extras and codecs when changing transfer objects.
- Regenerate affected annotations with `dart run build_runner build`; never
  manually patch generated `*.g.dart` or `*.freezed.dart` files.

Analyze the affected scope and verify changed behavior using the proportionate
validation guidance in `AGENTS.md`. Consult UI guidance when layout or interaction
also needs design work, without requiring a second workflow for every widget edit.
