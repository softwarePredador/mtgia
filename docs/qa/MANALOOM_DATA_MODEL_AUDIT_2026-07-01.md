# Data Model Final Validation — 2026-07-01

Generated at: `2026-07-01T20:42:29.128180Z`

## Executive summary

- Static inventory found `100` tables and `4` views across product backend and Hermes scripts.
- App scan found `66` API endpoint string references in Flutter code.
- Hermes sync scan found `24` sync/import/export/materialize scripts.
- PostgreSQL validation was `executed`.

## PostgreSQL runtime validation

- Public relations found: `78`.
- Critical view presence: `{"card_identity_bridge":true,"card_intelligence_snapshot":true,"commander_learning_snapshot":true,"optimize_candidate_quality_summary":true}`.
- Rollback view validation:
```json
{
  "card_identity_bridge": {
    "compiled_in_rollback": true,
    "row_count_in_rollback": 305907
  },
  "card_intelligence_snapshot": {
    "compiled_in_rollback": true,
    "row_count_in_rollback": 34331
  },
  "commander_learning_snapshot": {
    "compiled_in_rollback": true,
    "row_count_in_rollback": 107
  },
  "optimize_candidate_quality_summary": {
    "compiled_in_rollback": true,
    "row_count_in_rollback": 34331
  }
}
```
- Fanout checks:
```json
{
  "deck_cards_to_card_intelligence_snapshot": {
    "rows": 52371,
    "distinct_deck_card_rows": 52371,
    "extra_rows": 0
  },
  "direct_deck_cards_to_card_battle_rules_fanout_potential": {
    "rows": 83701,
    "distinct_deck_card_rows": 38394,
    "extra_rows": 45307
  },
  "cards_with_multiple_battle_rules": 1992,
  "cards_with_multiple_function_tags": 22682
}
```
- Null-owner deck audit:
```json
{
  "available": true,
  "status": "classified_private_pg_registered_lab_decks",
  "null_user_decks": 13,
  "public_count": 0,
  "private_or_null_public_count": 13,
  "empty_count": 0,
  "populated_count": 13,
  "commander_count": 13,
  "pg_registered_private_commander_count": 13,
  "examples": [
    {
      "id": "917674eb-6a3d-58de-acce-5a2a3ac9e497",
      "name": "PG REGISTERED Lorehold Variant 04 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T12:08:10.082426+00:00",
      "has_commander": true,
      "deck_card_rows": 92,
      "total_quantity": 100
    },
    {
      "id": "8aa57962-3a3e-5351-89fd-e4651456a3bd",
      "name": "PG REGISTERED Lorehold Variant 05 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T12:16:12.040357+00:00",
      "has_commander": true,
      "deck_card_rows": 95,
      "total_quantity": 100
    },
    {
      "id": "0936dae3-32c4-5fb8-9c6f-d986670de794",
      "name": "PG REGISTERED Lorehold Variant 06 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T12:21:51.98897+00:00",
      "has_commander": true,
      "deck_card_rows": 90,
      "total_quantity": 100
    },
    {
      "id": "231281c3-e6a2-579b-93fe-21ddfdd13bda",
      "name": "PG REGISTERED Lorehold Variant 07 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T12:31:20.817675+00:00",
      "has_commander": true,
      "deck_card_rows": 100,
      "total_quantity": 100
    },
    {
      "id": "6df74eb3-c4a7-5398-bcf5-febb38d80d7a",
      "name": "PG REGISTERED Lorehold Variant 08 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T12:36:22.600759+00:00",
      "has_commander": true,
      "deck_card_rows": 91,
      "total_quantity": 100
    },
    {
      "id": "b51c8f24-fa8b-50ee-8200-d78fe9908ffa",
      "name": "PG REGISTERED Lorehold Variant 09 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T12:40:02.757182+00:00",
      "has_commander": true,
      "deck_card_rows": 91,
      "total_quantity": 100
    },
    {
      "id": "43c026ae-2d92-5049-90fc-1fdad4b04298",
      "name": "PG REGISTERED Lorehold Variant 10 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T12:43:35.114137+00:00",
      "has_commander": true,
      "deck_card_rows": 84,
      "total_quantity": 100
    },
    {
      "id": "9df6ac2e-6620-5265-8008-1f57c8963d66",
      "name": "PG REGISTERED Lorehold Variant 11 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T12:48:33.302859+00:00",
      "has_commander": true,
      "deck_card_rows": 84,
      "total_quantity": 100
    },
    {
      "id": "34508aae-e393-577a-97d8-6259353664af",
      "name": "PG REGISTERED Kefka Variant 01 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T13:09:03.214743+00:00",
      "has_commander": true,
      "deck_card_rows": 97,
      "total_quantity": 100
    },
    {
      "id": "c77cb83c-dd28-5d66-a0d8-799079a848bb",
      "name": "PG REGISTERED Valgavoth Variant 01 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T13:14:38.678613+00:00",
      "has_commander": true,
      "deck_card_rows": 87,
      "total_quantity": 100
    },
    {
      "id": "b629f227-b2b2-5e71-9854-99d345a8e01c",
      "name": "PG REGISTERED Kaalia Variant 01 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T13:21:55.55722+00:00",
      "has_commander": true,
      "deck_card_rows": 89,
      "total_quantity": 100
    },
    {
      "id": "c2230827-7963-52e4-a6ba-298d7be3478a",
      "name": "PG REGISTERED Sauron Variant 01 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T13:29:05.729731+00:00",
      "has_commander": true,
      "deck_card_rows": 89,
      "total_quantity": 100
    },
    {
      "id": "982cf6a6-c84a-5c3e-b9fc-e79127598b89",
      "name": "PG REGISTERED Y'shtola Variant 01 - Rafael Paste 2026-06-24",
      "format": "commander",
      "is_public": false,
      "created_at": "2026-06-24T13:34:49.946287+00:00",
      "has_commander": true,
      "deck_card_rows": 93,
      "total_quantity": 100
    }
  ]
}
```
- Critical row counts:
```json
{
  "users": 1130,
  "cards": 34331,
  "sets": 951,
  "card_legalities": 393764,
  "card_localized_names": 251107,
  "card_function_tags": 112585,
  "card_role_scores": 46598,
  "card_semantic_tags_v2": 24185,
  "card_battle_rules": 7279,
  "decks": 1360,
  "deck_cards": 52371,
  "deck_matchups": 4,
  "battle_simulations": 1,
  "deck_weakness_reports": 15,
  "commander_learned_decks": 76,
  "deck_learning_events": 138,
  "commander_card_usage": 953,
  "commander_card_synergy": 7801,
  "commander_reference_profiles": 50,
  "commander_reference_card_stats": 1618,
  "commander_reference_decks": 121,
  "commander_reference_deck_cards": 10114,
  "commander_reference_deck_analysis": 27,
  "meta_decks": 653,
  "external_commander_meta_candidates": 10,
  "format_staples": 748,
  "ai_optimize_cache": 0,
  "ai_optimize_jobs": 0,
  "ai_generate_jobs": 0,
  "ml_prompt_feedback": 8,
  "ai_logs": 1104
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
- **P2 — Keep null-owner PG registered decks out of product cleanup**
  - Reason: All null-owner decks match private complete PG registered Commander lab variants.
  - Action: Do not delete automatically. Assign an owner only through an explicit PostgreSQL package if these variants need product visibility.
- **P1 — Adopt commander_learning_snapshot in future learning loaders**
  - Reason: The backend-owned commander learning aggregate exists; new consumers should not reassemble Hermes/usage/synergy lineage ad hoc.
  - Action: Route future learned-deck diagnostics and optimizer learning reads through commander_learning_snapshot while keeping raw Hermes metadata hidden from normal users.
- **P2 — Add decision-impact metrics inspired by 17Lands methodology**
  - Reason: Raw Lorehold WR is not enough to trust deck or battle improvements.
  - Action: Track with/without-seen/cast deltas, sample size, baseline hash, and opponent archetype; do not import 17Lands Commander recommendations.
