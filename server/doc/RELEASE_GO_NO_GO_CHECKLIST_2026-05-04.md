# ManaLoom Release Go/No-Go Checklist - 2026-05-04

## Executive summary

ManaLoom is **GO WITH RISKS** for the release scope validated on `master` at commit `784a44d`.

The final regression and pre-release QA proved the core app/backend flows on iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` with iOS runtime `com.apple.CoreSimulator.SimRuntime.iOS-17-4`, using a real local backend at `http://127.0.0.1:8082`. Scanner physical camera/OCR remains **DEFERRED / NOT PROVEN** and is **not a blocker** only if this release does not depend on scanner physical proof.

## Current verdict

| Field | Value |
|---|---|
| Verdict | **GO WITH RISKS** |
| Target branch | `master` |
| Evidence commit | `784a44d` |
| Release dependency on scanner physical camera/OCR | No |
| Scanner status | `DEFERRED / NOT PROVEN` |
| Blocking defects in validated scope | None recorded in final regression or pre-release QA |
| Main accepted risks | AI latency, trade detail latency, Firebase Performance unavailable in integration test, scanner physical proof deferred |

## Release scope

In scope for this go/no-go decision:

1. Auth register/login/current user.
2. Search Cards and Search -> Cards/Colecoes.
3. Sets catalog and set detail.
4. Deck create/detail/import/Commander flow.
5. AI Generate proposal preview.
6. AI Optimize preview/apply/validate.
7. Deck validation.
8. Meta reference surfaces used by generate/optimize.
9. Binder dashboard CRUD/stats.
10. Marketplace.
11. Trades, trade messages, trade status timeline.
12. Direct messages.
13. Notifications.
14. Life Counter/Lotus runtime.
15. Backend/app contract visibility for touched screens.

Out of scope for this release decision:

1. Scanner physical camera/OCR proof on a physical device.
2. Physical iPhone proof for non-scanner flows.
3. Dedicated Marketplace/Binder visual screenshot polish beyond the functional runtime evidence.
4. Search global unified product work.
5. Dedicated Meta Deck Intelligence visual dashboard.

## Modules status table

| Module | Release status | Evidence | Release note |
|---|---|---|---|
| Auth | PASS | Pre-release runtime registered QA users via `/auth/register` with 201; API contract marks Auth/Profile stable. | No blocker. Do not expose tokens, JWTs, emails, password hashes, or auth headers in artifacts. |
| Search/Cards | PASS | `sets_search_catalog_runtime_test.dart`; `/cards?name=Black+Lotus`, `/cards?name=Sol Ring` returned 200. | `/cards` p95 was 1126 ms in 5 local samples; acceptable P3 first-hit risk. |
| Sets | PASS | `sets_catalog_runtime_test.dart`, `sets_search_catalog_runtime_test.dart`; `/sets` and `/cards?set=...` returned 200. | `/sets` p95 was 702 ms. |
| Decks | PASS | `deck_runtime_m2006_test.dart` on iPhone 15 Simulator created deck, opened detail, imported commander, reached final screenshot `10_complete_validated`. | Core deck path approved against real local backend. |
| AI Generate | PASS WITH ACCEPTED RISK | Visual runtime captured `06_generate_preview`; `/ai/generate` returned 200. | p95 `10203 ms` is accepted for this release only with loading/progress UX; track as P1 follow-up if repeated above the criteria below. |
| AI Optimize | PASS WITH ACCEPTED RISK | Deck runtime used `/ai/archetypes`, `/ai/optimize`, job polling and bulk apply, then validated final deck. | `/ai/optimize` p95 `4825 ms`; polling `/ai/optimize/jobs/:id` p95 `1199 ms`. Accepted because flow completed without crash/timeout. |
| Validate | PASS | Runtime reached `10_complete_validated`; API contract documents `POST /decks/:id/validate` as stable. | Validation details may evolve; app must keep generic handling for unknown issue types. |
| Meta | PASS WITH KNOWN LIMITS | Meta Deck Intelligence report proved EDHTop16 -> TopDeck chain and safe staging gates; app audit shows meta references in optimize/generate surfaces. | Archidekt/Moxfield adapters remain not proven for repository runtime and must not be promoted without dedicated proof. |
| Binder | PASS WITH PERF WATCH | `binder_dashboard_runtime_test.dart`; `/binder`, `/binder/stats`, add/edit/delete returned 200/201/204. | `/binder` p95 603 ms; cold-ish `/binder/stats` showed 2523-4095 ms in smoke and needs P2 follow-up. |
| Marketplace | PASS | `binder_marketplace_trade_runtime_test.dart`; `/community/marketplace` returned 200 with trust/price surfaces. | p95 629 ms. Dedicated screenshot polish remains P3 backlog. |
| Trades | PASS WITH PERF WATCH | Create/respond/status/detail/messages passed in runtime social test. | `/trades/:id` p95 1227 ms; accepted for this release, follow up if above threshold below. Invalid QA input `GET /trades/None` produced 500 and is P3 hardening, not runtime app blocker. |
| Messages | PASS | Runtime social test covered conversations inbox/read/messages/poll with 200/201. | No blocker. |
| Notifications | PASS | Runtime social test covered list/read/read-all/count with 200. | No blocker. |
| Life Counter/Lotus | PASS | `life_counter_lotus_visual_runtime_proof_test.dart` passed on retry; screenshots `life_counter_lotus_runtime_initial` and `life_counter_lotus_runtime_after_plus`. | First attempt failed due to concurrent build/DDS, then retry passed; keep as environmental note. |
| Scanner | DEFERRED / NOT PROVEN | Unit/controlled tests passed in broader app test history, but no physical camera/OCR run was executed in this pre-release round. | Not a blocker only because scanner physical proof is outside release scope. It must become NO-GO if scanner is marketed or required in this release. |

