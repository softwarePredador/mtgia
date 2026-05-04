# ManaLoom Internal Release / Staging Handoff - 2026-05-04

## Release verdict

**READY WITH RISKS for internal/staging only.**

The validated non-scanner scope passed on `master` at commit `85b4200` with a real local backend on `http://127.0.0.1:8082` and iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` (`com.apple.CoreSimulator.SimRuntime.iOS-17-4`).

This is not a production/broad-rollout approval because the fresh 5-sample `/ai/generate` latency regressed beyond the previously accepted risk threshold. All `/ai/generate` samples returned `200`, but p95/p99 reached `44756ms`.

## Scope

In scope for this internal/staging handoff:

1. Auth register/login/current user.
2. Search Cards and Search -> Cards/Colecoes.
3. Sets catalog and set detail.
4. Deck generate/create/detail/import.
5. Deck optimize preview/apply/validate.
6. Binder dashboard.
7. Marketplace.
8. Trades, trade messages and trade status timeline.
9. Direct messages.
10. Notifications.
11. Life Counter/Lotus.
12. App/backend contract visibility for touched screens.
13. Staging/internal configuration readiness review without exposing secrets.

Explicitly out of scope:

1. Scanner physical camera/OCR.
2. Any physical scanner capture.
3. Claiming simulator proof as physical camera proof.

Scanner status remains **DEFERRED / NOT PROVEN** and is not a blocker only while scanner physical camera/OCR stays outside this release scope.

## Environment readiness

No secret values were printed or committed. Status below records only presence/classification.

| Area | Status | Notes |
|---|---|---|
| Backend URL for app | CONFIGURED BY COMMAND | Runtimes used `API_BASE_URL=http://127.0.0.1:8082`. Release/profile must pass a non-empty `API_BASE_URL`; app release fallback is empty. |
| Public backend URL for app | CONFIGURED BY COMMAND | Runtimes used `PUBLIC_API_BASE_URL=http://127.0.0.1:8082`. |
| Server `.env` | PRESENT | Values not exposed. |
| `DATABASE_URL` | PRESENT | Redacted. |
| `JWT_SECRET` | PRESENT | Redacted. |
| `OPENAI_API_KEY` | PRESENT | Redacted. |
| Server `SENTRY_DSN` | PRESENT | Redacted; backend log showed Sentry initialized in staging. |
| App `SENTRY_DSN` | NOT CONFIGURED IN RUNTIME COMMAND | App supports a Sentry DSN dart-define; this validation intentionally did not print/pass a DSN. |
| App `SENTRY_ENVIRONMENT` / `SENTRY_RELEASE` | NOT CONFIGURED IN RUNTIME COMMAND | Supported by `AppObservability`; recommended for internal builds. |
| Firebase iOS config | PRESENT | `GoogleService-Info.plist` present; values redacted. |
| Firebase Android config | PRESENT | `google-services.json` present; values redacted. |
| Firebase Performance in integration test | NOT PROVEN / DEGRADED | Integration logs reported Firebase Performance unavailable because the test session had no default Firebase app for HTTP metrics. App breadcrumbs/backend logs covered basic visibility. |
| Server FCM env keys | MISSING | `FIREBASE_PROJECT_ID` and `FCM_SERVER_KEY` were not present in `server/.env`; push delivery backend credentials need staging setup before push validation. |
| iOS camera permission | PRESENT | `NSCameraUsageDescription` exists, but scanner physical camera/OCR was not executed. |
| Android camera permission | PRESENT | `CAMERA` permission and optional camera features exist, but scanner physical camera/OCR was not executed. |
| iOS ATS/local networking | PRESENT | Local networking/arbitrary loads are enabled for current local/staging validation posture. Review before production hardening. |
| App version/build | `1.0.0+1` | From `app/pubspec.yaml`. Override build number for each internal upload. |
| iOS bundle id | `com.mtgia.mtgApp` | Runner tests use `com.mtgia.mtgApp.RunnerTests`. |
| Android package id | `com.mtgia.mtg_app` | Namespace and applicationId match. |
| Flavors/env | NOT CONFIGURED | No explicit product flavors found; environment is controlled by dart-defines. |
| Android release signing | NOT CONFIGURED LOCALLY | `key.properties` missing. Gradle falls back to debug signing locally; internal distribution requires CI/local release signing setup. |
| iOS export/signing | NOT CONFIGURED LOCALLY | No local `ExportOptions.plist`; project has code-sign style but no local development team/provisioning profile detected. |

## Device and backend

