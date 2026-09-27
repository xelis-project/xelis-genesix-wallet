---
name: flutter-forui-ux-design
description: Design and critique Genesix Flutter UX/UI using Forui as the primary component library. Useful when creating, reviewing, or materially changing screens, workflows, responsive layouts, interaction states, accessibility, visual hierarchy, or reusable UI patterns; application-behavior guidance may also help when state, routing, or data flow changes.
---

# Flutter Forui UX Design

Use this guidance for UI design and review when useful; a small visual fix does
not need a complete design exercise.

## Approach

- Start from the user's task, primary action, and relevant interaction states.
- Inspect shared widgets and nearby patterns; prefer Forui where it fits.
- Keep business decisions outside widgets. Consult application-behavior guidance
  when state or routing changes need it.
- Check the responsive and accessibility implications of the affected surface.

## Forui Documentation

- For API questions, use installed source and the local snapshots under
  `.agents/references/forui/`; refresh stale snapshots with
  `dart run tool/sync_forui_docs.dart` when needed.
- For a Forui migration, review the [official changelog](https://pub.dev/packages/forui/changelog)
  and refresh snapshots after resolving the version. If offline, use installed
  source and report material uncertainty.
- Use `llms.txt` as the snapshot index and `llms-full.txt` for details when present.
  These are ignored local caches; do not commit `.agents/references/forui/**`.

## Design Rules

- Build dense, scannable wallet UI for repeated operational use.
- Keep cards for repeated items, modals, and genuinely framed tools; avoid cards nested inside cards.
- Keep headings proportionate to the local surface; do not use hero-scale type inside panels or compact screens.
- Use familiar controls: buttons for commands, toggles for binary settings, tabs for views, menus for option sets, and inputs/sliders for values.
- Use icon buttons only where the symbol is familiar or accompanied by a tooltip/label.
- Preserve responsive behavior across mobile, desktop, web, and native targets.
- Avoid layout shifts by giving fixed-format controls stable dimensions.
- Make empty, error, loading, and disabled states actionable and consistent with nearby screens.
- Do not introduce a new design primitive when a shared component or Forui component already fits.

## Flutter Implementation Notes

- Prefer composition with small private widgets over named local builder functions.
- Keep text from overflowing buttons, cards, tiles, and navigation elements.
- Follow the localization parity rules in `AGENTS.md` when editing user-facing copy.
- Use existing theme tokens and spacing patterns before adding new styling constants.
- If the change affects navigation or state flow, validate the relevant routing/provider behavior.

## Review Prompts

Apply these to the changed workflow, not as a checklist for every visual edit.

- The first screen communicates the current state and primary next action.
- The workflow remains usable on narrow mobile and wider desktop layouts.
- Loading, empty, error, and success states are represented.
- Destructive or irreversible actions have clear affordances.
- Text, icons, badges, and controls do not overlap or resize unexpectedly.
- The design uses Forui/shared components consistently with nearby Genesix UI.
