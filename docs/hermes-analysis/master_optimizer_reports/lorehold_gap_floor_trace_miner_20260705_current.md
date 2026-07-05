# Lorehold Gap Floor Trace Miner

- Generated at: `2026-07-05T08:07:46Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `gap_floor_trace_miner_found_floor_evidence_keep_607`
- Scanned gate reports: `953`
- Scanned game-result reports: `171`
- Target cards: `6`
- Targets with floor trace: `6`
- Same-slot 607-win/candidate-loss traces: `540`
- Positive target-delta traces: `520`
- Structure matrix allowed now: `false`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Promotion allowed now: `false`
- Recommended next action: `feed_floor_trace_blockers_back_into_cut_models_before_structure_matrix`

## Target Floor Summaries

| Card | Status | Traces | Positive Delta | Event Total | Sources | Decision |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| Call Forth the Tempest | `floor_trace_found_cut_blocked` | 58 | 58 | 872 | 75 | `protect_cut_slot_until_same_lane_replacement_preserves_floor` |
| Hit the Mother Lode | `floor_trace_found_cut_blocked` | 45 | 44 | 119 | 55 | `protect_cut_slot_until_same_lane_replacement_preserves_floor` |
| Everything Comes to Dust | `floor_trace_found_cut_blocked` | 102 | 102 | 905 | 93 | `protect_cut_slot_until_same_lane_replacement_preserves_floor` |
| Rise of the Eldrazi | `floor_trace_found_cut_blocked` | 68 | 67 | 204 | 76 | `protect_cut_slot_until_same_lane_replacement_preserves_floor` |
| Surge to Victory | `floor_trace_found_cut_blocked` | 112 | 111 | 983 | 104 | `protect_cut_slot_until_same_lane_replacement_preserves_floor` |
| Esper Sentinel | `floor_trace_found_cut_blocked` | 155 | 138 | 813 | 103 | `protect_cut_slot_until_same_lane_replacement_preserves_floor` |

## Example Traces

### Call Forth the Tempest

- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `Thrasios, Triton Hero #101 (real)` game `2` while 607 won; target delta `48`, 607 events `{"spell_cast:Call Forth the Tempest": 24, "spell_resolved:Call Forth the Tempest": 24}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed20260630_real8_games3.json`.
- `candidate_607_gamble_storm_herd_v1` lost to `Thrasios, Triton Hero #101 (real)` game `2` while 607 won; target delta `48`, 607 events `{"spell_cast:Call Forth the Tempest": 24, "spell_resolved:Call Forth the Tempest": 24}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_gamble_gate_20260630_storm_herd_seed20260630_real8_games3.json`.
- `candidate_607_one_ring_improvisation_capstone_v1` lost to `Thrasios, Triton Hero #101 (real)` game `2` while 607 won; target delta `48`, 607 events `{"spell_cast:Call Forth the Tempest": 24, "spell_resolved:Call Forth the Tempest": 24}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_improvisation_capstone_seed20260630_real8_games3.json`.

### Hit the Mother Lode

- `deck_615` lost to `Vivi Ornitier #99 (real)` game `1` while 607 won; target delta `6`, 607 events `{"miracle_cast:Hit the Mother Lode": 1, "spell_cast:Hit the Mother Lode": 2, "spell_resolved:Hit the Mother Lode": 3}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_gate_607_614_615_20260629_seed42_real8_games3.json`.
- `candidate_607_chaos_warp_stroke_of_midnight_v1` lost to `Thrasios, Triton Hero #101 (real)` game `2` while 607 won; target delta `5`, 607 events `{"cost_paid:Hit the Mother Lode": 1, "miracle_cast:Hit the Mother Lode": 1, "spell_cast:Hit the Mother Lode": 1, "spell_resolved:Hit the Mother Lode": 2}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_chaos_warp_stroke_confirm_20260630_seed123_real8_games3.json`.
- `candidate_607_one_ring_creative_technique_v1` lost to `Thrasios, Triton Hero #101 (real)` game `2` while 607 won; target delta `5`, 607 events `{"cost_paid:Hit the Mother Lode": 1, "miracle_cast:Hit the Mother Lode": 1, "spell_cast:Hit the Mother Lode": 1, "spell_resolved:Hit the Mother Lode": 2}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_creative_technique_seed123_real8_games3.json`.

### Everything Comes to Dust

- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `Winota, Joiner of Forces #73 (real)` game `1` while 607 won; target delta `24`, 607 events `{"board_wipe_resolved:Everything Comes to Dust": 8, "miracle_cast:Everything Comes to Dust": 1, "spell_cast:Everything Comes to Dust": 7, "spell_resolved:Everything Comes to Dust": 8}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed20260630_real8_games3.json`.
- `candidate_607_deflecting_palm_redirect_lightning_v1` lost to `Winota, Joiner of Forces #73 (real)` game `1` while 607 won; target delta `24`, 607 events `{"board_wipe_resolved:Everything Comes to Dust": 8, "miracle_cast:Everything Comes to Dust": 1, "spell_cast:Everything Comes to Dust": 7, "spell_resolved:Everything Comes to Dust": 8}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json`.
- `candidate_607_gamble_storm_herd_v1` lost to `Winota, Joiner of Forces #73 (real)` game `1` while 607 won; target delta `24`, 607 events `{"board_wipe_resolved:Everything Comes to Dust": 8, "miracle_cast:Everything Comes to Dust": 1, "spell_cast:Everything Comes to Dust": 7, "spell_resolved:Everything Comes to Dust": 8}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_gamble_gate_20260630_storm_herd_seed20260630_real8_games3.json`.

