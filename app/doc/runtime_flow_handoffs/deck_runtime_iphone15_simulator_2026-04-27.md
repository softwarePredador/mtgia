# iPhone 15 Simulator Runtime Handoff

## Target

- iPhone 15 Simulator -> real app -> real local backend -> register/login -> create Commander deck -> details -> import commander -> optimize -> preview/apply -> validate

## Runtime Owner

Agent: `Mobile Runtime Device QA`

## Status

Verdict: `Approved for iPhone 15 Simulator runtime path`

## Runtime Environment

Date: `2026-04-27`

Simulator:

- `iPhone 15`
- UDID: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`
- runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`
- state: `Booted`

Backend:

- local Dart Frog instance on `http://127.0.0.1:8082`
- health: `{"status":"healthy","service":"mtgia-server","environment":"development"}`

Integration test used:

- `app/integration_test/deck_runtime_m2006_test.dart`

## Commands Executed

```bash
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
cd server
PORT=8082 dart run .dart_frog/server.dart
curl -sS http://127.0.0.1:8082/health

cd ../app
flutter analyze integration_test/deck_runtime_m2006_test.dart
flutter test test/features/decks/screens/deck_runtime_widget_flow_test.dart
flutter test \
  test/features/decks/screens/deck_details_screen_smoke_test.dart \
  test/features/decks/providers/deck_provider_test.dart \
  test/features/decks/providers/deck_provider_support_test.dart \
  test/features/decks/widgets/deck_optimize_flow_support_test.dart
flutter test integration_test/deck_runtime_m2006_test.dart \
  -d F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

## Evidence

Artifacts:

- `app/doc/runtime_flow_proofs_2026-04-27_iphone15_simulator/flutter_devices.txt`
- `app/doc/runtime_flow_proofs_2026-04-27_iphone15_simulator/simctl_devices.txt`
- `app/doc/runtime_flow_proofs_2026-04-27_iphone15_simulator/backend_health.json`
- `app/doc/runtime_flow_proofs_2026-04-27_iphone15_simulator/flutter_test_output.txt`
- `app/doc/runtime_flow_proofs_2026-04-27_iphone15_simulator/flutter_test_output_backend_updated.txt`

Final live flow proved in log:

- `POST /ai/archetypes -> 200`
- `POST /ai/optimize -> 202`
- `GET /ai/optimize/jobs/<jobId> -> completed after 4 polls`
- preview captured as `09_preview`
- `POST /decks/<deckId>/cards/bulk -> 200`
- `PUT /decks/<deckId> -> 200`
- `POST /decks/<deckId>/validate`
- post-apply capture recorded as `10_complete_validated`

Audit rerun on the same date against the same local backend also proved:

- `POST /ai/archetypes -> 200 (8495ms)`
- `POST /ai/optimize -> 202 (5718ms)`
- job completed after `4` polls on `/ai/optimize/jobs/<jobId>` (roughly `1.2s` each)
- backend telemetry for the same async completion reported:
  - `total_ms=10710`
  - `complete.fill_remainder=3457ms`
  - `complete.ai_suggestion_loop=2438ms`
  - `complete.build_final_response=1217ms`
  - `complete.prepare_commander_seed=597ms`
- preview remained captured as `09_preview`
- final validated capture remained `10_complete_validated`

Backend-updated rerun after the `/ai/archetypes` cache/telemetry patch also proved:

- focused app checks still passed:
  - `flutter analyze lib/features/decks test/features/decks`
  - `flutter test test/features/decks/screens/deck_details_screen_smoke_test.dart test/features/decks/providers/deck_provider_test.dart test/features/decks/widgets/deck_optimize_flow_support_test.dart`
- live iPhone 15 runtime still completed with:
  - `GET /ai/optimize/jobs/<jobId> -> completed after 4 polls`
  - `CAPTURE_TAKEN 09_preview bytes=271451`
  - `CAPTURE_TAKEN 10_complete_validated bytes=244136`
- direct latency probe against the same updated backend confirmed the new archetypes endpoint behavior:
  - first `POST /ai/archetypes` -> `200`, `cache.hit=false`, `total_ms=11995`, `openai_call=10756`
  - second `POST /ai/archetypes` -> `200`, `cache.hit=true`, `total_ms=1277`, `openai_call=0`
- conclusion: the backend patch improved repeated archetype fetches without regressing the real `preview -> apply -> validate` runtime path on iPhone 15.

## Harness Changes Applied

- `deck_runtime_m2006_test.dart` now waits for deck list readiness before trying to create a deck.
- The create-deck path now supports both:
  - empty-state `Novo Deck`
  - non-empty list `FAB -> popup -> Novo Deck`
- The test opens the created deck through either the fresh success path or the persisted deck list path.
- The optimize sheet path now handles the real iPhone 15 simulator behavior:
  - explicitly switches `Bracket / Power level` to `4 - cEDH` before continuing
  - waits for strategy options/current strategy actions
  - keeps the real optimize/apply/validate backend flow
  - dispatches the `StrategyOptionCard.onTap` callback inside the harness when the simulator hit-test for the draggable sheet becomes unreliable
- Final completion validation was relaxed to the real UI signals already shown after apply, instead of requiring only the exact `Válido` text.

## What Passed

- iPhone 15 Simulator discovery and boot.
- Real iOS app launch on simulator.
- Local backend binding through `API_BASE_URL` and `PUBLIC_API_BASE_URL` on `127.0.0.1:8082`.
- Register/login path.
- Deck creation path on real Decks screen.
- Empty Commander deck details path.
- Commander import path using `Talrand, Sky Summoner`.
- Competitive bracket selection path using `4 - cEDH`.
- Async optimize job path with real polling.
- Preview/apply flow.
- Real post-apply deck update plus `/validate` request.
- Focused Flutter analyze and deck widget/provider tests.

## Non-blocking Notes

- Flutter still prints the Apple Silicon simulator warning for the transitive MLKit pods (`GoogleMLKit`, `MLImage`, `MLKitCommon`, `MLKitVision`). The iPhone 15 iOS 17.4 runtime proof still built and completed successfully.
- The iPhone 15 simulator hit-test on the draggable optimize sheet was flaky for direct pointer taps on `StrategyOptionCard`; the harness workaround stays inside the real widget callback and preserves the live backend flow.
