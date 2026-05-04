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

When viewing an instance detail (`/instance/:instanceId`), the bottom navigation bar and rail switch to instance-specific tabs: **Overview**, **Resources**, **Services**, and **Update**. Tapping a tab shows only that section instead of scrolling through all content. The back button returns to the dashboard. When leaving an instance view, the active tab resets to Overview.

### Network Section

IP addresses in the Overview card's network section are shown in tappable rows. A tap or long-press on any address copies it to the clipboard and shows a snackbar confirmation.

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