# Data Model Final Validation — 2026-06-15

Generated at: `2026-06-15T19:49:45.500023Z`

## Executive summary

- Static inventory found `81` tables and `3` views across product backend and Hermes scripts.
- App scan found `66` API endpoint string references in Flutter code.
- Hermes sync scan found `20` sync/import/export/materialize scripts.
- PostgreSQL validation was `executed`.
- Follow-up applied in this cycle: migration
  `022_create_card_identity_and_intelligence_views` persisted
  `card_identity_bridge`, `card_intelligence_snapshot` and
  `optimize_candidate_quality_summary` in PostgreSQL.

## PostgreSQL runtime validation

- Public relations found: `71`.
- Critical view presence: `{"card_identity_bridge":true,"card_intelligence_snapshot":true,"optimize_candidate_quality_summary":true}`.
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
  "users": 1075,
  "cards": 34329,
  "sets": 951,
  "card_legalities": 324538,
  "card_localized_names": 251107,
  "card_function_tags": 112563,
  "card_role_scores": 46335,
  "card_semantic_tags_v2": 24181,
  "card_battle_rules": 3158,
  "decks": 1337,
  "deck_cards": 50841,
  "deck_matchups": 4,
  "battle_simulations": 1,
  "deck_weakness_reports": 15,
  "commander_learned_decks": 61,
  "deck_learning_events": 107,
  "commander_card_usage": 912,
  "commander_card_synergy": 7179,
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

- `docs/hermes-analysis/STRUCTURE_AUDIT.md:275` — #### P2 — `deck_matchups` permanece write-only no produto atual
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:294` — #### P2/P3 — `deck_weakness_reports` tambem permanece write-only
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:1478` — #### P2 — `deck_matchups` continua write-only no produto atual
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:3406` — #### P2 — `deck_matchups` continua write-only no produto atual
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:4612` — #### P2 — `deck_matchups` continua write-only no produto atual
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:5691` — #### P2 — `deck_matchups` continua write-only no produto atual
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:6808` — #### P2 — `deck_matchups` continua write-only no produto atual
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:7953` — #### P2 — `deck_matchups` continua write-only no produto atual
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:9082` — #### P2 — `deck_matchups` continua write-only no produto atual
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:10553` — #### P2 — `deck_matchups` continua write-only no produto atual
- `docs/hermes-analysis/STRUCTURE_AUDIT.md:10986` — #### P2 — `deck_matchups` é write-only no produto atual
- `docs/hermes-analysis/IMPLEMENTATION_TASKS.md:709` — ### [P3] Adicionar consumidor de leitura para `deck_weakness_reports` — dados persistidos nunca são lidos, anula benefício da persistência
- `docs/hermes-analysis/IMPLEMENTATION_TASKS.md:749` — | 5 | P3 | Adicionar consumidor de leitura para `deck_weakness_reports` — tabela write-only | STRUCTURE_AUDIT 2026-05-28 (postgresql-tables-not-used) |
- `docs/hermes-analysis/INFORMATION_BANK_DIAGNOSTIC_2026-06-15.md:443` — ainda descreviam `deck_matchups` e `deck_weakness_reports` como write-only.
- `docs/hermes-analysis/TECHNICAL_MAP.md:296` — `deck_weakness_reports` continuam write-only no produto atual;

## Hermes / EasyPanel / SQL coherence

- PostgreSQL remains the source of truth for product behavior.
- Hermes SQLite tables are classified as cache/lab/report-only unless a backend sync explicitly promotes reviewed data.
- Scripts with `--apply` or materialization behavior must remain opt-in and reviewed before promotion.
- EasyPanel public health check passed on `2026-06-15T19:54:31-03:00`: service
  `mtgia-server`, environment `production`, git SHA
  `aeeb8d4023c8e65a4a505a303bc86154a33f853c`.
- The public SHA is an ancestor of local `master`
  (`1f4f1f0994abc0d25d6a79c713aec7794e8db318` before this commit), so
  production is healthy but behind the current local source.
- Hermes AWS container `hermes_agent` is running (`Up 7 days`). With
  `/opt/data/.profile` loaded, the container exposes Flutter `3.44.0`, Dart
  `3.12.0`, and Python `3.13.5`.
- Hermes cron registry exists at `/opt/data/cron/jobs.json` inside the
  container with `25` jobs, `13` enabled. This validates Hermes as an
  operational lab/auditor, not as a clean source of product truth.
- Hermes workspace `/opt/data/workspace/mtgia` is present but dirty and out of
  sync (`ahead 1, behind 3`, plus many untracked cron artifacts). Any Hermes
  docs or generated reports must be triaged before copying into `master`.
- `sync_pg_target_deck_to_hermes.py` now prefers the backend-owned
  `card_intelligence_snapshot` when present and keeps an aggregated CTE
  fallback for older databases.

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

- **P1 — Clean stale Hermes docs about table usage**
  - Reason: Historical docs still claim write-only behavior for tables that now have runtime reads.
  - Action: Move stale sections to historical notes or update them with current source evidence.
- **P0 — Keep battle-rule joins behind card_intelligence_snapshot**
  - Reason: Direct joins from deck_cards to card_battle_rules multiply deck rows.
  - Action: Route deck analysis, optimize context, recommendations, weakness analysis, and Hermes syncs through aggregated snapshots.
- **P1 — Add commander_learning_snapshot**
  - Reason: Learned decks, commander usage, and Hermes evidence still require multiple table-specific reads.
  - Action: Create an internal backend-owned snapshot for commander learning, keeping Hermes metadata hidden from normal app users.
- **P2 — Add decision-impact metrics inspired by 17Lands methodology**
  - Reason: Raw Lorehold WR is not enough to trust deck or battle improvements.
  - Action: Track with/without-seen/cast deltas, sample size, baseline hash, and opponent archetype; do not import 17Lands Commander recommendations.
