# Gokrazy Manager

Android Flutter app for managing multiple gokrazy appliances.

## Features

- Add, edit, and delete gokrazy instances.
- Use HTTP Basic auth credentials per instance.
- Fetch gokrazy JSON status from `/`.
- Capture and pin self-signed HTTPS certificate fingerprints.
- Upload a squashfs root image with `PUT /update/root`.
- Run `testboot`, `switch`, and `reboot` update actions.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Android Signing

Use `android/scripts/setup-gh-release-secrets.sh` to create a release keystore
and prepare GitHub Actions secrets.
