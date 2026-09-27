---
name: validation-runner
description: Select and run the right Genesix validation commands, then verify completion evidence for the requested outcome. Useful for choosing proportionate checks, investigating check failures, or identifying important verification gaps.
---

# Validation Runner

Choose the narrowest checks that provide useful confidence in the requested outcome.

- Inspect the changed behavior, final diff, and repository status.
- Use the proportionate validation guidance in `AGENTS.md`.
- Check coupled artifacts when relevant: generated output, locale parity, skill
  mirrors, or shared package contracts.
- Prefer focused checks; expand to full suites or builds for cross-cutting changes
  or risks that focused checks do not cover.
- For failures, distinguish regressions from unrelated or pre-existing problems
  and report the useful error and next step.
- Do not treat a passing command as proof of behavior it does not exercise.

Report what was checked, the results, and important unverified outcomes in plain
language. No fixed acceptance labels, evidence categories, or completion template.

## Available Commands

Select as relevant, rather than running all of them:

- `dart analyze` or analysis of the affected scope.
- `flutter test` with relevant test paths, or the full suite when warranted.
- `dart run build_runner build` for changed generated annotations.
- `flutter gen-l10n` for changed ARBs.
- `dart format <touched-files>`.
- `flutter build <platform>` for behavior requiring a consumer build.
- `dart tool/validate_ai_guidelines.dart` for AI guidance consistency.

Native contract work follows the package owner's generation and validation
requirements before checking the affected Genesix consumers.
