# Deck runtime iPhone 15 Simulator — 2026-05-04

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
