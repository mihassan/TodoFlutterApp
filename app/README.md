# Todo Flutter App — `app/`

This directory contains the Flutter Android application. See the [root README](../README.md) for full project documentation, setup instructions, and architecture overview.

## Quick Reference

```sh
# Install dependencies
flutter pub get

# Code generation (freezed, json_serializable, drift)
dart run build_runner build --delete-conflicting-outputs

# Run on emulator with Firebase Emulators
flutter run --dart-define=USE_FIREBASE_EMULATORS=true

# Run all tests
flutter test

# Static analysis
flutter analyze
```
