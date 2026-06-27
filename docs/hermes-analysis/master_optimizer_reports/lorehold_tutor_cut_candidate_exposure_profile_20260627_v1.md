# Lorehold Card Exposure Profile - 2026-06-27

- Generated at: `2026-06-27T23:51:43Z`
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
| Gamble | 228 | `tutor_access` | `runtime_ready_cut_sensitive` | paid_cast_exposure, tutor_access, tutor_target | cast_announced=10, cost_paid=8, miracle_cast=7, priority_pass=45, random_discard_after_tutor=6, cost_paid:Gamble=2 |
| Enlightened Tutor | 202 | `tutor_access` | `runtime_ready_cut_sensitive` | paid_cast_exposure, tutor_access | cast_announced=6, cost_paid=5, end_step_instant=7, miracle_cast=6, priority_pass=24, cost_paid:Enlightened Tutor=18 |
| Land Tax | 296 | `tutor_access` | `review_required` | paid_cast_exposure, tutor_access | cast_announced=6, cost_paid=6, land_tax_trigger_resolved=1, priority_pass=23, spell_cast=41, cost_paid:Land Tax=430 |
| Library of Leng | 91 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context, paid_cast_exposure | cast_announced=1, cost_paid=1, priority_pass=4, runtime_rule_loaded=1, spell_cast=1, cost_paid:Library of Leng=263 |
| Scroll Rack | 788 | `tutor_target` | `review_required` | paid_cast_exposure, tutor_target | activated_ability_skipped=40, cast_announced=10, cost_paid=8, priority_pass=40, runtime_rule_loaded=1, cost_paid:Scroll Rack=203, topdeck:Scroll Rack=1915 |
| Sensei's Divining Top | 626 | `draw_filter_value` | `review_required` | draw_filter_value, paid_cast_exposure | activated_ability_skipped=4, cast_announced=5, cost_paid=4, priority_pass=18, spell_cast=39, cost_paid:Sensei's Divining Top=1079, topdeck:Sensei's Divining Top=2373 |
| The Mind Stone | 110 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | permanent_moved_from_battlefield=2, trigger_resolved=4, utility_artifact_activated=2, cost_paid:The Mind Stone=318 |
| Sol Ring | 369 | `tutor_target` | `review_required` | paid_cast_exposure, tutor_target | cast_announced=26, cost_paid=24, etb_removal_resolved=2, permanent_moved_from_battlefield=2, removal_resolved=4, cost_paid:Sol Ring=412 |
| Arcane Signet | 263 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cast_announced=9, cost_paid=6, removal_resolved=1, spell_cast=103, spell_resolved=4, cost_paid:Arcane Signet=356 |
| Boros Signet | 109 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cast_announced=1, cost_paid=1, spell_cast=30, spell_resolved=1, cost_paid:Boros Signet=219 |
| Fellwar Stone | 237 | `tutor_target` | `review_required` | paid_cast_exposure, tutor_target | cast_announced=9, cost_paid=8, removal_resolved=2, spell_cast=80, spell_resolved=8, cost_paid:Fellwar Stone=380 |
| Jeska's Will | 161 | `tutor_target` | `review_required` | miracle_hit, paid_cast_exposure, tutor_target | cast_announced=2, cost_paid=1, jeskas_will_resolved=6, miracle_cast=9, priority_pass=16, cost_paid:Jeska's Will=122, discard_to_top:Jeska's Will=12, lorehold_rummage_to_top:Jeska's Will=12, miracle:Jeska's Will=5 |
| Talisman of Conviction | 193 | `runtime_ready_unexposed` | `review_required` | paid_cast_exposure | cast_announced=4, cost_paid=3, permanent_moved_from_battlefield=2, removal_resolved=2, spell_cast=40, cost_paid:Talisman of Conviction=419 |
| Tragic Arrogance | 202 | `board_wipe_pressure_reset` | `review_required` | discard_or_rummage_context, miracle_hit, paid_cast_exposure, pressure_reset_board_wipe | board_wipe_resolved=91, permanent_moved_from_battlefield=95, turn_end=6, cost_paid:Tragic Arrogance=2, discard_to_top:Tragic Arrogance=16, miracle:Tragic Arrogance=5, spell_rummage_to_top:Tragic Arrogance=16 |
| Molecule Man | 5 | `runtime_ready_unexposed` | `review_required` | discard_or_rummage_context, paid_cast_exposure | turn_end=2, cost_paid:Molecule Man=5 |
| Creative Technique | 32 | `draw_filter_value` | `review_required` | discard_or_rummage_context, draw_filter_value, paid_cast_exposure | demonstrate_resolved=2, top_nonland_free_cast=4, top_nonland_free_cast_resolved=2, turn_end=16, cost_paid:Creative Technique=8, discard_to_top:Creative Technique=6, lorehold_rummage_to_top:Creative Technique=6 |
| Thor, God of Thunder | 11 | `unproven_or_unmodeled` | `blocked_runtime_gap` | paid_cast_exposure | cost_paid:Thor, God of Thunder=9, spell_cast:Thor, God of Thunder=3, thor_noncreature_damage_amount:Thor, God of Thunder=14 |

