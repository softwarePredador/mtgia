# iPhone 15 Simulator Runtime Runbook

## Objective

Prove the ManaLoom deck runtime on the iPhone 15 Simulator using a real local backend.

Target flow:

- register/login
- generate or create Commander deck
- open deck details
- optimize
- preview/apply
- validate

## Current Status

- Backend runtime E2E: proved with `19/19` against `http://127.0.0.1:8081`.
- App widget runtime: proved with mocked `ApiClient`.
- iPhone 15 Simulator runtime against live backend: not proven until this runbook is executed.

## Preconditions

1. Xcode/iOS Simulator is installed.
2. Flutter can see the iPhone 15 Simulator.
3. Backend can run locally on port `8081`.

## Simulator Discovery

Run from repo root:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
```

Expected:

- one `iPhone 15` simulator available or booted;
- exact simulator id recorded in the handoff.

If `iPhone 15` is not listed, record the command output and mark simulator proof as `not proven`.

## Backend Setup

Start backend:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
PORT=8081 dart run .dart_frog/server.dart
```

Validate from the Mac:

```bash
curl -sS http://127.0.0.1:8081/health
```

Expected JSON:

```json
{
  "service": "mtgia-server",
  "status": "healthy"
}
```

For iOS Simulator, `127.0.0.1` points to the Mac host, so do not use the Android LAN IP rule.

## Test Command

Preferred command once a deck runtime integration test exists:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter test integration_test/<deck_runtime_test>.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 \
  --reporter expanded \
  --no-version-check
```

Until that integration test exists, the current reusable app proof is widget-level:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart
```

Widget-level proof does not replace iPhone 15 Simulator proof because it uses a mocked `ApiClient`.

## Fallback Manual Run

If `flutter test integration_test/...` cannot attach reliably:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter run -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 \
  --no-version-check
```

Then perform the target flow manually and capture logs/screenshots.

## Evidence Folder

Use:

```text
app/doc/runtime_flow_proofs_YYYY-MM-DD_iphone15_simulator/
```

Suggested artifacts:

- `flutter_devices.txt`
- `simctl_devices.txt`
- `backend_health.json`
- `flutter_test_output.txt`
- screenshots, if captured

## Handoff Output

Create:

```text
app/doc/runtime_flow_handoffs/deck_runtime_iphone15_simulator_YYYY-MM-DD.md
```

Use verdicts:

- `Approved for iPhone 15 Simulator runtime path`
- `Blocked by iPhone 15 Simulator discovery`
- `Blocked by local backend connectivity`
- `Blocked in auth`
- `Blocked in deck creation`
- `Blocked in deck details`
- `Blocked in optimize`
- `Blocked in post-optimize apply/validate`

## Minimum Acceptance Criteria

iPhone 15 Simulator proof is complete only when the handoff includes:

- iPhone 15 simulator id from `flutter devices` or `xcrun simctl list devices available`;
- backend URL using `http://127.0.0.1:8081`;
- backend health proof;
- exact Flutter command;
- pass/fail result;
- whether API was real or mocked;
- artifacts/logs path;
- commit hash with the evidence.
