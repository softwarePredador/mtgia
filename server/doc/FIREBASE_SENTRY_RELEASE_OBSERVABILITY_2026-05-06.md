# Firebase/Sentry release observability readiness - 2026-05-06

## Verdict

**BLOCKED for TestFlight/internal iOS observability proof.**

The app code/config is ready enough for a controlled observability smoke, and a
local Android release APK builds, but the required staging/TestFlight proof is
blocked by local iOS distribution signing/export plus missing app Sentry secret
configuration. No secret values were printed or committed in this handoff; all
secret-like items below are classified only as `PRESENT`, `MISSING` or
`NOT CONFIGURED`.

## Scope

- Firebase Performance / Firebase app configuration review for iOS and Android.
- Sentry mobile bootstrap and dart-define contract review.
- Local release build attempt; no public upload.
- Runtime/smoke on the iPhone 15 Simulator.
- Scanner physical camera/OCR stayed out of scope.
- Backend was not started; no backend endpoint was required for this proof.

## Device and runtime evidence

| Item | Result |
| --- | --- |
| Date/time | `2026-05-06T13:10-03:00` to `2026-05-06T13:45-03:00` |
| Branch | `master` |
| Initial sync | `git pull --ff-only origin master` -> already up to date |
| iPhone 15 Simulator | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| iOS runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Backend URL | Not used |
| Backend health | Not applicable |

Device discovery summary:

