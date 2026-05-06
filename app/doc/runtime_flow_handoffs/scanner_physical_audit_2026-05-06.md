# Scanner Physical Audit - 2026-05-06

## Verdict

`BLOCKED / NOT PROVEN` for physical scanner camera/OCR release closure.

The physical iPhone was available and the app launched on it in debug mode, but
the required hands-on scanner matrix was not executed: no camera permission
confirmation, scanner screen navigation, real card positioning, live MLKit OCR
frame, physical scan result, Binder/Deck add, or manual retry path was proven in
this non-interactive run.

Backend scanner contracts and controlled scanner logic remain `PASS`, including
the token-safe `Phyrexian Horror` path. That does not close the final physical
camera/OCR deferred item.

## Date/time

- Started: `2026-05-06 13:53 -0300`
- Proof window: `2026-05-06 13:45-14:10 -0300`
- Backend stopped: `2026-05-06 14:10:56 -0300`

## Branch and repository

- Repository: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`
- Branch: `master`
- Commit at start: `cf01036 Resolve release data readiness follow-up`
- Sync: `git fetch origin master` + `git pull --ff-only origin master` returned
  `Already up to date.`

## Device discovery

### Physical iPhone target

- Device: `Rafa`
- Device id: `00008130-001C152922BA001C`
- Product type: `iPhone16,1`
- Runtime: `iOS 26.5 23F5043k`
- Discovery source:
  - `flutter devices`: `Rafa (mobile) • 00008130-001C152922BA001C • ios • iOS 26.5 23F5043k`
  - `idevice_id -l`: `00008130-001C152922BA001C`
  - `xcrun xctrace list devices`: `Rafa (26.5) (00008130-001C152922BA001C)`

### Simulator discovery

- iPhone 15 Simulator:
  `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`
- State: `Booted`
- Discovery output:
  `iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)`

## Backend

- Backend command used:
  `cd server && PORT=8082 dart run .dart_frog/server.dart`
- PID recorded by proof harness: `24844`
- App physical backend URL selected:
  `http://192.168.20.167:8082`
- Mac health checks:
  - `http://127.0.0.1:8082/health`: `healthy mtgia-server development`
  - `http://192.168.20.167:8082/health`: `healthy mtgia-server development`
  - `http://192.168.2.46:8082/health`: `healthy mtgia-server development`
- Stop check:
  `curl http://127.0.0.1:8082/health` failed after stop, confirming no listener
  remained on port `8082`.

## Commands executed

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
git fetch origin master --quiet
git pull --ff-only origin master
flutter devices --no-version-check
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
idevice_id -l
xcrun xctrace list devices
```

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
curl -sS http://127.0.0.1:8082/health
curl -sS http://192.168.20.167:8082/health
curl -sS http://192.168.2.46:8082/health
```

```bash
cd app
flutter analyze lib/features/scanner test/features/scanner --no-version-check
flutter test test/features/scanner --no-version-check
```

```bash
cd app
flutter test integration_test/scanner_controlled_harness_runtime_test.dart \
  -d "00008130-001C152922BA001C" \
  --dart-define=API_BASE_URL=http://192.168.20.167:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://192.168.20.167:8082 \
  --reporter expanded \
  --no-version-check
```

```bash
cd app
flutter run -d "00008130-001C152922BA001C" \
  --debug \
  --publish-port \
  --dart-define=API_BASE_URL=http://192.168.20.167:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://192.168.20.167:8082 \
  --no-version-check
```

## Runtime evidence

Proof folder:

- `app/doc/runtime_flow_proofs_2026-05-06_scanner_physical/`

Relevant local logs:

- `device_discovery_fresh.log`
- `backend_health_127001.log`
- `backend_health_en0.log`
- `backend_health_en1.log`
- `backend_scanner_contract_summary_fresh.log`
- `scanner_analyze.log`
- `scanner_unit_tests.log`
- `scanner_controlled_harness_physical_iphone_fresh.log`
- `flutter_run_physical_iphone_debug_publish_port_flag.log`
- `backend_stop_check.log`

No photos, raw OCR payloads, auth tokens, JWTs, Sentry DSNs, database URLs, or
real user emails are recorded in this handoff.

## What was real vs mocked

Real:

- Physical iPhone discovery through Flutter, `idevice_id`, and Xcode tooling.
- Physical iPhone debug app launch with `--publish-port`.
- Backend on local Mac port `8082`.
- Backend scanner contract probes through `/cards/resolve`,
  `/cards?include_tokens=true`, and `/cards/printings?dedupe=false`.
- Scanner unit/widget tests on app code.

Controlled/mocked:

- Scanner provider/service OCR tests use controlled OCR text or fake search
  services.
- `scanner_controlled_harness_runtime_test.dart` is above the camera layer and
  uses fake printings; it did not prove camera hardware or MLKit live OCR.

Not proven:

