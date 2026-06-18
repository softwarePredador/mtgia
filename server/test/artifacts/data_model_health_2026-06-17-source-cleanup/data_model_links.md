# Data Model Final Validation — 2026-06-15

Generated at: `2026-06-17T03:30:09.616585Z`

## Executive summary

- Static inventory found `81` tables and `4` views across product backend and Hermes scripts.
- App scan found `66` API endpoint string references in Flutter code.
- Hermes sync scan found `23` sync/import/export/materialize scripts.
- PostgreSQL validation was `executed`.

## PostgreSQL runtime validation

- Public relations found: `72`.
- Critical view presence: `{"card_identity_bridge":true,"card_intelligence_snapshot":true,"commander_learning_snapshot":true,"optimize_candidate_quality_summary":true}`.
- Rollback view validation:
```json
{
  "card_identity_bridge": {
    "compiled_in_rollback": true,
    "row_count_in_rollback": 305905
  },
  "card_intelligence_snapshot": {
    "compiled_in_rollback": true,
    "row_count_in_rollback": 34329
  },
  "commander_learning_snapshot": {
    "compiled_in_rollback": true,
    "row_count_in_rollback": 106
  },
  "optimize_candidate_quality_summary": {
    "compiled_in_rollback": true,
    "row_count_in_rollback": 34329
  }
}
```
- Fanout checks:
```json
{
  "deck_cards_to_card_intelligence_snapshot": {
    "rows": 50841,
    "distinct_deck_card_rows": 50841,
    "extra_rows": 0
  },
  "direct_deck_cards_to_card_battle_rules_fanout_potential": {
    "rows": 36440,
    "distinct_deck_card_rows": 35992,
    "extra_rows": 448
  },
  "cards_with_multiple_battle_rules": 10,
  "cards_with_multiple_function_tags": 22675
}
```
- Critical row counts:
```json
{
  "users": 1092,
  "cards": 34329,
  "sets": 951,
  "card_legalities": 324538,
  "card_localized_names": 251107,
  "card_function_tags": 112563,
  "card_role_scores": 46598,
  "card_semantic_tags_v2": 24181,
  "card_battle_rules": 3158,
  "decks": 1337,
  "deck_cards": 50841,
  "deck_matchups": 4,
  "battle_simulations": 1,
  "deck_weakness_reports": 15,
  "commander_learned_decks": 61,
  "deck_learning_events": 109,
  "commander_card_usage": 912,
  "commander_card_synergy": 7796,
  "commander_reference_profiles": 50,
  "commander_reference_card_stats": 1606,
  "commander_reference_decks": 121,
  "commander_reference_deck_cards": 10114,
  "commander_reference_deck_analysis": 27,
  "meta_decks": 653,
  "external_commander_meta_candidates": 10,
  "format_staples": 748,
  "ai_optimize_cache": 7,
  "ai_optimize_jobs": 0,
  "ai_generate_jobs": 4,
  "ml_prompt_feedback": 3,
  "ai_logs": 1102
}
```

## Static linkage validation

- Table classification distinguishes `postgres_product`, `postgres_product_and_hermes_bridge`, and `hermes_sqlite_or_lab` to avoid false positives.
- Low-use tables are not automatically bugs; lineage/cache/lab tables are valid when documented and excluded from app-facing assumptions.

### Stale documentation candidates

- None found for current stale write-only patterns.

## Hermes / EasyPanel / SQL coherence

- PostgreSQL remains the source of truth for product behavior.
- Hermes SQLite tables are classified as cache/lab/report-only unless a backend sync explicitly promotes reviewed data.
- Scripts with `--apply` or materialization behavior must remain opt-in and reviewed before promotion.

## External source gap review

- [Scryfall Card API](https://scryfall.com/docs/api/cards)
  - Relevance: Canonical card object fields for oracle_id, legalities, prices, images, all_parts, keywords, produced_mana, rulings_uri, and prints_search_uri.
  - Gap: ManaLoom has core card identity and prices, but should keep all_parts/keywords/produced_mana/rulings_uri available for battle and decision trace enrichment.
- [MTGJSON Card Atomic/Deck/Leadership Skills](https://mtgjson.com/data-models/card/card-atomic/)
  - Relevance: Atomic cards separate oracle-like data from printing data; leadershipSkills marks formats where a card can be commander.
  - Gap: Commander/Brawl eligibility should prefer explicit leadershipSkills/official rule gates over text-only inference when available.
- [Wizards Commander Format](https://magic.wizards.com/en/formats/commander)
  - Relevance: Official commander color identity, 100-card deck shape, command zone, commander tax, and commander damage framing.
  - Gap: Keep strict color identity and commander tax/damage as backend-owned validation; do not outsource this to Hermes SQLite.
- [Edge of Eternities Mechanics](https://magic.wizards.com/en/news/feature/edge-of-eternities-mechanics)
  - Relevance: Legendary Vehicles and Spacecraft with printed power/toughness can be commanders; Spacecraft/Station/Warp must be modeled deliberately.
  - Gap: Battle/Commander legality should retain backlog coverage for Vehicle/Spacecraft commander, Station, Warp, Void, and Lander signals.
- [17Lands Metrics](https://www.17lands.com/metrics_definitions)
  - Relevance: Metrics like OH WR, GIH WR, GP WR, IWD, ALSA, and ATA show how to avoid overtrusting raw win rate.
  - Gap: Use methodology for Hermes scorecards only; do not import 17Lands card performance into Commander recommendations.

## Prioritized next actions

- **P0 — Maintain card_intelligence_snapshot anti-fanout guardrail**
  - Reason: Direct joins from deck_cards to card_battle_rules multiply deck rows.
  - Action: Keep product consumers on card_intelligence_snapshot or equivalent per-card aggregation; do not replace this with direct deck_cards -> card_battle_rules joins.
- **P1 — Adopt commander_learning_snapshot in future learning loaders**
  - Reason: The backend-owned commander learning aggregate exists; new consumers should not reassemble Hermes/usage/synergy lineage ad hoc.
  - Action: Route future learned-deck diagnostics and optimizer learning reads through commander_learning_snapshot while keeping raw Hermes metadata hidden from normal users.
- **P2 — Add decision-impact metrics inspired by 17Lands methodology**
  - Reason: Raw Lorehold WR is not enough to trust deck or battle improvements.
  - Action: Track with/without-seen/cast deltas, sample size, baseline hash, and opponent archetype; do not import 17Lands Commander recommendations.
