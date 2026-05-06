# Physical iPhone Non-Scanner QA - 2026-05-06

## Verdict

`BLOCKED`

The app was installed and opened on the physical iPhone with the public backend
and reached `/login`, but automated Flutter device tests could not run because
the Dart VM Service was not discovered on the device. Scanner, camera, OCR and
MLKit scanner flows were intentionally ignored.

## Runtime environment

Date/time: `2026-05-06T16:27:04-03:00` to `2026-05-06T17:09:15-03:00`

Repository: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia`

Branch: `master`

Local git SHA: `059fc9b`

Backend URL used by app:
`https://evolution-cartinhas.8ktevp.easypanel.host`

Physical device:

- Name: `Rafa`
- Flutter device id: `00008130-001C152922BA001C`
- Runtime: `iOS 26.5 23F5043k`
- CoreDevice model: `iPhone 15 Pro (iPhone16,1)`

## Device discovery

`flutter devices --no-version-check` found:

```text
Rafa (mobile)      • 00008130-001C152922BA001C            • ios • iOS 26.5 23F5043k
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • iOS 17.4 simulator
macOS (desktop)    • macos                                • darwin-arm64
Chrome (web)       • chrome                               • web-javascript
```

`xcrun xctrace list devices` also reported:

```text
Rafa (26.5) (00008130-001C152922BA001C)
```

## Backend health and SHA

Command:

```bash
curl -fsS https://evolution-cartinhas.8ktevp.easypanel.host/health
```

Result:

```json
{
  "status": "healthy",
  "service": "mtgia-server",
  "environment": "production",
  "version": "1.0.0",
  "git_sha": "059fc9b466d45a81bc82cc54ba824de133bf5bff"
}
```

Low-level latency probes from the Mac:

| Endpoint | HTTP | Time |
| --- | ---: | ---: |
| `/health` | 200 | 1.099s |
| `/cards?name=Black%20Lotus&limit=1` | 200 | 0.633s |
| `/sets?search=OM2&limit=1` | 200 | 0.710s |
| `/sets/OM2` | 404 | 0.620s |

The direct `/sets/OM2` 404 was not proven as user-facing because the physical
UI test did not execute past runner startup.

## Static and unit validation

```bash
cd app
flutter analyze lib test integration_test --no-version-check
```

Result: `PASS`, no issues found.

```bash
cd app
flutter test test --no-version-check
```

Result: `PASS`, `548` tests passed. Scanner unit tests were included by this
repository-level unit command, but no scanner physical/runtime flow was executed.

## Physical automation attempts

All physical attempts used:

```bash
--dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host
--dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host
```

### Attempt 1 - sets catalog integration

Command:

