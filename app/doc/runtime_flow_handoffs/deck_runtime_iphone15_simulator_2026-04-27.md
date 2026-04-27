# iPhone 15 Simulator Runtime Handoff

## Target

- iPhone 15 Simulator -> real app -> real local backend -> register -> create Commander deck -> details -> import commander -> optimize -> apply -> validate

## Runtime Owner

Agent: `Mobile Runtime Device QA`

## Status

Verdict: `Blocked in deck creation harness`

## Runtime Environment

Date: `2026-04-27`

Simulator:

- `iPhone 15`
- UDID: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`
- state: `Booted`

Backend:

- first attempt: existing local backend on `http://127.0.0.1:8081`
- second attempt: fresh backend started for this validation on `http://127.0.0.1:8082`
- health check on `8082`: `healthy`

Integration test used:

- `app/integration_test/deck_runtime_m2006_test.dart`

## Evidence

Fresh iPhone 15 Simulator execution happened in this session.

Commands:

```bash
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
curl -sS http://127.0.0.1:8082/health
cd app
flutter test integration_test/deck_runtime_m2006_test.dart \
  -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Log artifact:

- `/tmp/mtgia_iphone15_runtime_20260427.log`

## What Passed

- iPhone 15 Simulator discovery.
- iPhone 15 Simulator boot.
- iOS build completed.
- App launched.
- `API_BASE_URL` resolved to localhost backend.
- `/login` rendered.
- Register flow started.
- Navigation reached `/decks`.
- Backend health was real and healthy.

## Blockers Found

### Fixed in this round

- `POST /import/to-deck` returned `400` when the list used `1x Talrand, Sky Summoner [Commander]`.
- Root cause: backend parser detected `[Commander]`, but kept the marker in the card name, so lookup tried to resolve `Talrand, Sky Summoner [Commander]`.
- Fix: `server/lib/import_list_service.dart` now strips `[Commander]`, `[cmdr]`, `*CMDR*` and `!commander` from parsed card names.

### Still open

- The integration harness failed at `app/integration_test/deck_runtime_m2006_test.dart:190`.
- Error: `Bad state: No element`.
- Cause observed: test searches specifically for `find.widgetWithText(ElevatedButton, 'Novo Deck')`.
- On live iPhone 15 runtime, the screen reached `Meus Decks`, but the test did not robustly wait for the actionable create-deck control and does not handle the non-empty-list FAB/menu path.

## Next Action

Update the integration harness for iPhone 15 Simulator:

- rename or replace the M2006-specific test with `deck_runtime_iphone15_simulator_test.dart`;
- wait for `find.text('Novo Deck')` after deck list load instead of assuming `ElevatedButton`;
- support both empty-state `ElevatedButton` and non-empty-list `FloatingActionButton`/popup path;
- keep backend URL as `http://127.0.0.1:<port>` for simulator;
- rerun the same command until the flow reaches optimize/apply/validate.
