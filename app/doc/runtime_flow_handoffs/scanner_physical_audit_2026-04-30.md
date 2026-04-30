# Scanner Physical Audit - 2026-04-30

## Verdict

`PARTIAL physical PASS / controlled logic PASS`

The Android physical runtime proved camera, MLKit OCR, live scanner confirmation, backend access through `adb reverse`, and token-safe printing lookup for `Phyrexian Horror`. The fully requested physical matrix was not completely executed non-interactively: normal well-lit card, multiple normal editions, foil-specific physical card, partial-outside-guide card, and low-light/reflection variants remain not physically proven in this run.

## Date/time

- Started: `2026-04-30 16:30 -03`
- Backend/device proof window: `2026-04-30 16:39-16:43 -03`

## Devices

### Physical Android

- Device: `SM A135M`
- Device id: `R58T300SREH`
- Runtime: `Android 14 (API 34)`
- Backend access from device: `adb reverse tcp:8082 tcp:8082`

### iPhone 15 Simulator discovery

- `flutter devices`: `iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)`
- `xcrun simctl list devices available | grep -E "iPhone 15|Booted"`: `iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)`

## Backend

- Backend URL used by app: `http://127.0.0.1:8082`
- Startup command: `cd server && PORT=8082 dart run .dart_frog/server.dart`
- Health result:

```json
{"status":"healthy","service":"mtgia-server","timestamp":"2026-04-30T16:39:53.138373","environment":"development","version":"1.0.0","git_sha":null,"checks":{"process":{"status":"healthy"}}}
```

## Commands executed

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia
git status --short
flutter devices
xcrun simctl list devices available | grep -E "iPhone 15|Booted"
```

```bash
cd app
flutter analyze lib/features/scanner test/features/scanner --no-version-check
flutter test test/features/scanner --no-version-check
flutter test integration_test/scanner_controlled_harness_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

```bash
cd server
dart analyze routes/cards routes/cards/resolve test/card_resolution_support_test.dart
dart test test/card_resolution_support_test.dart
PORT=8082 dart run .dart_frog/server.dart
```

```bash
curl -sS http://127.0.0.1:8082/health
curl -sS -X POST http://127.0.0.1:8082/cards/resolve \
  -H 'Content-Type: application/json' \
  -d '{"name":"Phyrexian Horror","include_tokens":true}'
curl -sS 'http://127.0.0.1:8082/cards?name=Phyrexian%20Horror&limit=10&page=1&dedupe=false&include_tokens=true'
curl -sS 'http://127.0.0.1:8082/cards/printings?name=Phyrexian%20Horror&limit=10&dedupe=false'
```

```bash
cd app
adb reverse tcp:8082 tcp:8082
flutter run -d R58T300SREH \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --no-version-check
```

## Runtime evidence

Proof folder:

- `app/doc/runtime_flow_proofs_2026-04-30_scanner_physical/`

Log files:

- `flutter_run_R58T300SREH.log`
- `flutter_run_R58T300SREH_after_stable_fix.log`
- `adb_scanner_logcat_tail.log`
- `adb_scanner_logcat_tail_after_stable_fix.log`

Key physical runtime lines after the stability fix:

```text
I/flutter: [📸 Camera] Zoom: 1.5 (min=1.0, max=8.0)
I/flutter: [📸 Live] Stream iniciado
D/DecoupledTextDelegate: Start loading thick OCR module.
D/PipelineManager: OCR process succeeded via visionkit pipeline.
I/flutter: [🏷️ Candidatos] live_stream: "Phyrexian Horror" (score=142, y=5%), ...
I/flutter: [🔍 Collector] Bottom: "*/*) */*) NC EN SCOTn CuoU NC EN SCOTn CuoU" → #?/? ★FOIL NC EN
I/flutter: [📸 Live] Confirmado: "Phyrexian Horror" (100.0%) | Collector: CollectorInfo(#null/null • CM null)
I/flutter: [🌐 ApiClient] GET http://127.0.0.1:8082/cards/printings?name=Phyrexian+Horror&limit=50&dedupe=false
I/flutter: [🌐 ApiClient] GET /cards/printings?name=Phyrexian+Horror&limit=50&dedupe=false → 200 (1587ms)
I/flutter: [📸 Live] Stream parado
```

