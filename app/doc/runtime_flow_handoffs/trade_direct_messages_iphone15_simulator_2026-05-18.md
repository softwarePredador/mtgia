# Trade and Direct Messages Runtime - iPhone 15 Simulator - 2026-05-18

## Status

`PASS_WITH_RISKS`

## Scope

Runtime public proof for the stale/persistence risks called out in the global
product audit:

- Binder item create/update/delete.
- Marketplace listing discovery.
- Trade create, accept, ship, delivery confirmation and completion.
- Trade chat message persistence and notification.
- Notifications list, tap-through and read-all.
- Direct Messages inbox, conversation open, read receipt and reply persistence.

Scanner/camera/OCR and real push delivery were not part of this proof.

## Environment

- Device: `iPhone 15 Simulator`
- Device id: `F0B1713F-4B8A-4DB9-825E-C8A4B17A03DF`
- Backend: `https://evolution-cartinhas.8ktevp.easypanel.host`
- Backend SHA: `5156f9b644f2cff0b6fc6572df1c5569ad313890`
- Harness: `app/integration_test/binder_marketplace_trade_runtime_test.dart`
- Result: `00:01:18 +2: All tests passed!`

## Sanitized Outcome

Trade runtime:

- Trade reached `completed`.
- Trade chat message was visible in detail and persisted in backend count.
- `trade_message` notification was present for the buyer.
- `trade_completed` notification was present for the seller.
- Notification tap-through returned to trade detail.
- Read-all left buyer unread notifications at `0`.
- Rate-limit retries observed by the harness: `0`.

Direct Messages runtime:

- Receiver opened inbox and saw the inbound message.
- Opening the conversation marked it read in backend unread count.
- Receiver reply persisted.
- Backend message count reached `2`.
- Receiver unread direct messages after read receipt: `0`.
- Rate-limit retries observed by the harness: `0`.

## Evidence

Sanitized machine summary:

- `app/doc/runtime_flow_proofs_2026-05-18_trade_direct_messages_iphone15_simulator/summary.json`

The raw runtime stream contained screenshot chunks and disposable runtime IDs;
those were not preserved in docs.

## Residual Risks

- This is simulator runtime, not a signed TestFlight/physical-device build.
- Real APNs/FCM delivery was not re-proven here; notification correctness was
  validated via app/backend state.
