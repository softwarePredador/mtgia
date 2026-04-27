# M2006 Device Runtime Runbook

This is now a fallback runbook. The primary automated app/runtime target is the iPhone 15 Simulator in `app/doc/runtime_flow_handoffs/IPHONE15_SIMULATOR_RUNTIME_RUNBOOK.md`.

## Objective

Prove the ManaLoom deck runtime on the physical Android M2006 device using a real local backend.

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
- Physical M2006 runtime against live backend: not proven until this runbook is executed.

## Preconditions

1. M2006 has USB debugging enabled.
2. Mac and M2006 are on the same network if testing via LAN.
3. Firewall allows inbound connection to the backend port, normally `8081`.
4. Flutter/Android toolchain can see the device.

## Device Discovery

Run from repo root:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices
adb devices -l
```

Expected:

- one Android physical device visible;
- prefer the device whose model/name identifies the M2006.

If M2006 is not listed, record the command output in the handoff and stop.

## Backend LAN Setup

Get the Mac LAN IP:

```bash
ipconfig getifaddr en0 || ipconfig getifaddr en1
```

Start backend:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
PORT=8081 dart run .dart_frog/server.dart
```

Validate from the Mac:

```bash
curl -sS http://<MAC_LAN_IP>:8081/health
```

Expected JSON:

```json
{
  "service": "mtgia-server",
  "status": "healthy"
}
```

If possible, validate from the Android device:

```bash
adb shell curl -sS http://<MAC_LAN_IP>:8081/health
```

If `curl` is not available on-device, mark device-side network probe as `not proven` and proceed only if the app run can reach the backend.

## Test Command

Preferred command once a deck runtime integration test exists:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter test integration_test/<deck_runtime_test>.dart \
  -d <M2006_DEVICE_ID> \
  --dart-define=API_BASE_URL=http://<MAC_LAN_IP>:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://<MAC_LAN_IP>:8081 \
  --reporter expanded \
  --no-version-check
```

Until that integration test exists, the current reusable app proof is widget-level:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart
```

Widget-level proof does not replace M2006 proof because it uses a mocked `ApiClient`.

## Fallback Manual Install/Run

If `flutter test integration_test/...` cannot attach reliably:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter run -d <M2006_DEVICE_ID> \
  --dart-define=API_BASE_URL=http://<MAC_LAN_IP>:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://<MAC_LAN_IP>:8081 \
  --no-version-check
```

Then perform the target flow manually and capture logs/screenshots.

## Evidence Folder

Use:

```text
app/doc/runtime_flow_proofs_YYYY-MM-DD_m2006/
```

Suggested artifacts:

- `flutter_devices.txt`
- `adb_devices.txt`
- `backend_health_mac.json`
- `backend_health_device.txt`
- `flutter_test_output.txt`
- screenshots, if captured

## Handoff Output

Create:

```text
app/doc/runtime_flow_handoffs/deck_runtime_m2006_YYYY-MM-DD.md
```

Use verdicts:

- `Approved for physical M2006 runtime path`
- `Blocked by M2006 device discovery`
- `Blocked by physical-device backend reachability`
- `Blocked in auth`
- `Blocked in deck creation`
- `Blocked in deck details`
- `Blocked in optimize`
- `Blocked in post-optimize apply/validate`

## Minimum Acceptance Criteria

Physical M2006 proof is complete only when the handoff includes:

- M2006 device id from `flutter devices` or `adb devices -l`;
- backend URL using Mac LAN IP, not `127.0.0.1`;
- backend health proof;
- exact Flutter command;
- pass/fail result;
- whether API was real or mocked;
- artifacts/logs path;
- commit hash with the evidence.
