# Deck runtime iPhone 15 Simulator — 2026-05-04

## Atualizacao Generate async app default — 2026-05-05T10:42-03:00 a 2026-05-05T11:35-03:00

- Verdict: `PASS WITH RISKS`.
- Backend usado pelo app: `http://127.0.0.1:8082`.
- Concrete simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.
- Backend health: `healthy`.
- Backend final state: stopped after validation; port `8082` free.
- Scanner fisico/camera/OCR: `DEFERRED / NOT PROVEN`.

Device discovery summary:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
```

Backend health:

```json
{"status":"healthy","service":"mtgia-server","environment":"development","checks":{"process":{"status":"healthy"}}}
```

Commands executed:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"

cd server
PORT=8082 dart run .dart_frog/server.dart
curl -sS http://127.0.0.1:8082/health
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_generate_create_optimize_flow_test.dart --tags live -r expanded

cd app
flutter analyze lib/features/decks test/features/decks --no-version-check
flutter test test/features/decks --no-version-check
flutter test integration_test/deck_generate_async_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
flutter test integration_test/deck_runtime_m2006_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Results:

| Area | Resultado |
| --- | --- |
| App deck analyze | PASS: no issues |
| App deck tests | PASS: `+142` |
| Backend live generate/create/optimize | PASS: `01:45 +2` |
| Generate async iPhone 15 | PASS parcial: `202/job_id`, feedback UI `547ms`, polling completed `result_status=200`, save/detail/validate reais; optimize direto caiu em `422 needs_repair` e seguiu para rebuild. |
| Optimize/apply iPhone 15 | PASS no harness existente: `01:27 +1`, final `10_complete_validated`. |

What was real:

- Real iPhone 15 Simulator UI, real local Dart Frog backend, real auth/register, real `/ai/generate` async job, real polling, real generated deck save, real deck details, real validation, real optimize/apply runtime in the existing deck harness.

What was mocked:

- Nothing in the iPhone 15 runtime paths. Provider/widget tests use controlled `ApiClient` fakes only for unit/widget coverage.

Evidence paths:

- `app/doc/runtime_flow_proofs_2026-05-05_iphone15_simulator/device_discovery_async_generate.txt`
- `app/doc/runtime_flow_proofs_2026-05-05_iphone15_simulator/backend_health_8082_async_generate.json`
- `app/doc/runtime_flow_proofs_2026-05-05_iphone15_simulator/backend_ai_generate_create_optimize_flow_async.log`
- `app/doc/runtime_flow_proofs_2026-05-05_iphone15_simulator/app_decks_analyze_after_async_generate.log`
- `app/doc/runtime_flow_proofs_2026-05-05_iphone15_simulator/app_decks_tests_after_async_generate.log`
- `app/doc/runtime_flow_proofs_2026-05-05_iphone15_simulator/deck_generate_async_iphone15_2026-05-05_retry3.log`
- `app/doc/runtime_flow_proofs_2026-05-05_iphone15_simulator/deck_runtime_m2006_after_async_generate_iphone15.log`

Blockers / risks:

- `deck_generate_async_runtime_test.dart` proved Generate async UX and save/detail/validate, but direct optimize of that generated deck returned expected quality gate `422 needs_repair` and used rebuild instead of preview/apply suggestions. Owner: Commander Optimize flow/harness strategy selection. Smallest next action: prefer a strategy matching the generated deck theme or extend the harness to accept the rebuild-guided branch.
- No secrets, JWT, DSN, database URL, prompt payload, or sensitive payload were documented.

## Atualizacao TestFlight/internal sanity — 2026-05-05T09:24-03:00

- Verdict: `READY WITH RISKS` para release interno/TestFlight sem scanner fisico.
- Backend usado pelo app: `http://127.0.0.1:8082`.
- Concrete simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.
- `flutter devices`: iPhone 15 Simulator bootado; macOS/Chrome disponiveis; iPhone fisico wireless `Rafa` detectado mas `NOT PROVEN`.
- Backend health: `healthy`.
- Backend final state: stopped after validation; port `8082` free.
- Scanner fisico/camera/OCR: `DEFERRED / NOT PROVEN`; nenhum fluxo fisico de scanner foi executado.
- `/ai/generate`: p95/p99 pos-patch `13005ms`, cache hit `3ms`; risco rebaixado de blocker para monitorado por dependencia de IA externa/fallback.

