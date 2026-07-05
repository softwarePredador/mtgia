# Lorehold Brain Cut-Slot Trace Miner

- Generated at: `2026-07-05T09:57:26Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `brain_cut_slot_trace_miner_found_floor_evidence_keep_607`
- Brain safe-cut gap status: `brain_safe_cut_gap_no_active_rule_no_seed_safe_cut_keep_607`
- Scanned gate reports: `966`
- Scanned game-result reports: `171`
- Target slots: `9`
- Slots with floor trace: `9`
- Slots without same-slot trace: `0`
- Same-slot 607-win/candidate-loss traces: `1435`
- Positive target-delta traces: `1128`
- Structure matrix allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Promotion allowed now: `false`
- Recommended next action: `feed_brain_cut_slot_traces_into_unlock_audit_keep_607`

## Target Floor Summaries

| Slot | Category | Status | Traces | Positive Delta | Event Total | Sources | Decision |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| Molecule Man | `prior_rejected_protected_slot` | `brain_cut_slot_floor_trace_found_cut_blocked` | 31 | 30 | 93 | 48 | `protect_brain_cut_slot_until_same_lane_replacement_preserves_floor` |
| The Scarlet Witch | `protected_structural_floor` | `brain_cut_slot_floor_trace_found_cut_blocked` | 165 | 146 | 504 | 104 | `protect_brain_cut_slot_until_same_lane_replacement_preserves_floor` |
| Library of Leng | `protected_core_topdeck_engine` | `brain_cut_slot_floor_trace_found_cut_blocked` | 118 | 86 | 354 | 94 | `protect_brain_cut_slot_until_same_lane_replacement_preserves_floor` |
| The Mind Stone | `protected_structural_floor` | `brain_cut_slot_floor_trace_found_cut_blocked` | 181 | 155 | 774 | 121 | `protect_brain_cut_slot_until_same_lane_replacement_preserves_floor` |
| Urza's Saga | `never_cut_mana_base` | `brain_cut_slot_floor_trace_found_cut_blocked` | 71 | 59 | 93 | 81 | `protect_brain_cut_slot_until_same_lane_replacement_preserves_floor` |
| Scroll Rack | `protected_core_topdeck_engine` | `brain_cut_slot_floor_trace_found_cut_blocked` | 188 | 177 | 1187 | 115 | `protect_brain_cut_slot_until_same_lane_replacement_preserves_floor` |
| Land Tax | `prior_rejected_protected_slot` | `brain_cut_slot_floor_trace_found_cut_blocked` | 146 | 120 | 438 | 104 | `protect_brain_cut_slot_until_same_lane_replacement_preserves_floor` |
| Sensei's Divining Top | `protected_core_topdeck_engine` | `brain_cut_slot_floor_trace_found_cut_blocked` | 145 | 133 | 1416 | 104 | `protect_brain_cut_slot_until_same_lane_replacement_preserves_floor` |
| Lorehold, the Historian | `never_cut_commander` | `brain_cut_slot_floor_trace_found_cut_blocked` | 390 | 222 | 670 | 126 | `protect_brain_cut_slot_until_same_lane_replacement_preserves_floor` |

## Example Traces

### Molecule Man

- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `K-9, Mark I #34 (real)` game `2` while 607 won; target delta `3`, 607 events `{"cost_paid:Molecule Man": 1, "spell_cast:Molecule Man": 1, "spell_resolved:Molecule Man": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed20260630_real8_games3.json`.
- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `Kefka, Court Mage #112 (real)` game `1` while 607 won; target delta `3`, 607 events `{"cost_paid:Molecule Man": 1, "spell_cast:Molecule Man": 1, "spell_resolved:Molecule Man": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed999_real8_games3.json`.
- `candidate_607_deflecting_palm_redirect_lightning_v1` lost to `K-9, Mark I #34 (real)` game `2` while 607 won; target delta `3`, 607 events `{"cost_paid:Molecule Man": 1, "spell_cast:Molecule Man": 1, "spell_resolved:Molecule Man": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json`.

### The Scarlet Witch

