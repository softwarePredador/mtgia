# ManaLoom Release Go/No-Go Checklist - 2026-05-04

## 2026-05-06 consolidation after AI Generate async, Optimize Intensity and Aggressive Candidate Quality

ManaLoom is **READY WITH RISKS** for the non-scanner internal/TestFlight candidate on `master` at `b6f8a1c144f76a6f9ed6b4b34595249bfcaad3e6`, after consolidating the context commits:

| Area | Context commit | Final release status |
|---|---|---|
| AI Generate v2 backend | `b1567dd` | PASS WITH MONITORED RISK. Sync remains backward-compatible; async job path is the preferred internal UX. |
| AI Generate async mobile | `9fd17f1` | PASS. App sends async by default, polls jobs and preserves sync fallback for legacy/unsupported responses. |
| Optimize Intensity mobile | `5cac310` | PASS. App sends `light/focused/aggressive/rebuild` intent and handles explicit repair/rebuild outcomes. |
| Aggressive async/performance | `2a861a6` | PASS WITH WATCH. Aggressive optimize uses async path and bounded polling instead of blocking UI. |
| Candidate quality backend | `b007e99` | PASS WITH RISKS. Candidate recall uses role/tag/meta signals as advisory input; legality, color identity, bracket and final gate remain authoritative. |
| No-op diagnostics UI | `b6875ec` | PASS. UI explains safe no-op/quality rejected outcomes from aggregate diagnostics, not raw payloads. |
| Runtime diagnostics proof | `b6f8a1c` | PASS WITH RISKS. iPhone 15 Simulator proof exists for aggressive no-op diagnostics; low-candidate-coverage line remains NOT PROVEN in that live run. |

Final focused sanity on 2026-05-06:

| Area | Command | Result |
|---|---|---|
| Branch sync | `git pull --ff-only origin master` | PASS: already up to date. |
| Backend analyze | `cd server && dart analyze lib routes test` | PASS: no issues. |
| Backend focused tests without backend | `cd server && dart test test/ai_generate_create_optimize_flow_test.dart test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/candidate_quality_data_support_test.dart -r expanded` | Expected setup failure: live tests hit `127.0.0.1:8082` before backend was started; offline tests continued passing. Not classified as product blocker. |
| Backend health | `cd server && PORT=8082 dart run .dart_frog/server.dart` + `curl -fsS http://127.0.0.1:8082/health` | PASS: `healthy`. |
| Backend focused tests with backend | `cd server && dart analyze lib routes test && dart test test/ai_generate_create_optimize_flow_test.dart test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/candidate_quality_data_support_test.dart -r expanded` | PASS: `02:50 +49 ~1`, expected skip for the full stress matrix. |
| Commander-only dry-run default URL | `cd server && dart run bin/run_commander_only_optimization_validation.dart --dry-run` | Expected setup failure: script defaulted to `8080`; rerun used `TEST_API_BASE_URL`. |
| Commander-only dry-run on 8082 | `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/run_commander_only_optimization_validation.dart --dry-run` | PASS: 19 candidates would be validated; no auth/deck/optimize/bulk-save/validate mutation executed. |
| App deck contract | `cd app && flutter analyze lib/features/decks test/features/decks --no-version-check && flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check` | PASS: no analyze issues, `+50`. |
| Backend cleanup | Stop PID `28521`; `lsof -nP -iTCP:8082 -sTCP:LISTEN` | PASS: no listener on `8082`. |

Current release interpretation:

| Topic | Status | Release note |
|---|---|---|
| Overall verdict | **READY WITH RISKS** | Suitable for internal/TestFlight non-scanner scope, not broad production approval. |
| Scanner physical camera/OCR | **DEFERRED / NOT PROVEN** | Outside this release gate. Becomes NO-GO if marketed or required. |
| AI Generate async | PASS WITH WATCH | Async accepted path is the product-safe UX; sync remains compatible but latency stays monitored. |
| Optimize intensity | PASS | Omitted intensity remains compatible; explicit intensities are additive and app-consumable. |
| Aggressive candidate quality | PASS WITH RISKS | More candidate recall is advisory and still reduced/rejected by quality gate when unsafe. |
| Diagnostics UI | PASS WITH RISKS | Safe no-op/quality rejected state is clear to users; live low-coverage diagnostic line was not proven in the last runtime and stays covered by widget/parser tests. |
| API contract docs | CURRENT | `server/doc/API_CONTRACTS_AND_DATA_MAP.md` already documents generate async, optimize intensity, aggressive diagnostics and no-op handling; no response-shape change was made in this consolidation. |
| Secrets/log hygiene | PASS | Release docs record commands, statuses and timings only; no JWT, tokens, DSN, database URL, prompts completos or sensitive payloads were added. |

