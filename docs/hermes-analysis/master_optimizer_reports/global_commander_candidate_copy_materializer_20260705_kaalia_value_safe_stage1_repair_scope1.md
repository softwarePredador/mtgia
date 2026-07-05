# Global Commander Candidate Copy Materializer

- generated_at: `2026-07-05T21:01:26.719194+00:00`
- status: `candidate_materialized_structure_ready_next_gate_closed`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_id: `619`
- commander: `Kaalia of the Vast`
- candidate: `1` swap(s)
- stage: `None`
- source_artifact_type: `global_commander_package_scope_reducer`
- role: `reduced_scope`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260705_kaalia_value_safe_stage1_repair_scope1_candidate/knowledge_candidate.db`
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
- deck_summary: `{"avg_cmc": 3.523, "cards": 100, "deck_id": 619, "hash": "31567fa18309ef598d94758b1d2bafa01eb3c659fd3858f990733698e9a66de6", "lands": 35, "nonlands": 65, "ruleset_hash": "2387e8e0fcd5025d52e1d87e65af9e1a48573668123c8c880c76260e00a9fd86", "semantics_hash": "17c78e5398c5a7952854143377ad55f11f7f935d0d1c04e1e402ed995ed56013"}`

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
| 1 | `Necromancy` | `Cabal Ritual` | `reanimation_plan_b` |

## Policy

- candidate_scope: The swap or value-safe stage exists only inside the copied Hermes SQLite candidate DB.
- promotion_gate: Promotion stays closed until structure, strategy matrix, battle gate, and replay trace pass.
- source_boundary: Source DB and PostgreSQL are not mutated by this materializer.
