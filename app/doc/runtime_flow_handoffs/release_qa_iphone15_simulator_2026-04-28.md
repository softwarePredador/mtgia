# Release QA iPhone 15 Simulator - 2026-04-28

## Verdict

- Overall release QA result: `PASS with scanner not proven`
- Runtime target: `iPhone 15 Simulator`
- Backend: real local Dart Frog server at `http://127.0.0.1:8082`
- Date/time: `2026-04-28 16:02:37 -0300`

## Device and backend

- `flutter devices` primary target:
  - `iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)`
- `xcrun simctl list devices available`:
  - `iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)`
- Backend health:
  - URL: `http://127.0.0.1:8082/health`
  - Result: `{"status":"healthy","service":"mtgia-server","timestamp":"2026-04-28T16:02:37.812031","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}`
- Backend process used for final runs:
  - `PID 72889`
  - started with `nohup env PORT=8082 dart run .dart_frog/server.dart`

## Git status before testing

- Initial `git status --short`: clean output.
- Changes made during QA:
  - `app/integration_test/sets_search_catalog_runtime_test.dart`
  - `app/integration_test/collection_entrypoints_runtime_test.dart`
  - this handoff
  - `server/manual-de-instrucao.md`

## Commands executed

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
```

```bash
cd server
nohup env PORT=8082 dart run .dart_frog/server.dart >/tmp/mtgia_backend_8082.log 2>&1 &
curl -fsS http://127.0.0.1:8082/health
```

```bash
cd app
flutter analyze lib test integration_test --no-version-check
flutter test test/features/cards test/features/collection test/features/decks --no-version-check
```

```bash
cd app
flutter test integration_test/sets_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
flutter test integration_test/sets_search_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
flutter test integration_test/collection_entrypoints_runtime_test.dart \
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

## Results by flow

| Flow | Result | Evidence |
|---|---:|---|
| Auth register/login equivalent | PASS | `deck_runtime_m2006_test.dart` registered `iphone15_<timestamp>@example.com`, reached authenticated shell, and loaded decks from real backend. |
| Search -> Cartas | PASS | `sets_search_catalog_runtime_test.dart` searched `Black Lotus` through `GET /cards?name=Black+Lotus&limit=50&page=1 -> 200`. |
| Card detail by image | PASS | Runtime harness taps `CachedCardImage`, opens `CardDetailScreen`, then returns to search. |
| Card text tap does not open detail | PASS | Runtime harness taps `Black Lotus` text and asserts `CardDetailScreen` is still absent. |
| Search -> Colecoes / ECC | PASS | `GET /sets?limit=50&page=1&q=ECC -> 200`; opened `Lorwyn Eclipsed Commander`; `GET /cards?set=ECC&limit=100&page=1&dedupe=true -> 200`; back navigation passed. |
| Colecao -> Colecoes / Marvel | PASS | `sets_catalog_runtime_test.dart` searched `Marvel`, opened `Marvel Super Heroes`, and called `GET /cards?set=MSH&limit=100&page=1&dedupe=true -> 200`. |
| Future/partial set OM2 | PASS | `sets_catalog_runtime_test.dart` searched `OM2`, opened `Through the Omenpaths 2`, and called `GET /cards?set=OM2&limit=100&page=1&dedupe=true -> 200`; UI accepted the future/partial state. |
| Collection / Binder | PASS | `collection_entrypoints_runtime_test.dart` opened `Colecao`, `Fichario`, `Tenho`; unauthenticated `/binder` and `/binder/stats` returned expected `401` without crash. |
| Collection / Marketplace | PASS | Runtime harness opened Marketplace and called `GET /community/marketplace?page=1&limit=20 -> 200`. |
| Collection / Trades | PASS | Runtime harness opened Trades and called `GET /trades?page=1&limit=20&role=receiver&status=pending -> 401` without crash; `Recebidas`, `Enviadas`, `Finalizadas` rendered. |
| Deck create/import Commander | PASS | `deck_runtime_m2006_test.dart` created Commander deck, imported `Talrand, Sky Summoner`, and reopened details from real backend. |
| Deck optimize/preview/apply/validate | PASS | `POST /ai/archetypes -> 200`, `POST /ai/optimize -> 202`, job polling `GET /ai/optimize/jobs/... -> 200`, preview rendered, `POST /decks/<id>/cards/bulk -> 200`, final UI showed completion/validity. |
| Explainability/meta refs compatibility | PASS | Optimize sheet and preview consumed the live optimize payload without UI crash while selecting cEDH bracket. |
| Scanner | NOT PROVEN | `CardScannerScreen` depends on `permission_handler`, `camera.availableCameras()`, camera stream, and MLKit OCR. No simulator proof was run because this needs camera/runtime support beyond the current harness. |