```bash
cd app
flutter test integration_test/sets_catalog_runtime_test.dart \
  -d 00008130-001C152922BA001C \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

Result: `BLOCKED`.

Evidence log:
`app/doc/runtime_flow_proofs_2026-05-06_physical_iphone_non_scanner/logs/sets_catalog_runtime_test.log`

Observed: build succeeded, install/launch started, but no test body output was
received.

### Attempt 2 - sets catalog integration after cleanup

Command: same as Attempt 1.

Result: `BLOCKED`.

Evidence log:
`app/doc/runtime_flow_proofs_2026-05-06_physical_iphone_non_scanner/logs/sets_catalog_runtime_test_after_cleanup.log`

Key runner output:

```text
The Dart VM Service was not discovered after 60 seconds.
Installing and launching... 616.2s
Failed to load ".../integration_test/sets_catalog_runtime_test.dart":
Unable to start the app on the device.
Some tests failed.
```

No integration test body ran.

### Attempt 3 - app boot with main.dart

Command:

```bash
cd app
flutter run -d 00008130-001C152922BA001C \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --no-version-check
```

Result: `APP BOOT PASS / RUNNER BLOCKED`.

Evidence log:
`app/doc/runtime_flow_proofs_2026-05-06_physical_iphone_non_scanner/logs/flutter_run_main_after_cleanup.log`

Key sanitized app output:

```text
flutter: [ApiClient] baseUrl = https://evolution-cartinhas.8ktevp.easypanel.host
flutter: [ApiClient] platform = TargetPlatform.iOS | kIsWeb=false | kDebugMode=true
flutter: [Router] redirect: location=/login | status=AuthStatus.unauthenticated
flutter: [Screen] -> PUSH: login
Process ... exited with status = 9
Error connecting to the service protocol: failed to connect to http://127.0.0.1:.../ws
```

This proves the app opened on the physical device and rendered the login route
with the public backend configuration. It does not prove automated interaction
flows because the debug service connection was lost.

## Test scope status

| Scope | Status | Notes |
| --- | --- | --- |
| App boot on physical iPhone | `PASS` | Reached `/login` with public backend. |
| Backend `/health` and `git_sha` | `PASS` | Public backend SHA matches local `master`. |
| `flutter analyze lib test integration_test` | `PASS` | No issues found. |
| `flutter test test` | `PASS` | 548 tests passed. |
| Auth/register/login integration | `NOT PROVEN` | No standalone auth harness found; blocked by common physical runner issue. |
| Sets/search/catalog | `BLOCKED` | First attempted harness; VM Service not discovered. |
| Collection entrypoints | `NOT RUN` | Blocked by same physical runner startup issue. |
| Deck generate/create/detail/optimize/preview/apply/validate | `NOT RUN` | Blocked by same physical runner startup issue. |
| Binder dashboard | `NOT RUN` | Blocked by same physical runner startup issue. |
| Marketplace/trades/messages/notifications | `NOT RUN` | Blocked by same physical runner startup issue. |
| Life counter/lotus non-scanner | `NOT RUN` | Blocked by same physical runner startup issue. |
| Visual non-scanner | `NOT RUN` | `app_full_non_life_counter_visual_capture_smoke_test.dart` mentions scanner and was not used before the runner blocker. |
| Sentry/Firebase Performance | `NOT RUN` | Blocked by same physical runner startup issue. |
| Scanner/camera/OCR/MLKit scanner | `DEFERRED / IGNORED` | Explicitly out of scope. |

## What was real vs mocked

Real:

- Physical iPhone `Rafa` (`00008130-001C152922BA001C`)
- iOS install/launch through Flutter/Xcode tooling
- Public backend URL passed via `--dart-define`
- Backend `/health` and low-level read-only probes
- App boot to `/login`

Mocked:

- Nothing in the physical boot attempt.

Not executed:

- User interactions inside integration tests, because the Flutter runner did not
  establish a service protocol connection.

## Artifacts

Log folder:

`app/doc/runtime_flow_proofs_2026-05-06_physical_iphone_non_scanner/logs/`

Key logs:

- `sets_catalog_runtime_test.log`
- `sets_catalog_runtime_test_retry_timeout.log`
- `sets_catalog_runtime_test_after_cleanup.log`
- `flutter_run_main_after_cleanup.log`

Screenshots: not captured. The available `devicectl` in this environment did not
expose a screenshot subcommand.

## Blocker ownership

Owner: `Mobile Runtime Device QA` / local iOS toolchain-device connection.

The app booted, so this is not currently classified as a backend contract bug or
as a scanner/camera/OCR issue. The physical automation blocker is that Flutter
cannot keep/discover the Dart VM Service on `Rafa`:

```text
The Dart VM Service was not discovered after 60 seconds.
Error connecting to the service protocol: WebSocket connection reset.
```

## Smallest next actions

1. Reboot/unlock `Rafa`, keep it wired and trusted, then rerun
   `flutter run -v -d 00008130-001C152922BA001C` to diagnose why the service
   protocol is terminated.
2. Check macOS Settings > Privacy & Security > Automation for Xcode/Terminal
   control, matching the Flutter prompt shown during the run.
3. Once `flutter run` stays attached, rerun `sets_catalog_runtime_test.dart`
   first, then the remaining non-scanner integration suite.
4. Keep `scanner_controlled_harness_runtime_test.dart` and any harness requiring
   scanner/camera/OCR/MLKit out of this matrix.