### Rise of the Eldrazi

- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `K-9, Mark I #34 (real)` game `2` while 607 won; target delta `3`, 607 events `{"miracle_cast:Rise of the Eldrazi": 1, "removal_resolved:Rise of the Eldrazi": 1, "spell_resolved:Rise of the Eldrazi": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed20260630_real8_games3.json`.
- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `Winota, Joiner of Forces #73 (real)` game `1` while 607 won; target delta `3`, 607 events `{"miracle_cast:Rise of the Eldrazi": 1, "removal_resolved:Rise of the Eldrazi": 1, "spell_resolved:Rise of the Eldrazi": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed20260630_real8_games3.json`.
- `candidate_607_deflecting_palm_redirect_lightning_v1` lost to `K-9, Mark I #34 (real)` game `2` while 607 won; target delta `3`, 607 events `{"miracle_cast:Rise of the Eldrazi": 1, "removal_resolved:Rise of the Eldrazi": 1, "spell_resolved:Rise of the Eldrazi": 1}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_deflecting_palm_redirect_lightning_gate_20260630_seed20260630_real8_games3.json`.

### Surge to Victory

- `candidate_607_boros_charm_tibalts_trickery_v1` lost to `Thrasios, Triton Hero #101 (real)` game `2` while 607 won; target delta `27`, 607 events `{"cost_paid:Surge to Victory": 1, "spell_cast:Surge to Victory": 1, "spell_resolved:Surge to Victory": 1, "trigger_resolved:Surge to Victory": 24}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_boros_charm_tibalt_confirm_20260630_seed20260630_real8_games3.json`.
- `candidate_607_gamble_storm_herd_v1` lost to `Thrasios, Triton Hero #101 (real)` game `2` while 607 won; target delta `27`, 607 events `{"cost_paid:Surge to Victory": 1, "spell_cast:Surge to Victory": 1, "spell_resolved:Surge to Victory": 1, "trigger_resolved:Surge to Victory": 24}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_gamble_gate_20260630_storm_herd_seed20260630_real8_games3.json`.
- `candidate_607_one_ring_improvisation_capstone_v1` lost to `Thrasios, Triton Hero #101 (real)` game `2` while 607 won; target delta `27`, 607 events `{"cost_paid:Surge to Victory": 1, "spell_cast:Surge to Victory": 1, "spell_resolved:Surge to Victory": 1, "trigger_resolved:Surge to Victory": 24}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_one_ring_gate_20260630_improvisation_capstone_seed20260630_real8_games3.json`.

### Esper Sentinel

- `deck_614` lost to `Aang, at the Crossroads #106 (real)` game `0` while 607 won; target delta `12`, 607 events `{"cost_paid:Esper Sentinel": 1, "spell_cast:Esper Sentinel": 1, "spell_resolved:Esper Sentinel": 1, "trigger_resolved:Esper Sentinel": 9}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_gate_607_614_615_20260629_seed7_real8_games3.json`.
- `deck_615` lost to `Aang, at the Crossroads #106 (real)` game `0` while 607 won; target delta `12`, 607 events `{"cost_paid:Esper Sentinel": 1, "spell_cast:Esper Sentinel": 1, "spell_resolved:Esper Sentinel": 1, "trigger_resolved:Esper Sentinel": 9}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_promotion_gate_607_614_615_20260629_seed7_real8_games3.json`.
- `candidate_607_enlightened_tutor_creative_technique_v1` lost to `Thrasios, Triton Hero #101 (real)` game `1` while 607 won; target delta `11`, 607 events `{"cost_paid:Esper Sentinel": 1, "spell_cast:Esper Sentinel": 1, "spell_resolved:Esper Sentinel": 1, "trigger_resolved:Esper Sentinel": 8}`, source `docs/hermes-analysis/master_optimizer_reports/lorehold_enlightened_tutor_gate_20260630_creative_technique_seed20260630_real8_games3.json`.

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- candidate_deck_materialization_allowed_now: `false`
- forced_access_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: At least one unprobed gap card has same-slot evidence where protected 607 won, a candidate lost, and the gap card produced real 607 events. These rows become cut blockers, not candidate materialization rows.
- next_actions:
  - feed_floor_trace_blockers_back_into_cut_models_before_structure_matrix
  - do_not_mutate_deck_607
  - do_not_treat_low_exposure_as_cut_safety
  - do_not_materialize_candidate_deck_from_floor_trace_rows
  - require same-lane replacement trace before any structure matrix row
