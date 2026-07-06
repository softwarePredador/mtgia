# Global Commander Candidate Copy Materializer

- generated_at: `2026-07-06T12:29:16.394409+00:00`
- status: `candidate_materialized_structure_ready_next_gate_closed`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_id: `612`
- commander: `Lorehold, the Historian`
- candidate: `5` swap(s)
- stage: `None`
- source_artifact_type: `global_commander_profile_repair_land_cut_reviewer`
- role: `profile_repair_land_cut_review`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260706_larger_gate_feedback_land_floor_profile_repair_deck612_candidate/knowledge_candidate.db`
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
- deck_summary: `{"avg_cmc": 3.047, "cards": 100, "deck_id": 612, "hash": "ab2cd75c69f8a3a44cb3c2f6bc185b21cc60741e99c40bddf80617256f45d73e", "lands": 36, "nonlands": 64, "ruleset_hash": "1440fc0f47cb56a9541c4026d294b03aa1c1d9955bb0b6b1217cc9b31d49b9c4", "semantics_hash": "4afccfa2d2662fd5f6484e2d456e64412739e7c5d4fd3a6d0d8ff30a060e679a"}`

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
| 1 | `Bant Panorama` | `Storm-Kiln Artist` | `land` |
| 2 | `Brokers Hideout` | `Jeska's Will` | `land` |
| 3 | `Pyromancer's Goggles` | `Artist's Talent` | `mana_acceleration` |
| 4 | `Call Forth the Tempest` | `Starfall Invocation` | `board_wipes_resets` |
| 5 | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `Brass's Bounty` | `mana_acceleration` |

## Policy

- candidate_scope: The swap or value-safe stage exists only inside the copied Hermes SQLite candidate DB.
- promotion_gate: Promotion stays closed until structure, strategy matrix, battle gate, and replay trace pass.
- source_boundary: Source DB and PostgreSQL are not mutated by this materializer.