```text
flutter devices:
iPhone 15 (mobile) - F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF - ios - com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
macOS, Chrome

xcrun simctl list devices available | grep -E "iPhone 15|Booted":
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

## Config checklist

| Area | Status | Notes |
| --- | --- | --- |
| App `SENTRY_DSN` env | `MISSING` | Sentry capture to SaaS cannot be proven without passing this as a secure dart-define/CI secret. |
| App `SENTRY_ENVIRONMENT` env | `MISSING` | Supported by code; passed as non-secret dart-define in smoke/build commands. |
| App `SENTRY_RELEASE` env | `MISSING` | Supported by code; passed as non-secret dart-define in smoke/build commands. |
| App `SENTRY_TRACES_SAMPLE_RATE` env | `MISSING` | Supported by code; passed as non-secret dart-define in smoke/build commands. |
| iOS Firebase config file | `PRESENT` | `app/ios/Runner/GoogleService-Info.plist`; values not printed. |
| Android Firebase config file | `PRESENT` | `app/android/app/google-services.json`; values not printed. |
| FlutterFire options | `PRESENT` | `app/lib/firebase_options.dart`; values not repeated in docs. |
| iOS Info.plist | `PRESENT` | ATS/local networking and camera usage string present; no Sentry/Firebase secret values stored there. |
| AndroidManifest | `PRESENT` | Internet and camera permissions present; no Sentry/Firebase secret values stored there. |
| Android Google Services plugin | `PRESENT` | `com.google.gms.google-services` applied in Android app Gradle. |
| Explicit build flavors | `NOT CONFIGURED` | No product flavors found; staging/release behavior is controlled by dart-defines. |
| Android release signing | `MISSING` | `app/android/key.properties` missing; Gradle falls back to debug signing for local release validation only. |
| iOS distribution signing/export | `MISSING` | Archive succeeds with development identity, but IPA export fails without iOS Distribution cert/provisioning/profile permissions. |
| Public upload | `NOT RUN` | Intentionally not generated/uploaded. |

## Code adjustments

- Added `app/integration_test/release_observability_smoke_test.dart`.
  - Boots a minimal UI under `AppObservability`.
  - Attempts a controlled Sentry event without printing DSN or payload.
  - Initializes Firebase and Firebase Performance, runs a short custom trace and
    prints only boolean/status markers.
- Added `@visibleForTesting` read-only status getters to
  `PerformanceService`; no runtime behavior changed.

## Commands and results

| Command | Result |
| --- | --- |
| `git status --short && git branch --show-current && git --no-pager log -1 --oneline` | PASS; branch `master`, no local tracked changes at start. |
| `git pull --ff-only origin master` | PASS; already up to date. |
| `flutter devices && xcrun simctl list devices available \| grep -E "iPhone 15\|Booted"` | PASS; iPhone 15 simulator id/runtime captured above. |
| Safe presence checks for Sentry/Firebase/env files | PASS; statuses recorded above without values. |
| `cd app && dart format lib/core/services/performance_service.dart integration_test/release_observability_smoke_test.dart` | PASS. |
| `cd app && flutter analyze lib/core/services/performance_service.dart integration_test/release_observability_smoke_test.dart --no-version-check` | PASS; no issues. |
| `cd app && flutter test integration_test/release_observability_smoke_test.dart -d "iPhone 15" --dart-define=SENTRY_ENVIRONMENT=staging --dart-define=SENTRY_RELEASE=mtgia-observability-2026-05-06 --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 --reporter expanded --no-version-check` | PASS; `SENTRY_RELEASE_SMOKE_RESULT=not_configured`, `SENTRY_RELEASE_DSN_CONFIGURED=false`, `FIREBASE_PERFORMANCE_SMOKE_RESULT=initialized`, `FIREBASE_PERFORMANCE_COLLECTION_ENABLED=true`. |
| `cd app && flutter build ipa --release --export-method ad-hoc --dart-define=SENTRY_ENVIRONMENT=staging --dart-define=SENTRY_RELEASE=mtgia-observability-2026-05-06 --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 --no-version-check` | PARTIAL/BLOCKED; `Runner.xcarchive` built, IPA export failed because iOS Distribution certificate/profiles and profile creation permission are unavailable locally. |
| `cd app && flutter build apk --release --dart-define=SENTRY_ENVIRONMENT=staging --dart-define=SENTRY_RELEASE=mtgia-observability-2026-05-06 --dart-define=SENTRY_TRACES_SAMPLE_RATE=1.0 --no-version-check` | PASS; local release APK built. Distribution signing remains not production/internal-ready because `key.properties` is missing and the build uses debug fallback. |

## Observability status

| Signal | Status | Interpretation |
| --- | --- | --- |
| Sentry SDK bootstrap | PASS | Code initializes Sentry only when `SENTRY_DSN` is non-empty and keeps PII disabled. |
| Sentry event capture to SaaS | **NOT PROVEN / BLOCKED** | Runtime command intentionally had no DSN; test reported `not_configured`. Needs secure DSN injection and dashboard/event-id verification in staging/TestFlight. |
| Firebase app config | PASS | iOS/Android config files and FlutterFire options exist. |
| Firebase Performance initialization | PASS in simulator smoke | iPhone 15 integration smoke initialized Performance and enabled collection. |
| Firebase Performance console ingestion | **NOT PROVEN** | Integration test can prove initialization, not that Firebase Console received a release/TestFlight trace. Needs signed staging/TestFlight/internal build on device/TestFlight and console verification. |
| iOS TestFlight/internal IPA | **BLOCKED** | Archive built, export failed due missing Distribution certificate/provisioning/profile permission. |
| Android local release | PASS WITH RISK | APK builds locally; release signing for distribution is not configured. |

## Go / no-go

**No-go for claiming TestFlight/internal release observability.**

Proceed only after:

1. Configure iOS Distribution certificate/provisioning/export profile in CI or a
   secure local Apple account with the correct permissions.
2. Pass `SENTRY_DSN`, `SENTRY_ENVIRONMENT`, `SENTRY_RELEASE` and trace sample
   rate as secure build-time values; never commit or print them.
3. Install/upload a signed internal/TestFlight build and verify a controlled
   Sentry event in Sentry using a non-sensitive smoke tag.
4. Verify Firebase Performance trace/session arrival in Firebase Console from
   the signed staging/TestFlight build.
5. If Android internal distribution is needed, configure release signing via
   secure `key.properties`/CI secrets instead of relying on debug fallback.

Until those items are complete, keep the classification **BLOCKED** for
TestFlight observability proof, even though code-level smoke and local Android
release build are passing.
