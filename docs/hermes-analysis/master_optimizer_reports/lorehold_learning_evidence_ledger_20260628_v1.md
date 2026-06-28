# Lorehold Learning Evidence Ledger

- generated_at: `2026-06-28T07:15:14.335996+00:00`
- postgres_writes: `False`
- source_db_mutated: `False`
- current_leader: `candidate_607_squee_v1`
- protected_baseline: `deck_607`
- untested_queue_count: `0`
- observation_count: `140`
- package_group_count: `70`
- classification_counts: `{"conflicting_signal_needs_champion_gate": 18, "current_champion": 1, "latest_rejected": 42, "positive_signal_needs_confirmation": 1, "registry_rejected": 1, "tie_signal_watch": 7}`
- hidden_retreat_classification: `latest_rejected`

## Decision Guardrails

- candidate must tie or beat deck_607 on same real-opponent gate
- candidate must not regress the Winota matchup
- candidate must preserve or improve miracle/topdeck game frequency
- candidate must not cut pressure absorption unless replacing same function

## Current Read

- The registry remains the authority for promotion status; raw positive gates below are treated as hypotheses until they clear the current-leader/equal-gate rule.
- Hidden Retreat is classified from the latest local overlay gate and is not promoted unless a later same-function gate reverses the result.

## Actionable Confirmation Queue

| Package | Class | Best Delta | Latest Delta | Latest Source |
| --- | --- | ---: | ---: | --- |
| brainstone_topdeck_miracle_cut_squelcher | `conflicting_signal_needs_champion_gate` | +55.56 | +22.22 | `lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1.json` |
| core_challenge_dance_over_storm | `conflicting_signal_needs_champion_gate` | +44.44 | +0.00 | `lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json` |
| galvanoth_topdeck_freecast | `conflicting_signal_needs_champion_gate` | +44.44 | +11.11 | `lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json` |
| angel_grace_life_floor_cut_dawn | `conflicting_signal_needs_champion_gate` | +33.33 | +0.00 | `lorehold_life_floor_conversion_gate_20260627_seed7_v1_life_floor_v1.json` |
| birgi_seething_chain_cut_medallions | `conflicting_signal_needs_champion_gate` | +33.33 | +22.22 | `lorehold_spellchain_conversion_gate_20260627_seed7_v1_spellchain_v1.json` |
| galvanoth_topdeck_freecast_cut_chimes | `conflicting_signal_needs_champion_gate` | +33.33 | +11.11 | `lorehold_squee_refinement_package_gate_20260627_v2_seed7_hash0_isolated_timeout_galvanoth_cut_chimes.json` |
| gamble_approach_access_cut_creative | `conflicting_signal_needs_champion_gate` | +33.33 | +22.22 | `lorehold_tutor_access_conversion_gate_20260627_seed7_v1_tutor_access_v1.json` |
| gods_willing_commander_shield_cut_promise | `conflicting_signal_needs_champion_gate` | +33.33 | +33.33 | `lorehold_targeted_shield_package_gate_20260628_seed7_targeted_shield_v1.json` |
| one_ring_protection_draw_cut_squelcher | `conflicting_signal_needs_champion_gate` | +33.33 | +0.00 | `lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1.json` |
| birgi_spellchain_cut_squelcher | `conflicting_signal_needs_champion_gate` | +22.22 | +22.22 | `lorehold_squee_refinement_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json` |
| core_challenge_aetherflux_over_storm | `conflicting_signal_needs_champion_gate` | +22.22 | +11.11 | `lorehold_finalizer_benchmark_gate_20260627_v1_seed7_hash0_isolated_timeout_storm_challenge.json` |
| galvanoth_topdeck_freecast_cut_squelcher | `conflicting_signal_needs_champion_gate` | +22.22 | +22.22 | `lorehold_squee_refinement_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json` |
| ghostly_prison_pressure_cut_squelcher | `conflicting_signal_needs_champion_gate` | +22.22 | +22.22 | `lorehold_library_pressure_conversion_gate_20260627_seed7_v1_library_pressure_v1.json` |
| penance_topdeck_protection_cut_squelcher | `conflicting_signal_needs_champion_gate` | +22.22 | +0.00 | `lorehold_squee_refinement_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json` |
| primal_amulet_spell_engine | `conflicting_signal_needs_champion_gate` | +22.22 | +22.22 | `lorehold_topfreecast_conversion_gate_20260627_seed7_v1_topfreecast_v1.json` |
| brainstone_topdeck_miracle | `conflicting_signal_needs_champion_gate` | +11.11 | +0.00 | `lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json` |
| faithless_looting_squee_enabler | `conflicting_signal_needs_champion_gate` | +11.11 | +11.11 | `lorehold_post_squee_package_gate_20260627_v1_seed7_hash0_isolated_timeout.json` |
| brass_bounty_cut_boros_signet | `conflicting_signal_needs_champion_gate` | +8.33 | +0.00 | `lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` |
| past_in_flames_recast | `positive_signal_needs_confirmation` | +50.00 | +50.00 | `lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json` |

## Key Package Groups

