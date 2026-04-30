# Deck runtime iPhone 15 Simulator — 2026-04-30

## Atualizacao — Deck Detail Validate Meta Intelligence runtime

### Resultado

- Verdict: `PASS`
- Date/time: `2026-04-30T17:24-03:00`
- Task: Sprint Deck Detail + Validate Deck + Meta Intelligence UI.
- Runtime target: iPhone 15 Simulator.
- Backend used by app: `http://127.0.0.1:8082` via `API_BASE_URL` and `PUBLIC_API_BASE_URL`.
- Test target: `app/integration_test/deck_runtime_m2006_test.dart`.

### Backend health

Command:

```bash
curl -s http://127.0.0.1:8082/health
```

Result:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-04-30T17:23:28.284841","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

### Commands executed

```bash
cd app
flutter analyze lib/features/decks lib/features/cards test/features/decks test/features/cards --no-version-check
```

Result: `PASS`, no issues.

```bash
cd app
flutter test test/features/decks test/features/cards --no-version-check
```

Result: `PASS`, `00:17 +137: All tests passed!`.

```bash
cd server
dart analyze routes/decks routes/ai lib/ai lib/meta test
dart test -r expanded
```

Result: analyze `PASS`; tests `PASS`, `00:04 +556: All tests passed!`.

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
TEST_API_BASE_URL=http://127.0.0.1:8082 dart run bin/run_commander_only_optimization_validation.dart --dry-run
```

Result: backend temporary process served health and runtime traffic; dry-run `PASS` with 19 candidates.

```bash
cd app
flutter test integration_test/deck_runtime_m2006_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Result: `PASS`, `01:13 +1: All tests passed!`.

### What was proven

UI/runtime real on iPhone 15 Simulator against live local backend:

- register and authenticated navigation worked;
- Commander deck was created and opened in Deck Detail;
- commander import added `Talrand, Sky Summoner`;
- Optimize sheet rendered a visible strategy action after `/ai/archetypes -> 200`;
- complete mode used async optimize job: `POST /ai/optimize -> 202`, then 4 successful job polls;
- preview opened before apply;
- bulk/apply persisted deck changes;
- final validation path reached screenshot `10_complete_validated`.

Captured backend contract visibility:

- `POST /auth/register -> 201 (2600ms)`;
- `POST /import/to-deck -> 200 (5268ms)`;
- `POST /ai/archetypes -> 200 (8591ms)`;
- `POST /ai/optimize -> 202 (5502ms)`;
- `GET /ai/optimize/jobs/<id> -> 200` x4;
- `POST /decks/<id>/cards/bulk -> 200 (4944ms)`;
- `POST /decks/<id>/validate` reached during final validation.

### What was real vs mocked

- Real: iPhone 15 Simulator UI, Flutter integration harness, local Dart Frog backend on `127.0.0.1:8082`, PostgreSQL-backed auth/decks/import/AI/validate flow, screenshot capture.
- Mocked: no API/provider mocks in the runtime path.
- Not touched: Life Counter/Lotus, Scanner camera/OCR, FCM, secrets, release build and official MTG assets.

### Evidence paths

- Proof folder: `app/doc/runtime_flow_proofs_2026-04-30_deck_meta_validate/`
- Backend health: `backend_health_8082.json`
- Runtime log: `deck_runtime_m2006_iphone15.log` (screenshot chunks omitted)
- Validation tails: `app_validation_tail.log`, `server_validation_tail.log`

### Blockers and next actions

- No crash, overflow, timeout, user-facing raw error, 4xx or 5xx remained in the passing runtime.
- Expected local warning remains: several pods do not support `arm64` simulator for Apple Silicon iOS 26+; this iPhone 15 run still built and passed.
- Backend 8082 was stopped after validation.

## Atualizacao — Life Counter/Lotus visual runtime proof

### Resultado

- Verdict: `PASS`
- Date/time: `2026-04-30T15:30-03:00`
- Task: Sprint Life Counter/Lotus visual/runtime proof.
- Runtime target: iPhone 15 Simulator.
- Concrete simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.
- Backend used by app: `http://127.0.0.1:8081` via `API_BASE_URL` and `PUBLIC_API_BASE_URL`.
- Test target: `app/integration_test/life_counter_lotus_visual_runtime_proof_test.dart`.

