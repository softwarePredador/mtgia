# Full App Screen / Field Audit - 2026-05-15

## Scope and verdict

Track B audited ManaLoom Flutter non-scanner screens, fields, actions, keys,
loading/empty/error/success states, and refresh expectations on `master`.

Overall status: **PASS_WITH_RISKS**.

Scanner/camera/OCR/MLKit: **DEFERRED / NOT TOUCHED** for this non-scanner
audit. Scanner entry points may still exist in the app tree, but they were not
used as functional acceptance criteria.

No secrets, tokens, JWTs, Sentry DSNs, database URLs, OpenAI keys, real emails,
sensitive payloads, Authorization headers, or full decklists are included here.

## Required docs read

- `docs/README.md`
- `server/doc/DOCS_ARTIFACT_RETENTION_AUDIT_2026-05-15.md`
- `server/doc/FULL_FLOW_STATE_AND_DOC_AUDIT_2026-05-15.md`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `app/doc/UI_TEST_SURFACE_MAP.md`
- `app/doc/APP_AUDIT_2026-04-29.md`
- `server/manual-de-instrucao.md`

## Screen / field matrix

| Module | Screens | Keyed fields/actions audited | Sends / receives | State and refresh notes | Status |
|---|---|---|---|---|---|
| Auth | `LoginScreen`, `RegisterScreen`, `SplashScreen` | Login/register email, username, password, confirm password, submit, route switches. | `/auth/login`, `/auth/register`, `/auth/me`. | Submit loading exists; error/success are snackbar/provider driven and not fully keyed. | PASS_WITH_RISKS |
| Profile | `ProfileScreen` | Avatar dialog, avatar URL, display name, state, city, trade notes, save, binder/marketplace shortcuts. | `/users/me`, `PATCH /users/me`, FCM token paths outside visible form. | Save loading visible; success/error snackbar not keyed. | PASS_WITH_RISKS |
| Deck list/detail | `DeckListScreen`, `DeckDetailsScreen` | Create dialog fields, public switch, deck rows, empty CTAs, FAB/menu import/generate/optimize, card detail and edition picker keys. | `/decks`, `/decks/:id`, card mutation routes, validate/pricing/import/AI. | Deck list refresh-on-return is implemented; detail mutations refresh selected deck. Loading/error states are visible but not consistently keyed. | PASS_WITH_RISKS |
| Deck import | `DeckImportScreen`, import-to-deck dialog | Full-screen import fields, commander field, list field, example/count/error/submit keys, dialog field/replace switch/error/not-found keys. | `/import`, `/import/validate`, `/import/to-deck`. | Dialog refreshes deck details after success; backend now returns commander status fields for clearer Commander/Brawl UX. | PASS |
| Generate | `DeckGenerateScreen` | Format, commander, prompt, submit, generated deck name, save. | `/ai/generate`, job polling, deck create. | Progress and validation feedback are visible; some panels still need stable state keys. | PASS_WITH_RISKS |
| Optimize | Optimize config/preview/outcome widgets | Preview dialog, intensity, keep-theme, current-strategy, add/remove suggestions, apply, outcome, guided rebuild, error snackbar. | `/ai/optimize`, optimize jobs, rebuild/archetypes/validate. | Strong alignment with `UI_TEST_SURFACE_MAP.md`. | PASS |
| Cards/search | `CardSearchScreen`, `CardDetailScreen` | Search field, tabs, result list/rows/images/add dialog/confirm. | `/cards`, `/cards/printings`, `/ai/explain`, deck/binder callbacks. | Loading/error/empty states are friendly but not consistently keyed. | PASS_WITH_RISKS |
| Sets/collections | `CollectionScreen`, `SetsCatalogScreen`, `SetCardsScreen` | Hub tabs, open catalog/latest, sets search/list/tile, set card list/empty/card. | `/sets`, `/cards?set=...`. | Refresh/retry exists; `setCardsEmptyState` is keyed, other states less consistently keyed. | PASS_WITH_RISKS |
| Binder | `BinderTabContent`, binder editor | Stats, search, have/want lists, item card, add action, foil/trade/sale/price/notes/language/condition/quantity/save/remove. | `/binder`, `/binder/stats`, binder CRUD. | Pull refresh and filters exist; loading/error/empty states need more stable keys. Scanner add action is deferred. | PASS_WITH_RISKS |
| Marketplace | `MarketplaceTabContent` | Search, list, item card, owner, propose trade. | `/community/marketplace`. | Infinite scroll and filters exist; loading/error/empty states are not fully keyed. | PASS_WITH_RISKS |
| Trades | `TradeInboxScreen`, `CreateTradeScreen`, `TradeDetailScreen` | Create type/items/payment/message/review, detail accept/decline/cancel/ship/deliver/complete/dispute, ship dialog, trade chat. | `/trades`, `/trades/:id`, respond/status/messages. | Tab change reloads; detail and chat refresh/polling exist. Inbox state keys remain a gap. | PASS_WITH_RISKS |
| Community/social | `CommunityScreen`, `UserSearchScreen`, public profile | Community tabs, explore search/clear/filter/list/owner, following feed list, inline user search rows, public profile tabs/actions. | `/community/decks`, `/community/decks/following`, `/community/users`, follow endpoints. | Explore/users/following visible states exist; loading/error/empty keys should be added. | PASS_WITH_RISKS |
| Messages | `MessageInboxScreen`, `ChatScreen` | Inbox list/tile, chat field/send. | `/conversations`, `/conversations/:id/messages`, read/unread count. | Polling and refresh exist; provider stale-response guard was added in Track C. Error state can still visually collapse into empty state. | PASS_WITH_RISKS |
| Notifications | `NotificationScreen` | Notification list/tile/read-all. | `/notifications`, count, read, read-all. | Polling and refresh exist; provider stale-response guard was added in Track C. Error state can still visually collapse into empty state. | PASS_WITH_RISKS |
| Life Counter / Lotus | Non-scanner screens and sheets | Local gameplay counters and non-scanner card-search surfaces. | Mostly local state plus card search where used. | Runtime was not rerun by Track B. | PASS_WITH_RISKS |
| Scanner | `app/lib/features/scanner` | Present in tree only. | Shared card routes exist for future scanner validation. | **DEFERRED / NOT TOUCHED**. | DEFERRED |