| Package | Class | Obs | +/-/0 | Best | Latest | Latest Source |
| --- | --- | ---: | --- | ---: | ---: | --- |
| candidate_607_squee_v1 | `current_champion` | 10 | 4/2/4 | +88.89 | +11.11 | `lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed99_20260627_v1.json` |
| ghostly_prison_pressure_cut_promise | `latest_rejected` | 5 | 4/1/0 | +37.50 | -100.00 | `lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2.json` |
| overmaster_protect_draw_cut_tibalts_trickery | `latest_rejected` | 4 | 2/2/0 | +25.00 | -33.33 | `lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2.json` |
| core_challenge_past_over_tragic | `latest_rejected` | 5 | 2/3/0 | +12.50 | -12.50 | `lorehold_past_tragic_gate_20260627_v4_seed123_smoke_opp8_20260627_220625.json` |
| pg245_twinflame_damage_payoff_cut_thor | `latest_rejected` | 2 | 0/1/1 | +0.00 | -33.34 | `lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json` |
| candidate_6_infernal_plunge_equal_gate | `latest_rejected` | 1 | 0/1/0 | -22.22 | -22.22 | `lorehold_infernal_plunge_equal_gate_20260627_020045_infernal_plunge.json` |
| enlightened_engine_access_cut_thor | `latest_rejected` | 1 | 0/1/0 | -44.45 | -44.45 | `lorehold_tutor_access_conversion_gate_20260627_seed42_v2_tutor_access_v2.json` |
| chandra_copy_engine | `latest_rejected` | 1 | 0/1/0 | -50.00 | -50.00 | `lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json` |
| boseiju_spell_protection_land | `latest_rejected` | 1 | 0/1/0 | -55.56 | -55.56 | `lorehold_spell_protection_land_gate_20260627_seed42_v1_spell_protection_land_v1.json` |
| galvanoth_topdeck_freecast_cut_thor | `latest_rejected` | 1 | 0/1/0 | -55.56 | -55.56 | `lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2.json` |
| gamble_access_cut_thor | `latest_rejected` | 1 | 0/1/0 | -55.56 | -55.56 | `lorehold_tutor_access_conversion_gate_20260627_seed42_v2_gamble_tutor_access_v2.json` |
| plateau_timing_upgrade_cut_turbulent_steppe | `latest_rejected` | 1 | 0/1/0 | -55.56 | -55.56 | `lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json` |
| enlightened_access_benchmark_cut_land_tax | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json` |
| gamble_access_benchmark_cut_land_tax | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json` |
| hidden_retreat_stack_damage_topdeck_cut_promise | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json` |
| lapse_approach_topdeck_cut_tibalts_trickery | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_lapse_approach_gate_20260627_v1_fixed.json` |
| monastery_mentor_spell_tokens_cut_prismari | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_spell_payoff_gate_20260627_v1_fixed.json` |
| perch_protection_cut_avatar_wrath | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_614_615_hypothesis_gate_20260627_v1_seed42_fixed.json` |
| plateau_timing_upgrade_cut_radiant_summit | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_mana_base_plateau_gate_20260627_v1_real.json` |
| radiant_scrollwielder_cut_scarlet_witch | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_radiant_scrollwielder_gate_20260627_v1_fixed.json` |
| silence_cut_avatar_wrath | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_614_615_hypothesis_gate_20260627_v1_seed42_silence_fixed.json` |
| storm_kiln_artist_cut_arcane_signet | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2.json` |
| sun_titan_cut_chimes | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_synergy_package_gate_20260627_sun_titan_noncore_v1_20260627_120928.json` |
| young_pyromancer_spell_tokens_cut_prismari | `latest_rejected` | 1 | 0/1/0 | -66.67 | -66.67 | `lorehold_spell_payoff_gate_20260627_v1_fixed.json` |
| boros_charm_pressure_cut_fated | `latest_rejected` | 1 | 0/1/0 | -88.89 | -88.89 | `lorehold_pressure_conversion_gate_20260627_seed42_v2_pressure_v2.json` |
| akromas_will_cut_avatar_wrath | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` |
| artifact_etb_value | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_synergy_package_gate_20260627_v1_20260627_114609.json` |
| austere_command_wipe_over_emeria_tradeoff | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_austere_emeria_tradeoff_gate_20260627_v1_20260627_232955.json` |
| birgi_spellchain_cut_jeskas_will | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2.json` |
| boros_charm_pressure_cut_avatar_wrath | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2.json` |
| dragon_rage_channeler_cut_scarlet_witch | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` |
| etb_tutor_blink | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_synergy_package_gate_20260627_v1_20260627_114609.json` |
| grand_abolisher_cut_mother_of_runes | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` |
| guttersnipe_spell_payoff_cut_prismari | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_spell_payoff_gate_20260627_v1_fixed.json` |
| one_ring_burden_reset | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_synergy_package_gate_20260627_v1_20260627_114609.json` |
| pg245_verge_rangers_topdeck_land_cut_waterskin | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_pg245_runtime_smoke_gate_20260628_pg245_smoke_v1.json` |
| reprieve_cut_avatar_wrath | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` |
| runaway_steamkin_cut_talisman | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2.json` |
| seething_song_cut_fellwar_stone | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_synergy_package_gate_20260627_v3_safe_queue_smoke2.json` |
| sun_titan_cut_squelcher | `latest_rejected` | 1 | 0/1/0 | -100.00 | -100.00 | `lorehold_synergy_package_gate_20260627_sun_titan_noncore_v1_20260627_120928.json` |

## Protected Cards

`Molecule Man`, `The Scarlet Witch`, `Promise of Loyalty`, `Tragic Arrogance`, `Hexing Squelcher`, `Sensei's Divining Top`, `Scroll Rack`, `Bender's Waterskin`, `Tibalt's Trickery`, `Creative Technique`, `High Noon`, `Prismari Pianist`, `Reforge the Soul`, `Storm Herd`
