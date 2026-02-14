## Overview
Fresh release drop! 🚀  
This version bundles builds for Android, Linux, and Windows.

## What's New
_Fill this section before publishing the release._
- [ ] New feature or improvement #1
- [ ] New feature or improvement #2

## Bug Fixes
_Fill this section before publishing the release._
- [ ] Bug fix #1
- [ ] Bug fix #2

## Important Note
⚠️ The application is still in an early stage. You may encounter bugs or unexpected behavior.  
Development is ongoing, and more significant improvements and new features are planned for upcoming releases.

Thank you for your patience and continued feedback.

## Important Security Reminder
⚠️ **Always keep your wallet seed phrase (recovery phrase) backed up and stored securely.**  
Do not share it with anyone. Anyone with access to it can fully control your wallet funds.

## Release Assets
- Android (64-bit ARM): `genesix-android-{{VERSION}}-64bit-arm.apk`
- Android (32-bit ARM): `genesix-android-{{VERSION}}-32bit-arm.apk`
- Linux (x64): `genesix-linux-{{VERSION}}-x64.tar.gz`
- Windows (x64, portable): `genesix-windows-x64-v{{VERSION}}.zip`
- Windows (x64, installer): `genesix-windows-x86_64-v{{VERSION}}.exe`

## Installation
### Android
- Download the APK matching your device architecture.
- Enable installation from unknown sources if required by your device policy.

### Linux
- Extract `genesix-linux-{{VERSION}}-x64.tar.gz`.
- Run the executable from the extracted `bundle` directory.

### Windows
- Recommended: run `genesix-windows-x86_64-v{{VERSION}}.exe`.
- Portable option: extract `genesix-windows-x64-v{{VERSION}}.zip` and run `genesix.exe`.
- The installer includes the Microsoft Visual C++ Redistributable bootstrapper and installs it only if needed.

## Upgrade Notes
- Close any running Genesix process before upgrading.
- On Windows, keep wallet data backups before replacing portable files manually.
- Take a minute to verify your backup status before any migration/update 🔐

## Known Issues
_Optional: list temporary limitations or known bugs for this version._
- None reported.

## Platform Coverage
- Included: Android, Linux, Windows
- Not included in this pipeline: macOS (for now) 🙂

Full Changelog: {{FULL_CHANGELOG}}

_Released on {{DATE_UTC}}._
