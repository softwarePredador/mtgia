# Lorehold Card Exposure Profile - 2026-06-28

- Generated at: `2026-06-28T08:20:18Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Evidence paths scanned: `749`
- JSON files scanned: `513`
- JSONL files scanned: `236`
- Parse errors: `0`

## Card Profiles

| Card | Unique Exposure | Role | Decision | Signals | Top Events/Metrics |
| --- | ---: | --- | --- | --- | --- |
| Winds of Abandon | 60 | `spot_removal` | `review_required` | paid_cast_exposure, spot_removal | removal_resolved=3, replacement_applied=1, spell_resolved=3, cost_paid:Winds of Abandon=128 |
| Stroke of Midnight | 61 | `spot_removal` | `review_required` | miracle_hit, paid_cast_exposure, spot_removal | compensation_tokens_created=2, post_state=1, removal_resolved=2, replacement_applied=4, runtime_rule_loaded=1, cost_paid:Stroke of Midnight=56, miracle:Stroke of Midnight=47 |
| Generous Gift | 249 | `spot_removal` | `review_required` | miracle_hit, paid_cast_exposure, spot_removal, tutor_target | cast_announced=1, compensation_tokens_created=2, cost_paid=1, end_step_instant=6, miracle_cast=9, cost_paid:Generous Gift=425, discard_to_top:Generous Gift=3, lorehold_rummage_to_top:Generous Gift=3, miracle:Generous Gift=11 |
| Path to Exile | 412 | `spot_removal` | `review_required` | miracle_hit, paid_cast_exposure, spot_removal | cast_announced=10, cost_paid=9, end_step_instant=6, focused_final_state=1, instant_removal=2, cost_paid:Path to Exile=513, miracle:Path to Exile=6 |
| Swords to Plowshares | 228 | `spot_removal` | `review_required` | miracle_hit, paid_cast_exposure, spot_removal | cast_announced=3, cost_paid=4, end_step_instant=5, instant_removal=1, miracle_cast=9, cost_paid:Swords to Plowshares=189, miracle:Swords to Plowshares=8 |
| Esper Sentinel | 672 | `draw_filter_value` | `review_required` | draw_filter_value, paid_cast_exposure, tutor_target | cast_announced=12, cost_paid=11, permanent_moved_from_battlefield=4, pg073_rule_snapshot=1, pg073_rule_summary=1, cost_paid:Esper Sentinel=967 |
| Monument to Endurance | 375 | `discard_ramp_value` | `review_required` | discard_payoff, paid_cast_exposure, ramp_engine | cast_announced=4, cost_paid=4, discard_modal_trigger_resolved=98, priority_pass=13, removal_resolved=4, cost_paid:Monument to Endurance=603 |
| Smothering Tithe | 340 | `ramp_engine` | `review_required` | discard_or_rummage_context, paid_cast_exposure, ramp_engine, tutor_target | cast_announced=8, cost_paid=6, priority_pass=28, removal_resolved=1, spell_cast=62, cost_paid:Smothering Tithe=581 |
| Sensei's Divining Top | 1669 | `draw_filter_value` | `review_required` | draw_filter_value, paid_cast_exposure | activated_ability_skipped=4, cast_announced=5, cost_paid=423, priority_pass=18, saga_chapter_resolved=17, cost_paid:Sensei's Divining Top=1447, topdeck:Sensei's Divining Top=2968 |

## Package Implications


## Samples

### Winds of Abandon

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[1]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955_austere_command_wipe_over_emeria_tradeoff.json` path `results[1].telemetry.top_cards[1]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955_austere_command_wipe_over_emeria_tradeoff_partial.json` path `results[1].telemetry.top_cards[1]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_authority_equal_gate_20260626_230051_authority_of_the_consuls.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_authority_equal_gate_20260626_230051_authority_of_the_consuls_partial.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_ready_gate_20260628_v1_20260628_113500.json` path `packages[3].gate_summary.candidate.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Winds of Abandon`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_exposure_ready_gate_20260628_v1_20260628_113500_austere_command_wipe_over_emeria_tradeoff.json` path `results[1].telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Winds of Abandon`

### Stroke of Midnight

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `runtime_rule_loaded` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_061026.jsonl` path `line:5` turn `` effect `` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_061026.jsonl` path `line:6` turn `6` effect `` metric ``
- `compensation_tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_061026.jsonl` path `line:7` turn `6` effect `` metric ``
- `post_state` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_061026.jsonl` path `line:8` turn `` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:7` turn `5` effect `remove_permanent` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:8` turn `5` effect `` metric ``
- `compensation_tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:9` turn `5` effect `` metric ``
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_access_classification_gate_20260628_v1_20260628_121500.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[11]` turn `` effect `` metric `miracle:Stroke of Midnight`

### Generous Gift

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `runtime_rule_loaded` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_061026.jsonl` path `line:1` turn `` effect `` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_061026.jsonl` path `line:2` turn `6` effect `` metric ``
- `compensation_tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_061026.jsonl` path `line:3` turn `6` effect `` metric ``
- `post_state` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_061026.jsonl` path `line:4` turn `` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:2` turn `5` effect `remove_permanent` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:3` turn `5` effect `` metric ``
- `compensation_tokens_created` from `docs/hermes-analysis/master_optimizer_reports/deck607_pg089_l6_removal_compensation_focused_events_20260623_062000.jsonl` path `line:4` turn `5` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1002.jsonl` path `line:84` turn `5` effect `remove_permanent` metric ``

### Path to Exile

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `end_step_instant` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:521` turn `22` effect `remove_creature` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:522` turn `22` effect `remove_creature` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:523` turn `22` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1000.jsonl` path `line:113` turn `6` effect `remove_creature` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1000.jsonl` path `line:116` turn `6` effect `remove_creature` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1000.jsonl` path `line:117` turn `6` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1015.jsonl` path `line:53` turn `3` effect `remove_creature` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1015.jsonl` path `line:54` turn `3` effect `remove_creature` metric ``

### Swords to Plowshares

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `miracle_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:390` turn `19` effect `remove_creature` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:391` turn `19` effect `remove_creature` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:392` turn `19` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:173` turn `8` effect `remove_creature` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:177` turn `8` effect `remove_creature` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:178` turn `8` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1006.jsonl` path `line:193` turn `10` effect `remove_creature` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1006.jsonl` path `line:194` turn `10` effect `remove_creature` metric ``

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

### Smothering Tithe

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `trigger_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg066_birgi_smothering_focused_events_20260623_032200.jsonl` path `line:2` turn `6` effect `create_treasure` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:51` turn `3` effect `ramp_engine` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:176` turn `8` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:196` turn `9` effect `ramp_engine` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:260` turn `13` effect `` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1009.jsonl` path `line:255` turn `14` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_101.jsonl` path `line:260` turn `12` effect `ramp_engine` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1011.jsonl` path `line:114` turn `7` effect `ramp_engine` metric ``

### Sensei's Divining Top

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:495` turn `22` effect `topdeck_manipulation` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:500` turn `22` effect `topdeck_manipulation` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1007.jsonl` path `line:191` turn `9` effect `topdeck_manipulation` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1007.jsonl` path `line:192` turn `9` effect `topdeck_manipulation` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1008.jsonl` path `line:148` turn `8` effect `topdeck_manipulation` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1008.jsonl` path `line:153` turn `8` effect `topdeck_manipulation` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1008.jsonl` path `line:185` turn `9` effect `topdeck_manipulation` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1008.jsonl` path `line:187` turn `9` effect `topdeck_manipulation` metric ``
