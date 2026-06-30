# Lorehold Exposure-Aware Gate Queue - 2026-06-30

- Generated at: `2026-06-30T04:27:44Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Readiness report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_candidate_readiness_20260628_v1.json`
- Hypothesis queue: `docs/hermes-analysis/master_optimizer_reports/lorehold_next_hypothesis_queue_20260630_after_past_reject.json`
- Planner: `docs/hermes-analysis/master_optimizer_reports/lorehold_next_action_planner_20260630_after_past_reject_v2.json`
- Cut safety report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v3_runtime_readiness.json`

## Summary

- Packages reviewed: `75`
- Status counts: `{"blocked_added_card_readiness": 8, "blocked_cut_safety": 47, "blocked_hypothesis_queue_prior_negative": 4, "blocked_prior_evidence": 5, "forced_exposure_probe_ready": 11}`
- Ready packages: `11`
- Natural gate ready: `0`
- Forced-exposure diagnostic ready: `11`
- Recommended next action: `run_forced_exposure_probe_before_natural_gate`

## Ready Queue

| Rank | Package | Status | Adds | Cuts | Promotion allowed | Command |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `austere_command_wipe_over_emeria_tradeoff` | `forced_exposure_probe_ready` | `Austere Command` | `Emeria's Call // Emeria, Shattered Skyclave` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages austere_command_wipe_over_emeria_tradeoff --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 2 | `boros_charm_pressure_cut_avatar_wrath` | `forced_exposure_probe_ready` | `Boros Charm` | `Avatar's Wrath` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages boros_charm_pressure_cut_avatar_wrath --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 3 | `enlightened_access_benchmark_cut_land_tax` | `forced_exposure_probe_ready` | `Enlightened Tutor` | `Land Tax` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages enlightened_access_benchmark_cut_land_tax --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 4 | `gamble_access_benchmark_cut_land_tax` | `forced_exposure_probe_ready` | `Gamble` | `Land Tax` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages gamble_access_benchmark_cut_land_tax --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 5 | `plateau_timing_upgrade_cut_radiant_summit` | `forced_exposure_probe_ready` | `Plateau` | `Radiant Summit` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages plateau_timing_upgrade_cut_radiant_summit --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 6 | `plateau_timing_upgrade_cut_turbulent_steppe` | `forced_exposure_probe_ready` | `Plateau` | `Turbulent Steppe` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages plateau_timing_upgrade_cut_turbulent_steppe --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 7 | `seething_song_cut_fellwar_stone` | `forced_exposure_probe_ready` | `Seething Song` | `Fellwar Stone` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages seething_song_cut_fellwar_stone --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 8 | `storm_kiln_artist_cut_arcane_signet` | `forced_exposure_probe_ready` | `Storm-Kiln Artist` | `Arcane Signet` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages storm_kiln_artist_cut_arcane_signet --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 9 | `valakut_hand_filter_cut_big_score` | `forced_exposure_probe_ready` | `Valakut Awakening // Valakut Stoneforge` | `Big Score` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages valakut_hand_filter_cut_big_score --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 10 | `volcanic_recursion_cut_pinnacle` | `forced_exposure_probe_ready` | `Volcanic Vision` | `Pinnacle Monk // Mystic Peak` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages volcanic_recursion_cut_pinnacle --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |
| 11 | `wheel_hand_filter_cut_big_score` | `forced_exposure_probe_ready` | `Wheel of Fortune` | `Big Score` | `false` | `python3 /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py --packages wheel_hand_filter_cut_big_score --games 3 --opponent-limit 8 --opponent-seed 20260629 --simulation-seed 20260630 --stem lorehold_exposure_aware_gate_queue_20260630_after_past_reject_run --package-file /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_profiled_cut_benchmark_20260630_after_past_reject_package_manifest.json --forced-access-mode opening_hand` |

## Blocked Queue

