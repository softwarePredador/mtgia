# Lorehold Synergy Seed Matrix

- generated_at: `2026-06-28T05:44:22.175200+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- seeds: `7, 20260625, 42`
- strong_seeds: `42`
- games_per_opponent: `1`
- opponent_limit: `3`
- postgres_writes: `false`
- source_db_mutated: `false`
- package_status_counts: `{"matrix_run": 25, "skipped_cut_safety": 37, "skipped_prior_evidence": 8}`

## Aggregate Decisions

| Package | Family | Adds | Cuts | Record Base | Record Candidate | Delta | Avg Seed Delta | Decision |
| --- | --- | --- | --- | --- | --- | ---: | ---: | --- |
| one_ring_burden_reset | misc | The One Ring | Bender's Waterskin | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| one_ring_protection_draw_cut_squelcher | draw_protection | The One Ring | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| birgi_spellchain_cut_squelcher | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| birgi_spellchain_cut_waterskin | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Bender's Waterskin | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| birgi_spellchain_cut_jeskas_will | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Jeska's Will | 4-5 | 0-9 | -44.44 | -44.44 | `reject_regresses_strong_seed` |
| birgi_seething_chain_cut_medallions | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty, Seething Song | Pearl Medallion, Ruby Medallion | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| seething_song_cut_fellwar_stone | spellchain_mana | Seething Song | Fellwar Stone | 4-5 | 0-9 | -44.44 | -44.44 | `reject_regresses_strong_seed` |
| storm_kiln_artist_cut_arcane_signet | spellchain_mana | Storm-Kiln Artist | Arcane Signet | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| brass_bounty_cut_boros_signet | spellchain_mana | Brass's Bounty | Boros Signet | 4-5 | 4-5 | +0.00 | +0.00 | `tie_hold_for_more_games` |
| runaway_steamkin_cut_talisman | spellchain_mana | Runaway Steam-Kin | Talisman of Conviction | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| gamble_approach_access_cut_creative | tutor_access | Gamble | Creative Technique | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| gamble_access_cut_thor | tutor_access | Gamble | Thor, God of Thunder | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| enlightened_engine_access_cut_thor | tutor_access | Enlightened Tutor | Thor, God of Thunder | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| gamble_access_benchmark_cut_land_tax | tutor_access_benchmark | Gamble | Land Tax | - | - | +0.00 | +0.00 | `skipped_prior_evidence` |
| enlightened_access_benchmark_cut_land_tax | tutor_access_benchmark | Enlightened Tutor | Land Tax | - | - | +0.00 | +0.00 | `skipped_prior_evidence` |
| galvanoth_topdeck_freecast | topdeck_freecast | Galvanoth | Bender's Waterskin | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| galvanoth_topdeck_freecast_cut_squelcher | topdeck_freecast | Galvanoth | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| galvanoth_topdeck_freecast_cut_chimes | topdeck_freecast | Galvanoth | Victory Chimes | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| galvanoth_topdeck_freecast_cut_thor | topdeck_freecast | Galvanoth | Thor, God of Thunder | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| pg245_verge_rangers_topdeck_land_cut_waterskin | topdeck_play | Verge Rangers | Bender's Waterskin | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| brainstone_topdeck_miracle | topdeck_setup | Brainstone | Bender's Waterskin | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| brainstone_topdeck_miracle_cut_squelcher | topdeck_setup | Brainstone | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| faithless_looting_squee_enabler | discard_rummage_recursion | Faithless Looting | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| penance_topdeck_protection_cut_squelcher | topdeck_protection | Penance | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| penance_runtime_topdeck_cut_promise | topdeck_protection | Penance | Promise of Loyalty | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| ghostly_prison_pressure_cut_squelcher | pressure_absorber | Ghostly Prison | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| boros_charm_pressure_cut_fated | pressure_absorber | Boros Charm | Fated Clash | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| boros_charm_pressure_cut_avatar_wrath | pressure_absorber | Boros Charm | Avatar's Wrath | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| perch_protection_cut_avatar_wrath | pressure_absorber | Perch Protection | Avatar's Wrath | 4-5 | 4-5 | +0.00 | +0.00 | `reject_regresses_strong_seed` |
| akromas_will_cut_avatar_wrath | pressure_absorber | Akroma's Will | Avatar's Wrath | 4-5 | 0-9 | -44.44 | -44.44 | `reject_regresses_strong_seed` |
| silence_cut_avatar_wrath | spell_protection | Silence | Avatar's Wrath | 4-5 | 4-5 | +0.00 | +0.00 | `reject_regresses_strong_seed` |
| gods_willing_commander_shield_cut_promise | targeted_commander_protection | Gods Willing | Promise of Loyalty | 4-5 | 3-6 | -11.11 | -11.11 | `reject_regresses_strong_seed` |
| sejiri_shelter_commander_shield_cut_promise | targeted_commander_protection | Sejiri Shelter // Sejiri Glacier | Promise of Loyalty | 4-5 | 0-9 | -44.44 | -44.44 | `reject_regresses_strong_seed` |
| dragon_rage_channeler_cut_scarlet_witch | topdeck_filter | Dragon's Rage Channeler | The Scarlet Witch | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| grand_abolisher_cut_mother_of_runes | spell_protection | Grand Abolisher | Mother of Runes | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| reprieve_cut_avatar_wrath | spell_protection | Reprieve | Avatar's Wrath | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| angel_grace_life_floor_cut_dawn | life_floor_protection | Angel's Grace | Dawn's Truce | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| primal_amulet_spell_engine | cost_reduce_copy | Primal Amulet // Primal Wellspring | Bender's Waterskin | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| chandra_copy_engine | spell_copy | Chandra, Hope's Beacon | Bender's Waterskin | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| arcane_bombardment_engine | spell_copy_recursion | Arcane Bombardment | Bender's Waterskin | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| past_in_flames_recast | graveyard_recast | Past in Flames | Bender's Waterskin | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| radiant_scrollwielder_cut_scarlet_witch | graveyard_recursion | Radiant Scrollwielder | The Scarlet Witch | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| volcanic_recursion_cut_pinnacle | graveyard_recursion_benchmark | Volcanic Vision | Pinnacle Monk // Mystic Peak | - | - | +0.00 | +0.00 | `skipped_prior_evidence` |
| austere_command_wipe_over_emeria_tradeoff | pressure_reset_tradeoff | Austere Command | Emeria's Call // Emeria, Shattered Skyclave | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| past_in_flames_cut_squelcher | graveyard_recast | Past in Flames | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| past_overmaster_spellchain | graveyard_recast_protection | Past in Flames, Overmaster | Bender's Waterskin, Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| copy_stack_package | spell_copy | Reverberate, Return the Favor, Flare of Duplication | Hexing Squelcher, Bender's Waterskin, Victory Chimes | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| overmaster_protect_draw | spell_protection | Overmaster | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| overmaster_protect_draw_cut_tibalts_trickery | spell_protection | Overmaster | Tibalt's Trickery | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| lapse_approach_topdeck_cut_tibalts_trickery | approach_topdeck_combo | Lapse of Certainty | Tibalt's Trickery | 4-5 | 5-4 | +11.11 | +11.11 | `reject_regresses_strong_seed` |
| valakut_hand_filter_cut_big_score | hand_filter_benchmark | Valakut Awakening // Valakut Stoneforge | Big Score | - | - | +0.00 | +0.00 | `skipped_prior_evidence` |
| wheel_hand_filter_cut_big_score | hand_filter_benchmark | Wheel of Fortune | Big Score | - | - | +0.00 | +0.00 | `skipped_prior_evidence` |
| guttersnipe_spell_payoff_cut_prismari | spellcast_payoff | Guttersnipe | Prismari Pianist | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| pg245_twinflame_damage_payoff_cut_thor | static_damage_modifier | Twinflame Tyrant | Thor, God of Thunder | 4-5 | 3-6 | -11.11 | -11.11 | `reject_or_rework` |
| monastery_mentor_spell_tokens_cut_prismari | spellcast_payoff | Monastery Mentor | Prismari Pianist | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| young_pyromancer_spell_tokens_cut_prismari | spellcast_payoff | Young Pyromancer | Prismari Pianist | 4-5 | 2-7 | -22.22 | -22.22 | `reject_regresses_strong_seed` |
| ghostly_prison_pressure_cut_promise | pressure_absorber | Ghostly Prison | Promise of Loyalty | 4-5 | 1-8 | -33.33 | -33.33 | `reject_regresses_strong_seed` |
| boseiju_spell_protection_land | spell_protection_land | Boseiju, Who Shelters All | Reliquary Tower | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| plateau_timing_upgrade_cut_radiant_summit | mana_base | Plateau | Radiant Summit | - | - | +0.00 | +0.00 | `skipped_prior_evidence` |
| plateau_timing_upgrade_cut_turbulent_steppe | mana_base | Plateau | Turbulent Steppe | - | - | +0.00 | +0.00 | `skipped_prior_evidence` |
| biblioplex_topdeck_land | topdeck_land | The Biblioplex | Reliquary Tower | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| mirrorpool_spellcopy_land | spell_copy_land | Mirrorpool | Reliquary Tower | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| core_challenge_dance_over_storm | payoff_challenge | Dance with Calamity | Storm Herd | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| core_challenge_aetherflux_over_storm | payoff_challenge | Aetherflux Reservoir | Storm Herd | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| core_challenge_past_over_tragic | payoff_challenge | Past in Flames | Tragic Arrogance | - | - | +0.00 | +0.00 | `skipped_prior_evidence` |
| etb_tutor_blink | misc | Imperial Recruiter, Recruiter of the Guard, Ranger-Captain of Eos | Bender's Waterskin, Victory Chimes, Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| sun_titan_blink_value | misc | Sun Titan | Bender's Waterskin | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| sun_titan_cut_chimes | misc | Sun Titan | Victory Chimes | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| sun_titan_cut_squelcher | misc | Sun Titan | Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |
| artifact_etb_value | misc | Archaeomancer's Map, Soul-Guide Lantern, The One Ring | Bender's Waterskin, Victory Chimes, Hexing Squelcher | - | - | +0.00 | +0.00 | `skipped_cut_safety` |

## Seed Detail


### one_ring_burden_reset

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### one_ring_protection_draw_cut_squelcher

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### birgi_spellchain_cut_squelcher

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`

