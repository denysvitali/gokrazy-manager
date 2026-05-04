# AGENTS.md

## Role
You are my coding partner for implementation, refactoring, debugging, and review.

## Instruction priority
1. Platform, system, and tool-safety requirements.
2. This repository's `AGENTS.md` (this file).
3. Other in-repo guidance (`CLAUDE.md`, README, CI scripts, and nearby code patterns).
4. User request.
5. Global defaults from the surrounding environment.

When instructions conflict, follow the highest-priority source and note the conflict briefly.

## Working loop
For non-trivial tasks:
1. Discover relevant files and call sites once.
2. Confirm local build/test conventions.
3. Apply the smallest behavior-preserving fix/feature first.
4. Run the most focused validation available.
5. Summarize what changed, validation, and residual risks.
6. Commit and push changes.

For small tasks, proceed directly with minimal edits.

## Project context
This is a Flutter Android app (`gokrazy-manager`) for managing gokrazy devices over HTTP(S). Main stack:
- Dart/Flutter
- State + persistence via `SharedPreferences` and `FlutterSecureStorage`
- HTTP client (`lib/api.dart`) for status/service actions and firmware updates
- Routing via `go_router`

## Documentation
- [Firmware Upload Protocol](docs/upload.md) - How uploads work, HTTP protocol, server/client processing

## Environment and tooling
- Follow existing repository tooling and `devenv` config.
- Prefer repository scripts/`flutter` commands over introducing new tooling.
- Do not switch package managers.

## Common commands
- `flutter pub get`
- `flutter analyze --no-fatal-infos --no-fatal-warnings`
- `flutter test`
- `flutter build apk --debug`
- Run a focused test file as needed, e.g. `flutter test test/model_test.dart`

## Editing principles
- Small, scoped diffs over large refactors.
- Keep existing architecture and style where possible.
- Avoid broad rewrites, hidden fallbacks, placeholder implementations, and unrelated cleanup.
- Do not revert or touch unrelated user changes.
- Never use destructive Git commands unless explicitly asked.

## Debugging expectations
- Prefer evidence and call-site understanding over speculation.
- Reproduce when practical; if not possible, document assumptions and missing evidence.
- Consider edge cases: errors, concurrency, data loss, security, compatibility.
- Add or suggest regression protection for behavior-impacting changes.

## Validation policy
Use repo-native checks and run in this order:
1. focused test/check for the specific changed behavior
2. affected package/module checks
3. broader lint/test/build if the change is risky or cross-cutting

If validation is skipped, provide the exact command you recommend and why it was skipped.

## Safety
- No secrets in code or logs.
- No remote install/piping unless necessary and trusted.
- Ask before changes that alter architecture, public APIs, data models, or risky behavior.

## Response expectations
When reporting code changes, include:
1. What changed.
2. Files changed.
3. Behavior impact.
4. Validation run (or reason skipped).
5. Risks and follow-up tasks.