| Package | Status | Adds | Cuts | Blockers |
| --- | --- | --- | --- | --- |
| `brainstone_topdeck_miracle` | `blocked_added_card_readiness` | `Brainstone` | `Bender's Waterskin` | `added_card_readiness_blocked`, `cut_safety_blocked`, `prior_exact_reject` |
| `brainstone_topdeck_miracle_cut_squelcher` | `blocked_added_card_readiness` | `Brainstone` | `Hexing Squelcher` | `added_card_readiness_blocked`, `cut_safety_blocked`, `prior_exact_reject` |
| `ephemerate_same_lane_benchmark_cut_winds_of_abandon` | `blocked_added_card_readiness` | `Ephemerate` | `Winds of Abandon` | `added_card_readiness_blocked` |
| `hidden_retreat_stack_damage_topdeck_cut_promise` | `blocked_added_card_readiness` | `Hidden Retreat` | `Promise of Loyalty` | `added_card_readiness_blocked`, `cut_safety_blocked` |
| `pg245_twinflame_damage_payoff_cut_thor` | `blocked_added_card_readiness` | `Twinflame Tyrant` | `Thor, God of Thunder` | `added_card_readiness_blocked`, `hypothesis_queue_exact_negative` |
| `pg245_verge_rangers_topdeck_land_cut_waterskin` | `blocked_added_card_readiness` | `Verge Rangers` | `Bender's Waterskin` | `added_card_readiness_blocked`, `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `planetarium_of_wan_shi_tong_same_lane_benchmark_cut_creative_technique` | `blocked_added_card_readiness` | `Planetarium of Wan Shi Tong` | `Creative Technique` | `added_card_readiness_blocked` |
| `the_warring_triad_same_lane_benchmark_cut_bender_s_waterskin` | `blocked_added_card_readiness` | `The Warring Triad` | `Bender's Waterskin` | `added_card_readiness_blocked` |
| `angel_grace_life_floor_cut_dawn` | `blocked_cut_safety` | `Angel's Grace` | `Dawn's Truce` | `cut_safety_blocked`, `prior_exact_reject` |
| `arcane_bombardment_engine` | `blocked_cut_safety` | `Arcane Bombardment` | `Bender's Waterskin` | `cut_safety_blocked` |
| `artifact_etb_value` | `blocked_cut_safety` | `Archaeomancer's Map`, `Soul-Guide Lantern`, `The One Ring` | `Bender's Waterskin`, `Victory Chimes`, `Hexing Squelcher` | `cut_safety_blocked` |
| `biblioplex_topdeck_land` | `blocked_cut_safety` | `The Biblioplex` | `Reliquary Tower` | `cut_safety_blocked` |
| `birgi_seething_chain_cut_medallions` | `blocked_cut_safety` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty`, `Seething Song` | `Pearl Medallion`, `Ruby Medallion` | `cut_safety_blocked`, `prior_exact_reject` |
| `birgi_spellchain_cut_squelcher` | `blocked_cut_safety` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `Hexing Squelcher` | `cut_safety_blocked`, `prior_exact_reject` |
| `birgi_spellchain_cut_waterskin` | `blocked_cut_safety` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `Bender's Waterskin` | `cut_safety_blocked`, `prior_exact_reject` |
| `boros_charm_pressure_cut_fated` | `blocked_cut_safety` | `Boros Charm` | `Fated Clash` | `cut_safety_blocked`, `prior_exact_reject` |
| `boseiju_spell_protection_land` | `blocked_cut_safety` | `Boseiju, Who Shelters All` | `Reliquary Tower` | `cut_safety_blocked`, `prior_exact_reject` |
| `chandra_copy_engine` | `blocked_cut_safety` | `Chandra, Hope's Beacon` | `Bender's Waterskin` | `cut_safety_blocked`, `prior_exact_reject` |
| `copy_stack_package` | `blocked_cut_safety` | `Reverberate`, `Return the Favor`, `Flare of Duplication` | `Hexing Squelcher`, `Bender's Waterskin`, `Victory Chimes` | `cut_safety_blocked` |
| `core_challenge_aetherflux_over_storm` | `blocked_cut_safety` | `Aetherflux Reservoir` | `Storm Herd` | `cut_safety_blocked`, `prior_exact_reject` |
| `core_challenge_dance_over_storm` | `blocked_cut_safety` | `Dance with Calamity` | `Storm Herd` | `cut_safety_blocked`, `prior_exact_reject` |
| `core_challenge_past_over_tragic` | `blocked_cut_safety` | `Past in Flames` | `Tragic Arrogance` | `cut_safety_blocked`, `prior_exact_reject` |
| `dragon_rage_channeler_cut_scarlet_witch` | `blocked_cut_safety` | `Dragon's Rage Channeler` | `The Scarlet Witch` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `enlightened_engine_access_cut_thor` | `blocked_cut_safety` | `Enlightened Tutor` | `Thor, God of Thunder` | `cut_safety_blocked`, `prior_exact_reject` |
| `etb_tutor_blink` | `blocked_cut_safety` | `Imperial Recruiter`, `Recruiter of the Guard`, `Ranger-Captain of Eos` | `Bender's Waterskin`, `Victory Chimes`, `Hexing Squelcher` | `cut_safety_blocked` |
| `faithless_looting_squee_enabler` | `blocked_cut_safety` | `Faithless Looting` | `Hexing Squelcher` | `cut_safety_blocked`, `prior_exact_reject` |
| `galvanoth_topdeck_freecast` | `blocked_cut_safety` | `Galvanoth` | `Bender's Waterskin` | `cut_safety_blocked` |
| `galvanoth_topdeck_freecast_cut_chimes` | `blocked_cut_safety` | `Galvanoth` | `Victory Chimes` | `cut_safety_blocked`, `prior_exact_reject` |
| `galvanoth_topdeck_freecast_cut_squelcher` | `blocked_cut_safety` | `Galvanoth` | `Hexing Squelcher` | `cut_safety_blocked`, `prior_exact_reject` |
| `galvanoth_topdeck_freecast_cut_thor` | `blocked_cut_safety` | `Galvanoth` | `Thor, God of Thunder` | `cut_safety_blocked`, `prior_exact_reject` |
| `gamble_access_cut_thor` | `blocked_cut_safety` | `Gamble` | `Thor, God of Thunder` | `cut_safety_blocked`, `prior_exact_reject` |
| `gamble_approach_access_cut_creative` | `blocked_cut_safety` | `Gamble` | `Creative Technique` | `cut_safety_blocked` |
| `ghostly_prison_pressure_cut_promise` | `blocked_cut_safety` | `Ghostly Prison` | `Promise of Loyalty` | `cut_safety_blocked` |
| `ghostly_prison_pressure_cut_squelcher` | `blocked_cut_safety` | `Ghostly Prison` | `Hexing Squelcher` | `cut_safety_blocked`, `prior_exact_reject` |
| `gods_willing_commander_shield_cut_promise` | `blocked_cut_safety` | `Gods Willing` | `Promise of Loyalty` | `cut_safety_blocked`, `prior_exact_reject` |
| `guttersnipe_spell_payoff_cut_prismari` | `blocked_cut_safety` | `Guttersnipe` | `Prismari Pianist` | `cut_safety_blocked`, `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `lapse_approach_topdeck_cut_tibalts_trickery` | `blocked_cut_safety` | `Lapse of Certainty` | `Tibalt's Trickery` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `mirrorpool_spellcopy_land` | `blocked_cut_safety` | `Mirrorpool` | `Reliquary Tower` | `cut_safety_blocked` |
| `monastery_mentor_spell_tokens_cut_prismari` | `blocked_cut_safety` | `Monastery Mentor` | `Prismari Pianist` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `one_ring_burden_reset` | `blocked_cut_safety` | `The One Ring` | `Bender's Waterskin` | `cut_safety_blocked` |
| `one_ring_protection_draw_cut_squelcher` | `blocked_cut_safety` | `The One Ring` | `Hexing Squelcher` | `cut_safety_blocked`, `prior_exact_reject` |
| `overmaster_protect_draw` | `blocked_cut_safety` | `Overmaster` | `Hexing Squelcher` | `cut_safety_blocked` |
| `overmaster_protect_draw_cut_tibalts_trickery` | `blocked_cut_safety` | `Overmaster` | `Tibalt's Trickery` | `cut_safety_blocked` |
| `past_in_flames_cut_squelcher` | `blocked_cut_safety` | `Past in Flames` | `Hexing Squelcher` | `cut_safety_blocked` |
| `past_in_flames_recast` | `blocked_cut_safety` | `Past in Flames` | `Bender's Waterskin` | `cut_safety_blocked` |
| `past_overmaster_spellchain` | `blocked_cut_safety` | `Past in Flames`, `Overmaster` | `Bender's Waterskin`, `Hexing Squelcher` | `cut_safety_blocked` |
| `penance_runtime_topdeck_cut_promise` | `blocked_cut_safety` | `Penance` | `Promise of Loyalty` | `cut_safety_blocked`, `prior_exact_reject` |
| `penance_topdeck_protection_cut_squelcher` | `blocked_cut_safety` | `Penance` | `Hexing Squelcher` | `cut_safety_blocked`, `prior_exact_reject` |
| `primal_amulet_spell_engine` | `blocked_cut_safety` | `Primal Amulet // Primal Wellspring` | `Bender's Waterskin` | `cut_safety_blocked`, `prior_exact_reject` |
| `radiant_scrollwielder_cut_scarlet_witch` | `blocked_cut_safety` | `Radiant Scrollwielder` | `The Scarlet Witch` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `sejiri_shelter_commander_shield_cut_promise` | `blocked_cut_safety` | `Sejiri Shelter // Sejiri Glacier` | `Promise of Loyalty` | `cut_safety_blocked`, `prior_exact_reject` |
| `sun_titan_blink_value` | `blocked_cut_safety` | `Sun Titan` | `Bender's Waterskin` | `cut_safety_blocked` |
| `sun_titan_cut_chimes` | `blocked_cut_safety` | `Sun Titan` | `Victory Chimes` | `cut_safety_blocked` |
| `sun_titan_cut_squelcher` | `blocked_cut_safety` | `Sun Titan` | `Hexing Squelcher` | `cut_safety_blocked` |
| `young_pyromancer_spell_tokens_cut_prismari` | `blocked_cut_safety` | `Young Pyromancer` | `Prismari Pianist` | `cut_safety_blocked`, `hypothesis_queue_exact_negative` |
| `birgi_spellchain_cut_jeskas_will` | `blocked_prior_evidence` | `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `Jeska's Will` | `prior_exact_reject` |
| `brass_bounty_cut_boros_signet` | `blocked_prior_evidence` | `Brass's Bounty` | `Boros Signet` | `prior_exact_reject` |
| `mana_vault_fast_mana_cut_arcane_signet` | `blocked_prior_evidence` | `Mana Vault` | `Arcane Signet` | `prior_exact_reject` |
| `reprieve_cut_avatar_wrath` | `blocked_prior_evidence` | `Reprieve` | `Avatar's Wrath` | `prior_exact_reject`, `hypothesis_queue_exact_negative` |
| `runaway_steamkin_cut_talisman` | `blocked_prior_evidence` | `Runaway Steam-Kin` | `Talisman of Conviction` | `prior_exact_reject` |
| `akromas_will_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Akroma's Will` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
| `grand_abolisher_cut_mother_of_runes` | `blocked_hypothesis_queue_prior_negative` | `Grand Abolisher` | `Mother of Runes` | `hypothesis_queue_exact_negative` |
| `perch_protection_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Perch Protection` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
| `silence_cut_avatar_wrath` | `blocked_hypothesis_queue_prior_negative` | `Silence` | `Avatar's Wrath` | `hypothesis_queue_exact_negative` |
