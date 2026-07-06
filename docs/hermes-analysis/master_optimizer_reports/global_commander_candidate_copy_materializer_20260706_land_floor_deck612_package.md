# Global Commander Candidate Copy Materializer

- generated_at: `2026-07-06T06:36:39.316444+00:00`
- status: `candidate_materialized_structure_ready_next_gate_closed`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_id: `612`
- commander: `Lorehold, the Historian`
- candidate: `7` swap(s)
- stage: `None`
- source_artifact_type: `global_commander_land_floor_package_synthesizer`
- role: `land_floor_package`
- candidate_db: `docs/hermes-analysis/master_optimizer_reports/global_commander_candidate_copy_materializer_20260706_land_floor_deck612_package_candidate/knowledge_candidate.db`
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
- deck_summary: `{"avg_cmc": 3.03, "cards": 100, "deck_id": 612, "hash": "a5c2900f3344fda8cbfd2b40cd628e3415974ab4b33b987c270e56a4b585170b", "lands": 34, "nonlands": 66, "ruleset_hash": "5fd1940c63e2b3489fa5d2fa1d545ac2fcce87b0bcb8d811a6c06b5cc60c89a7", "semantics_hash": "ed40a6d6e3f97ad764b35c51f1de3d10bc375e480d81f1a1dae122673206ea3e"}`

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
| 1 | `Ash Barrens` | `Longshot, Rebel Bowman` | `land` |
| 2 | `Sunbaked Canyon` | `Agate Instigator` | `land` |
| 3 | `Battlefield Forge` | `Warleader's Call` | `land` |
| 4 | `Cabaretti Courtyard` | `Pyromancer's Goggles` | `land` |
| 5 | `Demolition Field` | `Call Forth the Tempest` | `land` |
| 6 | `Escape Tunnel` | `Ancient Gold Dragon` | `land` |
| 7 | `Evolving Wilds` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `land` |

## Policy

- candidate_scope: The swap or value-safe stage exists only inside the copied Hermes SQLite candidate DB.
- promotion_gate: Promotion stays closed until structure, strategy matrix, battle gate, and replay trace pass.
- source_boundary: Source DB and PostgreSQL are not mutated by this materializer.
