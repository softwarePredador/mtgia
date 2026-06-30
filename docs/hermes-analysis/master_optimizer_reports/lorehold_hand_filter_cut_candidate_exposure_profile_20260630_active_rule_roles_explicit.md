# Lorehold Card Exposure Profile - 2026-06-28

- Generated at: `2026-06-30T08:08:56Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Evidence paths scanned: `255`
- JSON files scanned: `181`
- JSONL files scanned: `74`
- Parse errors: `0`

## Card Profiles

| Card | Unique Exposure | Role | Decision | Signals | Top Events/Metrics |
| --- | ---: | --- | --- | --- | --- |
| Apex of Power | 0 | `ramp_engine` | `review_required` | ramp_engine | none |
| Olórin's Searing Light | 8 | `spot_removal` | `review_required` | spot_removal | cost_paid=8 |
| Valakut Awakening // Valakut Stoneforge | 14 | `draw_filter_value` | `review_required` | draw_filter_value, paid_cast_exposure | cost_paid=4, hand_filter_resolved=4, runtime_rule_loaded=1, spell_resolved=4, cost_paid:Valakut Awakening // Valakut Stoneforge=3 |
| Wheel of Fortune | 6 | `draw_filter_value` | `review_required` | discard_payoff, draw_filter_value | cost_paid=4, spell_resolved=1, wheel_resolved=1 |
| Dance with Calamity | 0 | `draw_filter_value` | `review_required` | draw_filter_value, ramp_engine | none |

## Package Implications


## Samples

### Apex of Power

- Decision: `review_required`; next: connect role to an explicit package hypothesis

### Olórin's Searing Light

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_olorin_hand_filter_cut_improvisation_capstone_expanded607.json` path `results[1].telemetry.focus_card_game_traces.synergy_olorin_hand_filter_cut_improvisation_capstone_expanded607:K-9, Mark I #34 (real):2[72]` turn `11` effect `remove_creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_olorin_hand_filter_cut_improvisation_capstone_expanded607.json` path `results[1].telemetry.focus_card_game_traces.synergy_olorin_hand_filter_cut_improvisation_capstone_expanded607:Kinnan, Bonder Prodigy #72 (real):1[31]` turn `6` effect `remove_creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_olorin_hand_filter_cut_improvisation_capstone_expanded607.json` path `results[1].telemetry.focus_card_game_traces.synergy_olorin_hand_filter_cut_improvisation_capstone_expanded607:Rograkh, Son of Rohgahh #95 (real):0[83]` turn `15` effect `remove_creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_olorin_hand_filter_cut_improvisation_capstone_expanded607.json` path `results[1].telemetry.focus_card_game_traces.synergy_olorin_hand_filter_cut_improvisation_capstone_expanded607:Thrasios, Triton Hero #101 (real):0[49]` turn `8` effect `remove_creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_olorin_hand_filter_cut_improvisation_capstone_expanded607_partial.json` path `results[1].telemetry.focus_card_game_traces.synergy_olorin_hand_filter_cut_improvisation_capstone_expanded607:K-9, Mark I #34 (real):2[72]` turn `11` effect `remove_creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_olorin_hand_filter_cut_improvisation_capstone_expanded607_partial.json` path `results[1].telemetry.focus_card_game_traces.synergy_olorin_hand_filter_cut_improvisation_capstone_expanded607:Kinnan, Bonder Prodigy #72 (real):1[31]` turn `6` effect `remove_creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_olorin_hand_filter_cut_improvisation_capstone_expanded607_partial.json` path `results[1].telemetry.focus_card_game_traces.synergy_olorin_hand_filter_cut_improvisation_capstone_expanded607:Rograkh, Son of Rohgahh #95 (real):0[83]` turn `15` effect `remove_creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_olorin_hand_filter_cut_improvisation_capstone_expanded607_partial.json` path `results[1].telemetry.focus_card_game_traces.synergy_olorin_hand_filter_cut_improvisation_capstone_expanded607:Thrasios, Triton Hero #101 (real):0[49]` turn `8` effect `remove_creature` metric ``

### Valakut Awakening // Valakut Stoneforge

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `hand_filter_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:10` turn `4` effect `` metric ``
- `runtime_rule_loaded` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:4` turn `` effect `hand_filter` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_606_pg082_hash_only_focused_events_20260623_083100.jsonl` path `line:9` turn `4` effect `hand_filter` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl` path `line:13` turn `7` effect `hand_filter` metric ``
- `hand_filter_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_l2_hash_only_runtime_focused_events_20260623_011859.jsonl` path `line:14` turn `7` effect `` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:8` turn `4` effect `hand_filter` metric ``
- `hand_filter_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg077_runtime_events_20260623_062156.jsonl` path `line:9` turn `4` effect `` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_valakut_hand_filter_cut_improvisation_capstone_expanded607.json` path `results[1].telemetry.focus_card_game_traces.synergy_valakut_hand_filter_cut_improvisation_capstone_expanded607:Rograkh, Son of Rohgahh #95 (real):2[19]` turn `4` effect `hand_filter` metric ``

### Wheel of Fortune

- Decision: `review_required`; next: connect role to an explicit package hypothesis
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_wheel_hand_filter_cut_improvisation_capstone_expanded607.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kefka, Court Mage #112 (real):0[45]` turn `7` effect `draw_cards` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_wheel_hand_filter_cut_improvisation_capstone_expanded607.json` path `results[1].telemetry.focus_card_game_traces.synergy_wheel_hand_filter_cut_improvisation_capstone_expanded607:Kefka, Court Mage #112 (real):2[68]` turn `12` effect `draw_cards` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_wheel_hand_filter_cut_improvisation_capstone_expanded607_partial.json` path `results[0].telemetry.focus_card_game_traces.deck_607:Kefka, Court Mage #112 (real):0[45]` turn `7` effect `draw_cards` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110_wheel_hand_filter_cut_improvisation_capstone_expanded607_partial.json` path `results[1].telemetry.focus_card_game_traces.synergy_wheel_hand_filter_cut_improvisation_capstone_expanded607:Kefka, Court Mage #112 (real):2[68]` turn `12` effect `draw_cards` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_pg043_focused_events_20260622_231859.jsonl` path `line:3` turn `5` effect `draw_cards` metric ``
- `wheel_resolved` from `docs/hermes-analysis/master_optimizer_reports/wheel_of_fortune_pg043_focused_events_20260622_231859.jsonl` path `line:4` turn `5` effect `` metric ``

### Dance with Calamity

- Decision: `review_required`; next: connect role to an explicit package hypothesis