## Package Implications

- `tutor_access`: `seed_safe_cut_required` - Tutor effects are modelable, but promotion depends on a cut model that preserves the known strong seed.

## Samples

### Gamble

- Decision: `runtime_ready_cut_sensitive`; next: retest only with seed-safe cut model
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl` path `line:4` turn `3` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl` path `line:5` turn `3` effect `` metric ``
- `random_discard_after_tutor` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl` path `line:6` turn `3` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:29` turn `2` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:30` turn `2` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:31` turn `2` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1005.jsonl` path `line:5` turn `1` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1005.jsonl` path `line:6` turn `1` effect `tutor` metric ``

### Enlightened Tutor

- Decision: `runtime_ready_cut_sensitive`; next: retest only with seed-safe cut model
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:174` turn `8` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:175` turn `8` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:176` turn `8` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:257` turn `13` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:259` turn `13` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:260` turn `13` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_101.jsonl` path `line:261` turn `12` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_101.jsonl` path `line:262` turn `12` effect `tutor` metric ``

### Land Tax

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:491` turn `22` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:493` turn `22` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:494` turn `22` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:23` turn `2` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:24` turn `2` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:25` turn `2` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1002.jsonl` path `line:137` turn `7` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1002.jsonl` path `line:140` turn `7` effect `tutor` metric ``

### Library of Leng

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `runtime_rule_loaded` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:1` turn `` effect `passive` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v2.json` path `results[1].telemetry.top_cards[1]` turn `` effect `` metric `cost_paid:Library of Leng`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v2_partial.json` path `results[1].telemetry.top_cards[1]` turn `` effect `` metric `cost_paid:Library of Leng`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_reprieve_v1.json` path `results[1].telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Library of Leng`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_reprieve_v1_partial.json` path `results[1].telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Library of Leng`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[5]` turn `` effect `` metric `cost_paid:Library of Leng`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Library of Leng`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849_brass_bounty_cut_boros_signet.json` path `results[0].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:Library of Leng`

### Scroll Rack

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `runtime_rule_loaded` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:2` turn `` effect `topdeck_manipulation` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl` path `line:16` turn `7` effect `topdeck_manipulation` metric ``
- `topdeck_manipulation_activated` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:10` turn `6` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:306` turn `15` effect `topdeck_manipulation` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:307` turn `15` effect `topdeck_manipulation` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:26` turn `2` effect `topdeck_manipulation` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:27` turn `2` effect `topdeck_manipulation` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:5` turn `1` effect `topdeck_manipulation` metric ``

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

