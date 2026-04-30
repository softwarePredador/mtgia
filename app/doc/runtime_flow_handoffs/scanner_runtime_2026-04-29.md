# Scanner Runtime Handoff

## Target

- Fechar a pendencia `Scanner not proven` da QA release.
- Provar a melhor cobertura possivel em duas camadas:
  1. device fisico/camera real se viavel;
  2. harness controlado com texto OCR mockado quando camera real nao for viavel.

## Status

Verdict: `Parser/provider/backend fallback controlled path approved / camera real not proven`.

Date/time: `2026-04-29 09:17-09:33 -03`.

Follow-up 2026-04-30 late: `Physical Android scanner PARTIAL PASS / token OCR confirmed / stable requests fixed`.

- Device: `SM A135M` / `R58T300SREH`, Android 14.
- Backend: `http://127.0.0.1:8082`, with `adb reverse tcp:8082 tcp:8082`.
- Fresh physical proof: `app/doc/runtime_flow_handoffs/scanner_physical_audit_2026-04-30.md`.
- Proof logs: `app/doc/runtime_flow_proofs_2026-04-30_scanner_physical/`.
- App runtime command:
  - `cd app && flutter run -d R58T300SREH --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 --no-version-check`.
- Physical result after fix:
  - CameraX opened the back camera, MLKit local Latin OCR loaded, OCR frames processed successfully.
  - Live candidates included `Phyrexian Horror`, noisy package text (`Sedex`) and footer fragments.
  - Stable confirmation grouped close OCR variants and confirmed `Phyrexian Horror` at `100%`.
  - Only after confirmation the app issued `GET /cards/printings?name=Phyrexian+Horror&limit=50&dedupe=false`.
  - The request returned `200` in `1587ms`; the stream stopped while showing the result.
- Backend proof:
  - `POST /cards/resolve {"name":"Phyrexian Horror","include_tokens":true}` returned `Token Artifact Creature — Phyrexian Horror` and not `Phyrexian Censor`.
  - `GET /cards?name=Phyrexian%20Horror&dedupe=false&include_tokens=true` and `GET /cards/printings?name=Phyrexian%20Horror&dedupe=false` returned token printings with `collector_number` and `foil`.
- Remaining physical matrix:
  - Normal well-lit card, multiple normal editions, foil physical card, partially outside-guide card, and low-light/reflection are still not fully proven non-interactively, so the overall physical verdict is `PARTIAL`.

- Device: `SM A135M` / `R58T300SREH`.
- Backend: `http://127.0.0.1:8082`, with `adb reverse tcp:8082 tcp:8082`.
- App run: `flutter run -d R58T300SREH --dart-define=API_BASE_URL=http://127.0.0.1:8082 --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082`.
- Observed issue: OCR recognized `Phyrexian Horror` token, but the final scanner flow could resolve to a nearby normal card (`Phyrexian Censor`) when the local DB did not have that token and token context was lost across live frames.
- Fix: token context is now preserved across live confirmation frames, token OCR blocks normal/fuzzy fallback, and `/cards/resolve` supports `include_tokens=true` using Scryfall `type:token include:extras`.
- Live backend proof: `POST /cards/resolve {"name":"Phyrexian Horror","include_tokens":true}` returned `source=scryfall`, `total_returned=3`, and `type_line="Token Artifact Creature — Phyrexian Horror"`.
- Follow-up logs after reinstall showed camera/OCR running on the Android device, but the tested frame contained surrounding packaging/order text (`Itens do pedido`, `Método de Pagamento`, `Pinhais`, etc.), so a clean physical retest of only the token inside the guide is still required for final PASS.

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
  - `CollectorInfo` for `collectorNumber`, `totalInSet`, `setCode`, `isFoil`, `language`, `isToken`, `rawBottomText`
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
  - token fallback through `POST /cards/resolve {"include_tokens": true}`
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
| Token card resolution | `passed after fix` | Unit/live backend proof for `Phyrexian Horror` uses token-only search and blocks fallback to normal/fuzzy cards. |
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
- Token OCR now sets `CollectorInfo.isToken` only for token type-line patterns, not for normal rules text that merely mentions creating a token.
- `ScannerProvider` preserves the best live OCR frame across confirmation, so a frame with `Token Artifact Creature ...` is not overwritten by a later frame that only repeats the name.
- `ScannerProvider` uses token-only lookup for token OCR and refuses fuzzy/normal fallback if the token cannot be found.
- `POST /cards/resolve` accepts `include_tokens=true` and imports Scryfall extras/tokens with `type:token include:extras`.

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

1. Camera/OCR real is partially proven on Android physical device: camera permission, CameraX, MLKit OCR and backend traffic ran, but the clean `Phyrexian Horror` token retest still needs the card/token isolated inside the guide with no packaging/order text around it.
2. Physical iPhone `Rafa` was discovered only as wireless; `flutter test` could not start the integration app on that target in this environment.
3. Simulator warning remains known: Google MLKit transitive pods do not support arm64 for Apple Silicon iOS 26+ simulators, but the controlled harness still built and passed on the iPhone 15 Simulator.

## Smallest next actions

1. Retest `Phyrexian Horror` token on `SM A135M` with only the token inside the scanner guide and no visible package/order labels around it.
2. Connect a physical iPhone by cable, unlock it, confirm Developer Mode, and rerun a scanner integration/manual flow against a controlled physical card if iOS camera proof is still required.
3. If automated camera proof is required, add a native test seam or fixture-image flow that exercises MLKit on a file without live camera hardware.
