# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gokrazy Manager is an Android Flutter app for managing multiple gokrazy appliances. It communicates with gokrazy devices over HTTP/HTTPS, fetches status, manages services, and uploads root filesystem images.

## Build, Lint, and Test Commands

```sh
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
flutter build apk --debug
```

Run a single test file:
```sh
flutter test test/model_test.dart
```

## Architecture

### State and Persistence

- **InstanceRepository** (`lib/api.dart`): Loads/saves instances from SharedPreferences. Passwords are stored separately in `FlutterSecureStorage` under `gokrazy_password_<id>` keys.
- **GokrazyClient**: HTTP client for device communication. Handles Basic auth, certificate pinning, XSRF tokens, and streaming SSE logs.

### Certificate Pinning

The app pins SSL certificates to trust self-signed gokrazy devices. When an untrusted certificate is encountered, `CertificatePinRequired` is thrown with the SHA256 fingerprint. The user is prompted to accept or reject it, and the accepted fingerprint is stored in `GokrazyInstance.pinnedFingerprint`.

### Navigation

go_router handles routing with three routes: `/` (dashboard), `/settings`, and `/instance/:instanceId`. The main navigation uses `NavigationBar` with adaptive breakpoint switching to `NavigationRail` at desktop widths.

### Key Models

- `GokrazyInstance`: id, name, baseUrl, username, pinnedFingerprint, lastSeen
- `GokrazyStatus`: hostname, model, kernel, services, memory info, persistent storage info, addresses
- `GokrazyService`: path, stopped, pid, startTime, args

### API Communication

- Status fetched from `GET /`
- Features from `GET /update/features`
- Service log stream from `GET /log` (SSE)
- Squashfs upload via `PUT /update/root` (with SHA256 checksum verification)
- Service actions use `POST /restart` and `POST /stop` with XSRF token from `/status`
- Update actions: `POST /update/testboot`, `POST /update/switch`, `POST /reboot`

## GitHub Actions CI

The CI pipeline (`.github/workflows/ci.yml`) runs:
1. **analyze** - `flutter analyze`
2. **test** - `flutter test --coverage` with Codecov upload
3. **build-debug** - Manual workflow dispatch, builds debug APK
4. **build-release** - On push to tracked branches and tags, builds release APK with keystore

Flutter version is pinned to **3.38.7**. Debug APKs target `android-arm64`.