### birgi_spellchain_cut_waterskin

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`

### birgi_spellchain_cut_jeskas_will

- aggregate: `{"avg_seed_delta_pp": -44.44, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "0-9", "candidate_win_rate": 0.0, "decision": "reject_regresses_strong_seed", "delta_pp_total": -44.44, "games": 9, "incomplete_seeds": [], "package_key": "birgi_spellchain_cut_jeskas_will", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### birgi_seething_chain_cut_medallions

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Pearl Medallion", "current_lane": "early_mana", "effective_role": "ramp", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}, {"best_delta_pp": 0.0, "card_name": "Ruby Medallion", "current_lane": "early_mana", "effective_role": "ramp", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Pearl Medallion, Ruby Medallion", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### seething_song_cut_fellwar_stone

- aggregate: `{"avg_seed_delta_pp": -44.44, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "0-9", "candidate_win_rate": 0.0, "decision": "reject_regresses_strong_seed", "delta_pp_total": -44.44, "games": 9, "incomplete_seeds": [], "package_key": "seething_song_cut_fellwar_stone", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### storm_kiln_artist_cut_arcane_signet

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "storm_kiln_artist_cut_arcane_signet", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### brass_bounty_cut_boros_signet

- aggregate: `{"avg_seed_delta_pp": 0.0, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "4-5", "candidate_win_rate": 44.44, "decision": "tie_hold_for_more_games", "delta_pp_total": 0.0, "games": 9, "incomplete_seeds": [], "package_key": "brass_bounty_cut_boros_signet", "strong_seed_regressions": []}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 3/0/0 `100.00%` | +0.00 | `tie_promote_to_deeper_gate` |

### runaway_steamkin_cut_talisman

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "runaway_steamkin_cut_talisman", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### gamble_approach_access_cut_creative

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Creative Technique", "current_lane": "finisher_or_big_spell", "effective_role": "big_spell_value", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Creative Technique", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### gamble_access_cut_thor

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Thor, God of Thunder", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### enlightened_engine_access_cut_thor

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Thor, God of Thunder", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### gamble_access_benchmark_cut_land_tax

- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### enlightened_access_benchmark_cut_land_tax

- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### galvanoth_topdeck_freecast

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`

### galvanoth_topdeck_freecast_cut_squelcher

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### galvanoth_topdeck_freecast_cut_chimes

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Victory Chimes", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### galvanoth_topdeck_freecast_cut_thor

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Thor, God of Thunder", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### pg245_verge_rangers_topdeck_land_cut_waterskin

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "pg245_verge_rangers_topdeck_land_cut_waterskin", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### brainstone_topdeck_miracle

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### brainstone_topdeck_miracle_cut_squelcher

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### faithless_looting_squee_enabler

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### penance_topdeck_protection_cut_squelcher

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### penance_runtime_topdeck_cut_promise

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "penance_runtime_topdeck_cut_promise", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_watch_strategy_regression` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### ghostly_prison_pressure_cut_squelcher

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### boros_charm_pressure_cut_fated

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -88.89, "card_name": "Fated Clash", "current_lane": "pressure_absorber_or_protection", "effective_role": "removal", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -88.89}], "reason": "proposed cuts already have blocker evidence: Fated Clash", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### boros_charm_pressure_cut_avatar_wrath

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "boros_charm_pressure_cut_avatar_wrath", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### perch_protection_cut_avatar_wrath