## Accepted risks

| Risk | Current measurement / evidence | Release decision | Follow-up criterion |
|---|---|---|---|
| `/ai/generate` latency | p50 `9475 ms`, p95/p99 `10203 ms` over 5 local samples. | Accepted risk for this release. | P1 if the next release candidate or staging run keeps p95 > `10000 ms`, any sample exceeds `15000 ms`, or any user-facing timeout/non-200 occurs. Target: p95 <= `8000 ms` before broad rollout. |
| `/ai/optimize` latency | p50 `4518 ms`, p95/p99 `4825 ms`; job polling p95 `1199 ms`. | Accepted risk. | P1 if job creation p95 > `6000 ms`, polling p95 > `2000 ms`, or optimize fails to reach preview/apply/validate. |
| `/trades/:id` latency | p50 `1192 ms`, p95/p99 `1227 ms`. | Accepted P3/P2 performance risk. | P1 if p95 > `2000 ms` or detail screen shows loading failure/crash; P2 if p95 remains > `1500 ms` after release. |
| Firebase Performance unavailable in integration test | Integration logs showed no Firebase default app, so HTTP metrics plugin disabled itself. | Accepted observability risk because app breadcrumbs and backend logs covered basic visibility. | P1 before production rollout if Firebase Performance remains unavailable in release/staging builds where it is expected. |
| Xcode simulator architecture warnings | iPhone 15 iOS 17.4 built and tests passed; warnings mention future simulator architecture constraints. | Accepted environmental risk. | Re-test pods/plugins before treating iOS 26+ simulator build failure as app regression. |
| Scanner physical proof deferred | No physical camera/OCR execution in final regression/pre-release QA. | Accepted only because scanner is out of release scope. | NO-GO if scanner becomes release-critical before a physical proof exists. |

## Deferred items

| Item | Status | Owner / next action |
|---|---|---|
| Scanner physical camera/OCR | `DEFERRED / NOT PROVEN` | Run physical scanner matrix on an unlocked physical device and record a dedicated handoff before claiming scanner release readiness. |
| Physical iPhone non-scanner proof | `NOT PROVEN` | Optional fallback only; simulator is the primary automated target for this release. |
| `/ai/generate` p95 reduction | P1 follow-up if repeated above criteria | Add async/progress strategy, cache/fallback tuning, or server-side generation optimization. |
| `/binder/stats`, `/market/movers`, card-by-card deck writes | P2 performance backlog | Profile DB queries and prefer bulk write paths where product allows. |
| `GET /trades/None` 500 on invalid QA input | P3 hardening | Validate UUID and return 400. |
| Marketplace/Binder dedicated screenshots | P3 visual backlog | Add/refresh visual proof after functional runtime coverage. |
| Search global unified product | P3 product backlog | Separate feature decision; not part of this release gate. |
| Meta visual dashboard | P2/P3 product backlog | Keep current meta reference surfaces; do not block release. |

## Blockers

No blockers are recorded for the validated release scope.

