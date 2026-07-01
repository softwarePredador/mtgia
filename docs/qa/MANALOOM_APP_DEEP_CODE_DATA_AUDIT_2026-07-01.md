# ManaLoom App Deep Code/Data Audit - 2026-07-01

## Scope

Deep audit focused on the Flutter app and app-facing backend contracts:

- runtime-reachable Dart code from `app/lib/main.dart`;
- legacy/duplicate widgets and obsolete visual artifacts;
- app-facing PostgreSQL table/view usage;
- deck/card intelligence joins that can affect analysis, recommendations,
  optimize, weakness analysis and matchup simulation;
- validation commands after cleanup.

No PostgreSQL writes were performed.

## Findings Closed

### 1. Retired native life counter clone

The live route uses `LotusLifeCounterScreen`; the old
`LifeCounterScreen` file was not reachable from the app runtime graph and was
only referenced by legacy parity tests.

Removed:

- `app/lib/features/home/life_counter_screen.dart`;
- legacy clone tests;
- legacy clone goldens, benchmark PNGs and proof PNGs;
- obsolete concept PNG under `app/test/features/home/`.

Result: life counter coverage now points only at Lotus host/fallback suites.

### 2. Runtime-dead deck card widget

`DeckCard` was not used by the live deck list. The current screen uses
`_DeckSpotlightCard` and `_DeckGalleryCard` directly.

Removed:

- `app/lib/features/decks/widgets/deck_card.dart`;
- tests that only exercised that unused widget.

### 3. Hanging Home golden

Full Flutter test execution previously stalled at
`matches the SM A135M hero visual baseline` because the test waited for global
settling. The test now advances a bounded 900 ms after image precache, enough
for the Home intro animation while avoiding unrelated continuous activity.

### 4. Snapshot join contract alignment

App-facing deck intelligence loaders now join `card_intelligence_snapshot` via
the contract key `card_id`, not the alias `id`.

Updated:

- `/ai/simulate-matchup`;
- `/ai/weakness-analysis`;
- `/decks/:id/recommendations`;
- `/decks/:id/analysis`;
- `/decks/:id/ai-analysis`;
- optimize deck context loader;
- data model link audit;
- PostgreSQL-to-Hermes target deck sync.

## Database Evidence

Read-only live PostgreSQL checks:

- `cards=34331`;
- `card_intelligence_snapshot=34331`;
- `card_intelligence_snapshot_distinct_card_id=34331`;
- `deck_cards=52371`;
- `deck_cards_missing_cards_rows=0`;
- `deck_cards_missing_snapshot_rows=0`.

`dart run bin/audit_data_model_links.dart` confirmed:

- `card_intelligence_snapshot` compiles in rollback and has `34331` rows;
- `deck_cards_to_card_intelligence_snapshot.extra_rows=0`;
- direct `deck_cards -> card_battle_rules` would fan out
  `45307` extra rows, so product routes must stay on aggregated views or
  per-card aggregate fallback.

## Validation

Passed:

- `cd app && flutter analyze --no-version-check`;
- `cd server && dart analyze`;
- `python3 -m py_compile docs/hermes-analysis/manaloom-knowledge/scripts/sync_pg_target_deck_to_hermes.py`;
- focused Flutter tests for Home, theme token guard and affected deck widgets;
- focused server route/contract tests;
- full Flutter suite: `590` tests passed;
- read-only data model audit.

## Remaining Watch Items

- `cards.is_reserved` exists in live PostgreSQL but has no runtime reference in
  app/server source scan. Keep for now; decide later whether it should surface
  as reserved-list trading/price risk or remain backend-only metadata.
- Live scan found `13` decks with `user_id IS NULL`. They are not orphaned
  `deck_cards`, but should be classified as seed/public/system decks before any
  cleanup.
- Some Flutter unit tests still emit calls to the default public API URL through
  fakes/mocks. They pass, but future cleanup should isolate those tests from
  network-looking logs.
- Historical image folders under `app/doc/` remain untouched because they are
  documentation/reference material, not runtime or test artifacts.