| Item | Value |
|---|---|
| Date/time | `2026-05-04T16:40-03:00` to `2026-05-04T17:14-03:00` |
| Branch | `master` |
| Commit | `85b4200` |
| Backend command | `cd server && PORT=8082 dart run .dart_frog/server.dart` |
| Backend URL | `http://127.0.0.1:8082` |
| Backend health | `healthy` |
| Backend final state | Stopped; port `8082` free at handoff close. |
| iPhone 15 Simulator | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` |
| iOS runtime | `com.apple.CoreSimulator.SimRuntime.iOS-17-4` |
| Physical iPhone | Detected as `Rafa` on iOS 26.5, not used because simulator covered the non-scanner release scope. |

Device discovery summary:

```text
flutter devices:
iPhone 15 (mobile) - F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF - ios - com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
Rafa (mobile) - 00008130-001C152922BA001C - ios - iOS 26.5 23F5043k
macOS, Chrome

xcrun simctl list devices available | grep -E "iPhone 15|Booted":
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

Backend health:

```json
{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0","checks":{"process":{"status":"healthy"}}}
```

## Commands executed

| Area | Command | Result |
|---|---|---|
| Initial discovery | `git status --short && flutter devices && xcrun simctl list devices available \| grep -E "iPhone 15\|Booted"` | PASS; iPhone 15 booted. Initial status had no tracked app/server doc changes. |
| Config audit | Presence checks for app/server env, Sentry, Firebase, bundle/package ids, camera permissions, version/build and flavors | PASS with findings above; no secret values exposed. |
| Backend offline | `cd server && dart analyze lib routes bin test && dart test -r expanded` | PASS; `+558`. |
| Backend start/health | `cd server && PORT=8082 dart run .dart_frog/server.dart` and `curl -sS http://127.0.0.1:8082/health` | PASS; health `healthy`. |
| Backend live | `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded` | PASS; `+167 ~3`. |
| App analyze/test | `cd app && flutter analyze lib test integration_test --no-version-check && flutter test test --no-version-check` | PASS; `+530`. Scanner tests here are controlled/unit tests only, not physical scanner proof. |
| Sets catalog runtime | `cd app && flutter test integration_test/sets_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `00:17 +1`. |
| Search/Sets runtime | `cd app && flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `00:28 +1`. |
| Deck runtime | `cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `01:38 +1`, final screenshot marker `10_complete_validated`. |
| Binder dashboard runtime | `cd app && flutter test integration_test/binder_dashboard_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `00:43 +1`. |
| Marketplace/Trades/Messages/Notifications | `cd app && flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `01:50 +2`. |
| Life Counter/Lotus runtime | `cd app && flutter test integration_test/life_counter_lotus_visual_runtime_proof_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `00:28 +1`. |
| Visual non-scanner smoke | `cd app && flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS; `01:02 +1`. |
| AI performance | 5 samples each for `POST /ai/generate` and `POST /ai/optimize` using synthetic QA data | PASS for HTTP status, but `/ai/generate` latency is outside accepted risk. |
| Cleanup | Stop backend `8082`, confirm `lsof -nP -iTCP:8082 -sTCP:LISTEN` has no listener, restore generated live optimize artifact | PASS; port free and generated latest artifact restored. |

## Runtime/log visibility

Runtime logs for the iPhone 15 integration tests were clean for:

1. Flutter exceptions.
2. RenderFlex overflow.
3. Residual runtime `500`.
4. Runtime socket/timeout failures.
5. Failed integration-test result.

The keyword hits for `status=500`, `SocketException` and `TimeoutException` were found only in app unit-test logs or backend/process logs, not in the passing iPhone 15 runtime logs.

Sentry/log status:

| Area | Status |
|---|---|
| Backend Sentry | PRESENT and initialized; DSN not exposed. |
| App Sentry | Supported via dart-define; not enabled in this runtime command. |
| App breadcrumbs | PRESENT in debug/integration logs for API slow requests and Life Counter/Lotus events. |
| Firebase Performance | NOT PROVEN in integration session; plugin logged unavailable HTTP metrics. |
| Firebase push | App config present; server FCM env missing, so push delivery remains staging setup work. |

## Performance snapshot

5 samples per endpoint against the real local backend on `8082`; synthetic QA account/decks; no tokens/emails/payload secrets recorded.

| Endpoint | Statuses | p50 | p95 | p99 | Release interpretation |
|---|---:|---:|---:|---:|---|
| `POST /ai/generate` | `200x5` | `24293ms` | `44756ms` | `44756ms` | **Outside accepted risk.** Internal/staging can proceed only with explicit warning; not production-ready. |
| `POST /ai/optimize` | `202x5` | `4786ms` | `5029ms` | `5029ms` | Inside previous accepted risk; all async jobs completed. |

Previous accepted-risk reference was `/ai/generate` p95 around `10203ms` and release threshold `<=12000ms` for this cycle. The fresh p95/p99 now exceeds that threshold by a wide margin. Treat as P1 before any broader rollout, and as no-go for production/broad staging if repeated.

## Accepted risks for internal/staging

| Risk | Decision |
|---|---|
| Scanner physical camera/OCR not proven | Accepted only because scanner is excluded from this release scope. |
| `/ai/generate` p95/p99 `44756ms` | Accepted only for narrow internal/staging with clear loading expectations and monitoring; no-go for production/broad rollout until reduced or made async/resilient. |
| Firebase Performance unavailable in integration tests | Accepted for internal/staging because app breadcrumbs and backend logs provide basic visibility; must be fixed before relying on Firebase Performance. |
| Push server credentials missing locally | Accepted for this non-push runtime gate; required before claiming FCM delivery readiness. |
| Local release signing/export not configured | Accepted for runtime handoff; build/upload needs CI or local signing configuration before distribution. |
| No explicit flavors | Accepted if internal/staging builds consistently pass dart-defines; consider flavors before repeated internal tracks. |

## No-go criteria

Convert to **BLOCKED** if any of these become true:

1. Scanner physical camera/OCR is added to scope without fresh physical-device proof.
2. Any final command produces reproducible runtime crash, timeout, overflow, build/analyze/test failure, or residual app-runtime `4xx/5xx` on the validated paths.
3. Any committed artifact exposes secrets, tokens, JWTs, Sentry DSN, database URL, Firebase keys, real emails, Authorization headers, or sensitive payloads.
4. `/ai/generate` has user-facing timeout/failure, or this latency profile is considered unacceptable for the intended internal audience.
5. TestFlight/internal upload is required but signing/export credentials are not configured in CI or locally.

## Recommended internal build commands

Use CI secrets or a secure local shell for secret dart-defines. Do not commit secret values.

TestFlight/internal iOS archive:

```bash
cd app
flutter build ipa --release \
  --build-name=1.0.0 \
  --build-number=<internal-build-number> \
  --dart-define=API_BASE_URL=<staging-api-url> \
  --dart-define=PUBLIC_API_BASE_URL=<staging-api-url> \
  --dart-define=SENTRY_DSN=<ci-secret-sentry-dsn> \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=manaloom@1.0.0+<internal-build-number>