Backend token proof:

```json
{
  "source": "local",
  "name": "Phyrexian Horror",
  "total_returned": 3,
  "data": [
    {
      "name": "Phyrexian Horror",
      "type_line": "Token Artifact Creature — Phyrexian Horror",
      "set_code": "tmoc",
      "collector_number": "40",
      "foil": false
    }
  ]
}
```

## What was real vs mocked

Real:

- Physical Android device `R58T300SREH`.
- App launched through `flutter run`.
- CameraX initialization and back camera activation.
- MLKit local Latin OCR module loading and OCR frame processing.
- Live OCR candidate ranking from camera frames.
- Backend `http://127.0.0.1:8082` through `adb reverse`.
- `GET /cards/printings?name=Phyrexian+Horror&dedupe=false` triggered only after stable live confirmation.
- `/cards/resolve`, `/cards`, and `/cards/printings` probes against live backend.

Controlled/mocked:

- Unit tests for packaging/order text, normal rules text that mentions creating a token, foil auto-selection, and token fallback are controlled text/fake-service tests.
- iPhone 15 scanner harness uses controlled OCR text above the camera layer.

Not physically proven:

- Separate normal well-lit card.
- Multiple normal physical editions.
- Foil physical card-specific auto-selection.
- Physical card partially outside guide.
- Low-light/reflection variant.

## Findings and fixes

- The visual guide math is now shared through `ScannerGuideGeometry.cardRectForSize`, so the overlay and runtime ROI use the same rectangle.
- ROI filtering now requires real overlap with the guide and uses a much smaller margin, reducing contamination from surrounding packaging/order text.
- OCR ranking now rejects external text such as order, payment, SKU, price, address/city/shipping terms.
- The parser no longer treats `1/1` from rules text as collector metadata; it prefers real collector/set/footer patterns.
- Token type lines like `Token Artifact Creature ...` are treated as type lines, not card-name candidates.
- Stable live confirmation now groups close OCR variants such as `PuYREXIAN HORROR` and `Phyrexian Horror` without making network requests before confirmation.
- `/cards` now returns `collector_number` and `foil`, and supports token-priority ordering with `include_tokens=true`.
- `/cards/printings` now supports `dedupe=false`, preserving multiple printings/foil variants for scanner edition selection.
- Scanner exact printing calls now request `dedupe=false`.

## Result matrix

| Requirement | Result | Evidence |
| --- | --- | --- |
| Token does not resolve as normal card | `PASS` | `/cards/resolve {"name":"Phyrexian Horror","include_tokens":true}` returned `Token Artifact Creature — Phyrexian Horror`; support test rejects `Phyrexian Censor`. |
| External text penalized | `PASS controlled / PARTIAL physical` | Unit parser rejects order/payment/SKU text; physical logs still saw `Sedex` as candidate but stable confirmation selected `Phyrexian Horror` and made one backend call only after confirmation. |
| Visual guide and ROI coherent | `PASS controlled` | Shared `ScannerGuideGeometry` and widget test cover MTG ratio/position; runtime used same helper for camera ROI. |
| Editions respect set/collector/foil | `PASS controlled / backend PASS` | Provider test selects `BLB #157 foil`; `/cards/printings?dedupe=false` exposes all printings with `collector_number`/`foil`. |
| Requests only after stable confirmation | `PASS physical` | One `/cards/printings` call appears after `[📸 Live] Confirmado`. |
| Analyze/tests | `PASS` | App scanner analyze/test and server analyze/test passed. |
| Physical device full card matrix | `PARTIAL` | Camera/OCR/token path proven; normal/foil/low-light matrix not fully executed. |

## Blockers / smallest next actions

1. Execute a hands-on physical matrix with known cards in frame: one normal card, one multi-printing normal card with visible set/collector, one foil, one card partially outside the guide, and low-light/reflection.
2. Add optional per-frame OCR timing telemetry if future runs need p50/p95 frame latency; current logs show MLKit OCR success, GC pressure, and startup skipped frames, but not explicit OCR duration per frame.
3. If physical OCR continues to read footer noise like `CM: 49019900`, add a stricter footer whitelist for collector/set/language patterns after another real-card sample set.
