# Dart and Flutter Guidelines

## Structure
- Follow feature-first structure under `lib/features`.
- Keep cross-feature utilities in `lib/shared`.
- Avoid moving files across features without clear architecture reason.

## State and Data Flow
- Use Riverpod conventions already used in the repo.
- Keep providers focused and composable.
- Keep repository classes as the boundary for persistence and external services.

## Routing and Navigation
- Use typed GoRouter patterns already defined in `lib/features/router/**`.
- Keep route extras and codec updates consistent when adding new transfer objects.

## UI and Presentation
- Keep widgets lean; move business decisions to application/domain layers.
- Reuse existing shared components before creating new variants.
- Preserve responsive behavior for desktop and mobile.
- Do not declare named nested functions in Dart code; keep helpers at class/file scope.
- Anonymous callback closures are allowed only when short and UI-local (for example `onPressed`, `builder`).
- If callback logic grows or is reused, extract a private method or widget class.
- In widget classes, do not use local functions that build/return widgets; extract a private `StatelessWidget` or `StatefulWidget` instead.

## Generated Code and Serialization
- Do not edit generated files directly.
- When model annotations change, regenerate builders and verify imports/usages.
