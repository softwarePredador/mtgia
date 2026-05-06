# Release Consolidation After Optimize Upgrades - 2026-05-06

## Verdict

**READY WITH RISKS** for ManaLoom internal/TestFlight, limited to the validated non-scanner scope.

Scanner physical camera/OCR is **DEFERRED / NOT PROVEN** and must not be claimed by this release. If scanner becomes release-critical, the release becomes **BLOCKED** until a physical-device proof exists.

## Repository state

| Item | Value |
|---|---|
| Branch | `master` |
| HEAD inspected | `b6f8a1c144f76a6f9ed6b4b34595249bfcaad3e6` |
| Sync | `git pull --ff-only origin master` -> already up to date |
| Backend local URL used | `http://127.0.0.1:8082` |
| Backend final state | Stopped; `8082` had no listener after validation |

## Commits inspected

| Commit | Area | Release reading |
|---|---|---|
| `b1567dd` | AI Generate v2 backend | PASS WITH WATCH: async path and sync compatibility documented. |
| `9fd17f1` | Generate async app | PASS: mobile async-by-default with sync fallback. |
| `5cac310` | Optimize intensity mobile | PASS: intensity selector and app request path available. |
| `2a861a6` | Aggressive async/performance | PASS WITH WATCH: aggressive optimize can return async job and avoids blocking UI. |
| `b007e99` | Candidate quality backend | PASS WITH RISKS: candidate recall improved with advisory metadata before quality gate. |
| `b6875ec` | No-op diagnostics UI | PASS: safe no-op/quality rejected state is user-facing and sanitized. |
| `b6f8a1c` | Runtime diagnostics proof | PASS WITH RISKS: iPhone 15 Simulator proof exists; low-candidate-coverage live branch remains not proven. |

## Documents reviewed

- `server/doc/RELEASE_GO_NO_GO_CHECKLIST_2026-05-04.md`
- `server/doc/INTERNAL_RELEASE_STAGING_HANDOFF_2026-05-04.md`
- `server/doc/RELATORIO_AI_GENERATE_V2_PERFORMANCE_2026-05-05.md`
- `server/doc/RELATORIO_AGGRESSIVE_CANDIDATE_QUALITY_V2_2026-05-05.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`

`API_CONTRACTS_AND_DATA_MAP.md` already matches the consolidated response shapes for `/ai/generate`, `/ai/generate/jobs/:id`, `/ai/optimize`, `/ai/optimize/jobs/:id`, intensity metadata, aggressive diagnostics and rebuild-guided outcomes. No endpoint contract changed during this consolidation.

## Commands run

| Step | Command | Result |
|---|---|---|
| Branch/status | `git --no-pager status --short --branch && git --no-pager log --oneline -n 12` | PASS: on `master`, aligned with `origin/master`. |
| Sync | `git pull --ff-only origin master` | PASS: already up to date. |
| Backend sanity, first attempt | `cd server && dart analyze lib routes test && dart test test/ai_generate_create_optimize_flow_test.dart test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/candidate_quality_data_support_test.dart -r expanded` | Analyze PASS; live tests failed with connection refused because backend `8082` was not running. Classified as setup issue, not product blocker. |
| Backend start | `cd server && PORT=8082 dart run .dart_frog/server.dart` | PASS after detached start. `/health` returned `healthy`. |
| Backend sanity, live | `cd server && dart analyze lib routes test && dart test test/ai_generate_create_optimize_flow_test.dart test/ai_optimize_flow_test.dart test/optimization_quality_gate_test.dart test/optimization_pipeline_integration_test.dart test/candidate_quality_data_support_test.dart -r expanded` | PASS: `02:50 +49 ~1`; one expected stress-matrix skip. |
| Commander-only default URL | `cd server && dart run bin/run_commander_only_optimization_validation.dart --dry-run` | Expected setup failure: script defaulted to `8080`. |
| Commander-only on 8082 | `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/run_commander_only_optimization_validation.dart --dry-run` | PASS: 19 candidates would be validated; no auth/deck/optimize/bulk-save/validate mutation executed. |
| App decks contract | `cd app && flutter analyze lib/features/decks test/features/decks --no-version-check && flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart --no-version-check` | PASS: no analyze issues, `+50`. |
| Backend cleanup | Stop backend PID `28521`; `lsof -nP -iTCP:8082 -sTCP:LISTEN` | PASS: port free. |

## Final status matrix

| Area | Status | Evidence / risk |
|---|---|---|
| AI Generate async | PASS WITH WATCH | Backend/app docs and tests prove async job contract and sync fallback. Latency remains accepted risk. |
| Optimize Intensity | PASS | App/backend contract supports explicit intensity and omitted-intensity compatibility. Quality gate can reduce scope. |
| Aggressive async/performance | PASS WITH WATCH | Aggressive can route through async job; focused tests pass. Keep watching polling/stage latency. |
| Aggressive Candidate Quality | PASS WITH RISKS | Candidate pools use local DB legality/color filters, role/function/meta signals and final gate. More candidates do not imply forced swaps. |
| Diagnostics UI | PASS WITH RISKS | UI explains safe no-op/quality rejected aggregate diagnostics. Live low-candidate-coverage branch remains NOT PROVEN. |
| Commander legality/color identity | PASS | Focused backend tests, quality gate tests, pipeline tests and commander-only dry-run passed. |
| App preview/apply/validate contract | PASS | Focused app smoke proved optimize preview/apply/validate and needs-repair/rebuild-guided UI branch. |
| Sentry/logging hygiene | PASS WITH WATCH | Docs record observability status without DSN/secrets. App/backend breadcrumbs remain the minimum relied-on visibility. |
| Scanner physical camera/OCR | DEFERRED / NOT PROVEN | Explicitly out of scope. |

## Accepted risks

1. AI Generate still depends on external AI/fallback quality and DB validation latency; async/progress makes it acceptable for internal/TestFlight, not broad production.
2. Aggressive optimize may return fewer swaps, safe no-op, or quality-rejected diagnostics when safety gates block weak pools.
3. `low_candidate_coverage=true` was not exercised in the latest live iPhone 15 diagnostics run; keep widget/parser coverage and do not overclaim live proof.
4. Firebase Performance remains not proven in the integration runtime; backend/app breadcrumbs are the current fallback visibility.
5. TestFlight upload still requires secure signing/export configuration and non-local staging API URLs.

## Smallest next fixes

1. Run the signed internal build/upload proof with secure CI/local signing and real staging API URLs.
2. Add or re-run a targeted live case that exercises `low_candidate_coverage=true` in the aggressive no-op UI.
3. Continue reducing Generate validation/polling latency and keep async as the default mobile UX.
4. Keep scanner physical camera/OCR hidden/deferred until a separate physical-device handoff is produced.

## Final recommendation

Proceed as **READY WITH RISKS** for the internal/TestFlight non-scanner release candidate. Do not claim physical scanner/camera/OCR readiness from this consolidation.
