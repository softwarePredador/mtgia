# ManaLoom Card Entry QA - 2026-05-08

## Scope

Auditoria e correcao dos fluxos ManaLoom de busca, detalhe, insercao, edicao,
troca de edicao, remocao e fichario de cartas. Scanner/camera/OCR/MLKit ficaram
fora do escopo.

## Result

**PASS WITH RISKS**

## Commands run

- `git status --short --branch`
- `git fetch origin master --quiet`
- `cd app && flutter analyze lib/features/cards lib/features/decks lib/features/binder test/features/cards test/features/decks test/features/binder --no-version-check`
- `cd server && dart analyze routes/cards routes/decks routes/binder test`
- `cd app && flutter test test/features/decks test/features/cards test/features/binder --no-version-check`
- `cd server && PORT=8082 dart run .dart_frog/server.dart`
- `curl -fsS http://127.0.0.1:8082/health`
- `cd server && TEST_API_BASE_URL=http://127.0.0.1:8082 dart test test/cards_route_test.dart test/sets_route_test.dart test/decks_incremental_add_test.dart test/binder_route_test.dart -r expanded`
- `cd server && dart analyze routes/decks routes/cards test/decks_incremental_add_test.dart`
- `cd server && TEST_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host dart test test/decks_incremental_add_test.dart --tags live --plain-name 'Lorehold, the Historian picker options should all preserve commander slot' -r expanded`

## Affected files

- `app/lib/features/cards/widgets/card_edition_metadata.dart`
- `app/lib/features/cards/providers/card_provider.dart`
- `app/lib/features/cards/screens/card_search_screen.dart`
- `app/lib/features/cards/screens/card_detail_screen.dart`
- `app/lib/features/decks/screens/deck_details_screen.dart`
- `app/lib/features/decks/widgets/deck_card_edit_dialog.dart`
- `app/lib/features/binder/widgets/binder_item_editor.dart`
- `app/lib/features/binder/screens/binder_screen.dart`
- `app/lib/features/binder/screens/marketplace_screen.dart`
- `server/routes/decks/[id]/index.dart`
- `server/routes/decks/[id]/cards/index.dart`
- `server/test/binder_route_test.dart`
- `server/test/decks_incremental_add_test.dart`
- `server/doc/API_CONTRACTS_AND_DATA_MAP.md`
- `server/manual-de-instrucao.md`
- `app/doc/APP_AUDIT_2026-04-29.md`

## User-visible behavior before/after

| Flow | Before | After |
|---|---|---|
| Card search result | Edition metadata was partial and did not show known non-foil state. | Shows `SET #collector`, set name/year, rarity, and foil/non-foil when known before add. |
| Card Detail | Set/rarity were visible, but collector/release/foil state were incomplete. | Shows set, `SET #collector`, release date, rarity, colors, CMC, and foil/non-foil when known. |
| Add card to deck | Commander/Brawl quantity controls remained constrained, but edition metadata was partial. | Add confirmation carries complete edition summary and preserves Commander quantity rules. |
| Edit commander card | Quantity fixed at 1, but edition labels could omit rarity/non-foil and raw loading errors could surface. | Quantity remains fixed at 1; printing selector shows set, collector, rarity, foil/non-foil, set name and date with friendly error copy. |
| Edit non-commander card | Quantity/condition worked, edition labels were less explicit. | Quantity/condition remain editable; edition selector is explicit before save. |
| Change commander via incremental add | A new commander printing could demote the old commander into mainboard in the single-commander path. | `POST /decks/:id/cards` validates the final state and replaces the single commander slot atomically without adding the commander to the 99. |
| Remove card from deck | Removal failures could show raw exception text. | Removal failures use friendly app copy. |
| Binder add/edit/delete | Binder add exposed printing selection, but chips omitted collector/rarity/non-foil and foil used AI-like iconography. | Binder add prints explicit edition metadata, friendly loading errors, non-AI foil iconography, and validates selected printing before save. |

## Backend contracts verified