Accepted risks remain: external AI and DB validation latency, generated-deck fallback quality variance, aggressive safe no-op/low coverage on weak candidate pools, Firebase Performance not proven in integration runtime, and scanner physical proof deferred.

## 2026-05-05 refresh after AI Generate v2 async path

ManaLoom remains **READY WITH RISKS** for the internal/TestFlight candidate scope, with `/ai/generate` improved to **PASS WITH RISKS** through an opt-in async path. The sync API remains preserved for the current app.

Fresh backend evidence on `http://127.0.0.1:8082`:

| Area | Result |
|---|---|
| Sync `/ai/generate` cold after v2 | `200x10`, p50 `10033ms`, p95/p99 `11212ms` |
| Sync `/ai/generate` cache hit | `200x10`, p50 `2ms`, p95/p99 `7ms` |
| Async `/ai/generate` accepted response | `202x10`, accepted p50 `558ms`, p95/p99 `562ms` |
| Async completion | `completedx10`; internal completion proof `12089ms`; observed polling p95 `15620ms` including poll interval/middleware |
| Live create/validate/optimize | PASS: `TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_generate_create_optimize_flow_test.dart --tags live -r expanded` -> `01:41 +2` |

Release interpretation: sync p95 is still above the desired `<10000ms`, so broad rollout remains watchlisted. The accepted internal/TestFlight path is the async/progress-capable contract: `POST /ai/generate` with async opt-in returns `202` below 1s p95 and clients poll `/ai/generate/jobs/:id` for the same result body as sync.

## 2026-05-05 refresh after `/ai/generate` latency patch

ManaLoom is **READY WITH RISKS** for the internal/TestFlight candidate scope validated from `master` base commit `40fe6ab` plus the release-checklist quality-gate fix in this update.

The short sanity run used real backend `http://127.0.0.1:8082` and iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` (`com.apple.CoreSimulator.SimRuntime.iOS-17-4`). `POST /ai/generate` is no longer a blocker for internal release: the accepted measurement is p95/p99 `13005ms` with cache hit `3ms`, downgraded to a monitored AI-external-dependency risk. Scanner physical camera/OCR remains **DEFERRED / NOT PROVEN** and outside this release gate.

Short sanity evidence:

| Area | Command | Result |
|---|---|---|
| Backend health | `curl -sS http://127.0.0.1:8082/health` | PASS: `healthy` |
| Backend focused live | `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_generate_create_optimize_flow_test.dart --tags live -r expanded` | PASS after quality-gate fix: `01:59 +2` |
| App deck sanity | `cd app && flutter analyze lib/features/decks test/features/decks --no-version-check && flutter test test/features/decks --no-version-check` | PASS: analyze no issues, tests `00:09 +135` |
| iPhone 15 deck runtime | `cd app && flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check` | PASS: `01:16 +1`, final marker `10_complete_validated` |

Runtime contract visibility: register/login, generate/create, deck detail, optimize async job, preview, bulk apply and validate completed against the real local backend without Flutter exception, RenderFlex overflow, socket/timeout failure, or residual runtime `4xx/5xx` in the captured log. The run did show expected slow-request breadcrumbs for `/ai/optimize` (`202`, `5040ms`) and bulk apply (`200`, `5393ms`), both successful and monitored.

The first backend focused sanity attempt exposed a real quality-contract inconsistency: `/ai/optimize` could return 200 with `verdict=aprovado` but `validation_score=68`. This update tightens the final optimize gate so score `<70` is rejected/retried instead of returned as success; `optimization_quality_gate_test.dart` now covers the case.

## Executive summary

ManaLoom is **READY WITH RISKS** for the internal/TestFlight release scope validated on `master` base commit `40fe6ab` plus the quality-gate fix documented in the 2026-05-05 refresh.

The final regression and pre-release QA proved the core app/backend flows on iPhone 15 Simulator `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF` with iOS runtime `com.apple.CoreSimulator.SimRuntime.iOS-17-4`, using a real local backend at `http://127.0.0.1:8082`. Scanner physical camera/OCR remains **DEFERRED / NOT PROVEN** and is **not a blocker** only if this release does not depend on scanner physical proof.