### The Mind Stone

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v1.json` path `results[1].telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:The Mind Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v1_partial.json` path `results[1].telemetry.top_cards[7]` turn `` effect `` metric `cost_paid:The Mind Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v2.json` path `results[1].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:The Mind Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_bridge_battle_gate_20260626_v2_partial.json` path `results[1].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:The Mind Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_birgi_v1_post_molecule.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:The Mind Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_birgi_v1_post_molecule_partial.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:The Mind Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_longshot_v1.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:The Mind Stone`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_longshot_v1_partial.json` path `results[1].telemetry.top_cards[10]` turn `` effect `` metric `cost_paid:The Mind Stone`

### Sol Ring

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg078_l2_hash_scope_restore_focused_events_20260623_063535.jsonl` path `line:12` turn `4` effect `` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:17` turn `6` effect `` metric ``
- `etb_removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_high_battle_critical_focused_events_20260623_075434.jsonl` path `line:18` turn `6` effect `` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:23` turn `6` effect `` metric ``
- `etb_removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck606_pg079_runtime_semantics_focused_events_20260623_045814.jsonl` path `line:24` turn `6` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:427` turn `20` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:16` turn `1` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1002.jsonl` path `line:83` turn `5` effect `ramp_permanent` metric ``

### Arcane Signet

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:127` turn `6` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:126` turn `6` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:129` turn `7` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1005.jsonl` path `line:279` turn `14` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1007.jsonl` path `line:184` turn `8` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1007.jsonl` path `line:30` turn `2` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1009.jsonl` path `line:224` turn `12` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_101.jsonl` path `line:45` turn `2` effect `ramp_permanent` metric ``

### Boros Signet

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:28` turn `2` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1017.jsonl` path `line:163` turn `7` effect `ramp_permanent` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1017.jsonl` path `line:164` turn `7` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1021.jsonl` path `line:27` turn `2` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1023.jsonl` path `line:117` turn `6` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_104.jsonl` path `line:214` turn `11` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_201.jsonl` path `line:112` turn `6` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_203.jsonl` path `line:325` turn `19` effect `ramp_permanent` metric ``

### Fellwar Stone

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl` path `line:3` turn `7` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:429` turn `20` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1002.jsonl` path `line:160` turn `8` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:201` turn `10` effect `ramp_permanent` metric ``
- `removal_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:39` turn `2` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:5` turn `1` effect `ramp_permanent` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:6` turn `1` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:167` turn `6` effect `ramp_permanent` metric ``

### Jeska's Will

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:3` turn `5` effect `ramp_ritual` metric ``
- `jeskas_will_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_l4_battle_support_focused_events_20260623_062422.jsonl` path `line:4` turn `5` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:1` turn `5` effect `ramp_ritual` metric ``
- `jeskas_will_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:2` turn `5` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:74` turn `4` effect `ramp_ritual` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:92` turn `4` effect `ramp_ritual` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1005.jsonl` path `line:58` turn `3` effect `ramp_ritual` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_101.jsonl` path `line:184` turn `9` effect `ramp_ritual` metric ``

### Talisman of Conviction

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:126` turn `6` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1000.jsonl` path `line:35` turn `2` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1003.jsonl` path `line:154` turn `8` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:124` turn `5` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1011.jsonl` path `line:256` turn `14` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1013.jsonl` path `line:168` turn `7` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1015.jsonl` path `line:117` turn `6` effect `ramp_permanent` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1015.jsonl` path `line:243` turn `12` effect `ramp_permanent` metric ``

### Tragic Arrogance

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[7]` turn `` effect `` metric `miracle:Tragic Arrogance`
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Vivi Ornitier #99 (real):2[5]` turn `19` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.candidate.telemetry.squee_trace_samples[5]` turn `19` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge_core_challenge_dance_over_storm.json` path `results[1].telemetry.squee_game_traces.synergy_core_challenge_dance_over_storm:Vivi Ornitier #99 (real):2[5]` turn `19` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge_core_challenge_dance_over_storm.json` path `results[1].telemetry.squee_trace_samples[5]` turn `19` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[6]` turn `7` effect `` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):1[7]` turn `7` effect `` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_finalizer_benchmark_gate_20260627_v1_seed42_hash0_isolated_timeout_storm_challenge.json` path `packages[1].gate_summary.candidate.telemetry.squee_game_traces.synergy_core_challenge_aetherflux_over_storm:Sisay, Weatherlight Captain #61 (real):1[36]` turn `15` effect `` metric ``

