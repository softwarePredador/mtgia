# Scanner Runtime Handoff

## Target

- Fechar a pendencia `Scanner not proven` da QA release.
- Provar a melhor cobertura possivel em duas camadas:
  1. device fisico/camera real se viavel;
  2. harness controlado com texto OCR mockado quando camera real nao for viavel.

## Status

Verdict: `Parser/provider/backend fallback controlled path approved / camera real not proven`.

Date/time: `2026-04-29 09:17-09:33 -03`.

## Device discovery

- iPhone 15 Simulator: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`
- Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`
- State: `Booted`
- Physical device discovered: `Rafa (wireless)` / `00008130-001C152922BA001C` / `iOS 26.5 23F5043k`
- Physical runtime result: not usable for `flutter test` in this session; Flutter returned `Cannot start app on wirelessly tethered iOS device. Try running again with the --publish-port flag`, and `flutter test` did not accept `--publish-port`.

Proof log:

- `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator/scanner_device_discovery.log`

## Scanner audit

### App surfaces found

- `app/lib/features/scanner/models/card_recognition_result.dart`
  - `CardRecognitionResult`
  - `CardNameCandidate`
  - `CollectorInfo` for `collectorNumber`, `totalInSet`, `setCode`, `isFoil`, `language`, `rawBottomText`
- `app/lib/features/scanner/screens/card_scanner_screen.dart`
  - real camera screen using `camera`, `permission_handler`, live image stream, manual `takePicture`, scanner result preview, deck add, binder callback mode.
- `app/lib/features/scanner/providers/scanner_provider.dart`
  - scanner states: `idle`, `capturing`, `processing`, `searching`, `found`, `notFound`, `error`
  - live frame OCR confirmation threshold
  - exact printing -> fuzzy local -> `POST /cards/resolve` fallback pipeline
  - controlled harness entrypoint added: `processRecognitionResult(CardRecognitionResult result)`
- `app/lib/features/scanner/services/card_recognition_service.dart`
  - Google ML Kit text recognition, image/file OCR, live `CameraImage` OCR, candidate scoring, guide-rect filtering, collector extraction.
- `app/lib/features/scanner/services/image_preprocessor.dart`
  - grayscale/contrast/sharpen, foil preprocessing, name-region crop, temp cleanup.
- `app/lib/features/scanner/services/fuzzy_card_matcher.dart`
  - OCR variation generation and Levenshtein ranking over card search results.
- `app/lib/features/scanner/services/scanner_card_search_service.dart`
  - `GET /cards?name=...`
  - `GET /cards/printings?name=...`
  - `POST /cards/resolve`
- `app/lib/features/scanner/services/scanner_ocr_parser.dart`
  - new pure parser for controlled OCR text and collector metadata harnesses.
- `app/lib/features/scanner/widgets/scanner_overlay.dart`
  - visual card guide overlay.
- `app/lib/features/scanner/widgets/scanned_card_preview.dart`
  - preview, edition selector, foil/condition/set badges, not-found/manual-search UI.

### Entry points found

- Deck details menu: `app/lib/features/decks/screens/deck_details_screen.dart`
- Binder screen scanner mode: `app/lib/features/binder/screens/binder_screen.dart`

### Camera/OCR/backend dependencies

- Uses real camera: yes, through `package:camera`.
- Uses image picker: no `image_picker` dependency or scanner flow found.
- Uses MLKit: yes, through `google_mlkit_text_recognition`.
- Uses local backend: yes, through `ApiClient` scanner card search endpoints.
- Uses Scryfall directly from app: no; Scryfall fallback is backend-mediated through `POST /cards/resolve`.
- Physical/camera-dependent parts:
  - `Permission.camera.request()`
  - `availableCameras()`
  - `CameraController.initialize()`
  - `CameraPreview`
  - `startImageStream(_onCameraFrame)`
  - `takePicture()`
  - MLKit OCR over `CameraImage` or captured file

### Tests found/added

- Existing:
  - `app/test/features/scanner/widgets/scanned_card_preview_test.dart`
- Added:
  - `app/test/features/scanner/services/scanner_ocr_parser_test.dart`
  - `app/test/features/scanner/services/scanner_card_search_service_test.dart`
  - `app/test/features/scanner/providers/scanner_provider_test.dart`
  - `app/integration_test/scanner_controlled_harness_runtime_test.dart`

## Backend

Backend URL used: `http://127.0.0.1:8081`.

Health result:

```json
{"status":"healthy","service":"mtgia-server","environment":"development","version":"1.0.0"}
```

Backend contract probes:

