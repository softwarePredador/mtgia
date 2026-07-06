# Global Commander Candidate Copy Materializer

- generated_at: `2026-07-06T06:32:43.478400+00:00`
- status: `candidate_materialized_structure_ready_next_gate_closed`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_id: `612`
- commander: `Lorehold, the Historian`
- candidate: `1` swap(s)
- stage: `None`
- source_artifact_type: `global_commander_land_cut_candidate_model`
- role: ``
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260706_land_floor_deck612_ash_barrens_candidate/knowledge_candidate.db`
- source_unchanged: `true`
- source_matches_pair_report: `true`
- source_candidate_hash_differs: `true`
- promotion_allowed: `false`
- allow_battle_gate_now: `false`
- allow_next_strategy_matrix: `true`
- allow_chained_source: `false`
- protected_blocked_cut_cards: `[]`

## Structure Validation

- status: `pass`
- deck_summary: `{"avg_cmc": 3.167, "cards": 100, "deck_id": 612, "hash": "96003345d88b65ae10c6f39faf0f231a0e1b940128e5f2619c943ed190b55260", "lands": 28, "nonlands": 72, "ruleset_hash": "b5332a3f27aa89217b88355402eddadebe910eebd8296e2d56035983e0c0100a", "semantics_hash": "21e71a5797bf1f12464b9a2dbb71cb87a72d958189e677537dbd966ccbf65a25"}`

| Check | Pass |
| --- | --- |
| `total_cards_100` | `true` |
| `commander_count_1` | `true` |
| `all_adds_present_once` | `true` |
| `all_cuts_absent` | `true` |
| `added_roles_present` | `true` |
| `nonbasic_singleton_ok` | `true` |
| `unresolved_card_rows_0` | `true` |

## Swaps

| # | Add | Cut | Role |
| ---: | --- | --- | --- |
| 1 | `Ash Barrens` | `Longshot, Rebel Bowman` | `` |

## Policy

- candidate_scope: The swap or value-safe stage exists only inside the copied Hermes SQLite candidate DB.
- promotion_gate: Promotion stays closed until structure, strategy matrix, battle gate, and replay trace pass.
- source_boundary: Source DB and PostgreSQL are not mutated by this materializer.