### Device discovery

`flutter devices` summary:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` summary:

```text
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

### Backend health

Command:

```bash
curl -sS http://127.0.0.1:8081/health
```

Result:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-04-30T15:30:13.333370","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

### Commands executed

```bash
cd app
flutter analyze lib/features/home test/features/home integration_test --no-version-check
```

Result: `PASS`, no issues.

```bash
cd app
flutter test test/features/home --no-version-check
```

Result: `PASS`, exit code `0`.

```bash
cd server
PORT=8081 dart run .dart_frog/server.dart
```

Result: backend temporary process served health while the simulator proof ran.

```bash
cd app
flutter test integration_test/life_counter_lotus_visual_runtime_proof_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 \
  --reporter expanded \
  --no-version-check
```

Result: `PASS`, `00:31 +1: All tests passed!`.

### What was proven

UI/runtime real on iPhone 15 Simulator:

- `LotusLifeCounterScreen` opened the embedded Lotus WebView bundle;
- 4 player cards rendered with 4 `.player-life-count` surfaces;
- 4 `.increase-button.life` and 4 `.decrease-button.life` controls were present;
- player one and player two started at 40 life from the canonical ManaLoom session;
- the first player life number had high-contrast color `rgba(245, 247, 252, 0.96)`, text shadow, and a large rendered box (`135.58 x 75.06`);
- no horizontal overflow and no `Life counter unavailable` WebView error were detected;
- `+1` changed player one from `40` to `41`;
- `-1` changed player one from `41` to `40`;
- final `+1` persisted player one at `41`;
- closing and reopening the screen restored player one at `41` from persisted state.

### What was real vs mocked

- Real: iPhone 15 Simulator UI, Flutter integration harness, WKWebView-backed Lotus bundle, ManaLoom canonical local stores, screenshot capture, local Dart Frog backend health on `127.0.0.1:8081`.
- Mocked: no API/provider mocks in the runtime path.
- Backend contract visibility: Life Counter/Lotus did not call app JSON APIs in this proof; backend participation was limited to required local health and app base URL configuration.
- Not touched: core Lotus migration, meta pipeline, backend IA, marketplace/trades, scanner/OCR, secrets and JSON contracts.

### Evidence paths

- Proof folder: `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_life_counter_lotus/`
- Runtime log: `life_counter_lotus_visual_runtime_test.log` (sanitized; screenshot base64 omitted)
- Screenshots:
  - `life_counter_lotus_runtime_initial.png`
  - `life_counter_lotus_runtime_after_plus.png`

### Blockers and next actions

- No crash, timeout, overflow, or WebView error remained in the passing run.
- Expected local warning remains: several pods do not support `arm64` simulator for Apple Silicon iOS 26+; this iPhone 15 iOS 17.4 run succeeded.
- Smallest P2/P3 next actions: PT-BR copy pass for Lotus overlays, optional profiling for blur/CSS jank, and product decision on how distinct the Life Counter visual language may remain from the main ManaLoom shell.

## Atualizacao — Visual P1 fora de Trades / Search-Sets runtime

### Resultado

- Verdict: `PASS`
- Date/time: `2026-04-30T14:58-03:00`
- Task: Sprint visual P1 fora de Trades para Home, Decks, IA, Binder, Marketplace, Search/Cards e Sets/Colecoes.
- Runtime target: iPhone 15 Simulator.
- Concrete simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.
- Backend used by app: `http://127.0.0.1:8082`.
- Test target: `app/integration_test/sets_search_catalog_runtime_test.dart`.

### Device discovery

`flutter devices` summary:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` summary:

```text
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

### Backend health

Command:

```bash
curl -sS --max-time 5 http://127.0.0.1:8082/health
```

Result:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-04-30T14:57:19.223536","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

### Commands executed

```bash
cd app
flutter analyze lib/features/home lib/features/decks lib/features/cards lib/features/collection lib/features/binder lib/features/market lib/core test --no-version-check
```