- `GET /cards/printings?name=Lightning%20Bolt&limit=2`
  - real backend returned `collector_number` and `foil` keys.
- `POST /cards/resolve {"name":"Lightning Bolt"}`
  - before fix: local response omitted `collector_number` and `foil`;
  - after fix: local response includes `collector_number` and `foil` keys.

Proof logs:

- `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator/backend_health.log`
- `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator/backend_scanner_contract.log`
- `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator/backend_health_after_fix.log`
- `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator/backend_scanner_contract_after_fix.log`
- `app/doc/runtime_flow_proofs_2026-04-29_iphone15_simulator/backend_stop.log`

## Commands executed

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices --no-version-check
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
```

```bash
cd app
flutter analyze lib/features/scanner test/features/scanner integration_test --no-version-check
flutter test test/features/scanner --no-version-check
```

```bash
cd server
PORT=8081 dart run .dart_frog/server.dart
curl -sS http://127.0.0.1:8081/health
```

```bash
cd app
flutter test integration_test/scanner_controlled_harness_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 \
  --reporter expanded \
  --no-version-check
```

Physical attempt:

```bash
cd app
flutter test integration_test/scanner_controlled_harness_runtime_test.dart \
  -d "00008130-001C152922BA001C" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8081 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8081 \
  --reporter expanded \
  --no-version-check
```

Retry attempted with `--publish-port=0`; `flutter test` returned `Could not find an option named "--publish-port"`.

## Results by layer

| Layer | Result | Evidence |
| --- | --- | --- |
| Camera hardware | `not proven` | iPhone Simulator cannot prove camera; physical iPhone was wireless-only and `flutter test` could not start the app. |
| Real MLKit OCR over camera/file | `not proven` | No physical camera/card capture was executable non-interactively. |
| Controlled OCR parser | `passed` | Unit tests validate name, collector number, total, set code, foil/non-foil, language and empty OCR. |
| ScannerProvider | `passed` | Controlled `CardRecognitionResult` resolves exact printings, auto-selects `collector_number` + `setCode` + `foil`, falls back to resolve, and handles empty state. |
| Search service mapping | `passed` | Unit tests preserve `collector_number` and `foil` from printings and resolve responses. |
| Backend printings contract | `passed` | Real `GET /cards/printings` exposes `collector_number` and `foil`. |
| Backend resolve contract | `passed after fix` | Real `POST /cards/resolve` now exposes `collector_number` and `foil`. |
| iPhone 15 Simulator harness runtime | `passed` | `scanner_controlled_harness_runtime_test.dart` passed on `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`. |
| Physical iPhone harness runtime | `not proven` | Wireless-only Flutter integration start failed; no wired run available. |

## Bugs fixed

- `ScannerCardSearchService` now maps `collector_number` and `foil` into `DeckCardItem`.
- `ScannerProvider` now has `processRecognitionResult()` for controlled OCR harnesses above the camera layer.
- Scanner auto-selection now prefers matching foil/non-foil when OCR collector metadata includes `isFoil`.
- Controlled OCR parser avoids treating collector/footer lines as card names and extracts collector metadata without requiring MLKit.
- `POST /cards/resolve` now selects and returns `collector_number` and `foil`.
- Scryfall import paths in `cards/resolve` and `cards/printings?sync=true` now persist `collector_number` and `foil` when Scryfall provides them.

## What was real vs mocked

Real:

- iPhone 15 Simulator runtime execution.
- Flutter integration test runner.
- App scanner provider/model/service code paths above camera.
- Backend health and card endpoint contract via local Dart Frog on `127.0.0.1:8081`.

Controlled/mocked:

- OCR input text.
- Scanner search responses inside unit/integration harness.
- No real camera preview, no camera permission dialog, no physical card image, no real MLKit OCR result in the harness.

## Remaining real pendencies

1. Camera/OCR real remains `not proven` until a wired physical iPhone or otherwise testable physical device can run the scanner screen with camera permission and a controlled MTG card/image.
2. Physical iPhone `Rafa` was discovered only as wireless; `flutter test` could not start the integration app on that target in this environment.
3. Simulator warning remains known: Google MLKit transitive pods do not support arm64 for Apple Silicon iOS 26+ simulators, but the controlled harness still built and passed on the iPhone 15 Simulator.

## Smallest next actions

1. Connect a physical iPhone by cable, unlock it, confirm Developer Mode, and rerun a scanner integration/manual flow against a controlled physical card.
2. If automated camera proof is required, add a native test seam or fixture-image flow that exercises MLKit on a file without live camera hardware.
