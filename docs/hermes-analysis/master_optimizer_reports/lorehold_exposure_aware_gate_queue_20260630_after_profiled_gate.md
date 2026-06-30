# Lorehold Exposure-Aware Gate Queue - 2026-06-30

- Generated at: `2026-06-30T14:52:34Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Readiness report: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_candidate_readiness_20260630_post_pg280_kayla_music_box.json`
- Hypothesis queue: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260630_after_profiled_gate.json`
- Planner: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_after_profiled_gate.json`
- Cut safety report: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v3_runtime_readiness.json`

## Summary

- Packages reviewed: `22`
- Status counts: `{"blocked_cut_safety": 8, "blocked_hypothesis_queue_prior_negative": 5, "blocked_prior_evidence": 1, "blocked_unknown_package_definition": 1, "forced_exposure_probe_ready": 7}`
- Ready packages: `7`
- Natural gate ready: `0`
- Forced-exposure diagnostic ready: `7`
- Recommended next action: `run_forced_exposure_probe_before_natural_gate`

## Ready Queue

| Rank | Package | Status | Adds | Cuts | Promotion allowed | Command |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `austere_command_wipe_over_emeria_tradeoff` | `forced_exposure_probe_ready` | `Austere Command` | `Emeria's Call // Emeria, Shattered Skyclave` | `false` | `python3 /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages austere_command_wipe_over_emeria_tradeoff --games 1 --opponent-limit 3 --opponent-seed 20260626 --simulation-seed 42 --stem lorehold_exposure_aware_gate_queue_20260630_after_profiled_gate_run --forced-access-mode opening_hand` |
| 2 | `boros_charm_pressure_cut_avatar_wrath` | `forced_exposure_probe_ready` | `Boros Charm` | `Avatar's Wrath` | `false` | `python3 /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages boros_charm_pressure_cut_avatar_wrath --games 1 --opponent-limit 3 --opponent-seed 20260626 --simulation-seed 42 --stem lorehold_exposure_aware_gate_queue_20260630_after_profiled_gate_run --forced-access-mode opening_hand` |
| 3 | `plateau_timing_upgrade_cut_radiant_summit` | `forced_exposure_probe_ready` | `Plateau` | `Radiant Summit` | `false` | `python3 /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages plateau_timing_upgrade_cut_radiant_summit --games 1 --opponent-limit 3 --opponent-seed 20260626 --simulation-seed 42 --stem lorehold_exposure_aware_gate_queue_20260630_after_profiled_gate_run --forced-access-mode opening_hand` |
| 4 | `plateau_timing_upgrade_cut_turbulent_steppe` | `forced_exposure_probe_ready` | `Plateau` | `Turbulent Steppe` | `false` | `python3 /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages plateau_timing_upgrade_cut_turbulent_steppe --games 1 --opponent-limit 3 --opponent-seed 20260626 --simulation-seed 42 --stem lorehold_exposure_aware_gate_queue_20260630_after_profiled_gate_run --forced-access-mode opening_hand` |
| 5 | `seething_song_cut_fellwar_stone` | `forced_exposure_probe_ready` | `Seething Song` | `Fellwar Stone` | `false` | `python3 /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages seething_song_cut_fellwar_stone --games 1 --opponent-limit 3 --opponent-seed 20260626 --simulation-seed 42 --stem lorehold_exposure_aware_gate_queue_20260630_after_profiled_gate_run --forced-access-mode opening_hand` |
| 6 | `volcanic_recursion_cut_pinnacle` | `forced_exposure_probe_ready` | `Volcanic Vision` | `Pinnacle Monk // Mystic Peak` | `false` | `python3 /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages volcanic_recursion_cut_pinnacle --games 1 --opponent-limit 3 --opponent-seed 20260626 --simulation-seed 42 --stem lorehold_exposure_aware_gate_queue_20260630_after_profiled_gate_run --forced-access-mode opening_hand` |
| 7 | `wheel_hand_filter_cut_big_score` | `forced_exposure_probe_ready` | `Wheel of Fortune` | `Big Score` | `false` | `python3 /Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages wheel_hand_filter_cut_big_score --games 1 --opponent-limit 3 --opponent-seed 20260626 --simulation-seed 42 --stem lorehold_exposure_aware_gate_queue_20260630_after_profiled_gate_run --forced-access-mode opening_hand` |

## Blocked Queue

| Package | Status | Adds | Cuts | Blockers |
| --- | --- | --- | --- | --- |
| `dragon_rage_channeler_cut_scarlet_witch` | `blocked_cut_safety` | `Dragon's Rage Channeler` | `The Scarlet Witch` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `guttersnipe_spell_payoff_cut_prismari` | `blocked_cut_safety` | `Guttersnipe` | `Prismari Pianist` | `cut_safety_blocked`, `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `hidden_retreat_stack_damage_topdeck_cut_promise` | `blocked_cut_safety` | `Hidden Retreat` | `Promise of Loyalty` | `cut_safety_blocked` |
| `lapse_approach_topdeck_cut_tibalts_trickery` | `blocked_cut_safety` | `Lapse of Certainty` | `Tibalt's Trickery` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `monastery_mentor_spell_tokens_cut_prismari` | `blocked_cut_safety` | `Monastery Mentor` | `Prismari Pianist` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `pg245_verge_rangers_topdeck_land_cut_waterskin` | `blocked_cut_safety` | `Verge Rangers` | `Bender's Waterskin` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `radiant_scrollwielder_cut_scarlet_witch` | `blocked_cut_safety` | `Radiant Scrollwielder` | `The Scarlet Witch` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `young_pyromancer_spell_tokens_cut_prismari` | `blocked_cut_safety` | `Young Pyromancer` | `Prismari Pianist` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `reprieve_cut_avatar_wrath` | `blocked_prior_evidence` | `Reprieve` | `Avatar's Wrath` | `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `akromas_will_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Akroma's Will` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
| `grand_abolisher_cut_mother_of_runes` | `blocked_hypothesis_queue_prior_negative` | `Grand Abolisher` | `Mother of Runes` | `hypothesis_queue_exact_negative` |
| `perch_protection_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Perch Protection` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
| `pg245_twinflame_damage_payoff_cut_thor` | `blocked_hypothesis_queue_prior_negative` | `Twinflame Tyrant` | `Thor, God of Thunder` | `hypothesis_queue_exact_negative` |
| `silence_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Silence` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
| `planetarium_of_wan_shi_tong_same_lane_benchmark_cut_creative_technique` | `blocked_unknown_package_definition` |  |  | `unknown_package_definition` |
