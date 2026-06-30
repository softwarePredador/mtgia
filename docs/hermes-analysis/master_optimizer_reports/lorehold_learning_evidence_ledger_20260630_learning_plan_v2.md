# Lorehold Learning Evidence Ledger

- generated_at: `2026-06-30T19:26:01.979500+00:00`
- postgres_writes: `False`
- source_db_mutated: `False`
- current_leader: `deck_607`
- protected_baseline: `deck_607`
- untested_queue_count: `0`
- observation_count: `162`
- critical_matchup_observation_count: `3`
- package_group_count: `70`
- classification_counts: `{"conflicting_signal_needs_champion_gate": 5, "invalid_corrected_package_definition": 1, "latest_rejected": 45, "positive_signal_needs_confirmation": 1, "preflight_blocked_protected_cut": 2, "preflight_ready_negative_history": 11, "registry_rejected": 1, "tie_signal_watch": 4}`
- hidden_retreat_classification: `latest_rejected`

## Decision Guardrails

- candidate must tie or beat deck_607 on same real-opponent gate
- candidate must not regress the Winota matchup
- candidate must preserve or improve miracle/topdeck game frequency
- candidate must not cut pressure absorption unless replacing same function

## Current Read

- The registry remains the authority for promotion status; raw positive gates below are treated as hypotheses until they clear the current-leader/equal-gate rule.
- Critical matchup rows track Winota, Vivi, and Sisay from detailed synergy gates; a positive aggregate gate with critical regression is held for rework.
- Hidden Retreat is classified from the latest local overlay gate and is not promoted unless a later same-function gate reverses the result.

## Actionable Confirmation Queue

| Package | Class | Best Delta | Latest Delta | Critical +/-/0 | Winota +/- | Latest Source |
| --- | --- | ---: | ---: | --- | --- | --- |
| core_challenge_dance_over_storm | `conflicting_signal_needs_champion_gate` | +44.44 | +44.44 | 0/0/0 | 0/0 | `lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` |
| galvanoth_topdeck_freecast_cut_chimes | `conflicting_signal_needs_champion_gate` | +33.33 | +33.33 | 0/0/0 | 0/0 | `lorehold_squee_refinement_package_gate_20260627_v2_seed20260625_hash0_isolated_timeout_galvanoth_cut_chimes.json` |
| gamble_approach_access_cut_creative | `conflicting_signal_needs_champion_gate` | +33.33 | +33.33 | 0/0/0 | 0/0 | `lorehold_tutor_access_conversion_gate_20260627_seed20260625_v1_tutor_access_v1.json` |
| core_challenge_aetherflux_over_storm | `conflicting_signal_needs_champion_gate` | +22.22 | +22.22 | 0/0/0 | 0/0 | `lorehold_finalizer_benchmark_gate_20260627_v1_seed20260625_hash0_isolated_timeout_storm_challenge.json` |
| brass_bounty_cut_boros_signet | `conflicting_signal_needs_champion_gate` | +8.33 | +0.00 | 0/0/0 | 0/0 | `lorehold_brass_bounty_gate_20260627_v6_seed7_games2_opp8_20260627_213848.json` |
| past_in_flames_recast | `positive_signal_needs_confirmation` | +50.00 | +50.00 | 0/0/0 | 0/0 | `lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json` |

## Key Package Groups

