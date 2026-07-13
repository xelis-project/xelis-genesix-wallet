## Overview
Fresh release drop! 🚀  
This version bundles builds for Android, Linux, and Windows.

## What's New
<!-- Add concise, user-facing highlights before publishing. -->

## Bug Fixes
<!-- Add the most relevant user-facing fixes before publishing. -->

## Important Note
⚠️ The application is still in an early stage. You may encounter bugs or unexpected behavior.  
Development is ongoing, and more significant improvements and new features are planned for upcoming releases.

Thank you for your patience and continued feedback.

## Important Security Reminder
⚠️ **Always keep your wallet seed phrase (recovery phrase) backed up and stored securely.**  
Do not share it with anyone. Anyone with access to it can fully control your wallet funds.

Download Genesix only from the official GitHub release page.

## Release Assets
- Android (64-bit ARM, recommended for most recent devices): `genesix-android-{{VERSION}}-64bit-arm.apk`
- Android (32-bit ARM, for older compatible devices): `genesix-android-{{VERSION}}-32bit-arm.apk`
- Linux (x64): `genesix-linux-{{VERSION}}-x64.tar.gz`
- Windows (x64, portable): `genesix-windows-x64-v{{VERSION}}.zip`
- Windows (x64, installer): `genesix-windows-x86_64-v{{VERSION}}.exe`

## Installation
### Android
- Use the 64-bit ARM APK for most recent devices. Use the 32-bit ARM APK only for older compatible devices.
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
- On Windows, run the latest installer to upgrade an existing installation.
- If you use the Windows portable build, extract the new version to a separate folder instead of overwriting the previous files.
- Take a minute to verify your backup status before any migration/update 🔐

## Known Issues
<!-- Replace this line if release-specific limitations or bugs are known. -->
- No release-specific issues reported at publication time.

## Platform Coverage
- Included: Android, Linux, Windows
- Not included in this pipeline: iOS, macOS (for now) 🙂

Full Changelog: {{FULL_CHANGELOG_LINK}}
