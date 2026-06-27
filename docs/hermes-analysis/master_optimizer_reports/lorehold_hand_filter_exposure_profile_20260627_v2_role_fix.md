# Lorehold Card Exposure Profile - 2026-06-27

- Generated at: `2026-06-27T23:44:22Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Evidence paths scanned: `626`
- JSON files scanned: `390`
- JSONL files scanned: `236`
- Parse errors: `0`

## Card Profiles

| Card | Unique Exposure | Role | Decision | Signals | Top Events/Metrics |
| --- | ---: | --- | --- | --- | --- |
| Apex of Power | 0 | `draw_filter_value` | `review_required` | draw_filter_value | none |
| Olórin's Searing Light | 2 | `draw_filter_value` | `review_required` | draw_filter_value, paid_cast_exposure | cost_paid:Olórin's Searing Light=2 |
| Valakut Awakening // Valakut Stoneforge | 85 | `draw_filter_value` | `review_required` | draw_filter_value, paid_cast_exposure | end_step_instant=9, hand_filter_resolved=7, miracle_cast=4, priority_pass=2, runtime_rule_loaded=1, cost_paid:Valakut Awakening // Valakut Stoneforge=3 |
| Wheel of Fortune | 86 | `draw_filter_value` | `review_required` | draw_filter_value, tutor_target | cast_announced=2, cost_paid=1, miracle_cast=9, priority_pass=8, spell_cast=26 |
| Dance with Calamity | 0 | `draw_filter_value` | `review_required` | draw_filter_value | none |
| Artist's Talent | 92 | `draw_filter_value` | `review_required` | draw_filter_value, paid_cast_exposure | permanent_moved_from_battlefield=2, spell_cast=5, spell_resolved=5, trigger_resolved=11, cost_paid:Artist's Talent=233 |
| Big Score | 34 | `runtime_ready_unexposed` | `review_required` | miracle_hit, paid_cast_exposure | additional_cost_paid=10, cost_paid:Big Score=34, miracle:Big Score=10 |
| Esper Sentinel | 610 | `draw_filter_value` | `review_required` | draw_filter_value, paid_cast_exposure, tutor_target | cast_announced=12, cost_paid=11, permanent_moved_from_battlefield=4, pg073_rule_snapshot=1, pg073_rule_summary=1, cost_paid:Esper Sentinel=835 |
| Monument to Endurance | 262 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cast_announced=4, cost_paid=4, discard_modal_trigger_resolved=14, priority_pass=13, removal_resolved=4, cost_paid:Monument to Endurance=540 |
| Rise of the Eldrazi | 206 | `tutor_target` | `review_required` | miracle_hit, tutor_target | cast_announced=1, composite_rule_component_resolved=5, composite_rule_resolved=5, miracle_cast=17, permanent_moved_from_battlefield=2, discard_to_top:Rise of the Eldrazi=90, lorehold_rummage_to_top:Rise of the Eldrazi=80, miracle:Rise of the Eldrazi=4, spell_rummage_to_top:Rise of the Eldrazi=10 |

## Package Implications


## Samples

### Apex of Power

- Decision: `review_required`; next: connect role to an explicit package hypothesis

### Olórin's Searing Light

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1.json` path `results[10].telemetry.top_cards[3]` turn `` effect `` metric `cost_paid:Olórin's Searing Light`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1_partial.json` path `results[10].telemetry.top_cards[3]` turn `` effect `` metric `cost_paid:Olórin's Searing Light`