- `GET /cards`
- `GET /cards/printings`
- `POST /decks/:id/cards`
- `POST /decks/:id/cards/set`
- `POST /decks/:id/cards/replace`
- `PUT /decks/:id`
- `POST /decks/:id/validate`
- Binder add/update/delete/list source contracts

Contract drift was real for deck card details: `GET /decks/:id` now returns
optional `collector_number`, `foil`, `set_name` and `set_release_date` in card
rows so deck card review and Card Detail can show edition identity consistently.
`server/doc/API_CONTRACTS_AND_DATA_MAP.md` was updated.

## Addendum 2026-05-11 - Lorehold commander edition options

Added a live backend regression test for `Lorehold, the Historian` covering the
same picker contract used by the app:

- fetches `/cards/printings?name=Lorehold%2C%20the%20Historian&limit=50&sync=true`;
- requires multiple unique picker options;
- verifies every option is commander-eligible and has visible edition metadata
  (`set_code`, `collector_number`, `foil` key and `rarity`);
- verifies Boros color identity (`R/W`) for each option;
- creates a Commander deck, adds Lorehold as commander, then iterates through
  every returned picker option using `POST /decks/:id/cards/set` with
  `is_commander=true` and `replace_same_name=true`;
- after every replacement, verifies exactly one commander remains and no
  Lorehold printing appears in `main_board`.

Result against public backend:

- `PASS`, `+1`, `All tests passed!`.

## Addendum 2026-05-11 - Android runtime proof for SM A135M

Added `app/integration_test/lorehold_commander_edition_android_runtime_test.dart`
to compile and run the Lorehold commander edition flow on Android/SM A135M.

The harness:

- registers a disposable QA user against the configured API;
- fetches all `/cards/printings` options for `Lorehold, the Historian`;
- verifies picker metadata before UI interaction;
- creates a Commander deck and adds Lorehold as commander;
- opens the app UI, confirms Lorehold edition metadata is visible in search and
  deck detail;
- opens the deck card edition picker, selects each alternate printing, and
  verifies `Edição atualizada.`;
- verifies after every change that exactly one commander remains and no Lorehold
  printing was added to `main_board`;
- captures visual proof markers through the shared runtime helpers.

Command prepared for SM A135M:

```bash
cd app
flutter test integration_test/lorehold_commander_edition_android_runtime_test.dart -d R58T300SREH --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check
```

Validation completed in this pass:

- `dart format integration_test/lorehold_commander_edition_android_runtime_test.dart`: `PASS`;
- `flutter analyze integration_test/lorehold_commander_edition_android_runtime_test.dart --no-version-check`: `PASS`;
- `flutter analyze lib test integration_test --no-version-check`: `PASS`;
- `flutter build apk --debug --no-version-check`: `PASS`, built
  `build/app/outputs/flutter-apk/app-debug.apk`;
- `flutter test test --no-version-check`: `PASS`, `+559`;
- `flutter test integration_test/lorehold_commander_edition_android_runtime_test.dart -d R58T300SREH --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host --reporter expanded --no-version-check`: `PASS`, `00:39 +1`, `All tests passed!`.

Physical runtime status:

- `PASS` on `SM A135M` / `R58T300SREH` / Android 14 against the public backend;
- the run printed `LOREHOLD_ANDROID_OPTIONS 2` and
  `LOREHOLD_ANDROID_RUNTIME_RESULT PASS`;
- visual proof markers were captured for search edition visibility, deck detail
  before edition change, picker option visibility and deck detail after all
  changes.

## Visual findings

- Edition metadata is visible before confirmation in search/add, deck edit and
  binder add surfaces.
- Foil/rarity non-AI surfaces no longer use `Icons.auto_awesome`.
- Existing AppTheme tokens are used for chips, warning copy and metadata text.
- Quantity controls keep Commander quantity fixed at `1`; destructive binder
  delete still requires confirmation.
- No runtime screenshots were collected in this pass.

## Remaining risks

- Android runtime proof for the visual Lorehold picker passed on `SM A135M`.
- Binder server coverage added in this pass is an offline source contract guard;
  the deck mutation path received the live backend proof on `127.0.0.1:8082`.
- Scanner/camera/OCR/MLKit were intentionally not tested.
