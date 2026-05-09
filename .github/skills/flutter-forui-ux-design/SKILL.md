---
name: flutter-forui-ux-design
description: Design and critique Genesix Flutter UX/UI using Forui as the primary component library. Use when creating or reviewing screens, workflows, responsive layouts, interaction states, empty/error/loading states, accessibility, visual hierarchy, or reusable UI patterns.
---

# Flutter Forui UX Design

Use this skill before designing, reviewing, or materially changing Flutter UI.

## Workflow

1. Start from the user task, not from visual decoration.
2. Identify the primary action, secondary actions, destructive actions, and expected recovery paths.
3. Map states before layout: loading, empty, populated, error, disabled, selected, pending, and offline when relevant.
4. Inspect neighboring Genesix screens and shared widgets before introducing new UI patterns.
5. Prefer Forui components when they fit the interaction.
6. Keep business decisions outside widgets; pair this skill with `flutter-riverpod-change` when state or providers are involved.

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
- Verify long localized strings in English and French when editing user-facing copy.
- Use existing theme tokens and spacing patterns before adding new styling constants.
- If the change affects navigation or state flow, validate the relevant routing/provider behavior.

## Review Checklist

- The first screen communicates the current state and primary next action.
- The workflow remains usable on narrow mobile and wider desktop layouts.
- Loading, empty, error, and success states are represented.
- Destructive or irreversible actions have clear affordances.
- Text, icons, badges, and controls do not overlap or resize unexpectedly.
- The design uses Forui/shared components consistently with nearby Genesix UI.