### Valakut Awakening // Valakut Stoneforge

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `hand_filter_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:10` turn `4` effect `` metric ``
- `runtime_rule_loaded` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:4` turn `` effect `hand_filter` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:9` turn `4` effect `hand_filter` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl` path `line:13` turn `7` effect `hand_filter` metric ``
- `hand_filter_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl` path `line:14` turn `7` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:8` turn `4` effect `hand_filter` metric ``
- `hand_filter_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:9` turn `4` effect `` metric ``
- `end_step_instant` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:62` turn `3` effect `draw_cards` metric ``

### Wheel of Fortune

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1008.jsonl` path `line:150` turn `8` effect `draw_cards` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1008.jsonl` path `line:152` turn `8` effect `draw_cards` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1013.jsonl` path `line:192` turn `8` effect `draw_cards` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1013.jsonl` path `line:193` turn `8` effect `draw_cards` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1017.jsonl` path `line:158` turn `7` effect `draw_cards` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1017.jsonl` path `line:159` turn `7` effect `draw_cards` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1017.jsonl` path `line:190` turn `8` effect `draw_cards` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1017.jsonl` path `line:191` turn `8` effect `draw_cards` metric ``

### Dance with Calamity

- Decision: `review_required`; next: connect role to an explicit package hypothesis

### Artist's Talent

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_607_608_pg080_pg081_focused_events_20260623_082229.jsonl` path `line:4` turn `4` effect `rummage` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1013.jsonl` path `line:106` turn `5` effect `draw_engine` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1013.jsonl` path `line:107` turn `5` effect `draw_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1015.jsonl` path `line:249` turn `12` effect `draw_engine` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1015.jsonl` path `line:250` turn `12` effect `draw_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1017.jsonl` path `line:293` turn `14` effect `draw_engine` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1017.jsonl` path `line:294` turn `14` effect `draw_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1024.jsonl` path `line:116` turn `5` effect `draw_engine` metric ``

### Big Score

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v2.json` path `results[1].telemetry.top_cards[4]` turn `` effect `` metric `miracle:Big Score`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v2_partial.json` path `results[1].telemetry.top_cards[4]` turn `` effect `` metric `miracle:Big Score`
- `additional_cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_angel_grace_life_floor_cut_dawn:Sisay, Weatherlight Captain #61 (real):0[3]` turn `4` effect `` metric ``
- `additional_cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_angel_grace_life_floor_cut_dawn:Winota, Joiner of Forces #39 (real):2[7]` turn `9` effect `` metric ``
- `additional_cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[3]` turn `4` effect `` metric ``
- `additional_cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1_angel_grace_life_floor_cut_dawn.json` path `results[1].telemetry.squee_game_traces.synergy_angel_grace_life_floor_cut_dawn:Sisay, Weatherlight Captain #61 (real):0[3]` turn `4` effect `` metric ``
- `additional_cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1_angel_grace_life_floor_cut_dawn.json` path `results[1].telemetry.squee_game_traces.synergy_angel_grace_life_floor_cut_dawn:Winota, Joiner of Forces #39 (real):2[7]` turn `9` effect `` metric ``
- `additional_cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1_angel_grace_life_floor_cut_dawn.json` path `results[1].telemetry.squee_trace_samples[3]` turn `4` effect `` metric ``

### Esper Sentinel

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_card_flow_focused_events_20260623_051141.jsonl` path `line:2` turn `4` effect `draw_cards` metric ``
- `pg073_rule_snapshot` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl` path `line:1` turn `` effect `draw_engine` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl` path `line:2` turn `4` effect `draw_cards` metric ``
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl` path `line:3` turn `5` effect `draw_cards` metric ``
- `pg073_rule_summary` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg073_l4_l6_card_flow_focused_events_20260623_052954.jsonl` path `line:4` turn `` effect `` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg076_support_passive_annotation_focused_events_20260623_054358.jsonl` path `line:6` turn `6` effect `` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_recruiter_guard_pg064_focused_events_20260623_025848.jsonl` path `line:3` turn `3` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:413` turn `20` effect `draw_engine` metric ``

### Monument to Endurance

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:48` turn `3` effect `ramp_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_101.jsonl` path `line:87` turn `5` effect `ramp_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1010.jsonl` path `line:107` turn `6` effect `ramp_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1014.jsonl` path `line:42` turn `3` effect `ramp_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1023.jsonl` path `line:45` turn `3` effect `ramp_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_104.jsonl` path `line:102` turn `6` effect `ramp_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_201.jsonl` path `line:336` turn `15` effect `ramp_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_203.jsonl` path `line:347` turn `20` effect `ramp_engine` metric ``

### Rise of the Eldrazi

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `composite_rule_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:11` turn `9` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:6` turn `9` effect `composite_resolution` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:7` turn `9` effect `` metric ``
- `composite_rule_component_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:8` turn `9` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:10` turn `9` effect `composite_resolution` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:11` turn `9` effect `` metric ``
- `composite_rule_component_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:12` turn `9` effect `` metric ``
- `composite_rule_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:15` turn `9` effect `` metric ``