```

Android internal app bundle:

```bash
cd app
flutter build appbundle --release \
  --build-name=1.0.0 \
  --build-number=<internal-build-number> \
  --dart-define=API_BASE_URL=<staging-api-url> \
  --dart-define=PUBLIC_API_BASE_URL=<staging-api-url> \
  --dart-define=SENTRY_DSN=<ci-secret-sentry-dsn> \
  --dart-define=SENTRY_ENVIRONMENT=staging \
  --dart-define=SENTRY_RELEASE=manaloom@1.0.0+<internal-build-number>
```

Build prerequisites before upload:

1. Configure iOS signing team/profile/export options in CI or local Xcode.
2. Configure Android release signing via secure `key.properties`/CI secrets; do not rely on debug fallback for distributed builds.
3. Use a real staging API URL, not `127.0.0.1`, for distributed devices.
4. Pass Sentry dart-defines from secret storage.
5. Decide whether Firebase/FCM should be fully validated for this internal build; if yes, configure server push credentials first.

## Rollback plan

1. Stop rollout immediately if the staging build shows crash, timeout, residual app-runtime `4xx/5xx`, secret exposure, or scanner scope creep.
2. Keep failing logs local, sanitize before sharing, and do not commit raw tokens/emails/JWTs/DSNs.
3. Revert app distribution to the last known good internal build and backend to the last known good deployed revision.
4. If `/ai/generate` latency impacts users, disable/promote an async/loading-gated path or gate AI Generate for the internal group until latency is reduced.
5. Keep scanner physical camera/OCR hidden/deferred until a separate physical-device handoff exists.

## Next sprint

1. P1: reduce `/ai/generate` p95 or make the flow async/progress-resilient before broad rollout.
2. P1: configure internal build signing/export in CI and record a signed build proof.
3. P2: initialize/validate Firebase Performance in staging builds if it is required for release observability.
4. P2: configure server FCM credentials and run a push smoke if notifications delivery is release-critical.
5. P2: keep profiling `/binder/stats`, `/market/movers`, trade detail and card-by-card deck writes.
6. DEFERRED: run scanner physical camera/OCR matrix only when scanner returns to scope.