- `candidate_607_chaos_warp_stroke_of_midnight_v1` lost to `Kefka, Court Mage #112 (real)` game `2` while 607 won; target delta `4`, 607 events `{"cost_paid:The Scarlet Witch": 2, "spell_cast:The Scarlet Witch": 1, "spell_resolved:The Scarlet Witch": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_confirm_20260630_seed123_real8_games3.json`.
- `candidate_607_enlightened_tutor_insurrection_v1` lost to `Kefka, Court Mage #112 (real)` game `2` while 607 won; target delta `4`, 607 events `{"cost_paid:The Scarlet Witch": 2, "spell_cast:The Scarlet Witch": 1, "spell_resolved:The Scarlet Witch": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed123_real8_games3.json`.
- `candidate_607_grand_abolisher_tibalts_trickery_v1` lost to `Kinnan, Bonder Prodigy #84 (real)` game `0` while 607 won; target delta `4`, 607 events `{"cost_paid:The Scarlet Witch": 2, "spell_cast:The Scarlet Witch": 1, "spell_resolved:The Scarlet Witch": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_grand_abolisher_tibalt_gate_20260630_seed20260630_real8_games3.json`.

### Library of Leng

- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `Etali, Primal Conqueror #67 (real)` game `1` while 607 won; target delta `3`, 607 events `{"cost_paid:Library of Leng": 1, "spell_cast:Library of Leng": 1, "spell_resolved:Library of Leng": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_gate_20260630_seed20260630_real8_games3.json`.
- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `K-9, Mark I #34 (real)` game `0` while 607 won; target delta `3`, 607 events `{"cost_paid:Library of Leng": 1, "spell_cast:Library of Leng": 1, "spell_resolved:Library of Leng": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed999_real8_games3.json`.
- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `K-9, Mark I #34 (real)` game `1` while 607 won; target delta `3`, 607 events `{"cost_paid:Library of Leng": 1, "spell_cast:Library of Leng": 1, "spell_resolved:Library of Leng": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed999_real8_games3.json`.

### The Mind Stone

- `candidate_607_chaos_warp_stroke_of_midnight_v1` lost to `Thrasios, Triton Hero #76 (real)` game `2` while 607 won; target delta `13`, 607 events `{"cost_paid:The Mind Stone": 1, "spell_cast:The Mind Stone": 1, "trigger_resolved:The Mind Stone": 10, "utility_artifact_activated:The Mind Stone": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_gate_20260630_seed20260630_real8_games3.json`.
- `candidate_607_deflecting_palm_redirect_lightning_v1` lost to `Thrasios, Triton Hero #76 (real)` game `2` while 607 won; target delta `13`, 607 events `{"cost_paid:The Mind Stone": 1, "spell_cast:The Mind Stone": 1, "trigger_resolved:The Mind Stone": 10, "utility_artifact_activated:The Mind Stone": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json`.
- `candidate_607_enlightened_tutor_creative_technique_v1` lost to `Thrasios, Triton Hero #76 (real)` game `2` while 607 won; target delta `13`, 607 events `{"cost_paid:The Mind Stone": 1, "spell_cast:The Mind Stone": 1, "trigger_resolved:The Mind Stone": 10, "utility_artifact_activated:The Mind Stone": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json`.

### Urza's Saga

- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `Kefka, Court Mage #112 (real)` game `1` while 607 won; target delta `2`, 607 events `{"land_played:Urza's Saga": 1, "utility_land_activated:Urza's Saga": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed999_real8_games3.json`.
- `candidate_607_chaos_warp_stroke_of_midnight_v1` lost to `Thrasios, Triton Hero #76 (real)` game `2` while 607 won; target delta `2`, 607 events `{"land_played:Urza's Saga": 1, "utility_land_activated:Urza's Saga": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_confirm_20260630_seed123_real8_games3.json`.
- `candidate_607_enlightened_tutor_insurrection_v1` lost to `Kraum, Ludevic's Opus #81 (real)` game `2` while 607 won; target delta `2`, 607 events `{"land_played:Urza's Saga": 1, "utility_land_activated:Urza's Saga": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed999_real8_games3.json`.

### Scroll Rack

- `candidate_607_deflecting_palm_redirect_lightning_v1` lost to `Winota, Joiner of Forces #73 (real)` game `0` while 607 won; target delta `11`, 607 events `{"cost_paid:Scroll Rack": 1, "spell_cast:Scroll Rack": 1, "spell_resolved:Scroll Rack": 1, "topdeck_manipulation_activated:Scroll Rack": 8}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json`.
- `candidate_607_enlightened_tutor_insurrection_v1` lost to `Winota, Joiner of Forces #73 (real)` game `0` while 607 won; target delta `11`, 607 events `{"cost_paid:Scroll Rack": 1, "spell_cast:Scroll Rack": 1, "spell_resolved:Scroll Rack": 1, "topdeck_manipulation_activated:Scroll Rack": 8}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_insurrection_seed20260630_real8_games3.json`.
- `candidate_607_gamble_storm_herd_v1` lost to `Winota, Joiner of Forces #73 (real)` game `0` while 607 won; target delta `11`, 607 events `{"cost_paid:Scroll Rack": 1, "spell_cast:Scroll Rack": 1, "spell_resolved:Scroll Rack": 1, "topdeck_manipulation_activated:Scroll Rack": 8}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_gamble_gate_20260630_storm_herd_seed20260630_real8_games3.json`.