The following conditions would convert the verdict to NO-GO:

1. Scanner physical camera/OCR is added to release scope without a fresh physical device proof.
2. Any final validation command below produces a reproducible crash, timeout, residual 4xx/5xx in app runtime paths, or build/analyze/test failure.
3. Any artifact or log intended for commit contains secrets, tokens, JWTs, Sentry DSNs, database URLs, real emails, Authorization headers, or sensitive payloads.

## Required pre-release commands

Run these commands immediately before release from the repository root. Use a fresh terminal and keep logs sanitized.

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short --branch
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
```

Start the local backend:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
PORT=8082 dart run .dart_frog/server.dart
```

Verify health:

```bash
curl -sS http://127.0.0.1:8082/health
```

Run backend checks:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
dart analyze lib routes bin test
dart test -r expanded
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test -P live -r expanded
```

Run app checks:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter analyze lib test integration_test --no-version-check
flutter test test --no-version-check
flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/providers/deck_provider_support_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check
flutter analyze lib/features/cards lib/features/collection test/features/cards test/features/collection --no-version-check
flutter test test/features/cards test/features/collection --no-version-check
```

Run iPhone 15 Simulator runtime checks:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/app
flutter test integration_test/sets_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/binder_dashboard_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/life_counter_lotus_visual_runtime_proof_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

After validation, stop the backend with the exact PID started for this run and confirm the port is free:

```bash
lsof -nP -iTCP:8082 -sTCP:LISTEN
```

## Required runtime devices

| Device | Requirement | Current evidence |
|---|---|---|
| iPhone 15 Simulator | Required primary automated runtime device. Must show simulator id from `flutter devices` and/or `xcrun simctl`. | `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`, `com.apple.CoreSimulator.SimRuntime.iOS-17-4`, booted in final regression/pre-release QA. |
| Physical iPhone | Optional for this release unless scanner or physical-only behavior is in scope. | Detected as wireless device in pre-release QA, but `NOT PROVEN`. |
| Physical Android/M2006 | Optional fallback only. | Not required for this release decision. |
| Physical scanner/camera/OCR device | Required only if scanner physical capability is release-critical. | `DEFERRED / NOT PROVEN` in this release gate. |

## Observability checklist

| Check | Required state | Current state |
|---|---|---|
| Backend health | `/health` returns `healthy` before runtime tests. | PASS in final regression and pre-release QA. |
| App slow request breadcrumbs | Logs include method, endpoint, status, duration and request id without sensitive values. | PASS via `api_slow_request` breadcrumbs. |
| Backend slow/error observability | Logs include HTTP observability for slow/client/server errors. | PASS via `http_observability`; social notification deferred logs observed. |
| Sentry | May initialize, but no DSN or secret value may be committed or printed in release docs. | PASS with no DSN exposed in artifacts. |
| Firebase Performance | Expected for production/staging visibility; integration test can be `NOT PROVEN` if Firebase default app is not initialized. | Accepted risk: unavailable in integration test. |
| Sanitization | No tokens, JWTs, Authorization headers, Sentry DSN, database URL, real emails, password hashes, FCM tokens, or sensitive payloads in committed docs/log snippets. | Required before commit/release. |

## Data/API contract checklist

| Area | Required check |
|---|---|
| Auth/Profile | `/auth/login`, `/auth/register`, `/auth/me`, `/users/me` remain compatible and never expose password hashes, JWT secrets, FCM tokens, or raw Authorization headers. |
| Cards/Sets | Mobile uses backend `/cards`, `/cards/resolve`, `/cards/printings`, `/sets`; no mobile runtime calls to Scryfall, MTGJSON or other MTG external APIs. |
| Decks/Validate | Deck mutations preserve quantity semantics; `POST /decks/:id/validate` remains backend-owned and app handles evolving validation fields. |
| AI Generate/Optimize | `/ai/generate` and `/ai/optimize` remain tolerant/experimental contracts; app handles mock/cached/repaired responses, sync 200 and async 202 job flows. |
| Meta | Meta references are advisory and backend-owned; do not promote new external sources without source proof and staging/promotion gates. |
| Binder/Marketplace | Binder private items stay private; marketplace exposes only intended public trade/sale inventory and optional trust/price fields. |
| Trades/Messages/Notifications | Participants-only trade detail/messages; unknown notification types must be ignored gracefully by the app. |
| Scanner | Scanner uses backend card resolution/printings; physical scanner readiness is not claimed by simulator tests. |
| Health | `/health` is liveness only; use `/health/ready` when DB readiness is required. |