Result: `PASS`, no issues.

```bash
cd app
flutter test test/features/home test/features/decks test/features/cards test/features/collection test/features/binder test/features/market test/core --no-version-check
```

Result: `PASS`, `00:23 +463: All tests passed!`.

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
```

Result: backend temporary process served health and runtime traffic.

```bash
cd app
flutter test integration_test/sets_search_catalog_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Result: `PASS`, `00:18 +1: All tests passed!`.

### What was proven

UI/runtime real on iPhone 15 Simulator against live local backend:

- Search/Cards opened and searched `Black Lotus`;
- Colecoes tab opened from Search;
- sets catalog loaded from `/sets`;
- search by set code `ECC` returned a collection;
- set detail opened and loaded cards from `/cards?set=ECC`.

Captured backend contract visibility:

- `GET /cards?name=Black+Lotus&limit=50&page=1 -> 200 (1335ms)`;
- `GET /sets?limit=50&page=1 -> 200 (869ms)`;
- `GET /sets?limit=50&page=1&q=ECC -> 200 (626ms)`;
- `GET /cards?set=ECC&limit=100&page=1&dedupe=true -> 200 (1597ms)`.

### What was real vs mocked

- Real: iPhone 15 Simulator UI, Flutter integration harness, local Dart Frog backend on `127.0.0.1:8082`, PostgreSQL-backed `/cards` and `/sets` API contracts.
- Mocked: no API/provider mocks in this runtime path.
- Not proven in this run: full register/generate/optimize/apply/validate on simulator, Home/Deck/Binder/Marketplace screenshots, APNS/FCM, Scanner camera and Life Counter/Lotus.

### Evidence paths

- Proof folder: `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_visual_p1/`
- Device discovery: `flutter_devices.log`, `simctl_devices.log`
- Backend health: `backend_health.json`
- Runtime log: `sets_search_catalog_runtime.log`
- Screenshots: not captured in this run.

### Blockers and next actions

- No crash, overflow, timeout or 4xx/5xx remained in the passing runtime.
- Expected local warning remains: several pods do not support arm64 simulator for Apple Silicon iOS 26+; this iPhone 15 iOS 17.4 run succeeded.
- Backend 8082 was stopped after validation.
- Smallest P2/P3 next actions: screenshots for Home/Deck Detail/Generate/Optimize/Binder/Marketplace, product decision for Search global and Meta Deck Intelligence surface, and separate Life Counter/Lotus/Scanner runtime proof.

## Resultado

- Verdict: `PASS`
- Date/time: `2026-04-30T14:33-03:00`
- Task: P1 UX trust / Social Trading after new review and confirmation dialogs.
- Runtime target: iPhone 15 Simulator.
- Backend used by app: `http://127.0.0.1:8082`.
- Test target: `app/integration_test/binder_marketplace_trade_runtime_test.dart`.

## Device discovery

`flutter devices` summary:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` summary:

```text
iPhone 15 Pro (F3C5B123-673F-4ACC-84B2-489957CB81C8) (Shutdown)
iPhone 15 Pro Max (DABB9D79-2FDB-4585-94DB-E31F1288EE74) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (6A3E5508-0190-48AC-B6D1-E4BA8A94FFD9) (Shutdown)
```

Concrete simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.

## Backend health

Command:

```bash
curl -sS --max-time 5 http://127.0.0.1:8082/health
```

Result:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-04-30T14:33:...","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

## Commands executed

```bash
cd app
flutter analyze integration_test/binder_marketplace_trade_runtime_test.dart --no-version-check
```

Result: `PASS`, no issues.

```bash
cd server
PORT=8082 dart run .dart_frog/server.dart
```

Result: backend temporary process served health and runtime traffic.

```bash
cd app
flutter test integration_test/binder_marketplace_trade_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Result: `PASS`, `01:44 +2: All tests passed!`.

Supporting focused validation:

```bash
cd app
flutter analyze lib/features/trades/screens/trade_detail_screen.dart integration_test/binder_marketplace_trade_runtime_test.dart --no-version-check
flutter test test/features/trades/screens/trade_confirmation_flow_test.dart --no-version-check
```