Comandos executados:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"

cd server
PORT=8082 dart run .dart_frog/server.dart
curl -sS http://127.0.0.1:8082/health
TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/ai_generate_create_optimize_flow_test.dart --tags live -r expanded

cd app
flutter analyze lib/features/decks test/features/decks --no-version-check
flutter test test/features/decks --no-version-check
flutter test integration_test/deck_runtime_m2006_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Resultados:

| Area | Resultado |
| --- | --- |
| Backend focused live | PASS apos fix de gate: `01:59 +2` |
| App deck analyze | PASS: no issues |
| App deck tests | PASS: `00:09 +135` |
| Deck runtime iPhone 15 | PASS: `01:16 +1`, final `10_complete_validated` |

O fluxo real cobriu register/login, create/generate, deck detail, optimize async, preview, apply/bulk e validate contra backend local real. O log runtime nao teve Flutter exception, RenderFlex overflow, timeout/socket, `status=4xx`, `status=5xx` ou `Some tests failed`. Warnings observados foram slow-request breadcrumbs bem-sucedidos (`/ai/optimize` 202 em `5040ms`; bulk apply 200 em `5393ms`) e avisos ambientais de simulator/plugins.

Evidencias locais ignoradas por git: `app/doc/runtime_flow_proofs_2026-05-05_iphone15_simulator/` com `backend_health_8082.json`, `backend_ai_generate_create_optimize_flow.log`, `app_decks_analyze.log`, `app_decks_tests.log` e `deck_runtime_iphone15_2026-05-05.log`.

Blockers: nenhum para deck runtime. O primeiro backend sanity encontrou `/ai/optimize` 200 com `validation_score=68`; foi corrigido no gate final para score `<70` virar rejeicao/retry, e a sanity live passou em seguida.

## Atualizacao internal release/staging — 2026-05-04T17:14-03:00

- Verdict: `READY WITH RISKS for internal/staging only`.
- Backend usado pelo app: `http://127.0.0.1:8082`.
- Concrete simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.
- Backend health: `healthy`.
- Scanner fisico/camera/OCR: `DEFERRED / NOT PROVEN`; nenhum fluxo fisico de scanner foi executado.
- Runtimes iPhone 15 desta rodada: Sets catalog `00:17 +1`, Search/Sets `00:28 +1`, Deck generate/create/detail/optimize/apply/validate `01:38 +1`, Binder dashboard `00:43 +1`, Marketplace/Trades/Messages/Notifications `01:50 +2`, Life Counter/Lotus `00:28 +1`, visual non-scanner `01:02 +1`.
- Performance nova: `/ai/generate` `200x5` p95/p99 `44756ms` fora do risco aceito anterior; `/ai/optimize` `202x5` p95/p99 `5029ms` com jobs concluidos.
- Handoff completo: `server/doc/INTERNAL_RELEASE_STAGING_HANDOFF_2026-05-04.md`.
- Proof folder local ignorado: `app/doc/runtime_flow_proofs_2026-05-04_iphone15_simulator/`.

## Atualizacao pre-release — 2026-05-04T15:29-03:00

- Verdict: `PASS WITH RISKS` para QA pre-release sem scanner fisico.
- Backend usado pelo app: `http://127.0.0.1:8082`.
- Concrete simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.
- `flutter devices` tambem listou iPhone fisico `Rafa (wireless)`, mas ele ficou `NOT PROVEN` porque nao foi necessario para os fluxos sem scanner.
- Scanner fisico/camera/OCR: `DEFERRED / NOT PROVEN`.

Comandos adicionais executados contra iPhone 15 Simulator:

```bash
cd app
flutter test integration_test/sets_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/sets_search_catalog_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/deck_runtime_m2006_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/binder_dashboard_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/binder_marketplace_trade_runtime_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/life_counter_lotus_visual_runtime_proof_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
flutter test integration_test/app_full_non_life_counter_visual_capture_smoke_test.dart -d "iPhone 15" --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --reporter expanded --no-version-check
```

Resultados adicionais:

