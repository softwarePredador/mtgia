# Deck runtime iPhone 15 Simulator — 2026-04-30

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