- Camera permission prompt acceptance on physical iPhone.
- `CameraController` initialization from the scanner screen on physical iPhone.
- Live image stream and MLKit OCR over camera frames on physical iPhone.
- ROI/guide behavior with a real card in the physical frame.
- Feedback visual, loading, retry, manual search, and Binder/Deck add from a
  real scanner result.
- Any of the six required physical scan categories.

## Scanner contract proof

Sanitized backend checks returned token printings for `Phyrexian Horror`:

| Endpoint | Result |
| --- | --- |
| `POST /cards/resolve {"name":"Phyrexian Horror","include_tokens":true}` | `source=local`, `total=3`, all returned rows were `Token Artifact Creature - Phyrexian Horror`. |
| `GET /cards?name=Phyrexian%20Horror&dedupe=false&include_tokens=true` | `total=3`, token rows only. |
| `GET /cards/printings?name=Phyrexian%20Horror&dedupe=false` | `total=3`, token rows with collector and foil metadata. |
| `GET /cards/printings?name=Lightning%20Bolt&dedupe=false` | `total=10`, multiple printings available for edition selection. |

This confirms the backend/token contract still prevents the token path from
falling into a normal-card fuzzy result such as `Phyrexian Censor` or
`Phyrexian Scissor`. Physical OCR recognition of the token was not repeated in
this run.

## Physical scan matrix

| Required scan | Expected card/category | OCR/resolve result | Endpoint from physical scanner | Token preserved | Editions/printings UI | Time perceived | Classification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Token | `Phyrexian Horror` token | Not captured | Not called by physical scanner | Backend PASS only; physical NOT PROVEN | Backend printings PASS only | N/A | `NOT PROVEN` |
| Similar name | Card with nearby name risk | Not captured | Not called by physical scanner | N/A | N/A | N/A | `NOT PROVEN` |
| Foil/reflection | Foil card | Not captured | Not called by physical scanner | N/A | N/A | N/A | `NOT PROVEN` |
| Old card | Older frame/card | Not captured | Not called by physical scanner | N/A | N/A | N/A | `NOT PROVEN` |
| Dark card | Low-light/dark card | Not captured | Not called by physical scanner | N/A | N/A | N/A | `NOT PROVEN` |
| Multiple editions | Card with multiple printings | Not captured | Not called by physical scanner | N/A | Backend printings PASS only | N/A | `NOT PROVEN` |
| Easy normal | Normal well-lit card | Not captured | Not called by physical scanner | N/A | N/A | N/A | `NOT PROVEN` |

## Result matrix

| Requirement | Result | Evidence |
| --- | --- | --- |
| Physical iPhone available | `PASS` | `Rafa`, `00008130-001C152922BA001C`, `iOS 26.5 23F5043k`. |
| Backend local 8082 healthy and accessible on LAN IP | `PASS` | `127.0.0.1`, `192.168.20.167`, and `192.168.2.46` health returned `healthy`. |
| App launched on physical iPhone | `PASS` | `flutter run --debug --publish-port` reached Dart VM Service on `Rafa`. |
| Controlled scanner unit/widget layer | `PASS` | `flutter analyze` no issues; `flutter test test/features/scanner` passed `+20`. |
| Controlled physical integration test | `BLOCKED` | `flutter test ... -d 00008130...` installed/launched but ended with `No tests ran`; earlier attempt timed out waiting for VM Service. |
| Camera permission on physical iPhone | `NOT PROVEN` | No scanner screen/manual camera permission step executed. |
| Live camera/OCR scans, 6-card matrix | `NOT PROVEN` | No non-interactive way to position physical cards and record scanner outcomes from CLI. |
| Phyrexian Horror token not resolving as Censor/Scissor | `BACKEND PASS / PHYSICAL NOT PROVEN` | Backend token endpoints returned token rows only; no physical OCR retest. |
| Backend stopped at end | `PASS` | Port `8082` health failed after kill; no listener remained. |

## Blockers

1. The requested physical scanner closure needs a human-in-the-loop card matrix:
   unlock device, navigate to scanner, accept camera permission if prompted,
   place each physical card inside the guide, classify OCR/resolve result, and
   verify add/retry/manual-search UI.
2. `flutter test` on the physical iPhone did not execute the controlled
   integration assertions in this run (`No tests ran`), although `flutter run`
   succeeded after adding `--publish-port`.
3. The existing controlled harness intentionally bypasses camera/MLKit frames,
   so it cannot close a physical camera/OCR release blocker.

## Smallest next actions

1. Run a hands-on QA session on `Rafa` or another wired physical iPhone with the
   seven-card matrix above and save sanitized per-scan notes plus screenshots
   that do not expose sensitive photos.
2. Add a dedicated physical camera smoke harness if automation is required:
   boot directly into `CardScannerScreen`, surface camera permission/camera
   initialization state, and optionally allow a fixture-image MLKit path
   separate from live camera proof.
3. Keep the backend token contract as a required preflight:
   `/cards/resolve include_tokens=true`,
   `/cards?include_tokens=true`, and `/cards/printings?dedupe=false`.
