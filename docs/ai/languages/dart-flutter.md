# Dart and Flutter Guidelines

## Structure
- Follow feature-first structure under `lib/features`.
- Keep cross-feature utilities in `lib/shared`.
- Avoid moving files across features without a clear architecture reason.

## Dependency Compatibility
- Read package versions from `pubspec.yaml` before suggesting or writing code using third-party Dart/Flutter packages.
- Use APIs and examples compatible with the installed version.
- Do not silently use APIs from newer package versions.
- If a requested solution requires a migration, state it explicitly.

## State and Data Flow
- Reuse Riverpod patterns already established in the repo.
- Prefer providers using `riverpod_generator` with `@riverpod` when suitable for the feature and compatible with the installed Riverpod version.
- Keep providers focused, composable, and aligned with existing project patterns.
- Keep repository classes as the boundary for persistence and external services.
- Do not introduce a second state-management style within the same feature.

## Models and Serialization
- Prefer immutable data models with clear typed states.
- Prefer union/sealed-style models when they meaningfully improve expressiveness, correctness, or maintainability.
- When appropriate, prefer Freezed-style sealed classes and factory constructors, consistent with the installed package version and the local codebase.
- Do not edit generated files directly.
- When model annotations change, regenerate builders and verify imports/usages.

## Routing and Navigation
- Use typed GoRouter patterns already defined in `lib/features/router/**`.
- Keep route extras and codec updates consistent when adding new transfer objects.

## UI and Presentation
- Keep widgets lean; move business decisions to application/domain layers.
- Reuse existing shared components before creating new variants.
- Preserve responsive behavior for desktop and mobile.
- Prefer Forui as the primary UI library when it fits the existing feature.
- Do not declare named nested functions in Dart code.
- Anonymous callback closures are allowed only when short and UI-local.
- If callback logic grows or is reused, extract a private method, helper, or widget class.
- In widget classes, do not use local functions that build/return widgets; extract a private `StatelessWidget` or `StatefulWidget` instead.

## Reuse and Simplicity
- Avoid over-engineering.
- Prefer the simplest implementation that fits the current feature and architecture.
- Reuse existing project primitives before introducing new helpers, wrappers, or abstractions.
- Extract reusable elements when they are clearly beneficial, not pre-emptively.

## Modern Dart and Flutter
- Prefer modern Dart and Flutter idioms when they improve readability and remain compatible with the installed SDK and package versions.
- Use recent language features such as pattern matching, sealed classes, records, or dot shorthands when they are supported and make the code clearer.
- Do not force new syntax where it reduces readability or clashes with local conventions.

## Do
- Reuse existing provider patterns from the same feature.
- Prefer `@riverpod` generators where appropriate.
- Prefer sealed/union-style models when they clarify state modeling.
- Reuse `lib/shared` widgets and utilities before creating new ones.
- Keep diffs small and locally consistent.

## Do Not
- Do not use latest package APIs without checking `pubspec.yaml`.
- Do not introduce Hook-based or alternative Riverpod patterns unless the feature already uses them or the task explicitly asks for it.
- Do not create new design primitives when an existing shared component already fits.
- Do not manually patch generated files.