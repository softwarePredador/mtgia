# Global Commander Reviewed External Seeded Force Access Trace Generator

- generated_at: `2026-07-06T01:35:47.470135+00:00`
- status: `reviewed_external_seeded_forced_access_blocks_absent_hypotheses`
- commander: `Kaalia of the Vast`
- deck_id: `619`
- source_hypothesis_count: `10`
- focus_hypothesis_count: `10`
- focus_cards: `Basalt Monolith, Monologue Tax, Burnt Offering, Culling the Weak, Desperate Ritual, Grim Monolith, Infernal Plunge, Pyretic Ritual, Cabal Ritual, Strike It Rich`
- seed_count: `3`
- forced_access_mode: `opening_hand`
- usage_blocked_count: `0`
- manual_review_count: `0`
- force_failure_count: `0`
- selected_db_absent_count: `10`
- missing_input_count: `0`
- card_level_cut_permission_count: `0`
- candidate_copy_allowed_count: `0`
- candidate_copy_allowed_now: `false`
- value_safe_reclassification_allowed_now: `false`
- battle_gate_allowed_now: `false`
- promotion_allowed: `false`
- next_gate: `rerun_seeded_cut_source_miner_against_current_evaluation_db`

## Review Rows

| Cut | Role | Status | Forced Present | Usage | Exposure | Decisions | Source Score | Next Gate |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `Basalt Monolith` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 58 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |
| `Monologue Tax` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 58 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |
| `Burnt Offering` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 52 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |
| `Culling the Weak` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 52 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |
| `Desperate Ritual` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 52 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |
| `Grim Monolith` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 52 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |
| `Infernal Plunge` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 52 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |
| `Pyretic Ritual` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 52 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |
| `Cabal Ritual` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 44 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |
| `Strike It Rich` | `mana_acceleration` | `reviewed_seeded_forced_access_card_absent_from_selected_db_blocks_cut_permission` | 0 | 0 | 0 | 0 | 42 | `rerun_seeded_cut_source_miner_against_current_evaluation_db` |

## Blockers

- `seeded_hypotheses_absent_from_selected_db:Basalt Monolith,Monologue Tax,Burnt Offering,Culling the Weak,Desperate Ritual,Grim Monolith,Infernal Plunge,Pyretic Ritual,Cabal Ritual,Strike It Rich`
- `candidate_copy_closed_after_seeded_forced_access_trace`

## Policy

- forced_access_boundary: Forced access is diagnostic evidence only; it is not a natural battle gate.
- seeded_hypothesis_boundary: Reviewed external seeds can target trace work, but do not create card-level cut permission.
- target_boundary: Forced access applies only to the current evaluation target player.
- promotion_boundary: No candidate copy, deck mutation, battle gate, value-safe reclassification, or promotion is opened by this report.