## Current verdict

| Field | Value |
|---|---|
| Verdict | **READY WITH RISKS** |
| Target branch | `master` |
| Evidence commit | `40fe6ab` plus this refresh commit |
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
| AI Generate | PASS WITH MONITORED RISK | Visual/runtime flow reached generate preview; focused performance report after commit `40fe6ab` measured `/ai/generate` `200x5`. | p95/p99 `13005 ms`, cache hit `3 ms`. No longer a release blocker for internal/TestFlight; monitor because external OpenAI/fallback quality and DB validation latency remain variable. |
| AI Optimize | PASS WITH ACCEPTED RISK | Deck runtime used `/ai/archetypes`, `/ai/optimize`, job polling and bulk apply, then validated final deck. | `/ai/optimize` passed runtime on iPhone 15. Gate now blocks/retries score `<70` even when validator text says `aprovado`, preventing success-shaped low-quality optimize responses. |
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
| `/ai/generate` latency | p50 `10433 ms`, p95/p99 `13005 ms` over 5 post-patch local/staging samples; cache hit `3 ms`. | Monitored accepted risk for internal/TestFlight. | P1 if p95 exceeds `15000 ms`, any user-facing timeout/non-200 occurs, fallback quality is unacceptable, or broad rollout requires tighter SLA. Target: p95 <= `8000 ms` before broad rollout. |
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
| `/ai/generate` p95 reduction | MONITORED | Current p95/p99 `13005ms` is below the sprint `<15000ms` target; continue async/progress and DB validation optimization before broad rollout. |
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
| `POST /ai/generate` sync v2 | 11212 ms | <= 15000 ms for internal/TestFlight; desired <= 10000 ms before broad rollout | PASS WITH MONITORED RISK |
| `POST /ai/generate` async accepted v2 | 562 ms | <= 1000 ms | PASS |
| `GET /ai/generate/jobs/:id` async completion v2 | internal `12089 ms`; observed polling p95 `15620 ms` | internal <= 15000 ms; optimize poll endpoint separately if observed p95 must include polling overhead | PASS WITH WATCH |
| `POST /ai/optimize` | 4825 ms | <= 6000 ms | ACCEPTED RISK |
| `GET /ai/optimize/jobs/:id` | 1199 ms | <= 2000 ms | PASS WITH WATCH |

## Rollback plan

1. Stop rollout if final validation finds a new blocker, secret exposure, crash, timeout, or residual runtime 4xx/5xx.
2. Preserve the failing logs locally, sanitize them, and attach only non-sensitive excerpts to the incident handoff.
3. Revert to the last known good app/backend release artifact or previous deployed backend revision; do not roll forward with unproven scanner changes.
4. If backend-only regression appears, disable or revert the backend deployment first while keeping the mobile build unchanged when contract compatibility allows it.
5. If app-only regression appears, hold the app release and keep backend on the last validated compatible revision.
6. Re-run the required pre-release commands and affected iPhone 15 runtime tests before changing the verdict back to READY WITH RISKS.

## Go criteria

The release remains READY WITH RISKS when all criteria below are true:

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
3. `/ai/generate` p95 exceeds `15000 ms` in final local QA, any user-facing timeout/non-200 occurs, or generate fails to show a preview.
4. `/ai/optimize` does not reach preview/apply/validate, job creation p95 exceeds `6000 ms`, or polling p95 exceeds `2000 ms`.
5. `/trades/:id` p95 exceeds `2000 ms` or trade detail fails to load.
6. Scanner physical proof becomes release-critical while still `DEFERRED / NOT PROVEN`.
7. Any docs/logs/commits contain secrets, real emails, JWTs, bearer tokens, Sentry DSN, database URL, FCM tokens, password hashes, or sensitive payloads.
8. API contract changes are found without updates to `server/doc/API_CONTRACTS_AND_DATA_MAP.md` and compatible app handling.

## Final recommendation

Proceed as **READY WITH RISKS** for the non-scanner ManaLoom internal/TestFlight release candidate.

Do not market or claim physical scanner/camera/OCR readiness from this release gate. Treat `/ai/generate` latency as a monitored accepted risk: it is not blocking this internal release because the UI/runtime flow passed and post-patch p95/p99 is below `15000ms`, but it remains dependent on external AI, fallback quality and remote DB validation latency.