- aggregate: `{"avg_seed_delta_pp": 0.0, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "4-5", "candidate_win_rate": 44.44, "decision": "reject_regresses_strong_seed", "delta_pp_total": 0.0, "games": 9, "incomplete_seeds": [], "package_key": "perch_protection_cut_avatar_wrath", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 1/2/0 `33.33%` | +33.33 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### akromas_will_cut_avatar_wrath

- aggregate: `{"avg_seed_delta_pp": -44.44, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "0-9", "candidate_win_rate": 0.0, "decision": "reject_regresses_strong_seed", "delta_pp_total": -44.44, "games": 9, "incomplete_seeds": [], "package_key": "akromas_will_cut_avatar_wrath", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### silence_cut_avatar_wrath

- aggregate: `{"avg_seed_delta_pp": 0.0, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "4-5", "candidate_win_rate": 44.44, "decision": "reject_regresses_strong_seed", "delta_pp_total": 0.0, "games": 9, "incomplete_seeds": [], "package_key": "silence_cut_avatar_wrath", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 1/2/0 `33.33%` | +33.33 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### gods_willing_commander_shield_cut_promise

- aggregate: `{"avg_seed_delta_pp": -11.11, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "3-6", "candidate_win_rate": 33.33, "decision": "reject_regresses_strong_seed", "delta_pp_total": -11.11, "games": 9, "incomplete_seeds": [], "package_key": "gods_willing_commander_shield_cut_promise", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 1/2/0 `33.33%` | +33.33 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### sejiri_shelter_commander_shield_cut_promise

- aggregate: `{"avg_seed_delta_pp": -44.44, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "0-9", "candidate_win_rate": 0.0, "decision": "reject_regresses_strong_seed", "delta_pp_total": -44.44, "games": 9, "incomplete_seeds": [], "package_key": "sejiri_shelter_commander_shield_cut_promise", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### dragon_rage_channeler_cut_scarlet_witch

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "dragon_rage_channeler_cut_scarlet_witch", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 1/2/0 `33.33%` | +33.33 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### grand_abolisher_cut_mother_of_runes

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "grand_abolisher_cut_mother_of_runes", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### reprieve_cut_avatar_wrath

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "reprieve_cut_avatar_wrath", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### angel_grace_life_floor_cut_dawn

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -18.52, "card_name": "Dawn's Truce", "current_lane": "hand_filter", "effective_role": "protection", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -88.89}], "reason": "proposed cuts already have blocker evidence: Dawn's Truce", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### primal_amulet_spell_engine

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`

### chandra_copy_engine

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### arcane_bombardment_engine

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`

### past_in_flames_recast

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### radiant_scrollwielder_cut_scarlet_witch

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "radiant_scrollwielder_cut_scarlet_witch", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### volcanic_recursion_cut_pinnacle

- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### austere_command_wipe_over_emeria_tradeoff

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "austere_command_wipe_over_emeria_tradeoff", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### past_in_flames_cut_squelcher

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### past_overmaster_spellchain

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}, {"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin, Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### copy_stack_package

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}, {"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}, {"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher, Bender's Waterskin, Victory Chimes", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`

### overmaster_protect_draw

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### overmaster_protect_draw_cut_tibalts_trickery

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "overmaster_protect_draw_cut_tibalts_trickery", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 1/2/0 `33.33%` | +33.33 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### lapse_approach_topdeck_cut_tibalts_trickery

- aggregate: `{"avg_seed_delta_pp": 11.11, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "5-4", "candidate_win_rate": 55.56, "decision": "reject_regresses_strong_seed", "delta_pp_total": 11.11, "games": 9, "incomplete_seeds": [], "package_key": "lapse_approach_topdeck_cut_tibalts_trickery", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 3/0/0 `100.00%` | +100.00 | `promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### valakut_hand_filter_cut_big_score

- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### wheel_hand_filter_cut_big_score

- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### guttersnipe_spell_payoff_cut_prismari

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "guttersnipe_spell_payoff_cut_prismari", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 2/1/0 `66.67%` | +33.34 | `promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### pg245_twinflame_damage_payoff_cut_thor

- aggregate: `{"avg_seed_delta_pp": -11.11, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "3-6", "candidate_win_rate": 33.33, "decision": "reject_or_rework", "delta_pp_total": -11.11, "games": 9, "incomplete_seeds": [], "package_key": "pg245_twinflame_damage_payoff_cut_thor", "strong_seed_regressions": []}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 0/3/0 `0.00%` | -33.33 | `reject_or_rework` |
| 42 | 3/0/0 `100.00%` | 3/0/0 `100.00%` | +0.00 | `tie_watch_strategy_regression` |

### monastery_mentor_spell_tokens_cut_prismari

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "monastery_mentor_spell_tokens_cut_prismari", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### young_pyromancer_spell_tokens_cut_prismari

- aggregate: `{"avg_seed_delta_pp": -22.22, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "2-7", "candidate_win_rate": 22.22, "decision": "reject_regresses_strong_seed", "delta_pp_total": -22.22, "games": 9, "incomplete_seeds": [], "package_key": "young_pyromancer_spell_tokens_cut_prismari", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_promote_to_deeper_gate` |
| 42 | 3/0/0 `100.00%` | 1/2/0 `33.33%` | -66.67 | `reject_or_rework` |

### ghostly_prison_pressure_cut_promise

- aggregate: `{"avg_seed_delta_pp": -33.33, "baseline_record": "4-5", "baseline_win_rate": 44.44, "candidate_record": "1-8", "candidate_win_rate": 11.11, "decision": "reject_regresses_strong_seed", "delta_pp_total": -33.33, "games": 9, "incomplete_seeds": [], "package_key": "ghostly_prison_pressure_cut_promise", "strong_seed_regressions": [42]}`

| Seed | Baseline | Candidate | Delta | Decision |
| ---: | --- | --- | ---: | --- |
| 7 | 0/3/0 `0.00%` | 0/3/0 `0.00%` | +0.00 | `tie_promote_to_deeper_gate` |
| 20260625 | 1/2/0 `33.33%` | 1/2/0 `33.33%` | +0.00 | `tie_watch_strategy_regression` |
| 42 | 3/0/0 `100.00%` | 0/3/0 `0.00%` | -100.00 | `reject_or_rework` |

### boseiju_spell_protection_land

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -55.56, "card_name": "Reliquary Tower", "current_lane": "mana_base", "effective_role": "land", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Reliquary Tower", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### plateau_timing_upgrade_cut_radiant_summit

- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### plateau_timing_upgrade_cut_turbulent_steppe

- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### biblioplex_topdeck_land

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -55.56, "card_name": "Reliquary Tower", "current_lane": "mana_base", "effective_role": "land", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Reliquary Tower", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### mirrorpool_spellcopy_land

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -55.56, "card_name": "Reliquary Tower", "current_lane": "mana_base", "effective_role": "land", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Reliquary Tower", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### core_challenge_dance_over_storm

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -3.7, "card_name": "Storm Herd", "current_lane": "finisher_or_big_spell", "effective_role": "wincon", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -88.89}], "reason": "proposed cuts already have blocker evidence: Storm Herd", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`

### core_challenge_aetherflux_over_storm

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -3.7, "card_name": "Storm Herd", "current_lane": "finisher_or_big_spell", "effective_role": "wincon", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -88.89}], "reason": "proposed cuts already have blocker evidence: Storm Herd", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### core_challenge_past_over_tragic

- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`

### etb_tutor_blink

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}, {"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}, {"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin, Victory Chimes, Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### sun_titan_blink_value

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### sun_titan_cut_chimes

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Victory Chimes", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### sun_titan_cut_squelcher

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`

### artifact_etb_value

- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "status": "risky_cut_only_same_lane", "worst_strong_seed_delta_pp": -44.45}, {"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}, {"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts already have blocker evidence: Bender's Waterskin, Victory Chimes, Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"latest_decision": null, "latest_delta_pp": null, "latest_source_report": null, "match_count": 0, "reason": "no previous package-key result", "status": "clear"}`
