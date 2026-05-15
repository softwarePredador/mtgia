# Full State / Realtime / Cache Audit - 2026-05-15

## Scope and verdict

Track C audited ManaLoom app provider state, polling/realtime refresh, and cache behavior on `master` for the full-stack non-scanner round. Scanner/camera/OCR/MLKit were not functionally audited and remain **DEFERRED / NOT PROVEN**.

Overall status: **PASS_WITH_RISKS**.

No secrets, tokens, JWTs, DSNs, database URLs, API keys, real emails, sensitive payloads, Authorization headers, or full decklists are included in this document.

## Required docs read

- `docs/README.md`
- `server/doc/DOCS_ARTIFACT_RETENTION_AUDIT_2026-05-15.md`
- `server/doc/FULL_FLOW_STATE_AND_DOC_AUDIT_2026-05-15.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/manual-de-instrucao.md`

## Key source findings

- Global auth transition cleanup is wired in `app/lib/main.dart`: authenticated sessions start notification/message polling, unauthenticated sessions stop polling and call provider clears (`app/lib/main.dart:468`, `app/lib/main.dart:498`, `app/lib/main.dart:504`).
- Backend-driven realtime remains polling/FCM-refresh based for notifications, direct messages, and trades; no WebSocket contract was found in the audited docs/source.
- Clear stale-response bugs were found in Auth/Profile, Messages, Notifications, and Trades: late responses could repopulate provider state after logout/account clear or after an active detail/chat changed.
- Safe app-only fixes were implemented with provider generation guards. No app-facing API contract changed.

## Provider matrix

| Area | Status | State / realtime / cache notes | Risks / follow-up |
|---|---|---|---|
| Auth / Profile | PASS | `AuthProvider` now uses an auth generation guard for initialize/login/register/logout/profile refresh/update, preventing late profile/auth responses or stale credential persistence from mutating state after logout (`app/lib/features/auth/providers/auth_provider.dart:19`, `:31`, `:232`, `:245`, `:323`, `:366`). | No request cancellation exists at HTTP layer; stale mutation is guarded at provider layer. |
| Decks | PASS_WITH_RISKS | `DeckProvider.clearAllState()` clears deck list, selected deck, errors, and 5-minute detail cache (`app/lib/features/decks/providers/deck_provider.dart:1120`). | In-flight deck fetches are not globally generation-guarded; rely on logout clear and route/auth failures. Add request epoch if a reproducible leak appears. |
| Binder | PASS | Binder, marketplace, and public binder fetches already use generation counters and clear increments them (`app/lib/features/binder/providers/binder_provider.dart:1051`). | Mutations still depend on follow-up fetches; no clear cross-account leak was proven. |
| Marketplace / Binder marketplace | PASS | Covered by BinderProvider generation guards for `/community/marketplace`; late marketplace pages are ignored after clear (`app/lib/features/binder/providers/binder_provider.dart:1004`, `:1020`, `:1051`). | None blocking. |
| Messages | PASS | `MessageProvider` polling is stopped on logout; unread, inbox, active chat, send, and mark-read paths now check provider generation, and active chat responses are ignored after chat close/switch (`app/lib/features/messages/providers/message_provider.dart:108`, `:181`, `:204`, `:279`, `:448`). | HTTP requests are not cancelled, but stale mutations are blocked. |
| Notifications | PASS | `NotificationProvider` polling is stopped on logout; unread count/list/read operations now check generation and clear increments generation (`app/lib/features/notifications/providers/notification_provider.dart:61`, `:87`, `:116`, `:273`). | HTTP requests are not cancelled, but stale mutations are blocked. |
| Trades | PASS | `TradeProvider` now generation-guards list, pagination, detail, chat, create/respond/status/message paths and clear increments list/detail/message epochs (`app/lib/features/trades/providers/trade_provider.dart:479`, `:506`, `:635`, `:844`, `:959`). | No WebSocket/live stream; realtime remains push-triggered refresh. |
| Community decks | PASS | Community public deck paging already had a fetch generation guard and clear increments it (`app/lib/features/community/providers/community_provider.dart:93`, `:122`, `:216`). | Other community detail helpers return maps directly; no retained stale state bug was proven. |
| Social / public profile | PASS_WITH_RISKS | `SocialProvider.clearAllState()` clears search, visited profile, followers/following, and following feed state (`app/lib/features/social/providers/social_provider.dart:611`). | Social fetches do not have full generation guards; late search/profile/following responses could repopulate state after logout. Recommended next hardening if Track C continues. |
| Cards / Sets | PASS_WITH_RISKS | `CardProvider` guards stale search by comparing request query and clears search on logout (`app/lib/features/cards/providers/card_provider.dart:75`, `app/lib/main.dart:506`). Sets catalog uses screen-local state/debounce, backed by backend `/sets` cache. | Card search is query-guarded, not auth-epoch guarded; sets local screen requests were not runtime-proven in this track. |
| Profile screen | PASS | Profile mutations route through `AuthProvider`; late `/users/me` refresh/update is now ignored after logout/account clear. | None blocking. |
| Market | PASS_WITH_RISKS | `MarketProvider` has a 5-minute cache and `clearAllState()` clears movers/cache timestamp (`app/lib/features/market/providers/market_provider.dart:21`, `:71`). | Market fetches lack generation guard; lower sensitivity because data is public/market-wide, but stale UI after logout remains possible. |
| Scanner / camera / OCR / MLKit | BLOCKED / DEFERRED | Out of functional scope for this non-scanner audit. | Do not use scanner docs/tests as release gate for this track. |