| Fluxo | Resultado |
| --- | --- |
| Search/Sets/Colecoes | PASS: sets catalog `00:32 +1`, search catalog `00:35 +1` |
| Deck create/detail/optimize/apply/validate | PASS: `01:38 +1`, final `10_complete_validated` |
| Binder dashboard | PASS: `00:59 +1` |
| Marketplace/Trades/Messages/Notifications | PASS: `01:51 +2` |
| Life Counter/Lotus | PASS no retry: `00:27 +1`; primeira tentativa falhou por build/DDS concorrente |
| Visual Home/Deck/IA/Collection/Profile | PASS apos patch do harness: `01:05 +1` |

Evidencias adicionais:

- Relatorio: `server/doc/RELATORIO_PRE_RELEASE_QA_2026-05-04.md`.
- Proof folder local ignorado: `app/doc/runtime_flow_proofs_2026-05-04_iphone15_simulator/`.
- Logs sanitizados: `iphone15_*runtime*.log`, `pre_release_endpoint_metrics*.log`.
- Screenshots extraidos: `03_home.png`, `04_decks.png`, `04b_deck_details.png`, `05_generate.png`, `06_generate_preview.png`, `08_optimize_sheet.png`, `09_preview.png`, `10_complete_validated.png`, `life_counter_lotus_runtime_initial.png`, `life_counter_lotus_runtime_after_plus.png`.

## Resultado

- Verdict: `PASS` para deck runtime no iPhone 15 Simulator contra backend local real.
- Date/time: `2026-05-04T13:38-03:00` a `2026-05-04T13:55-03:00`.
- Runtime target: iPhone 15 Simulator.
- Concrete simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.
- Backend used by app: `http://127.0.0.1:8082` via `API_BASE_URL` and `PUBLIC_API_BASE_URL`.
- Test target: `app/integration_test/deck_runtime_m2006_test.dart`.

## Device discovery

`flutter devices` summary:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
macOS (desktop) • macos • darwin-arm64
Chrome (web) • chrome • web-javascript
Rafa (wireless) (mobile) • 00008130-001C152922BA001C • ios • iOS 26.5 23F5043k
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` summary:

```text
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

## Backend health

Command:

```bash
curl -sS http://127.0.0.1:8082/health
```

Result:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-05-04T13:38:55.431347","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

## Exact command executed

```bash
cd app
flutter test integration_test/deck_runtime_m2006_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Result: `PASS`, `01:24 +1: All tests passed!`.

## What was proven

- Real iPhone 15 Simulator UI launched with the app pointing at `http://127.0.0.1:8082`.
- Real local Dart Frog backend served auth, decks, import, AI archetypes, optimize, bulk apply and validate.
- Runtime path reached screenshots:
  - `01_login`
  - `02_registered_home`
  - `03_decks`
  - `04_deck_created`
  - `05_empty_deck_details`
  - `06_import_commander`
  - `07_commander_imported`
  - `08_optimize_sheet`
  - `09_preview`
  - `10_complete_validated`
- Final deck state reached `10_complete_validated`.

## What was real vs mocked

- Real: iPhone 15 Simulator, Flutter integration harness, local backend on 8082, PostgreSQL-backed runtime contracts, screenshots, navigation, optimize preview/apply/validate.
- Mocked: nothing in this runtime path.
- Not proven here: physical scanner camera/OCR; it remains separate from the simulator deck proof.

## Evidence paths

- Proof folder: `app/doc/runtime_flow_proofs_2026-05-04_iphone15_simulator/` (local ignored runtime artifact folder).
- Device discovery: `device_discovery_summary.txt`.
- Backend health: `backend_health_8082.json`.
- Runtime log: `deck_runtime_m2006_iphone15.log` with screenshot chunks sanitized.
- Screenshots decoded from runtime chunks:
  - `01_login.png`
  - `02_registered_home.png`
  - `03_decks.png`
  - `04_deck_created.png`
  - `05_empty_deck_details.png`
  - `06_import_commander.png`
  - `07_commander_imported.png`
  - `08_optimize_sheet.png`
  - `09_preview.png`
  - `10_complete_validated.png`

## Backend contract visibility

No runtime 4xx/5xx, timeout, overflow or crash remained in the passing deck path. The app/runtime log includes the expected local warnings:

- Firebase Performance unavailable in the integration session because no default Firebase app is initialized.
- Xcode emitted simulator architecture warnings for plugin targets, but the build completed and the test passed.

## Blockers and smallest next actions

- Blockers: none for the deck runtime path.
- Scanner physical camera: `NOT PROVEN` in this round because no physical camera/OCR runtime was executed; simulator proof must not be treated as camera proof.