Result: `PASS`, `All tests passed!`.

## What was proven

UI/runtime real on iPhone 15 Simulator against live local backend:

- binder item create/edit/delete entry points;
- marketplace search;
- proposal review dialog `Revisar proposta`;
- trade creation via `POST /trades` (`201`);
- seller login and seller accept dialog `Aceitar trade?`;
- seller accept via `PUT /trades/:id/respond` (`200`);
- trade chat message creation and message count proof;
- seller shipment dialog `Confirmar envio`;
- seller ship via `PUT /trades/:id/status` to `shipped` (`200`);
- buyer confirm delivery dialog `Confirmar entrega?`;
- buyer delivery via `PUT /trades/:id/status` to `delivered` (`200`);
- buyer finalization dialog `Finalizar trade?`;
- buyer complete via `PUT /trades/:id/status` to `completed` (`200`);
- notifications list, notification read, read-all;
- direct messages conversation, send, read receipt, unread count.

The captured runtime included:

- `POST /auth/login 200`;
- `GET /cards/printings 200`;
- `POST /binder 201`;
- `PUT /binder/:id 200`;
- `DELETE /binder/:id 204`;
- `GET /community/marketplace 200`;
- `POST /trades 201`;
- `PUT /trades/:id/respond 200`;
- `POST /trades/:id/messages 201`;
- `PUT /trades/:id/status 200` for shipped/delivered/completed;
- `GET/PUT /notifications 200`;
- `GET/POST/PUT /conversations 200/201`.

## Fixes applied during this attempt

1. iOS Simulator build unblocked for the existing MLKit/MLImage dependency chain:
   - `google_mlkit_text_recognition -> MLKitVision -> MLImage 1.0.0-beta8`;
   - `MLImage.framework` contains `x86_64` and `arm64`, but the `arm64` slice is built for iOS device, not iOS Simulator;
   - `app/ios/Flutter/Debug.xcconfig`, `app/ios/Flutter/Release.xcconfig`, and `app/ios/Podfile` now exclude `arm64 i386` only for `iphonesimulator*`, forcing simulator builds to use `x86_64` and preserving iOS physical-device builds.
2. Harness label aligned with current shipment dialog:
   - expected `Confirmar envio`;
   - taps `ElevatedButton` with `Confirmar envio` instead of ambiguous title text.
3. Real runtime crash fixed:
   - `TradeDetailScreen` shipment dialog no longer disposes a `TextEditingController` while the dialog `TextField` is still being torn down;
   - controller ownership moved into a private stateful dialog widget.

Flutter still prints the Apple Silicon/iOS 26+ warning that pods do not support `arm64` simulator. In this environment, the iPhone 15 Simulator runtime is iOS 17.4 and the x86_64 simulator build runs successfully.

## Evidence paths

- Proof folder: `app/doc/runtime_flow_proofs_2026-04-30_iphone15_simulator_social_trading_ux_trust/`
- Device discovery: `flutter_devices.log`, `simctl_devices.log`
- Backend health: `backend_health.json`
- Analyze log: `flutter_analyze_binder_marketplace_trade_runtime.log`
- Runtime log: `iphone15_runtime_validation.log`
- Screenshots: not captured in this run.

## What was real vs mocked

- Real: iPhone 15 Simulator UI, Flutter integration harness, local Dart Frog backend on `127.0.0.1:8082`, PostgreSQL-backed API contracts, auth, binder, marketplace, trades, trade messages, notifications, direct messages.
- Mocked: no API/provider mocks in the runtime path.
- Not proven: APNS/FCM delivery on a real push device; simulator warning remains a technical debt for future Apple Silicon iOS 26+ simulator-only support.

## Observability and blockers

- Build blocker `MLImage.framework built for iOS linked into iOS-simulator` is resolved for this runtime by the simulator-only `x86_64` build guard.
- Runtime crash/assertion from disposed shipment `TextEditingController` is resolved.
- No unclassified crash, 4xx, 5xx, timeout, or overflow remained in the passing run.
- Expected local warning: Firebase Performance unavailable in integration context because Firebase default app is not initialized.