## Fixes implemented

1. Added auth/session generation guards in:
   - `app/lib/features/auth/providers/auth_provider.dart`
   - `app/lib/features/messages/providers/message_provider.dart`
   - `app/lib/features/notifications/providers/notification_provider.dart`
   - `app/lib/features/trades/providers/trade_provider.dart`
2. Added focused regression tests proving late responses cannot repopulate state after logout/clear or active chat/detail close:
   - `app/test/features/auth/providers/auth_provider_log_sanitization_test.dart`
   - `app/test/features/messages/providers/message_provider_test.dart`
   - `app/test/features/notifications/models/notification_models_test.dart`
   - `app/test/features/trades/providers/trade_provider_test.dart`

## Commands run

- Baseline focused tests before code changes:
  - `cd app && flutter test test/features/messages/providers/message_provider_test.dart test/features/notifications/models/notification_models_test.dart test/features/trades/providers/trade_provider_test.dart test/features/auth/providers/auth_provider_log_sanitization_test.dart` — PASS.
- Post-fix focused tests:
  - Same focused `flutter test ...` command — initial run failed because the new notification test missed `dart:async`; fixed import and reran.
  - Final focused `flutter test ...` — PASS.
- Static analysis:
  - `cd app && dart analyze lib/features/auth/providers/auth_provider.dart lib/features/messages/providers/message_provider.dart lib/features/notifications/providers/notification_provider.dart lib/features/trades/providers/trade_provider.dart test/features/messages/providers/message_provider_test.dart test/features/notifications/models/notification_models_test.dart test/features/trades/providers/trade_provider_test.dart test/features/auth/providers/auth_provider_log_sanitization_test.dart` — PASS after removing a `return` from `finally`.
- Repository quick gate:
  - `./scripts/quality_gate.sh quick` — PASS (rerun after final code changes).

## Remaining risks

- Several providers still rely on clearAllState without HTTP cancellation. The highest-risk retained-state providers were fixed in this pass; Social, Decks, Card search, and Market should receive the same generation pattern if future runtime evidence shows cross-account bleed.
- Backend caches are authoritative for cards/sets and AI optimize. This track did not alter server cache contracts or `server/doc/API_CONTRACTS_AND_DATA_MAP.md`.
- Scanner/camera/OCR/MLKit remain explicitly **DEFERRED / NOT PROVEN**.