## Clear findings

### P1 - Empty/error states can mislead users

| Finding | File | Repro summary | Recommended patch |
|---|---|---|---|
| Messages inbox can show empty copy when `/conversations` fails before data exists. | `app/lib/features/messages/screens/message_inbox_screen.dart` | Force conversations fetch failure on an empty inbox. | Add `messages-inbox-error`, `messages-inbox-empty`, and retry state keys. |
| Notifications can show empty copy when `/notifications` fails before data exists. | `app/lib/features/notifications/screens/notification_screen.dart` | Force notification list failure on an empty list. | Add `notifications-error`, `notifications-empty`, and retry state keys. |
| Chat message load failure has no dedicated keyed error panel. | `app/lib/features/messages/screens/chat_screen.dart` | Force `/conversations/:id/messages` failure. | Expose provider fetch error through `chat-messages-error` with retry. |

### P2 - UI test surface gaps

Recommended stable state keys for future patches:

- `deck-list-loading`, `deck-list-error`
- `card-search-loading`, `card-search-error`, `card-search-empty-state`
- `binder-list-loading-<have|want>`, `binder-list-error-<have|want>`,
  `binder-list-empty-<have|want>`
- `marketplace-list-loading`, `marketplace-list-error`,
  `marketplace-list-empty`
- `community-explore-loading`, `community-explore-error`,
  `community-explore-empty`
- `community-following-loading`, `community-following-error`,
  `community-following-empty`
- `community-users-loading`, `community-users-error`, `community-users-empty`
- `messages-inbox-loading`, `messages-inbox-error`, `messages-inbox-empty`
- `notifications-loading`, `notifications-error`, `notifications-empty`
- `deck-generate-progress-panel`, `deck-generate-validation-errors`,
  `deck-generate-warnings`

## Refresh / realtime expectations

- Deck list refreshes when visible again.
- Deck details refresh after import and card mutations.
- Trades reload on tab changes and detail actions refresh selected detail.
- Community following/quotes load on tab changes.
- Messages and notifications poll and support pull-to-refresh.
- Binder/marketplace support initial load, filters, infinite scroll, and pull
  refresh where the list exists.
- Collection hub tab switch itself does not force binder/marketplace refresh;
  child widgets rely on init/filter/pull refresh.

## Commands run by Track B

```bash
git status --short --branch
git log -1 --oneline
find app/lib/features -maxdepth 3 -type f ...
grep <docs/routes/key-surface patterns>
python3 <key inventory for app/lib/features excluding scanner>
git diff --check
cd app && flutter analyze lib test --no-version-check
```

Results from the Track B pass:

- `git diff --check`: PASS.
- `flutter analyze lib test --no-version-check`: initially blocked by issues that
  were later addressed by Track C tests/provider hardening in the combined audit
  worktree.

## Final classification

**PASS_WITH_RISKS**. Core non-scanner screens have usable keys and flows, but
state panels should be keyed more consistently so runtime tests can distinguish
loading, empty, error, success, and stale-refresh behavior without relying only
on visible copy.