### Land Tax

- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `K-9, Mark I #34 (real)` game `2` while 607 won; target delta `3`, 607 events `{"cost_paid:Land Tax": 1, "spell_cast:Land Tax": 1, "spell_resolved:Land Tax": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed123_real8_games3.json`.
- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `K-9, Mark I #34 (real)` game `2` while 607 won; target delta `3`, 607 events `{"cost_paid:Land Tax": 1, "spell_cast:Land Tax": 1, "spell_resolved:Land Tax": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed999_real8_games3.json`.
- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `Thrasios, Triton Hero #101 (real)` game `0` while 607 won; target delta `3`, 607 events `{"cost_paid:Land Tax": 1, "spell_cast:Land Tax": 1, "spell_resolved:Land Tax": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed20260630_real8_games3.json`.

### Sensei's Divining Top

- `synergy_plateau_timing_upgrade_cut_turbulent_steppe` lost to `K-9, Mark I #34 (real)` game `2` while 607 won; target delta `30`, 607 events `{"cost_paid:Sensei's Divining Top": 6, "spell_cast:Sensei's Divining Top": 6, "spell_resolved:Sensei's Divining Top": 6, "topdeck_manipulation_activated:Sensei's Divining Top": 12}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_forced_exposure_probe_20260630_after_607_fix_20260630_043721_plateau_timing_upgrade_cut_turbulent_steppe.json`.
- `synergy_storm_kiln_artist_cut_arcane_signet` lost to `Winota, Joiner of Forces #73 (real)` game `0` while 607 won; target delta `27`, 607 events `{"cost_paid:Sensei's Divining Top": 6, "spell_cast:Sensei's Divining Top": 6, "spell_resolved:Sensei's Divining Top": 6, "topdeck_manipulation_activated:Sensei's Divining Top": 9}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_forced_exposure_probe_20260630_after_607_fix_20260630_043721_storm_kiln_artist_cut_arcane_signet.json`.
- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `K-9, Mark I #34 (real)` game `0` while 607 won; target delta `25`, 607 events `{"cost_paid:Sensei's Divining Top": 5, "spell_cast:Sensei's Divining Top": 5, "spell_resolved:Sensei's Divining Top": 5, "topdeck_manipulation_activated:Sensei's Divining Top": 10}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed123_real8_games3.json`.

### Lorehold, the Historian

- `candidate_607_silence_tibalts_trickery_v1` lost to `Thrasios, Triton Hero #76 (real)` game `2` while 607 won; target delta `5`, 607 events `{"cost_paid:Lorehold, the Historian": 5}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_silence_tibalt_confirm_20260630_seed123_real8_games3.json`.
- `synergy_chaos_warp_same_lane_benchmark_cut_generous_gift` lost to `Thrasios, Triton Hero #76 (real)` game `2` while 607 won; target delta `5`, 607 events `{"cost_paid:Lorehold, the Historian": 5}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_generous_gift_seed_matrix_20260630_goal_learning_confirm_seed123_chaos_warp_same_lane_benchmark_cut_generous_62cf3c52_20260630_205527_chaos_warp_same_lane_benchmark_cut_generous_gift.json`.
- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `Thrasios, Triton Hero #76 (real)` game `2` while 607 won; target delta `4`, 607 events `{"cost_paid:Lorehold, the Historian": 5}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed123_real8_games3.json`.

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- candidate_deck_materialization_allowed_now: `false`
- forced_access_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- postgres_writes_allowed: `false`
- reason: At least one Brain cut-slot card produced real 607 events in same-slot games where protected 607 won and a candidate lost. These rows protect the slot; they do not unlock Brain.
- next_actions:
  - feed_brain_cut_slot_traces_into_unlock_audit_keep_607
  - do_not_mutate_deck_607
  - do_not_treat_low_exposure_as_cut_safety
  - do_not_materialize_brain_candidate_deck_from_trace_rows
  - require active Brain rule and named same-lane seed-safe cut before matrix