## Performance thresholds

These thresholds gate the final pre-release command set. Local development measurements include remote DB latency and should be compared with the same environment unless stated otherwise.

| Endpoint / flow | Current p95 | Release threshold | Decision |
|---|---:|---:|---|
| `GET /cards?name=Sol Ring&limit=20` | 1126 ms | <= 1500 ms | PASS |
| `GET /sets?limit=50&page=1` | 702 ms | <= 1500 ms | PASS |
| `GET /binder?page=1&limit=20` | 603 ms | <= 1500 ms | PASS |
| `GET /community/marketplace?search=Sol Ring` | 629 ms | <= 1500 ms | PASS |
| `GET /trades?page=1&limit=20&role=all` | 602 ms | <= 1500 ms | PASS |
| `GET /trades/:id` | 1227 ms | <= 1500 ms for release; P1 if > 2000 ms | PASS WITH WATCH |
| `POST /ai/generate` | 10203 ms | <= 12000 ms for this release; P1 follow-up if repeated > 10000 ms | ACCEPTED RISK |
| `POST /ai/optimize` | 4825 ms | <= 6000 ms | ACCEPTED RISK |
| `GET /ai/optimize/jobs/:id` | 1199 ms | <= 2000 ms | PASS WITH WATCH |

## Rollback plan

1. Stop rollout if final validation finds a new blocker, secret exposure, crash, timeout, or residual runtime 4xx/5xx.
2. Preserve the failing logs locally, sanitize them, and attach only non-sensitive excerpts to the incident handoff.
3. Revert to the last known good app/backend release artifact or previous deployed backend revision; do not roll forward with unproven scanner changes.
4. If backend-only regression appears, disable or revert the backend deployment first while keeping the mobile build unchanged when contract compatibility allows it.
5. If app-only regression appears, hold the app release and keep backend on the last validated compatible revision.
6. Re-run the required pre-release commands and affected iPhone 15 runtime tests before changing the verdict back to GO or GO WITH RISKS.

## Go criteria

The release remains GO WITH RISKS when all criteria below are true:

1. Branch is `master` and worktree is clean after docs/commit.
2. Required pre-release commands pass on a fresh run.
3. iPhone 15 Simulator id and runtime are recorded in the release evidence.
4. Backend health is `healthy` at the URL used by the app.
5. Auth, Cards/Sets, Decks, AI Generate, AI Optimize, Validate, Binder, Marketplace, Trades, Messages, Notifications and Life Counter/Lotus remain PASS.
6. Scanner physical camera/OCR remains explicitly `DEFERRED / NOT PROVEN` and out of scope.
7. Accepted performance risks stay within the release thresholds above.
8. Observability has at least app breadcrumbs and backend logs; Firebase Performance limitation is documented if still unavailable in integration tests.
9. No committed artifact exposes secrets or sensitive payloads.

## No-go criteria

Release becomes NO-GO if any condition below is true:

1. A final validation command fails reproducibly.
2. Any runtime path has a residual crash, timeout, overflow, or app-facing 4xx/5xx not caused by a test harness negative case.
3. `/ai/generate` p95 exceeds `12000 ms` in final local QA, any sample exceeds `15000 ms`, or generate fails to show a preview.
4. `/ai/optimize` does not reach preview/apply/validate, job creation p95 exceeds `6000 ms`, or polling p95 exceeds `2000 ms`.
5. `/trades/:id` p95 exceeds `2000 ms` or trade detail fails to load.
6. Scanner physical proof becomes release-critical while still `DEFERRED / NOT PROVEN`.
7. Any docs/logs/commits contain secrets, real emails, JWTs, bearer tokens, Sentry DSN, database URL, FCM tokens, password hashes, or sensitive payloads.
8. API contract changes are found without updates to `server/doc/API_CONTRACTS_AND_DATA_MAP.md` and compatible app handling.

## Final recommendation

Proceed as **GO WITH RISKS** for the non-scanner ManaLoom release candidate on `master` at commit `784a44d`.

Do not market or claim physical scanner/camera/OCR readiness from this release gate. Treat `/ai/generate` latency as the highest-priority accepted risk: it is not blocking this release because the UI/runtime flow passed, but it requires P1 follow-up if the next release candidate or staging run repeats p95 above `10000 ms` or shows any timeout/non-200 behavior.
