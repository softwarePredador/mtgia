# Deck runtime iPhone 15 Simulator — 2026-04-30

## Attempt

- Date/time: `2026-04-30T12:12:08-03:00` sprint start; validation run during P1 UX trust sprint.
- Task: P1 UX trust, friendly errors and critical trade confirmations.
- Runtime target: iPhone 15 Simulator.
- Backend intended for Social Trading runtime: `http://127.0.0.1:8082`.

## Device discovery

`flutter devices` summary:

```text
iPhone 15 (mobile) • F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF • ios • com.apple.CoreSimulator.SimRuntime.iOS-17-4 (simulator)
```

`xcrun simctl list devices available | grep -E "iPhone 15|Booted"` summary:

```text
iPhone 15 Pro (...) (Shutdown)
iPhone 15 Pro Max (...) (Shutdown)
iPhone 15 (F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF) (Booted)
iPhone 15 Plus (...) (Shutdown)
```

Concrete simulator id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`.
Runtime: `com.apple.CoreSimulator.SimRuntime.iOS-17-4`.

## Backend health

Command:

```bash
curl -sS --max-time 5 http://127.0.0.1:8082/health
```

Initial sprint result:

```text
curl: (7) Failed to connect to 127.0.0.1 port 8082 after 5 ms: Couldn't connect to server
```

Follow-up validation started a temporary backend on `8082` and `/health` returned `healthy`.

## Runtime command

```bash
cd app
flutter test integration_test/binder_marketplace_trade_runtime_test.dart \
  -d "iPhone 15" \
  --dart-define=API_BASE_URL=http://127.0.0.1:8082 \
  --dart-define=PUBLIC_API_BASE_URL=http://127.0.0.1:8082 \
  --reporter expanded \
  --no-version-check
```

Follow-up status: `blocked by simulator build`, not by backend health.

The harness was updated to match the new UX trust dialogs:

- `CreateTradeScreen`: taps `Revisar proposta` and confirms `create-trade-review-confirm-button`.
- `TradeDetailScreen`: confirms `Aceitar trade?`, `Confirmar entrega?` and `Finalizar trade?`.

`flutter analyze integration_test/binder_marketplace_trade_runtime_test.dart --no-version-check` passed after the harness update.

The rerun on iPhone 15 reached iOS build and then failed before app launch with the known MLKit simulator link issue:

```text
Failed to build iOS app
Error (Xcode): Building for 'iOS-simulator', but linking in object file (.../Pods/MLImage/Frameworks/MLImage.framework/MLImage[arm64][2](GMLImage.o)) built for 'iOS'
Error (Xcode): Linker command failed with exit code 1
```

## What was real vs mocked

- Real: code changes, static analysis, focused Flutter unit/widget tests, simulator discovery for iPhone 15, backend health after temporary 8082 startup, and iOS build attempt.
- Mocked/faked in tests: ApiClient/provider responses for Auth timeout, Sets 500, TradeProvider failures, CreateTrade review and TradeDetail action confirmations.
- Not proven in device UI: `binder_marketplace_trade_runtime_test.dart` against backend 8082, because the iOS Simulator build failed before app launch on MLKit/MLImage linking.
- Not touched: backend code/contracts, Life Counter/Lotus, meta pipeline, scanner, FCM.

## Validation run

```bash
cd app
flutter analyze lib/features/auth lib/features/decks lib/features/collection lib/features/trades lib/features/binder lib/features/market lib/core test --no-version-check
```

Result: `PASS`, no issues.

```bash
cd app
flutter test test/features/auth test/features/decks test/features/collection test/features/trades test/features/binder test/features/market test/core --no-version-check
```

Result: `PASS`, `01:02 +178: All tests passed!`.

## Blockers

| Area | Owner/module | Status | Smallest next action |
| --- | --- | --- | --- |
| Social Trading iPhone 15 runtime | local backend/app QA | `blocked by simulator build` | Resolve/guard the MLKit `MLImage.framework` simulator link issue or run the same command on a physical iOS device, then rerun `integration_test/binder_marketplace_trade_runtime_test.dart`. |
