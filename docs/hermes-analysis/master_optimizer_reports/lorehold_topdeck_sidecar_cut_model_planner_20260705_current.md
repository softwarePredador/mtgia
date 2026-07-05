# Lorehold Topdeck Sidecar Cut Model Planner

- Generated at: `2026-07-05T06:41:07Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Status: `topdeck_sidecar_cut_model_planner_review_probes_ready_no_safe_cut_keep_607`
- Target rows: `12`
- Named cut probes: `48`
- Safe-cut ready count: `0`
- Matrix candidate rows eligible: `0`
- Candidate deck materialization allowed now: `false`
- Natural battle gate allowed now: `false`
- Recommended next action: `collect_probe_evidence_for_named_topdeck_and_mana_cuts`

## Source Reports

- `safe_cut_miner`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_safe_cut_miner_20260705_current.json`
- `sidecar_queue`: `docs/hermes-analysis/master_optimizer_reports/lorehold_topdeck_sidecar_candidate_queue_20260705_current.json`
- `value_model`: `docs/hermes-analysis/master_optimizer_reports/lorehold_deckbuilding_value_model_20260704_current.json`

## Probe Summary

- tag_counts: `{"mana_base_safe_cut_model": 7, "topdeck_access_sidecar_primary": 5}`
- blocker_counts: `{"mana_source_floor_equivalence_required": 28, "miracle_topdeck_floor_equivalence_required": 20, "requires_exposure_trace_before_safe_cut": 48, "safe_cut_miner_zero_current_ready": 48, "structural_floor_equivalence_required": 28}`

## Cut Model Targets

### Boros Garrison
- sidecar_tag: `mana_base_safe_cut_model`
- named_cut_probe_count: `4`
- target_cut_lanes: `land, mana_base`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Mountain // Mountain | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Plains // Plains | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Ancient Tomb | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Battlefield Forge | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
### Boseiju, Who Shelters All
- sidecar_tag: `mana_base_safe_cut_model`
- named_cut_probe_count: `4`
- target_cut_lanes: `land, mana_base`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Mountain // Mountain | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Plains // Plains | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Ancient Tomb | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Battlefield Forge | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
### Cavern of Souls
- sidecar_tag: `mana_base_safe_cut_model`
- named_cut_probe_count: `4`
- target_cut_lanes: `land, mana_base`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Mountain // Mountain | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Plains // Plains | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Ancient Tomb | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Battlefield Forge | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
### Clifftop Retreat
- sidecar_tag: `mana_base_safe_cut_model`
- named_cut_probe_count: `4`
- target_cut_lanes: `land, mana_base`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Mountain // Mountain | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Plains // Plains | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Ancient Tomb | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Battlefield Forge | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
### Plateau
- sidecar_tag: `mana_base_safe_cut_model`
- named_cut_probe_count: `4`
- target_cut_lanes: `land, mana_base`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Mountain // Mountain | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Plains // Plains | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Ancient Tomb | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Battlefield Forge | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
### Rugged Prairie
- sidecar_tag: `mana_base_safe_cut_model`
- named_cut_probe_count: `4`
- target_cut_lanes: `land, mana_base`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Mountain // Mountain | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Plains // Plains | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Ancient Tomb | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Battlefield Forge | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
### Sundown Pass
- sidecar_tag: `mana_base_safe_cut_model`
- named_cut_probe_count: `4`
- target_cut_lanes: `land, mana_base`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Mountain // Mountain | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Plains // Plains | 18 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Ancient Tomb | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
| Battlefield Forge | 28 | `tier_1_structural_floor` | `false` | `mana_source_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready, structural_floor_equivalence_required` |
### Dragon's Rage Channeler
- sidecar_tag: `topdeck_access_sidecar_primary`
- named_cut_probe_count: `4`
- target_cut_lanes: `draw, engine, topdeck_miracle_engine`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Artist's Talent | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Improvisation Capstone | 10 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Pinnacle Monk // Mystic Peak | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Reforge the Soul | 13 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
### Galvanoth
- sidecar_tag: `topdeck_access_sidecar_primary`
- named_cut_probe_count: `4`
- target_cut_lanes: `draw, engine, topdeck_miracle_engine`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Artist's Talent | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Improvisation Capstone | 10 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Pinnacle Monk // Mystic Peak | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Reforge the Soul | 13 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
### Penance
- sidecar_tag: `topdeck_access_sidecar_primary`
- named_cut_probe_count: `4`
- target_cut_lanes: `draw, engine, topdeck_miracle_engine`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Artist's Talent | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Improvisation Capstone | 10 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Pinnacle Monk // Mystic Peak | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Reforge the Soul | 13 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
### Valakut Awakening // Valakut Stoneforge
- sidecar_tag: `topdeck_access_sidecar_primary`
- named_cut_probe_count: `4`
- target_cut_lanes: `draw, engine, topdeck_miracle_engine`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Artist's Talent | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Improvisation Capstone | 10 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Pinnacle Monk // Mystic Peak | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Reforge the Soul | 13 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
### Wheel of Fortune
- sidecar_tag: `topdeck_access_sidecar_primary`
- named_cut_probe_count: `4`
- target_cut_lanes: `draw, engine, topdeck_miracle_engine`
| Probe cut | Score | Tier | Usable now | Blockers |
| --- | ---: | --- | ---: | --- |
| Artist's Talent | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Improvisation Capstone | 10 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Pinnacle Monk // Mystic Peak | 10 | `tier_3_role_filler_with_battle_context` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |
| Reforge the Soul | 13 | `tier_2_commander_contextual_synergy` | `false` | `miracle_topdeck_floor_equivalence_required, requires_exposure_trace_before_safe_cut, safe_cut_miner_zero_current_ready` |

## Decision

- keep_607_as_protected_baseline: `true`
- deck_action_allowed: `false`
- safe_cut_ready_now: `false`
- matrix_candidate_rows_ready: `false`
- candidate_deck_materialization_allowed_now: `false`
- forced_access_allowed_now: `false`
- natural_battle_allowed_now: `false`
- promotion_allowed: `false`
- reason: Named cut probes exist for review, but every probe remains blocked by safe-cut, exposure-trace, or floor-equivalence requirements.
- next_actions:
  - do_not_mutate_deck_607
  - do_not_turn_review_probes_into_cuts_without trace evidence
  - mine exposure and floor-equivalence traces for topdeck and mana probes
  - feed only safe-cut-ready rows into the structure matrix
