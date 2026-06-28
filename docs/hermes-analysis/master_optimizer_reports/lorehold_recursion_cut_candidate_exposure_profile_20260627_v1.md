# Lorehold Card Exposure Profile - 2026-06-27

- Generated at: `2026-06-28T00:31:45Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Evidence paths scanned: `633`
- JSON files scanned: `397`
- JSONL files scanned: `236`
- Parse errors: `0`

## Card Profiles

| Card | Unique Exposure | Role | Decision | Signals | Top Events/Metrics |
| --- | ---: | --- | --- | --- | --- |
| Squee, Goblin Nabob | 6752 | `recursion_engine` | `protect_current_engine` | discard_or_rummage_context, graveyard_recursion, paid_cast_exposure | airbend_creature_cast_from_exile=82, cast_announced=1562, cast_illegal=4, cost_paid=1550, creature_cast=1459, cost_paid:Squee, Goblin Nabob=992, graveyard_return:Squee, Goblin Nabob=269 |
| Volcanic Vision | 2 | `recursion_candidate` | `needs_non_squee_cut` | miracle_hit, spell_or_permanent_recursion | miracle:Volcanic Vision=2 |
| Restoration Seminar | 2 | `recursion_candidate` | `needs_non_squee_cut` | paid_cast_exposure, spell_or_permanent_recursion | cost_paid:Restoration Seminar=2 |
| Farewell | 29 | `board_wipe_pressure_reset` | `review_required` | discard_or_rummage_context, miracle_hit, pressure_reset_board_wipe | permanent_moved_from_battlefield=18, turn_end=6, miracle:Farewell=8 |
| Furygale Flocking | 22 | `runtime_ready_unexposed` | `review_required` | board_development_tokens, miracle_hit, paid_cast_exposure | spell_resolved=1, tokens_created=1, cost_paid:Furygale Flocking=13, discard_to_top:Furygale Flocking=8, lorehold_rummage_to_top:Furygale Flocking=8, miracle:Furygale Flocking=9 |
| Mizzix's Mastery | 196 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context, miracle_hit, paid_cast_exposure | cast_announced=4, cost_paid=4, miracle_cast=10, mizzix_mastery_copy_cast=2, mizzix_mastery_resolved=2, cost_paid:Mizzix's Mastery=126, discard_to_top:Mizzix's Mastery=36, lorehold_rummage_to_top:Mizzix's Mastery=18, miracle:Mizzix's Mastery=6, spell_rummage_to_top:Mizzix's Mastery=18 |
| Pinnacle Monk // Mystic Peak | 14 | `recursion_engine` | `review_required` | graveyard_recursion, paid_cast_exposure, spell_or_permanent_recursion | etb_recursion_resolved=1, spell_resolved=1, cost_paid:Pinnacle Monk // Mystic Peak=30 |

## Package Implications

- `volcanic_or_restoration_over_squee`: `blocked_until_non_squee_cut` - Squee has measured graveyard-return exposure and should remain protected.

## Samples

### Squee, Goblin Nabob

- Decision: `protect_current_engine`; next: do_not_cut_for_volcanic_or_restoration_without_non_squee_package
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[14]` turn `15` effect `` metric ``
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[1]` turn `12` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[2]` turn `12` effect `creature` metric ``
- `creature_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[3]` turn `12` effect `creature` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[14]` turn `15` effect `` metric ``
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[1]` turn `12` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[2]` turn `12` effect `creature` metric ``
- `creature_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[3]` turn `12` effect `creature` metric ``

### Volcanic Vision

- Decision: `needs_non_squee_cut`; next: find recursion cut that is not the protected Squee engine
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1.json` path `results[8].telemetry.top_cards[4]` turn `` effect `` metric `miracle:Volcanic Vision`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1_partial.json` path `results[8].telemetry.top_cards[4]` turn `` effect `` metric `miracle:Volcanic Vision`

### Restoration Seminar

- Decision: `needs_non_squee_cut`; next: find recursion cut that is not the protected Squee engine
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1.json` path `results[6].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Restoration Seminar`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1_partial.json` path `results[6].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Restoration Seminar`

### Farewell

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Aang, at the Crossroads #106 (real):2[23]` turn `14` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Winota, Joiner of Forces #39 (real):0[12]` turn `13` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849_brass_bounty_cut_boros_signet.json` path `results[0].telemetry.squee_game_traces.deck_6:Aang, at the Crossroads #106 (real):2[23]` turn `14` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849_brass_bounty_cut_boros_signet.json` path `results[1].telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Winota, Joiner of Forces #39 (real):0[12]` turn `13` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_gate_20260627_v1_games2_opp8_20260627_221429.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_ghostly_prison_pressure_cut_promise:Sisay, Weatherlight Captain #61 (real):0[5]` turn `6` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_gate_20260627_v1_games2_opp8_20260627_221429.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[5]` turn `6` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_gate_20260627_v1_games2_opp8_20260627_221429_ghostly_prison_pressure_cut_promise.json` path `results[1].telemetry.squee_game_traces.synergy_ghostly_prison_pressure_cut_promise:Sisay, Weatherlight Captain #61 (real):0[5]` turn `6` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_gate_20260627_v1_games2_opp8_20260627_221429_ghostly_prison_pressure_cut_promise.json` path `results[1].telemetry.squee_trace_samples[5]` turn `6` effect `` metric ``