### Molecule Man

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_integration_gate_20260627_v2_seed314_games3_opp8_20260627_223721.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_ghostly_prison_pressure_cut_promise:Kenrith, the Returned King #113 (real):1[27]` turn `9` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_ghostly_promise_integration_gate_20260627_v2_seed314_games3_opp8_20260627_223721_ghostly_prison_pressure_cut_promise.json` path `results[1].telemetry.squee_game_traces.synergy_ghostly_prison_pressure_cut_promise:Kenrith, the Returned King #113 (real):1[27]` turn `9` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260627_v1.json` path `results[2].telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Molecule Man`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_thor_synced_rule_gate_20260627_seed13_v1.json` path `results[0].telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Molecule Man`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_thor_synced_rule_gate_20260627_seed13_v1_partial.json` path `results[0].telemetry.top_cards[11]` turn `` effect `` metric `cost_paid:Molecule Man`

### Creative Technique

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_one_ring_protection_draw_cut_squelcher:Sisay, Weatherlight Captain #61 (real):0[7]` turn `4` effect `` metric ``
- `top_nonland_free_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_one_ring_protection_draw_cut_squelcher:Winota, Joiner of Forces #39 (real):1[2]` turn `7` effect `` metric ``
- `top_nonland_free_cast_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_one_ring_protection_draw_cut_squelcher:Winota, Joiner of Forces #39 (real):1[6]` turn `7` effect `` metric ``
- `demonstrate_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_one_ring_protection_draw_cut_squelcher:Winota, Joiner of Forces #39 (real):1[7]` turn `7` effect `` metric ``
- `top_nonland_free_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[18]` turn `7` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[7]` turn `4` effect `` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1_one_ring_protection_draw_cut_squelcher.json` path `results[1].telemetry.squee_game_traces.synergy_one_ring_protection_draw_cut_squelcher:Sisay, Weatherlight Captain #61 (real):0[7]` turn `4` effect `` metric ``
- `top_nonland_free_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_library_pressure_conversion_gate_20260627_seed20260625_v1_library_pressure_v1_one_ring_protection_draw_cut_squelcher.json` path `results[1].telemetry.squee_game_traces.synergy_one_ring_protection_draw_cut_squelcher:Winota, Joiner of Forces #39 (real):1[2]` turn `7` effect `` metric ``

### Thor, God of Thunder

- Decision: `blocked_runtime_gap`; next: implement or sync active rule before gate
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Thor, God of Thunder`
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` path `packages[0].gate_summary.candidate.telemetry.top_cards[7]` turn `` effect `` metric `spell_cast:Thor, God of Thunder`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955_austere_command_wipe_over_emeria_tradeoff.json` path `results[1].telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Thor, God of Thunder`
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955_austere_command_wipe_over_emeria_tradeoff.json` path `results[1].telemetry.top_cards[7]` turn `` effect `` metric `spell_cast:Thor, God of Thunder`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955_austere_command_wipe_over_emeria_tradeoff_partial.json` path `results[1].telemetry.top_cards[6]` turn `` effect `` metric `cost_paid:Thor, God of Thunder`
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955_austere_command_wipe_over_emeria_tradeoff_partial.json` path `results[1].telemetry.top_cards[7]` turn `` effect `` metric `spell_cast:Thor, God of Thunder`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_sun_titan_noncore_v1_20260627_120928.json` path `packages[1].gate_summary.candidate.telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Thor, God of Thunder`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_synergy_package_gate_20260627_sun_titan_noncore_v1_20260627_120928_sun_titan_cut_chimes.json` path `results[1].telemetry.top_cards[4]` turn `` effect `` metric `cost_paid:Thor, God of Thunder`