## Final command results

- `flutter analyze lib test integration_test --no-version-check`: PASS, no issues.
- `flutter test test/features/cards test/features/collection test/features/decks --no-version-check`: PASS.
- Final iPhone 15 integration status:
  - `sets_catalog_runtime_test.dart`: PASS, `STATUS=0`, `18:51:20Z -> 18:54:21Z`.
  - `collection_entrypoints_runtime_test.dart`: PASS, `STATUS=0`, `18:56:26Z -> 18:58:13Z`.
  - `deck_runtime_m2006_test.dart`: PASS, `STATUS=0`, `18:58:13Z -> 19:00:23Z`.
  - `sets_search_catalog_runtime_test.dart`: PASS after harness pop fix; final focused rerun passed with `All tests passed!`.

## Logs and screenshots

Local proof folder:

- `app/doc/runtime_flow_proofs_2026-04-28_iphone15_simulator_release/`

Important log files:

- `flutter_analyze_after_search_pop_fix.log`
- `flutter_test_features_after_harness_updates.log`
- `sets_catalog_runtime_test_iphone15_final_after_harness_updates.log`
- `sets_search_catalog_runtime_test_iphone15_after_pop_fix.log`
- `collection_entrypoints_runtime_test_iphone15_final_after_harness_updates.log`
- `deck_runtime_m2006_test_iphone15_final_after_harness_updates.log`

Screenshots extracted from the deck runtime log:

- `01_login.png`
- `02_registered_home.png`
- `03_decks.png`
- `04_deck_created.png`
- `05_empty_deck_details.png`
- `06_import_commander.png`
- `07_commander_imported.png`
- `08_optimize_sheet.png`
- `08b_optimize_sheet_cedh.png`
- `09_preview.png`
- `10_complete_validated.png`

The proof folder is intentionally ignored by `.gitignore` via `app/doc/*proofs*/`; the handoff records paths instead of forcing large generated artifacts into git.

## Warnings observed

- iOS simulator build warning for Apple Silicon iOS 26+ arm64 support:
  - `GoogleMLKit`
  - `MLImage`
  - `MLKitCommon`
  - `MLKitVision`
- Firebase Performance warning in isolated tests:
  - `[core/no-app] No Firebase App '[DEFAULT]' has been created - call Firebase.initializeApp()`
- Slow requests observed but non-blocking:
  - `GET /sets?limit=50&page=1` around `2522ms`
  - `POST /ai/archetypes` around `8855ms`
  - `POST /ai/optimize` around `5846ms`

## Bugs fixed during QA

- Expanded `sets_search_catalog_runtime_test.dart` to prove live Search -> Cartas behavior:
  - text tap does not open card detail;
  - image tap opens `CardDetailScreen`;
  - Material route is closed via `Navigator.pop()` instead of `tester.pageBack()`.
- Expanded `collection_entrypoints_runtime_test.dart` to prove Marketplace and Trades entry points in addition to Fichario and Colecoes.
- Operational correction: first backend attempt was started as a non-persistent shell background process and produced simulator `Connection refused`; final runs used persistent `nohup` backend on `8082`.

## Pending / not proven

- Scanner camera/OCR runtime on simulator remains `not proven`.
- Auth logout/login was not separately exercised; release auth coverage is register -> authenticated shell -> backend JWT calls through the deck runtime.
- Proof logs and screenshots are local ignored artifacts; preserve the proof folder if this machine-level evidence is needed later.