### Furygale Flocking

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl` path `line:2` turn `9` effect `token_maker` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg091_token_maker_family_focused_events_20260623_093259.jsonl` path `line:3` turn `9` effect `token_maker` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json` path `packages[10].gate_summary.candidate.telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Furygale Flocking`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json` path `packages[4].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `miracle:Furygale Flocking`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_arcane_bombardment_engine.json` path `results[1].telemetry.top_cards[11]` turn `` effect `` metric `miracle:Furygale Flocking`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_arcane_bombardment_engine_partial.json` path `results[1].telemetry.top_cards[11]` turn `` effect `` metric `miracle:Furygale Flocking`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_dance_over_storm.json` path `results[1].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Furygale Flocking`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_dance_over_storm_partial.json` path `results[1].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Furygale Flocking`

### Mizzix's Mastery

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `mizzix_mastery_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:11` turn `6` effect `` metric ``
- `self_exiled_on_resolution` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:12` turn `6` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:6` turn `6` effect `overload_recursion` metric ``
- `mizzix_mastery_copy_cast` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:7` turn `6` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:3` turn `6` effect `overload_recursion` metric ``
- `mizzix_mastery_copy_cast` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:4` turn `6` effect `` metric ``
- `mizzix_mastery_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:5` turn `6` effect `` metric ``
- `miracle_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1002.jsonl` path `line:183` turn `9` effect `overload_recursion` metric ``

### Pinnacle Monk // Mystic Peak

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_607_608_pg080_pg081_focused_events_20260623_082229.jsonl` path `line:5` turn `5` effect `creature` metric ``
- `etb_recursion_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_607_608_pg080_pg081_focused_events_20260623_082229.jsonl` path `line:6` turn `5` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_ashling_equal_gate_rerun_20260626_221622_ashling_flame_dancer.json` path `results[1].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Pinnacle Monk // Mystic Peak`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_ashling_equal_gate_rerun_20260626_221622_ashling_flame_dancer_partial.json` path `results[1].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Pinnacle Monk // Mystic Peak`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_galvanoth_v1_galvanoth_v1_gate.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Pinnacle Monk // Mystic Peak`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_registry_candidate_runner_20260626_galvanoth_v1_galvanoth_v1_gate_partial.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Pinnacle Monk // Mystic Peak`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260625_v1.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Pinnacle Monk // Mystic Peak`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_rule_materialized_equal_gate_20260627_v1_20260627_162145_squee_goblin_nabob_partial.json` path `results[0].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Pinnacle Monk // Mystic Peak`