| Package | Class | Obs | +/-/0 | Critical +/-/0 | Best | Latest | Latest Source |
| --- | --- | ---: | --- | --- | ---: | ---: | --- |
| overmaster_protect_draw_cut_tibalts_trickery | `preflight_blocked_protected_cut` | 2 | 0/1/0 | 0/0/0 | -33.33 | +0.00 | `lorehold_tibalt_slot_preflight_20260630_v1_20260630_032247.json` |
| lapse_approach_topdeck_cut_tibalts_trickery | `preflight_blocked_protected_cut` | 2 | 0/1/0 | 0/0/0 | -66.67 | +0.00 | `lorehold_tibalt_slot_preflight_20260630_v1_20260630_032247.json` |
| candidate_607_squee_hashseed0_isolated_cached_timeout_v3 | `latest_rejected` | 10 | 4/2/4 | 0/0/0 | +88.89 | -33.33 | `lorehold_squee_hashseed0_isolated_cached_timeout_gate_seed20260625_v1.json` |
| brainstone_topdeck_miracle_cut_squelcher | `latest_rejected` | 3 | 2/1/0 | 0/0/0 | +55.56 | -77.78 | `lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` |
| galvanoth_topdeck_freecast | `latest_rejected` | 4 | 2/1/1 | 0/0/0 | +44.44 | -44.45 | `lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` |
| angel_grace_life_floor_cut_dawn | `latest_rejected` | 3 | 1/1/1 | 0/0/0 | +33.33 | -88.89 | `lorehold_life_floor_conversion_gate_20260627_seed42_v1_life_floor_v1.json` |
| birgi_seething_chain_cut_medallions | `latest_rejected` | 3 | 2/1/0 | 0/0/0 | +33.33 | -55.56 | `lorehold_spellchain_conversion_gate_20260627_seed42_v1_spellchain_v1.json` |
| one_ring_protection_draw_cut_squelcher | `latest_rejected` | 3 | 1/1/1 | 0/0/0 | +33.33 | -77.78 | `lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` |
| birgi_spellchain_cut_squelcher | `latest_rejected` | 4 | 2/1/1 | 0/0/0 | +22.22 | -55.56 | `lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` |
| galvanoth_topdeck_freecast_cut_squelcher | `latest_rejected` | 3 | 2/1/0 | 0/0/0 | +22.22 | -66.67 | `lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` |
| ghostly_prison_pressure_cut_squelcher | `latest_rejected` | 3 | 2/1/0 | 0/0/0 | +22.22 | -55.56 | `lorehold_library_pressure_conversion_gate_20260627_seed42_v1_library_pressure_v1.json` |
| penance_topdeck_protection_cut_squelcher | `latest_rejected` | 3 | 1/1/1 | 0/0/0 | +22.22 | -44.45 | `lorehold_squee_refinement_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` |
| primal_amulet_spell_engine | `latest_rejected` | 4 | 2/1/1 | 0/0/0 | +22.22 | -44.45 | `lorehold_topfreecast_conversion_gate_20260627_seed42_v1_topfreecast_v1.json` |
| brainstone_topdeck_miracle | `latest_rejected` | 4 | 1/2/1 | 0/0/0 | +11.11 | -33.33 | `lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` |
| faithless_looting_squee_enabler | `latest_rejected` | 3 | 2/1/0 | 0/0/0 | +11.11 | -66.67 | `lorehold_post_squee_package_gate_20260627_v1_seed42_hash0_isolated_timeout.json` |
| pg245_twinflame_damage_payoff_cut_thor | `latest_rejected` | 2 | 0/1/1 | 0/0/0 | +0.00 | -33.34 | `lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json` |
| cloud_key_same_lane_benchmark_cut_bender_s_waterskin | `latest_rejected` | 2 | 0/1/0 | 0/0/0 | -8.33 | -8.33 | `lorehold_cloud_key_waterskin_gate_20260630_all_lanes_20260630_082705.json` |
| ephemerate_same_lane_benchmark_cut_winds_of_abandon | `latest_rejected` | 2 | 0/2/0 | 0/0/0 | -8.33 | -8.33 | `lorehold_profiled_cut_benchmark_gate_decision_20260630.json` |
| wheel_hand_filter_cut_improvisation_capstone_expanded607 | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -8.33 | -8.33 | `lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110.json` |
| planetarium_of_wan_shi_tong_same_lane_benchmark_cut_creative_technique | `latest_rejected` | 2 | 0/2/0 | 0/0/0 | -12.50 | -12.50 | `lorehold_profiled_cut_benchmark_gate_decision_20260630.json` |
| valakut_hand_filter_cut_improvisation_capstone_expanded607 | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -16.66 | -16.66 | `lorehold_hand_filter_expanded_package_gate_20260630_post_pg270_v2_20260630_080110.json` |
| the_warring_triad_same_lane_benchmark_cut_bender_s_waterskin | `latest_rejected` | 2 | 0/2/0 | 0/0/0 | -20.83 | -20.83 | `lorehold_profiled_cut_benchmark_gate_decision_20260630.json` |
| enlightened_engine_access_cut_thor | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -44.45 | -44.45 | `lorehold_tutor_access_conversion_gate_20260627_seed42_v2_tutor_access_v2.json` |
| chandra_copy_engine | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -50.00 | -50.00 | `lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json` |
| core_challenge_past_over_tragic | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -50.00 | -50.00 | `lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json` |
| boseiju_spell_protection_land | `latest_rejected` | 1 | 0/1/0 | 1/2/0 | -55.56 | -55.56 | `lorehold_spell_protection_land_gate_20260627_seed42_v1_spell_protection_land_v1.json` |
| galvanoth_topdeck_freecast_cut_thor | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -55.56 | -55.56 | `lorehold_topfreecast_conversion_gate_20260627_seed42_v2_topfreecast_v2.json` |
| gamble_access_cut_thor | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -55.56 | -55.56 | `lorehold_tutor_access_conversion_gate_20260627_seed42_v2_gamble_tutor_access_v2.json` |
| gods_willing_commander_shield_cut_promise | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -66.67 | -66.67 | `lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json` |
| hidden_retreat_stack_damage_topdeck_cut_promise | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -66.67 | -66.67 | `lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json` |
| mana_vault_fast_mana_cut_arcane_signet | `latest_rejected` | 6 | 0/4/0 | 0/0/0 | -66.67 | -66.67 | `lorehold_exposure_by_game_gate_20260628_v1_20260628_101737.json` |
| monastery_mentor_spell_tokens_cut_prismari | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -66.67 | -66.67 | `lorehold_spell_payoff_gate_20260627_v1_fixed.json` |
| perch_protection_cut_avatar_wrath | `latest_rejected` | 2 | 0/2/0 | 0/0/0 | -66.67 | -66.67 | `lorehold_protection_ready_gate_20260628_v1_20260628_095000.json` |
| radiant_scrollwielder_cut_scarlet_witch | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -66.67 | -66.67 | `lorehold_radiant_scrollwielder_gate_20260627_v1_fixed.json` |
| silence_cut_avatar_wrath | `latest_rejected` | 2 | 0/2/0 | 0/0/0 | -66.67 | -66.67 | `lorehold_protection_ready_gate_20260628_v1_20260628_095000.json` |
| young_pyromancer_spell_tokens_cut_prismari | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -66.67 | -66.67 | `lorehold_spell_payoff_gate_20260627_v1_fixed.json` |
| boros_charm_pressure_cut_fated | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -88.89 | -88.89 | `lorehold_pressure_conversion_gate_20260627_seed42_v2_pressure_v2.json` |
| akromas_will_cut_avatar_wrath | `latest_rejected` | 2 | 0/2/0 | 0/0/0 | -100.00 | -100.00 | `lorehold_protection_ready_gate_20260628_v1_20260628_095000.json` |
| birgi_spellchain_cut_jeskas_will | `latest_rejected` | 2 | 0/2/0 | 0/0/0 | -100.00 | -100.00 | `lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json` |
| dragon_rage_channeler_cut_scarlet_witch | `latest_rejected` | 1 | 0/1/0 | 0/0/0 | -100.00 | -100.00 | `lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` |

## Protected Cards

`Molecule Man`, `The Scarlet Witch`, `Promise of Loyalty`, `Tragic Arrogance`, `Hexing Squelcher`, `Sensei's Divining Top`, `Scroll Rack`, `Bender's Waterskin`, `Tibalt's Trickery`, `Creative Technique`, `High Noon`, `Prismari Pianist`, `Reforge the Soul`, `Storm Herd`, `Insurrection`
