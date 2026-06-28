# Lorehold Synergy Package Gate

- generated_at: `2026-06-28T07:39:04.778605+00:00`
- source_db: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- source_db_mutated: `false`
- games_per_opponent: `1`
- opponent_limit: `3`
- opponent_seed: `20260626`
- simulation_seed: `42`
- preflight_only: `True`
- apply_only: `False`
- no_game_checkpoint: `False`
- runtime_package_proposal_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260628_v5_topdeck_damage_proposals.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/xmage_hidden_retreat_runtime_scope_20260628_v3_proposals.json`
- package_definition_files: `-`
- cut_safety_report: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- protected_cut_registry: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json`
- prior_package_reports: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_confirm_matrix_20260628_v2_20260628_072000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json, /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000.json`
- package_status_counts: `{"preflight_ready": 6, "skipped_cut_safety": 51, "skipped_prior_evidence": 15}`

| Package | Family | Adds | Cuts | Preflight | Baseline | Candidate | Delta | Strategic Delta | Decision |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- |
| one_ring_burden_reset | misc | The One Ring | Bender's Waterskin | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| one_ring_protection_draw_cut_squelcher | draw_protection | The One Ring | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| birgi_spellchain_cut_squelcher | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Hexing Squelcher | `blocked_cut_safety;seen_no_blocker` | - | - | +0.00 | - | skipped_cut_safety |
| birgi_spellchain_cut_waterskin | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Bender's Waterskin | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| birgi_spellchain_cut_jeskas_will | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Jeska's Will | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| birgi_seething_chain_cut_medallions | spellchain_mana | Birgi, God of Storytelling // Harnfel, Horn of Bounty, Seething Song | Pearl Medallion, Ruby Medallion | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| seething_song_cut_fellwar_stone | spellchain_mana | Seething Song | Fellwar Stone | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| storm_kiln_artist_cut_arcane_signet | spellchain_mana | Storm-Kiln Artist | Arcane Signet | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| mana_vault_fast_mana_cut_arcane_signet | fast_mana | Mana Vault | Arcane Signet | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| brass_bounty_cut_boros_signet | spellchain_mana | Brass's Bounty | Boros Signet | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| runaway_steamkin_cut_talisman | spellchain_mana | Runaway Steam-Kin | Talisman of Conviction | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| gamble_approach_access_cut_creative | tutor_access | Gamble | Creative Technique | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| gamble_access_cut_thor | tutor_access | Gamble | Thor, God of Thunder | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| enlightened_engine_access_cut_thor | tutor_access | Enlightened Tutor | Thor, God of Thunder | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| gamble_access_benchmark_cut_land_tax | tutor_access_benchmark | Gamble | Land Tax | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| enlightened_access_benchmark_cut_land_tax | tutor_access_benchmark | Enlightened Tutor | Land Tax | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| galvanoth_topdeck_freecast | topdeck_freecast | Galvanoth | Bender's Waterskin | `blocked_cut_safety;seen_no_blocker` | - | - | +0.00 | - | skipped_cut_safety |
| galvanoth_topdeck_freecast_cut_squelcher | topdeck_freecast | Galvanoth | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| galvanoth_topdeck_freecast_cut_chimes | topdeck_freecast | Galvanoth | Victory Chimes | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| galvanoth_topdeck_freecast_cut_thor | topdeck_freecast | Galvanoth | Thor, God of Thunder | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| pg245_verge_rangers_topdeck_land_cut_waterskin | topdeck_play | Verge Rangers | Bender's Waterskin | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| brainstone_topdeck_miracle | topdeck_setup | Brainstone | Bender's Waterskin | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| brainstone_topdeck_miracle_cut_squelcher | topdeck_setup | Brainstone | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| faithless_looting_squee_enabler | discard_rummage_recursion | Faithless Looting | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| penance_topdeck_protection_cut_squelcher | topdeck_protection | Penance | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| penance_runtime_topdeck_cut_promise | topdeck_protection | Penance | Promise of Loyalty | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| hidden_retreat_stack_damage_topdeck_cut_promise | topdeck_protection | Hidden Retreat | Promise of Loyalty | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| ghostly_prison_pressure_cut_squelcher | pressure_absorber | Ghostly Prison | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| boros_charm_pressure_cut_fated | pressure_absorber | Boros Charm | Fated Clash | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| boros_charm_pressure_cut_avatar_wrath | pressure_absorber | Boros Charm | Avatar's Wrath | `clear` | - | - | +0.00 | - | preflight_ready |
| perch_protection_cut_avatar_wrath | pressure_absorber | Perch Protection | Avatar's Wrath | `clear` | - | - | +0.00 | - | preflight_ready |
| akromas_will_cut_avatar_wrath | pressure_absorber | Akroma's Will | Avatar's Wrath | `clear` | - | - | +0.00 | - | preflight_ready |
| silence_cut_avatar_wrath | spell_protection | Silence | Avatar's Wrath | `clear` | - | - | +0.00 | - | preflight_ready |
| gods_willing_commander_shield_cut_promise | targeted_commander_protection | Gods Willing | Promise of Loyalty | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| sejiri_shelter_commander_shield_cut_promise | targeted_commander_protection | Sejiri Shelter // Sejiri Glacier | Promise of Loyalty | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| dragon_rage_channeler_cut_scarlet_witch | topdeck_filter | Dragon's Rage Channeler | The Scarlet Witch | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| grand_abolisher_cut_mother_of_runes | spell_protection | Grand Abolisher | Mother of Runes | `clear` | - | - | +0.00 | - | preflight_ready |
| reprieve_cut_avatar_wrath | spell_protection | Reprieve | Avatar's Wrath | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| angel_grace_life_floor_cut_dawn | life_floor_protection | Angel's Grace | Dawn's Truce | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| primal_amulet_spell_engine | cost_reduce_copy | Primal Amulet // Primal Wellspring | Bender's Waterskin | `blocked_cut_safety;seen_no_blocker` | - | - | +0.00 | - | skipped_cut_safety |
| chandra_copy_engine | spell_copy | Chandra, Hope's Beacon | Bender's Waterskin | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| arcane_bombardment_engine | spell_copy_recursion | Arcane Bombardment | Bender's Waterskin | `blocked_cut_safety;seen_no_blocker` | - | - | +0.00 | - | skipped_cut_safety |
| past_in_flames_recast | graveyard_recast | Past in Flames | Bender's Waterskin | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| radiant_scrollwielder_cut_scarlet_witch | graveyard_recursion | Radiant Scrollwielder | The Scarlet Witch | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| volcanic_recursion_cut_pinnacle | graveyard_recursion_benchmark | Volcanic Vision | Pinnacle Monk // Mystic Peak | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| austere_command_wipe_over_emeria_tradeoff | pressure_reset_tradeoff | Austere Command | Emeria's Call // Emeria, Shattered Skyclave | `clear` | - | - | +0.00 | - | preflight_ready |
| past_in_flames_cut_squelcher | graveyard_recast | Past in Flames | Hexing Squelcher | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| past_overmaster_spellchain | graveyard_recast_protection | Past in Flames, Overmaster | Bender's Waterskin, Hexing Squelcher | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| copy_stack_package | spell_copy | Reverberate, Return the Favor, Flare of Duplication | Hexing Squelcher, Bender's Waterskin, Victory Chimes | `blocked_cut_safety;seen_no_blocker` | - | - | +0.00 | - | skipped_cut_safety |
| overmaster_protect_draw | spell_protection | Overmaster | Hexing Squelcher | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| overmaster_protect_draw_cut_tibalts_trickery | spell_protection | Overmaster | Tibalt's Trickery | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| lapse_approach_topdeck_cut_tibalts_trickery | approach_topdeck_combo | Lapse of Certainty | Tibalt's Trickery | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| valakut_hand_filter_cut_big_score | hand_filter_benchmark | Valakut Awakening // Valakut Stoneforge | Big Score | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| wheel_hand_filter_cut_big_score | hand_filter_benchmark | Wheel of Fortune | Big Score | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| guttersnipe_spell_payoff_cut_prismari | spellcast_payoff | Guttersnipe | Prismari Pianist | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| pg245_twinflame_damage_payoff_cut_thor | static_damage_modifier | Twinflame Tyrant | Thor, God of Thunder | `override_locked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| monastery_mentor_spell_tokens_cut_prismari | spellcast_payoff | Monastery Mentor | Prismari Pianist | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| young_pyromancer_spell_tokens_cut_prismari | spellcast_payoff | Young Pyromancer | Prismari Pianist | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| ghostly_prison_pressure_cut_promise | pressure_absorber | Ghostly Prison | Promise of Loyalty | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| boseiju_spell_protection_land | spell_protection_land | Boseiju, Who Shelters All | Reliquary Tower | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| plateau_timing_upgrade_cut_radiant_summit | mana_base | Plateau | Radiant Summit | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| plateau_timing_upgrade_cut_turbulent_steppe | mana_base | Plateau | Turbulent Steppe | `clear;blocked_prior_reject` | - | - | +0.00 | - | skipped_prior_evidence |
| biblioplex_topdeck_land | topdeck_land | The Biblioplex | Reliquary Tower | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| mirrorpool_spellcopy_land | spell_copy_land | Mirrorpool | Reliquary Tower | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| core_challenge_dance_over_storm | payoff_challenge | Dance with Calamity | Storm Herd | `blocked_cut_safety;seen_no_blocker` | - | - | +0.00 | - | skipped_cut_safety |
| core_challenge_aetherflux_over_storm | payoff_challenge | Aetherflux Reservoir | Storm Herd | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| core_challenge_past_over_tragic | payoff_challenge | Past in Flames | Tragic Arrogance | `blocked_cut_safety;blocked_prior_reject` | - | - | +0.00 | - | skipped_cut_safety |
| etb_tutor_blink | misc | Imperial Recruiter, Recruiter of the Guard, Ranger-Captain of Eos | Bender's Waterskin, Victory Chimes, Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| sun_titan_blink_value | misc | Sun Titan | Bender's Waterskin | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| sun_titan_cut_chimes | misc | Sun Titan | Victory Chimes | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| sun_titan_cut_squelcher | misc | Sun Titan | Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |
| artifact_etb_value | misc | Archaeomancer's Map, Soul-Guide Lantern, The One Ring | Bender's Waterskin, Victory Chimes, Hexing Squelcher | `blocked_cut_safety` | - | - | +0.00 | - | skipped_cut_safety |

## Package Notes

### one_ring_burden_reset

- family: misc
- hypothesis: The Mind Stone can reset The One Ring burden counters after harness; test whether that draw engine is worth a non-core utility/ramp slot.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### one_ring_protection_draw_cut_squelcher

- family: draw_protection
- hypothesis: The One Ring may buy the exact turn seed 20260625 lacks while adding repeatable draw. This preserves the three-mana ramp shell and cuts the narrower anti-counter creature instead.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### birgi_spellchain_cut_squelcher

- family: spellchain_mana
- hypothesis: Birgi adds red mana on every spell cast, which should help Lorehold chain miracle spells without cutting the expensive spell package.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"], "adds_signature": ["birgi, god of storytelling // harnfel, horn of bounty"], "baseline": {"avg_win_turn": 11.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 22, "miracle_cast": 5, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "candidate": {"avg_win_turn": 15.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 24, "lorehold_spell_cast": 22, "miracle_cast": 5}, "win_rate": 50.0, "wins": 1}, "cuts": ["Hexing Squelcher"], "cuts_signature": ["hexing squelcher"], "decision": "tie_promote_to_deeper_gate", "delta_pp": 0.0, "family": "spellchain_mana", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_birgi_spellchain_cut_squelcher.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_birgi_spellchain_cut_squelcher.md", "gate_returncode": 0, "package_key": "birgi_spellchain_cut_squelcher", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -4, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": 0, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": 0, "random_discard_after_tutor": 1, "ritual_mana_added": 2, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -3, "tutor_resolved": 2}}], "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### birgi_spellchain_cut_waterskin

- family: spellchain_mana
- hypothesis: Birgi may outperform a three-mana mana rock because the deck often casts several spells in a turn after a miracle setup.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"], "adds_signature": ["birgi, god of storytelling // harnfel, horn of bounty"], "baseline": {}, "candidate": {}, "cuts": ["Bender's Waterskin"], "cuts_signature": ["bender's waterskin"], "decision": "reject_or_rework", "delta_pp": null, "family": "registry_rejected", "gate_json": null, "gate_markdown": null, "gate_returncode": null, "package_key": "registry:tested:5:birgi, god of storytelling // harnfel, horn of bounty", "registry_learning": "Isolated Birgi sidegrade kept structural intent at 100, but reduced miracle games from 8/9 to 4/9 and topdeck games from 3/9 to 2/9 versus the same deck_607 gate. Bender's Waterskin remains protected until a same-function replacement wins.", "registry_result": "3W/6L/0S, WR 33.33%, Winota 1W/2L, miracle games 4/9, topdeck games 2/9", "registry_section": "tested", "registry_status": "rejected", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json", "strategic_delta": {}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### birgi_spellchain_cut_jeskas_will

- family: spellchain_mana
- hypothesis: Birgi tests the same early-mana/spell-chain job without cutting the now-protected medallions, Bender's Waterskin, or Victory Chimes. Jeska's Will is the comparison slot because it is a powerful but one-shot mana burst rather than a repeatable cast-trigger engine.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Birgi, God of Storytelling // Harnfel, Horn of Bounty"], "adds_signature": ["birgi, god of storytelling // harnfel, horn of bounty"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 3, "lorehold_cost_paid": 61, "lorehold_spell_cast": 53, "lorehold_spell_rummage": 16, "lorehold_spell_rummage_discards_squee": 4, "lorehold_upkeep_rummage": 8, "miracle_cast": 13, "squee_return_after_known_graveyard_entry": 3, "squee_to_graveyard": 4, "squee_upkeep_return": 3, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"birgi_spell_cast_mana": 1, "lorehold_cost_paid": 20, "lorehold_spell_cast": 13, "lorehold_upkeep_rummage": 6, "miracle_cast": 1, "spell_cast_mana_trigger": 1}, "win_rate": 0.0, "wins": 0}, "cuts": ["Jeska's Will"], "cuts_signature": ["jeska's will"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "spellchain_mana", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000_birgi_spellchain_cut_jeskas_will.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000_birgi_spellchain_cut_jeskas_will.md", "gate_returncode": 0, "package_key": "birgi_spellchain_cut_jeskas_will", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json", "strategic_delta": {"birgi_spell_cast_mana": 1, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -41, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -40, "lorehold_spell_rummage": -16, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -12, "random_discard_after_tutor": -1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 1, "squee_return_after_known_graveyard_entry": -3, "squee_to_graveyard": -4, "squee_upkeep_return": -3, "topdeck_manipulation_activated": -12, "tutor_resolved": -5}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### birgi_seething_chain_cut_medallions

- family: spellchain_mana
- hypothesis: The loss classifier shows mana/spell-volume failures under pressure. This imports the narrow 615 ritual lane while preserving Dawn's Truce, Teferi's Protection, High Noon, Hexing Squelcher, Storm Herd, and the three-mana ramp shell; it tests whether cast-trigger mana plus a one-shot ritual beats static red/white medallion discounts.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Pearl Medallion", "current_lane": "early_mana", "effective_role": "ramp", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}, {"best_delta_pp": 0.0, "card_name": "Ruby Medallion", "current_lane": "early_mana", "effective_role": "ramp", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Pearl Medallion, Ruby Medallion", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### seething_song_cut_fellwar_stone

- family: spellchain_mana
- hypothesis: Seething Song tests whether a ritual burst converts the current mana/spell bottleneck faster than a generic two-mana rock while preserving all cut-safety-protected ramp slots.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Seething Song"], "adds_signature": ["seething song"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 3, "lorehold_cost_paid": 61, "lorehold_spell_cast": 53, "lorehold_spell_rummage": 16, "lorehold_spell_rummage_discards_squee": 4, "lorehold_upkeep_rummage": 8, "miracle_cast": 13, "squee_return_after_known_graveyard_entry": 3, "squee_to_graveyard": 4, "squee_upkeep_return": 3, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 31, "lorehold_spell_cast": 29, "lorehold_spell_rummage": 2, "lorehold_upkeep_rummage": 21, "miracle_cast": 6, "topdeck_manipulation_activated": 4}, "win_rate": 0.0, "wins": 0}, "cuts": ["Fellwar Stone"], "cuts_signature": ["fellwar stone"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "spellchain_mana", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000_seething_song_cut_fellwar_stone.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000_seething_song_cut_fellwar_stone.md", "gate_returncode": 0, "package_key": "seething_song_cut_fellwar_stone", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -30, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -24, "lorehold_spell_rummage": -14, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -7, "random_discard_after_tutor": -1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -3, "squee_to_graveyard": -4, "squee_upkeep_return": -3, "topdeck_manipulation_activated": -8, "tutor_resolved": -1}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### storm_kiln_artist_cut_arcane_signet

- family: spellchain_mana
- hypothesis: Storm-Kiln Artist can turn every instant or sorcery into treasure. This tests a repeatable spell-mana engine over the most generic untested rock, without touching medallions, Bender's Waterskin, Victory Chimes, or the finisher package.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Storm-Kiln Artist"], "adds_signature": ["storm-kiln artist"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 3, "lorehold_cost_paid": 61, "lorehold_spell_cast": 53, "lorehold_spell_rummage": 16, "lorehold_spell_rummage_discards_squee": 4, "lorehold_upkeep_rummage": 8, "miracle_cast": 13, "squee_return_after_known_graveyard_entry": 3, "squee_to_graveyard": 4, "squee_upkeep_return": 3, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 20.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 1, "lorehold_cost_paid": 38, "lorehold_spell_cast": 29, "lorehold_spell_rummage": 5, "lorehold_spell_rummage_discards_squee": 1, "lorehold_upkeep_rummage": 7, "miracle_cast": 8, "squee_return_after_known_graveyard_entry": 1, "squee_to_graveyard": 1, "squee_upkeep_return": 1, "topdeck_manipulation_activated": 5}, "win_rate": 33.33, "wins": 1}, "cuts": ["Arcane Signet"], "cuts_signature": ["arcane signet"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "spellchain_mana", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000_storm_kiln_artist_cut_arcane_signet.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000_storm_kiln_artist_cut_arcane_signet.md", "gate_returncode": 0, "package_key": "storm_kiln_artist_cut_arcane_signet", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_storm_kiln_artist_gate_20260628_v1_20260628_082000.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -23, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -24, "lorehold_spell_rummage": -11, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -5, "random_discard_after_tutor": 0, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -2, "squee_to_graveyard": -3, "squee_upkeep_return": -2, "topdeck_manipulation_activated": -7, "tutor_resolved": -2}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### mana_vault_fast_mana_cut_arcane_signet

- family: fast_mana
- hypothesis: Mana Vault is legal, battle-ready fast mana and appears in multiple Lorehold variants. This tests whether one-mana colorless burst accelerates commander and expensive spell windows more than Arcane Signet's colored fixing, without cutting protected medallions, Bender's Waterskin, Victory Chimes, or Jeska's Will.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Mana Vault"], "adds_signature": ["mana vault"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 3, "lorehold_cost_paid": 61, "lorehold_spell_cast": 53, "lorehold_spell_rummage": 16, "lorehold_spell_rummage_discards_squee": 4, "lorehold_upkeep_rummage": 8, "miracle_cast": 13, "squee_return_after_known_graveyard_entry": 3, "squee_to_graveyard": 4, "squee_upkeep_return": 3, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 24.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 30, "lorehold_spell_cast": 25, "lorehold_upkeep_rummage": 9, "miracle_cast": 7, "topdeck_manipulation_activated": 11}, "win_rate": 33.33, "wins": 1}, "cuts": ["Arcane Signet"], "cuts_signature": ["arcane signet"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "fast_mana", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000_mana_vault_fast_mana_cut_arcane_signet.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000_mana_vault_fast_mana_cut_arcane_signet.md", "gate_returncode": 0, "package_key": "mana_vault_fast_mana_cut_arcane_signet", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_vault_gate_20260628_v1_20260628_092000.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -31, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -28, "lorehold_spell_rummage": -16, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -6, "random_discard_after_tutor": -1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -3, "squee_to_graveyard": -4, "squee_upkeep_return": -3, "topdeck_manipulation_activated": -1, "tutor_resolved": -2}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### brass_bounty_cut_boros_signet

- family: spellchain_mana
- hypothesis: Brass's Bounty is shared by six Lorehold variants and now has a reviewed runtime model that creates Treasure equal to lands controlled. This tests whether a late ritual/treasure burst is better than the least-blocked two-mana Boros rock without cutting Sol Ring, Bender's Waterskin, medallions, Victory Chimes, or the protection/finisher shell.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Brass's Bounty"], "adds_signature": ["brass's bounty"], "baseline": {"avg_win_turn": null, "losses": null, "stalls": null, "strategic_event_counts": {}, "win_rate": null, "wins": null}, "candidate": {"avg_win_turn": null, "losses": null, "stalls": null, "strategic_event_counts": {}, "win_rate": null, "wins": null}, "cuts": ["Boros Signet"], "cuts_signature": ["boros signet"], "decision": "reject_or_rework", "delta_pp": -2.22, "family": "spellchain_mana", "gate_json": null, "gate_markdown": null, "gate_returncode": null, "package_key": "brass_bounty_cut_boros_signet", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_confirm_matrix_20260628_v2_20260628_072000.json", "strategic_delta": {}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### runaway_steamkin_cut_talisman

- family: spellchain_mana
- hypothesis: Runaway Steam-Kin is a low-curve red spell mana engine. It tests whether repeated red-spell turns create more conversion pressure than a generic two-mana Boros rock while preserving the protected three-mana ramp and medallion shell.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Runaway Steam-Kin"], "adds_signature": ["runaway steam-kin"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 3, "lorehold_cost_paid": 61, "lorehold_spell_cast": 53, "lorehold_spell_rummage": 16, "lorehold_spell_rummage_discards_squee": 4, "lorehold_upkeep_rummage": 8, "miracle_cast": 13, "squee_return_after_known_graveyard_entry": 3, "squee_to_graveyard": 4, "squee_upkeep_return": 3, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 26, "lorehold_spell_cast": 16, "lorehold_upkeep_rummage": 11, "miracle_cast": 1, "topdeck_manipulation_activated": 1}, "win_rate": 0.0, "wins": 0}, "cuts": ["Talisman of Conviction"], "cuts_signature": ["talisman of conviction"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "spellchain_mana", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000_runaway_steamkin_cut_talisman.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000_runaway_steamkin_cut_talisman.md", "gate_returncode": 0, "package_key": "runaway_steamkin_cut_talisman", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_spellchain_safe_cuts_gate_20260628_v1_20260628_084000.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -35, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -37, "lorehold_spell_rummage": -16, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -12, "random_discard_after_tutor": -1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -3, "squee_to_graveyard": -4, "squee_upkeep_return": -3, "topdeck_manipulation_activated": -11, "tutor_resolved": -3}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### gamble_approach_access_cut_creative

- family: tutor_access
- hypothesis: The loss classifier shows topdeck/miracle turns failing to find or recast Approach before combat pressure. Gamble tests a cheap universal tutor over a five-mana demonstrate/free-cast slot while preserving the existing protection, ramp, medallion, Bender's Waterskin, Hexing Squelcher, and Storm Herd shell.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Creative Technique", "current_lane": "finisher_or_big_spell", "effective_role": "big_spell_value", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Creative Technique", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### gamble_access_cut_thor

- family: tutor_access
- hypothesis: Gamble improved weak seeds when it cut Creative Technique but broke seed 42. This retest keeps the modeled free-cast slot and instead cuts Thor, whose local runtime rule has natural exposure but no deck win-rate lift yet, while preserving Dawn's Truce, Teferi's Protection, High Noon, Hexing Squelcher, Storm Herd, medallions, Bender's Waterskin, and the three-mana ramp shell.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Thor, God of Thunder", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### enlightened_engine_access_cut_thor

- family: tutor_access
- hypothesis: Enlightened Tutor tests a lower-risk access line than Gamble: it cannot find Approach, but it can put artifact/enchantment engines on top for Lorehold and miracle setup without random discard. Thor is the cut for the same modeled-not-proven reason as the Gamble retest.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Thor, God of Thunder", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### gamble_access_benchmark_cut_land_tax

- family: tutor_access_benchmark
- hypothesis: The tutor cut model found no seed-safe direct tutor swap, but ranked Land Tax as the highest same-access benchmark. This is not a promotion candidate by itself: it tests whether Gamble's any-card access can outperform Land Tax's upkeep basic-land access without repeating the failed Thor or Creative Technique cuts.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Gamble"], "adds_signature": ["gamble"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "lorehold_spell_rummage": 12, "lorehold_upkeep_rummage": 8, "miracle_cast": 14, "squee_to_graveyard": 1, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 16.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 36, "lorehold_spell_cast": 30, "lorehold_spell_rummage": 8, "lorehold_upkeep_rummage": 4, "miracle_cast": 4}, "win_rate": 33.33, "wins": 1}, "cuts": ["Land Tax"], "cuts_signature": ["land tax"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "tutor_access_benchmark", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_gamble_access_benchmark_cut_land_tax.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_gamble_access_benchmark_cut_land_tax.md", "gate_returncode": 0, "package_key": "gamble_access_benchmark_cut_land_tax", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -25, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -21, "lorehold_spell_rummage": -4, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -10, "random_discard_after_tutor": 1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": -1, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -12, "tutor_resolved": -1}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### enlightened_access_benchmark_cut_land_tax

- family: tutor_access_benchmark
- hypothesis: The tutor cut model found no seed-safe direct tutor swap, but ranked Land Tax as the highest same-access benchmark. Enlightened Tutor is the lower-randomness comparison: it cannot find Approach directly, but it can put artifact/enchantment engines on top for Lorehold's miracle draw window while preserving the failed Thor and Creative Technique slots.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Enlightened Tutor"], "adds_signature": ["enlightened tutor"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "lorehold_spell_rummage": 12, "lorehold_upkeep_rummage": 8, "miracle_cast": 14, "squee_to_graveyard": 1, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 18.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"discard_to_top_replacement": 9, "lorehold_cost_paid": 32, "lorehold_rummage_discard_to_top": 9, "lorehold_spell_cast": 27, "lorehold_upkeep_rummage": 18, "miracle_cast": 14, "topdeck_manipulation_activated": 9}, "win_rate": 33.33, "wins": 1}, "cuts": ["Land Tax"], "cuts_signature": ["land tax"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "tutor_access_benchmark", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_enlightened_access_benchmark_cut_land_tax.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real_enlightened_access_benchmark_cut_land_tax.md", "gate_returncode": 0, "package_key": "enlightened_access_benchmark_cut_land_tax", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_tutor_land_tax_benchmark_gate_20260627_v1_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 9, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -29, "lorehold_rummage_discard_to_top": 9, "lorehold_spell_cast": -24, "lorehold_spell_rummage": -12, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": 0, "random_discard_after_tutor": -1, "ritual_mana_added": 1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": -1, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -3, "tutor_resolved": -4}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### galvanoth_topdeck_freecast

- family: topdeck_freecast
- hypothesis: Galvanoth turns topdeck setup into free upkeep casts for the same expensive instant/sorcery package Lorehold wants to miracle.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Galvanoth"], "adds_signature": ["galvanoth"], "baseline": {"avg_win_turn": 11.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 22, "miracle_cast": 5, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "candidate": {"avg_win_turn": 17.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 32, "lorehold_spell_cast": 23, "miracle_cast": 2}, "win_rate": 50.0, "wins": 1}, "cuts": ["Bender's Waterskin"], "cuts_signature": ["bender's waterskin"], "decision": "tie_watch_strategy_regression", "delta_pp": 0.0, "family": "topdeck_freecast", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_galvanoth_topdeck_freecast.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_galvanoth_topdeck_freecast.md", "gate_returncode": 0, "package_key": "galvanoth_topdeck_freecast", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": 4, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": 1, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -3, "random_discard_after_tutor": 1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -3, "tutor_resolved": 2}}], "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### galvanoth_topdeck_freecast_cut_squelcher

- family: topdeck_freecast
- hypothesis: Galvanoth was aggregate-positive but failed the seed-42 success case when it cut Bender's Waterskin. This retest preserves the ramp shell and cuts the narrower anti-counter creature instead.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### galvanoth_topdeck_freecast_cut_chimes

- family: topdeck_freecast
- hypothesis: Galvanoth was the only aggregate-positive topdeck package, but the Bender's Waterskin cut broke the seed-42 success case and the Hexing Squelcher cut was worse. This retest preserves both colored ramp and anti-counter pressure, cutting the more generic colorless three-mana ramp slot instead.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Victory Chimes", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### galvanoth_topdeck_freecast_cut_thor

- family: topdeck_freecast
- hypothesis: Galvanoth is the current topdeck/freecast lane with a weak-seed signal but bad prior cuts. This retest preserves Bender's Waterskin, Hexing Squelcher, Victory Chimes, the protection shell, and the medallions, cutting Thor only as a same-plan diagnostic because Thor has local runtime exposure but no proven win-rate lift yet.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Thor, God of Thunder", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### pg245_verge_rangers_topdeck_land_cut_waterskin

- family: topdeck_play
- hypothesis: PG245 gives Verge Rangers an executable XMage-backed topdeck land play model. This same-lane diagnostic challenges Bender's Waterskin only because both occupy the three-mana early-mana/topdeck support slot, while preserving the expensive miracle spell package.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### brainstone_topdeck_miracle

- family: topdeck_setup
- hypothesis: Brainstone is another cheap topdeck manipulation artifact that can turn the first draw into a planned miracle window.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Brainstone"], "adds_signature": ["brainstone"], "baseline": {"avg_win_turn": 11.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 22, "miracle_cast": 5, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "candidate": {"avg_win_turn": 0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 15, "lorehold_spell_cast": 11}, "win_rate": 0.0, "wins": 0}, "cuts": ["Bender's Waterskin"], "cuts_signature": ["bender's waterskin"], "decision": "reject_or_rework", "delta_pp": -50.0, "family": "topdeck_setup", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_brainstone_topdeck_miracle.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_brainstone_topdeck_miracle.md", "gate_returncode": 0, "package_key": "brainstone_topdeck_miracle", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -13, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -11, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -5, "random_discard_after_tutor": 0, "ritual_mana_added": 3, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -3, "tutor_resolved": 2}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### brainstone_topdeck_miracle_cut_squelcher

- family: topdeck_setup
- hypothesis: Brainstone failed when it cut Bender's Waterskin; this variant preserves ramp and tests whether a cheap one-shot topdeck engine can help seed 7 find the Library/topdeck conversion line.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### faithless_looting_squee_enabler

- family: discard_rummage_recursion
- hypothesis: Faithless Looting gives the Squee shell a cheap, executable discard outlet plus card flow, testing whether the proven Squee return loop needs more ways to put Squee into the graveyard before Lorehold's topdeck/miracle engine can convert.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### penance_topdeck_protection_cut_squelcher

- family: topdeck_protection
- hypothesis: Penance gives an executable hand-to-library topdeck line plus combat damage prevention. It tests topdeck consistency without relying on land-only placeholder rules such as The Biblioplex or Mirrorpool.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### penance_runtime_topdeck_cut_promise

- family: topdeck_protection
- hypothesis: Penance is retested after the battle runtime learned to use hand-to-library activations proactively as Lorehold miracle setup, not only as a lethal-combat damage shield. This avoids the locked Hexing Squelcher cut and measures whether the new sequencing can replace one five-mana wipe/political spell without reducing the known topdeck engine.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Promise of Loyalty", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Promise of Loyalty", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Penance"], "adds_signature": ["penance"], "baseline": {}, "candidate": {}, "cuts": ["Promise of Loyalty"], "cuts_signature": ["promise of loyalty"], "decision": "reject_or_rework", "delta_pp": null, "family": "registry_rejected", "gate_json": null, "gate_markdown": null, "gate_returncode": null, "package_key": "registry:tested:3:penance", "registry_learning": "Penance is coherent, but cutting pressure absorption hurt the pressure matchup.", "registry_result": "3W/6L/0S, WR 33.33%, Winota 0W/3L", "registry_section": "tested", "registry_status": "rejected", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json", "strategic_delta": {}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### hidden_retreat_stack_damage_topdeck_cut_promise

- family: topdeck_protection
- hypothesis: Hidden Retreat now has a local XMage-backed runtime proposal and responds to damaging instant/sorcery spells by putting a hand card on top of the library and preventing that spell's damage. This isolated overlay test measures whether the stack-damage shield plus miracle-topdeck setup beats the five-mana Promise of Loyalty pressure slot without cutting ramp, medallions, Squee, topdeck engines, or the known protection shell.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Promise of Loyalty", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Promise of Loyalty", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Hidden Retreat"], "adds_signature": ["hidden retreat"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 3, "lorehold_cost_paid": 61, "lorehold_spell_cast": 53, "lorehold_spell_rummage": 16, "lorehold_spell_rummage_discards_squee": 4, "lorehold_upkeep_rummage": 8, "miracle_cast": 13, "squee_return_after_known_graveyard_entry": 3, "squee_to_graveyard": 4, "squee_upkeep_return": 3, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 15.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 35, "lorehold_spell_cast": 26, "lorehold_upkeep_rummage": 6, "miracle_cast": 3, "thor_cost_paid": 1, "thor_spell_cast": 1}, "win_rate": 33.33, "wins": 1}, "cuts": ["Promise of Loyalty"], "cuts_signature": ["promise of loyalty"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "topdeck_protection", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000_hidden_retreat_stack_damage_topdeck_cut_promise.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000_hidden_retreat_stack_damage_topdeck_cut_promise.md", "gate_returncode": 0, "package_key": "hidden_retreat_stack_damage_topdeck_cut_promise", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hidden_retreat_synergy_gate_20260628_v2_20260628_071000.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -26, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -27, "lorehold_spell_rummage": -16, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -10, "random_discard_after_tutor": 0, "ritual_mana_added": -1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -3, "squee_to_graveyard": -4, "squee_upkeep_return": -3, "topdeck_manipulation_activated": -12, "tutor_resolved": -4}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### ghostly_prison_pressure_cut_squelcher

- family: pressure_absorber
- hypothesis: Ghostly Prison directly attacks the seed-20260625 failure mode: the deck can put Approach on top but dies to combat pressure before conversion. This retest avoids the prior bad High Noon cut.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### boros_charm_pressure_cut_fated

- family: pressure_absorber
- hypothesis: Boros Charm appears across the stronger Lorehold variants as cheap instant-speed protection/pressure absorption. This same-lane triage tests whether lowering a five-mana pressure-response slot into a two-mana modal protection spell improves the life-zero combat failures without cutting ramp, topdeck engines, High Noon, Hexing Squelcher, Storm Herd, or the protection shell.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -88.89, "card_name": "Fated Clash", "current_lane": "pressure_absorber_or_protection", "effective_role": "removal", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -88.89}], "reason": "proposed cuts already have blocker evidence: Fated Clash", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### boros_charm_pressure_cut_avatar_wrath

- family: pressure_absorber
- hypothesis: Boros Charm previously failed when it cut protected Fated Clash. This retest keeps Fated Clash, Dawn's Truce, Hexing Squelcher, and the ramp shell intact, using another pressure/protection lane slot as the comparison instead. This is an explicit same-lane high-CMC spell benchmark, not a free cut of the miracle payoff package.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### perch_protection_cut_avatar_wrath

- family: pressure_absorber
- hypothesis: Perch Protection is present in the two strongest non-607 variants and has active local battle rules. It tests a same-lane protection upgrade over Avatar's Wrath while preserving Dawn's Truce, Fated Clash, Hexing Squelcher, High Noon, medallions, Storm Herd, and Thor.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### akromas_will_cut_avatar_wrath

- family: pressure_absorber
- hypothesis: Akroma's Will is a 614 protection/finisher bridge with active local battle rules. It challenges Avatar's Wrath without touching the locked protection shell or the medallion/topdeck engine.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### silence_cut_avatar_wrath

- family: spell_protection
- hypothesis: Silence is shared by 614/615 and protects the decisive Lorehold or Approach turn at one mana. This tests whether cheap proactive stack protection beats a slower protection spell without cutting locked cards.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### gods_willing_commander_shield_cut_promise

- family: targeted_commander_protection
- hypothesis: After the runtime learned targeted protection responses, Gods Willing tests the cheapest 616 commander shield against the seed-7 failure mode where Lorehold died to targeted removal with one mana available. Promise of Loyalty is the pressure-lane comparison slot: it is a five-mana sorcery cleanup spell already challenged by the Ghostly Prison pressure test, while this keeps Mother/Giver, Dawn's Truce, High Noon, topdeck engines, ramp, and the expensive win package intact.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Promise of Loyalty", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Promise of Loyalty", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Gods Willing"], "adds_signature": ["gods willing"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 2, "lorehold_cost_paid": 62, "lorehold_spell_cast": 53, "lorehold_spell_rummage": 16, "lorehold_spell_rummage_discards_squee": 2, "lorehold_upkeep_rummage": 8, "miracle_cast": 13, "squee_return_after_known_graveyard_entry": 2, "squee_to_graveyard": 3, "squee_upkeep_return": 2, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 14.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 21, "lorehold_upkeep_rummage": 7, "miracle_cast": 4}, "win_rate": 33.33, "wins": 1}, "cuts": ["Promise of Loyalty"], "cuts_signature": ["promise of loyalty"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "targeted_commander_protection", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_gods_willing_commander_shield_cut_promise.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_gods_willing_commander_shield_cut_promise.md", "gate_returncode": 0, "package_key": "gods_willing_commander_shield_cut_promise", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -34, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -32, "lorehold_spell_rummage": -16, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -9, "random_discard_after_tutor": -1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -2, "squee_to_graveyard": -3, "squee_upkeep_return": -2, "topdeck_manipulation_activated": -12, "tutor_resolved": -4}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### sejiri_shelter_commander_shield_cut_promise

- family: targeted_commander_protection
- hypothesis: Sejiri Shelter carries the same targeted protection rule as Gods Willing, but costs two mana and is currently evaluated by the local runtime as the spell face rather than as a flexible MDFC land. This benchmark checks whether the extra shield density is still useful when compared against the same five-mana pressure cleanup slot.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Promise of Loyalty", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Promise of Loyalty", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Sejiri Shelter // Sejiri Glacier"], "adds_signature": ["sejiri shelter // sejiri glacier"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 2, "lorehold_cost_paid": 62, "lorehold_spell_cast": 53, "lorehold_spell_rummage": 16, "lorehold_spell_rummage_discards_squee": 2, "lorehold_upkeep_rummage": 8, "miracle_cast": 13, "squee_return_after_known_graveyard_entry": 2, "squee_to_graveyard": 3, "squee_upkeep_return": 2, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 1, "lorehold_cost_paid": 22, "lorehold_rummage_discards_squee": 1, "lorehold_spell_cast": 19, "lorehold_spell_rummage": 1, "lorehold_spell_rummage_discards_squee": 1, "lorehold_upkeep_rummage": 8, "miracle_cast": 2, "squee_return_after_known_graveyard_entry": 1, "squee_to_graveyard": 3, "squee_upkeep_return": 1, "topdeck_manipulation_activated": 2}, "win_rate": 0.0, "wins": 0}, "cuts": ["Promise of Loyalty"], "cuts_signature": ["promise of loyalty"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "targeted_commander_protection", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_sejiri_shelter_commander_shield_cut_promise.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2_sejiri_shelter_commander_shield_cut_promise.md", "gate_returncode": 0, "package_key": "sejiri_shelter_commander_shield_cut_promise", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_targeted_shield_package_gate_20260628_seed42_targeted_shield_v2.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -40, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -34, "lorehold_spell_rummage": -15, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -11, "random_discard_after_tutor": -1, "ritual_mana_added": -1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -1, "squee_to_graveyard": 0, "squee_upkeep_return": -1, "topdeck_manipulation_activated": -10, "tutor_resolved": -6}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### dragon_rage_channeler_cut_scarlet_witch

- family: topdeck_filter
- hypothesis: Dragon's Rage Channeler is a low-cost 614 topdeck/filter engine with active local battle rules. It targets seed 7's missing early engine by challenging The Scarlet Witch, a materialization-sensitive slot.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "The Scarlet Witch", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: The Scarlet Witch", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### grand_abolisher_cut_mother_of_runes

- family: spell_protection
- hypothesis: Grand Abolisher protects the whole decisive turn and appears in 615. Mother of Runes is the same-creature-protection comparison slot, so this is a risky same-lane test rather than a generic support cut.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### reprieve_cut_avatar_wrath

- family: spell_protection
- hypothesis: Reprieve is a 615 tempo/protection card with active local battle rules. It can buy a turn and draw without cutting cards already locked by the seed-42 protection pattern.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Reprieve"], "adds_signature": ["reprieve"], "baseline": {}, "candidate": {}, "cuts": ["Avatar's Wrath"], "cuts_signature": ["avatar's wrath"], "decision": "reject_or_rework", "delta_pp": null, "family": "registry_rejected", "gate_json": null, "gate_markdown": null, "gate_returncode": null, "package_key": "registry:leader_follow_up_probes:2:reprieve", "registry_learning": "Reprieve did not preserve the pressure-absorption shell that the Squee champion is using well. Avatar's Wrath remains the stronger protection slot in this shell.", "registry_result": "0W/3L/0S, WR 0.00%, delta -88.89pp vs Squee baseline 88.89%", "registry_section": "leader_follow_up_probes", "registry_status": "rejected_probe", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json", "strategic_delta": {}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### angel_grace_life_floor_cut_dawn

- family: life_floor_protection
- hypothesis: The loss classifier shows early life-zero deaths even when the deck sometimes finds topdeck or Approach setup. Angel's Grace is a one-mana life-floor effect with executable runtime rules; this tests a same-lane protection swap over Dawn's Truce without cutting ramp, High Noon, Hexing Squelcher, or Storm Herd.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -18.52, "card_name": "Dawn's Truce", "current_lane": "hand_filter", "effective_role": "protection", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -88.89}], "reason": "proposed cuts already have blocker evidence: Dawn's Truce", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### primal_amulet_spell_engine

- family: cost_reduce_copy
- hypothesis: Primal Amulet reduces instant/sorcery costs and can transform into a spell-copying mana land, matching the deck's expensive spell plan.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Primal Amulet // Primal Wellspring"], "adds_signature": ["primal amulet // primal wellspring"], "baseline": {"avg_win_turn": 11.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 22, "miracle_cast": 5, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "candidate": {"avg_win_turn": 10.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 12, "lorehold_spell_cast": 11, "miracle_cast": 2}, "win_rate": 50.0, "wins": 1}, "cuts": ["Bender's Waterskin"], "cuts_signature": ["bender's waterskin"], "decision": "tie_watch_strategy_regression", "delta_pp": 0.0, "family": "cost_reduce_copy", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_primal_amulet_spell_engine.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_primal_amulet_spell_engine.md", "gate_returncode": 0, "package_key": "primal_amulet_spell_engine", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -16, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -11, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -3, "random_discard_after_tutor": 0, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -3, "tutor_resolved": 1}}], "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### chandra_copy_engine

- family: spell_copy
- hypothesis: Chandra, Hope's Beacon copies the first instant or sorcery each turn and can add mana, so it may turn one miracle spell into a win turn.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Chandra, Hope's Beacon"], "adds_signature": ["chandra, hope's beacon"], "baseline": {"avg_win_turn": 11.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 22, "miracle_cast": 5, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "candidate": {"avg_win_turn": 0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 15, "lorehold_spell_cast": 11}, "win_rate": 0.0, "wins": 0}, "cuts": ["Bender's Waterskin"], "cuts_signature": ["bender's waterskin"], "decision": "reject_or_rework", "delta_pp": -50.0, "family": "spell_copy", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_chandra_copy_engine.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_chandra_copy_engine.md", "gate_returncode": 0, "package_key": "chandra_copy_engine", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -13, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -11, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -5, "random_discard_after_tutor": 0, "ritual_mana_added": 3, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -3, "tutor_resolved": 2}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### arcane_bombardment_engine

- family: spell_copy_recursion
- hypothesis: Arcane Bombardment rewards repeated instant/sorcery casting by copying graveyard spells, which should scale with Lorehold chains.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Arcane Bombardment"], "adds_signature": ["arcane bombardment"], "baseline": {"avg_win_turn": 11.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 22, "miracle_cast": 5, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "candidate": {"avg_win_turn": 8.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 12, "lorehold_spell_cast": 10, "miracle_cast": 3, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "cuts": ["Bender's Waterskin"], "cuts_signature": ["bender's waterskin"], "decision": "tie_watch_strategy_regression", "delta_pp": 0.0, "family": "spell_copy_recursion", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_arcane_bombardment_engine.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_arcane_bombardment_engine.md", "gate_returncode": 0, "package_key": "arcane_bombardment_engine", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -16, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -12, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -2, "random_discard_after_tutor": 0, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": 0, "tutor_resolved": -1}}], "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### past_in_flames_recast

- family: graveyard_recast
- hypothesis: Past in Flames turns the graveyard of used instant/sorcery cards into a second spell chain without removing a miracle payoff.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Past in Flames"], "adds_signature": ["past in flames"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "miracle_cast": 14, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 17.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 49, "lorehold_spell_cast": 42, "miracle_cast": 6, "topdeck_manipulation_activated": 11}, "win_rate": 33.33, "wins": 1}, "cuts": ["Bender's Waterskin"], "cuts_signature": ["bender's waterskin"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "graveyard_recast", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331_past_in_flames_recast.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331_past_in_flames_recast.md", "gate_returncode": 0, "package_key": "past_in_flames_recast", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -12, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -9, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -8, "random_discard_after_tutor": -1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -1, "tutor_resolved": -4}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### radiant_scrollwielder_cut_scarlet_witch

- family: graveyard_recursion
- hypothesis: Radiant Scrollwielder tests the 614 recursion/lifegain bridge: it turns a used instant/sorcery into a same-turn recast while giving all controlled instant/sorcery spells lifelink.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "The Scarlet Witch", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: The Scarlet Witch", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### volcanic_recursion_cut_pinnacle

- family: graveyard_recursion_benchmark
- hypothesis: The recursion cut model protects Squee, Farewell, Furygale Flocking, and Mizzix's Mastery. Volcanic Vision over Pinnacle Monk is the first non-Squee same-lane benchmark: it trades a low-exposure ETB recursion engine for a high-cost instant/sorcery recursion spell with opponent creature damage annotation.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Volcanic Vision"], "adds_signature": ["volcanic vision"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "lorehold_spell_rummage": 12, "lorehold_upkeep_rummage": 8, "miracle_cast": 14, "squee_to_graveyard": 1, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 21, "lorehold_spell_cast": 14, "lorehold_upkeep_rummage": 11, "miracle_cast": 1}, "win_rate": 0.0, "wins": 0}, "cuts": ["Pinnacle Monk // Mystic Peak"], "cuts_signature": ["pinnacle monk // mystic peak"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "graveyard_recursion_benchmark", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real_volcanic_recursion_cut_pinnacle.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real_volcanic_recursion_cut_pinnacle.md", "gate_returncode": 0, "package_key": "volcanic_recursion_cut_pinnacle", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_recursion_volcanic_pinnacle_gate_20260627_v2_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -40, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -37, "lorehold_spell_rummage": -12, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -13, "random_discard_after_tutor": 0, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": -1, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -12, "tutor_resolved": -3}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### austere_command_wipe_over_emeria_tradeoff

- family: pressure_reset_tradeoff
- hypothesis: Austere Command is a flexible board reset with active runtime rules, but Emeria's Call now has measured token/protection exposure. This gate is therefore an explicit wipe-over-rebuild tradeoff: it must prove that extra board-reset control beats losing Emeria's rebuild tokens, protection window, and miracle hit density.
- status: `preflight_ready`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### past_in_flames_cut_squelcher

- family: graveyard_recast
- hypothesis: Past in Flames may be strongest if it replaces narrow anti-counter pressure while preserving the deck's three-mana ramp artifact.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Past in Flames"], "adds_signature": ["past in flames"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "miracle_cast": 14, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 14.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 41, "lorehold_spell_cast": 40, "miracle_cast": 3, "topdeck_manipulation_activated": 10}, "win_rate": 33.33, "wins": 1}, "cuts": ["Hexing Squelcher"], "cuts_signature": ["hexing squelcher"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "graveyard_recast", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331_past_in_flames_cut_squelcher.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331_past_in_flames_cut_squelcher.md", "gate_returncode": 0, "package_key": "past_in_flames_cut_squelcher", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -20, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -11, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -11, "random_discard_after_tutor": -1, "ritual_mana_added": -1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -2, "tutor_resolved": -4}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### past_overmaster_spellchain

- family: graveyard_recast_protection
- hypothesis: Past in Flames plus Overmaster combines the winning recast package with the best strategic-engine improvement from the broad triage.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}, {"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Bender's Waterskin, Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Past in Flames", "Overmaster"], "adds_signature": ["overmaster", "past in flames"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "miracle_cast": 14, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 36, "lorehold_spell_cast": 28, "miracle_cast": 6, "topdeck_manipulation_activated": 2}, "win_rate": 0.0, "wins": 0}, "cuts": ["Bender's Waterskin", "Hexing Squelcher"], "cuts_signature": ["bender's waterskin", "hexing squelcher"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "graveyard_recast_protection", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331_past_overmaster_spellchain.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331_past_overmaster_spellchain.md", "gate_returncode": 0, "package_key": "past_overmaster_spellchain", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -25, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -23, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -8, "random_discard_after_tutor": 0, "ritual_mana_added": -1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -10, "tutor_resolved": -3}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### copy_stack_package

- family: spell_copy
- hypothesis: A compact copy package should make the deck's expensive miracle spells matter more without replacing the payoff suite itself.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}, {"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}, {"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts are registry-protected: Hexing Squelcher, Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Reverberate", "Return the Favor", "Flare of Duplication"], "adds_signature": ["flare of duplication", "return the favor", "reverberate"], "baseline": {"avg_win_turn": 11.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 22, "miracle_cast": 5, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "candidate": {"avg_win_turn": 8.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 17, "lorehold_spell_cast": 13, "miracle_cast": 1}, "win_rate": 50.0, "wins": 1}, "cuts": ["Hexing Squelcher", "Bender's Waterskin", "Victory Chimes"], "cuts_signature": ["bender's waterskin", "hexing squelcher", "victory chimes"], "decision": "tie_watch_strategy_regression", "delta_pp": 0.0, "family": "spell_copy", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_copy_stack_package.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_copy_stack_package.md", "gate_returncode": 0, "package_key": "copy_stack_package", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -11, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -9, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -4, "random_discard_after_tutor": 0, "ritual_mana_added": 2, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -3, "tutor_resolved": 0}}], "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### overmaster_protect_draw

- family: spell_protection
- hypothesis: Overmaster protects the next key instant or sorcery and replaces itself, so it may be better than narrow anti-counter pressure.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Overmaster"], "adds_signature": ["overmaster"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "miracle_cast": 14, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 14.0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 41, "lorehold_spell_cast": 40, "miracle_cast": 3, "topdeck_manipulation_activated": 10}, "win_rate": 33.33, "wins": 1}, "cuts": ["Hexing Squelcher"], "cuts_signature": ["hexing squelcher"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "spell_protection", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331_overmaster_protect_draw.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331_overmaster_protect_draw.md", "gate_returncode": 0, "package_key": "overmaster_protect_draw", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_confirm_20260627_real3_v1_20260627_125331.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -20, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -11, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -11, "random_discard_after_tutor": -1, "ritual_mana_added": -1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -2, "tutor_resolved": -4}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### overmaster_protect_draw_cut_tibalts_trickery

- family: spell_protection
- hypothesis: Overmaster protects a decisive instant or sorcery and replaces itself. This tests the spell-protection lane while keeping Hexing Squelcher and the known protection shell intact, comparing against a swingy protection/counter slot instead.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Tibalt's Trickery", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Tibalt's Trickery", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### lapse_approach_topdeck_cut_tibalts_trickery

- family: approach_topdeck_combo
- hypothesis: Lapse of Certainty is an external Lorehold/Approach line: counter the first Approach of the Second Sun and put it on top, then use Lorehold's first-draw miracle window for the second cast. Tibalt's Trickery is the comparison slot because it is the existing swingy counter/protection card.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Tibalt's Trickery", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Tibalt's Trickery", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### valakut_hand_filter_cut_big_score

- family: hand_filter_benchmark
- hypothesis: The hand-filter cut model ranked Valakut Awakening over Big Score as the first benchmark: Valakut has measured hand-filter exposure and a verified MDFC rule, while Big Score is the least-exposed visible protected cut but still provides discard, draw, and Treasure. This is an explicit hand-filter-over-ramp tradeoff, not a free cut.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Valakut Awakening // Valakut Stoneforge"], "adds_signature": ["valakut awakening // valakut stoneforge"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "lorehold_spell_rummage": 12, "lorehold_upkeep_rummage": 8, "miracle_cast": 14, "squee_to_graveyard": 1, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 21, "lorehold_spell_cast": 16, "lorehold_upkeep_rummage": 11, "miracle_cast": 1, "topdeck_manipulation_activated": 2}, "win_rate": 0.0, "wins": 0}, "cuts": ["Big Score"], "cuts_signature": ["big score"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "hand_filter_benchmark", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real_valakut_hand_filter_cut_big_score.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real_valakut_hand_filter_cut_big_score.md", "gate_returncode": 0, "package_key": "valakut_hand_filter_cut_big_score", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_valakut_big_score_gate_20260627_v1_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -40, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -35, "lorehold_spell_rummage": -12, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -13, "random_discard_after_tutor": -1, "ritual_mana_added": -1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": -1, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -10, "tutor_resolved": -3}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### wheel_hand_filter_cut_big_score

- family: hand_filter_benchmark
- hypothesis: After Valakut over Big Score failed, the prior-aware hand-filter cut model ranked Wheel of Fortune as the next exact benchmark. Wheel has verified multiplayer discard/draw runtime and strong Lorehold variant exposure, but this remains an explicit wheel-over-ramp tradeoff because Big Score provides discard, draw, and Treasure.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Wheel of Fortune"], "adds_signature": ["wheel of fortune"], "baseline": {"avg_win_turn": 15.0, "losses": 0, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 61, "lorehold_spell_cast": 51, "lorehold_spell_rummage": 12, "lorehold_upkeep_rummage": 8, "miracle_cast": 14, "squee_to_graveyard": 1, "topdeck_manipulation_activated": 12}, "win_rate": 100.0, "wins": 3}, "candidate": {"avg_win_turn": 0, "losses": 3, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 21, "lorehold_spell_cast": 16, "lorehold_upkeep_rummage": 11, "miracle_cast": 1, "topdeck_manipulation_activated": 2}, "win_rate": 0.0, "wins": 0}, "cuts": ["Big Score"], "cuts_signature": ["big score"], "decision": "reject_or_rework", "delta_pp": -100.0, "family": "hand_filter_benchmark", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real_wheel_hand_filter_cut_big_score.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real_wheel_hand_filter_cut_big_score.md", "gate_returncode": 0, "package_key": "wheel_hand_filter_cut_big_score", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_hand_filter_wheel_big_score_gate_20260627_v1_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -40, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -35, "lorehold_spell_rummage": -12, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -13, "random_discard_after_tutor": -1, "ritual_mana_added": -1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": -1, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -10, "tutor_resolved": -3}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### guttersnipe_spell_payoff_cut_prismari

- family: spellcast_payoff
- hypothesis: Guttersnipe is present in Lorehold variants 615/616 and gives direct multiplayer damage on every instant or sorcery. This tests whether a lower-curve spell payoff converts miracle/topdeck turns better than Prismari Pianist without cutting the protected ramp, pressure, or finisher shell.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Prismari Pianist", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Prismari Pianist", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Guttersnipe"], "adds_signature": ["guttersnipe"], "baseline": {}, "candidate": {}, "cuts": ["Prismari Pianist"], "cuts_signature": ["prismari pianist"], "decision": "reject_or_rework", "delta_pp": null, "family": "registry_rejected", "gate_json": null, "gate_markdown": null, "gate_returncode": null, "package_key": "registry:tested:9:guttersnipe", "registry_learning": "Guttersnipe increased topdeck event frequency but did not convert to wins. Replacing Prismari Pianist removed too much board-pressure payoff; Prismari Pianist remains protected until a same-function replacement wins.", "registry_result": "1W/8L/0S, WR 11.11%, Winota 0W/3L, miracle games 8/9, topdeck games 5/9", "registry_section": "tested", "registry_status": "rejected", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_candidate_hypothesis_registry_20260626.json", "strategic_delta": {}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### pg245_twinflame_damage_payoff_cut_thor

- family: static_damage_modifier
- hypothesis: PG245 gives Twinflame Tyrant an executable XMage-backed static damage-doubling model. This is a same-mana-value damage payoff diagnostic over Thor, not a promotion, because prior Thor cuts failed when the replacement was not a direct damage payoff.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [{"best_delta_pp": -44.45, "card_name": "Thor, God of Thunder", "current_lane": "graveyard_recursion", "effective_role": "spell_damage_engine", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "PG245 same-slot damage payoff benchmark; isolated candidate only", "status": "override_locked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Twinflame Tyrant"], "adds_signature": ["twinflame tyrant"], "baseline": {"avg_win_turn": 16.14, "losses": 2, "stalls": 0, "strategic_event_counts": {"discard_to_top_replacement": 16, "graveyard_upkeep_return_self_to_hand": 5, "lorehold_cost_paid": 137, "lorehold_rummage_discard_to_top": 13, "lorehold_spell_cast": 107, "lorehold_spell_rummage": 18, "lorehold_spell_rummage_discard_to_top": 3, "lorehold_upkeep_rummage": 39, "miracle_cast": 32, "squee_return_after_known_graveyard_entry": 5, "squee_to_graveyard": 7, "squee_upkeep_return": 5, "topdeck_manipulation_activated": 30}, "win_rate": 77.78, "wins": 7}, "candidate": {"avg_win_turn": 11.5, "losses": 5, "stalls": 0, "strategic_event_counts": {"discard_to_top_replacement": 24, "lorehold_cost_paid": 102, "lorehold_rummage_discard_to_top": 16, "lorehold_spell_cast": 91, "lorehold_spell_rummage": 20, "lorehold_spell_rummage_discard_to_top": 8, "lorehold_upkeep_rummage": 29, "miracle_cast": 16, "topdeck_manipulation_activated": 20}, "win_rate": 44.44, "wins": 4}, "cuts": ["Thor, God of Thunder"], "cuts_signature": ["thor, god of thunder"], "decision": "reject_or_rework", "delta_pp": -33.34, "family": "static_damage_modifier", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1_pg245_twinflame_damage_payoff_cut_thor.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1_pg245_twinflame_damage_payoff_cut_thor.md", "gate_returncode": 0, "package_key": "pg245_twinflame_damage_payoff_cut_thor", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_pg245_twinflame_deeper_gate_20260628_pg245_twinflame_deeper_v1.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 8, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -35, "lorehold_rummage_discard_to_top": 3, "lorehold_spell_cast": -16, "lorehold_spell_rummage": 2, "lorehold_spell_rummage_discard_to_top": 5, "miracle_cast": -16, "random_discard_after_tutor": 2, "ritual_mana_added": -3, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -5, "squee_to_graveyard": -7, "squee_upkeep_return": -5, "topdeck_manipulation_activated": -10, "tutor_resolved": -2}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### monastery_mentor_spell_tokens_cut_prismari

- family: spellcast_payoff
- hypothesis: Monastery Mentor is present in Lorehold variant 616 and turns each noncreature spell into a growing board. This checks whether a token payoff survives combat pressure while converting Lorehold's miracle spell volume better than Prismari Pianist.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Prismari Pianist", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Prismari Pianist", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### young_pyromancer_spell_tokens_cut_prismari

- family: spellcast_payoff
- hypothesis: Young Pyromancer is present in Lorehold variant 616 and creates board presence from instant/sorcery casts at two mana. This tests the same payoff lane at the lowest curve point while leaving the known topdeck and protection shell untouched.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Prismari Pianist", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Prismari Pianist", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### ghostly_prison_pressure_cut_promise

- family: pressure_absorber
- hypothesis: Ghostly Prison previously failed when it cut protected Hexing Squelcher. This retest keeps Hexing Squelcher and Fated Clash, then checks whether a static attack tax is better than a slower pressure cleanup spell against the combat-pressure deaths. This is an explicit pressure-lane benchmark, not a generic cut of the big-spell miracle plan.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Promise of Loyalty", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Promise of Loyalty", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### boseiju_spell_protection_land

- family: spell_protection_land
- hypothesis: Boseiju, Who Shelters All protects decisive instant/sorcery casts from counters while preserving land count.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -55.56, "card_name": "Reliquary Tower", "current_lane": "mana_base", "effective_role": "land", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Reliquary Tower", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### plateau_timing_upgrade_cut_radiant_summit

- family: mana_base
- hypothesis: The deterministic mana-base validator marks Plateau over Radiant Summit as a strict Boros-source timing upgrade: it preserves red and white access, keeps land count unchanged, and removes a conditional tapped dual without cutting fetches or utility lands.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Plateau"], "adds_signature": ["plateau"], "baseline": {"avg_win_turn": 15.12, "losses": 1, "stalls": 0, "strategic_event_counts": {"discard_to_top_replacement": 16, "graveyard_upkeep_return_self_to_hand": 5, "lorehold_cost_paid": 148, "lorehold_rummage_discard_to_top": 13, "lorehold_spell_cast": 118, "lorehold_spell_rummage": 19, "lorehold_spell_rummage_discard_to_top": 3, "lorehold_upkeep_rummage": 41, "miracle_cast": 33, "squee_return_after_known_graveyard_entry": 5, "squee_to_graveyard": 7, "squee_upkeep_return": 5, "topdeck_manipulation_activated": 30}, "win_rate": 88.89, "wins": 8}, "candidate": {"avg_win_turn": 15.5, "losses": 7, "stalls": 0, "strategic_event_counts": {"discard_to_top_replacement": 3, "graveyard_upkeep_return_self_to_hand": 3, "lorehold_cost_paid": 91, "lorehold_rummage_discard_to_top": 3, "lorehold_spell_cast": 67, "lorehold_upkeep_rummage": 30, "miracle_cast": 14, "squee_return_after_known_graveyard_entry": 3, "squee_to_graveyard": 5, "squee_upkeep_return": 3, "topdeck_manipulation_activated": 2}, "win_rate": 22.22, "wins": 2}, "cuts": ["Radiant Summit"], "cuts_signature": ["radiant summit"], "decision": "reject_or_rework", "delta_pp": -66.67, "family": "mana_base", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real_plateau_timing_upgrade_cut_radiant_summit.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real_plateau_timing_upgrade_cut_radiant_summit.md", "gate_returncode": 0, "package_key": "plateau_timing_upgrade_cut_radiant_summit", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_gate_20260627_v1_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": -13, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -57, "lorehold_rummage_discard_to_top": -10, "lorehold_spell_cast": -51, "lorehold_spell_rummage": -19, "lorehold_spell_rummage_discard_to_top": -3, "miracle_cast": -19, "random_discard_after_tutor": 2, "ritual_mana_added": -2, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -2, "squee_to_graveyard": -2, "squee_upkeep_return": -2, "topdeck_manipulation_activated": -28, "tutor_resolved": -5}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### plateau_timing_upgrade_cut_turbulent_steppe

- family: mana_base
- hypothesis: After Plateau over Radiant Summit failed the real gate, the mana-base validator still marks Plateau over Turbulent Steppe as a separate strict timing upgrade: it preserves red and white sources, keeps land count unchanged, and removes a late-game-only conditional tapped dual without cutting fetches or utility lands.
- status: `skipped_prior_evidence`
- cut_safety: `{"cuts": [], "reason": "no proposed cut has previous blocker evidence", "status": "clear"}`
- prior_evidence: `{"matches": [{"adds": ["Plateau"], "adds_signature": ["plateau"], "baseline": {"avg_win_turn": 15.12, "losses": 1, "stalls": 0, "strategic_event_counts": {"discard_to_top_replacement": 16, "graveyard_upkeep_return_self_to_hand": 5, "lorehold_cost_paid": 148, "lorehold_rummage_discard_to_top": 13, "lorehold_spell_cast": 118, "lorehold_spell_rummage": 19, "lorehold_spell_rummage_discard_to_top": 3, "lorehold_upkeep_rummage": 41, "miracle_cast": 33, "squee_return_after_known_graveyard_entry": 5, "squee_to_graveyard": 7, "squee_upkeep_return": 5, "topdeck_manipulation_activated": 30}, "win_rate": 88.89, "wins": 8}, "candidate": {"avg_win_turn": 12.0, "losses": 6, "stalls": 0, "strategic_event_counts": {"graveyard_upkeep_return_self_to_hand": 3, "lorehold_cost_paid": 93, "lorehold_spell_cast": 70, "lorehold_spell_rummage": 2, "lorehold_upkeep_rummage": 39, "miracle_cast": 21, "squee_return_after_known_graveyard_entry": 3, "squee_to_graveyard": 3, "squee_upkeep_return": 3, "topdeck_manipulation_activated": 10}, "win_rate": 33.33, "wins": 3}, "cuts": ["Turbulent Steppe"], "cuts_signature": ["turbulent steppe"], "decision": "reject_or_rework", "delta_pp": -55.56, "family": "mana_base", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real_plateau_timing_upgrade_cut_turbulent_steppe.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real_plateau_timing_upgrade_cut_turbulent_steppe.md", "gate_returncode": 0, "package_key": "plateau_timing_upgrade_cut_turbulent_steppe", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_mana_base_plateau_turbulent_gate_20260627_v1_real.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": -16, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -55, "lorehold_rummage_discard_to_top": -13, "lorehold_spell_cast": -48, "lorehold_spell_rummage": -17, "lorehold_spell_rummage_discard_to_top": -3, "miracle_cast": -12, "random_discard_after_tutor": 2, "ritual_mana_added": -3, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": -2, "squee_to_graveyard": -4, "squee_upkeep_return": -2, "topdeck_manipulation_activated": -20, "tutor_resolved": 1}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### biblioplex_topdeck_land

- family: topdeck_land
- hypothesis: The Biblioplex gives a land-slot instant/sorcery topdeck selection tool for late games where Lorehold has a large hand.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -55.56, "card_name": "Reliquary Tower", "current_lane": "mana_base", "effective_role": "land", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Reliquary Tower", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### mirrorpool_spellcopy_land

- family: spell_copy_land
- hypothesis: Mirrorpool uses a land slot to copy a decisive instant or sorcery, testing whether colorless utility is worth more than hand size.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -55.56, "card_name": "Reliquary Tower", "current_lane": "mana_base", "effective_role": "land", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Reliquary Tower", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### core_challenge_dance_over_storm

- family: payoff_challenge
- hypothesis: Dance with Calamity is an expensive sorcery payoff that may produce more immediate wins than Storm Herd when miracle makes it cheap.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -3.7, "card_name": "Storm Herd", "current_lane": "finisher_or_big_spell", "effective_role": "wincon", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -88.89}], "reason": "proposed cuts are registry-protected: Storm Herd", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Dance with Calamity"], "adds_signature": ["dance with calamity"], "baseline": {"avg_win_turn": 11.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 22, "miracle_cast": 5, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "candidate": {"avg_win_turn": 14.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 26, "lorehold_spell_cast": 24, "miracle_cast": 7, "topdeck_manipulation_activated": 2}, "win_rate": 50.0, "wins": 1}, "cuts": ["Storm Herd"], "cuts_signature": ["storm herd"], "decision": "tie_promote_to_deeper_gate", "delta_pp": 0.0, "family": "payoff_challenge", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_dance_over_storm.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_dance_over_storm.md", "gate_returncode": 0, "package_key": "core_challenge_dance_over_storm", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -2, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": 2, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": 2, "random_discard_after_tutor": 1, "ritual_mana_added": 0, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -1, "tutor_resolved": 1}}], "reason": "previous exact package result was not a reject blocker", "status": "seen_no_blocker"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### core_challenge_aetherflux_over_storm

- family: payoff_challenge
- hypothesis: Aetherflux Reservoir may convert Lorehold's spell-chain turns into a deterministic life-gain and 50-damage finish while preserving the expensive instant/sorcery package outside the Storm Herd slot.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -3.7, "card_name": "Storm Herd", "current_lane": "finisher_or_big_spell", "effective_role": "wincon", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -88.89}], "reason": "proposed cuts are registry-protected: Storm Herd", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### core_challenge_past_over_tragic

- family: payoff_challenge
- hypothesis: Past in Flames may be a stronger spell-chain payoff than a generic five-mana cleanup sorcery in the current shell.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": null, "card_name": "Tragic Arrogance", "current_lane": "registry_protected", "effective_role": null, "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": null}], "reason": "proposed cuts are registry-protected: Tragic Arrogance", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [{"adds": ["Past in Flames"], "adds_signature": ["past in flames"], "baseline": {"avg_win_turn": 11.0, "losses": 1, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 28, "lorehold_spell_cast": 22, "miracle_cast": 5, "topdeck_manipulation_activated": 3}, "win_rate": 50.0, "wins": 1}, "candidate": {"avg_win_turn": 0, "losses": 2, "stalls": 0, "strategic_event_counts": {"lorehold_cost_paid": 22, "lorehold_spell_cast": 16, "miracle_cast": 2}, "win_rate": 0.0, "wins": 0}, "cuts": ["Tragic Arrogance"], "cuts_signature": ["tragic arrogance"], "decision": "reject_or_rework", "delta_pp": -50.0, "family": "payoff_challenge", "gate_json": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_past_over_tragic.json", "gate_markdown": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013_core_challenge_past_over_tragic.md", "gate_returncode": 0, "package_key": "core_challenge_past_over_tragic", "source_report": "/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_general_synergy_gate_20260627_real2_v1_20260627_123013.json", "strategic_delta": {"birgi_spell_cast_mana": 0, "damage_prevention_shield_created": 0, "discard_to_top_replacement": 0, "hand_to_topdeck_activation": 0, "lorehold_cost_paid": -6, "lorehold_rummage_discard_to_top": 0, "lorehold_spell_cast": -6, "lorehold_spell_rummage": 0, "lorehold_spell_rummage_discard_to_top": 0, "miracle_cast": -3, "random_discard_after_tutor": 0, "ritual_mana_added": 1, "spell_cast_mana_trigger": 0, "squee_return_after_known_graveyard_entry": 0, "squee_to_graveyard": 0, "squee_upkeep_return": 0, "topdeck_manipulation_activated": -3, "tutor_resolved": 2}}], "reason": "exact package already produced `reject_or_rework`", "status": "blocked_prior_reject"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### etb_tutor_blink

- family: misc
- hypothesis: The Mind Stone blink becomes materially stronger when it can reuse creature tutors without cutting Lorehold's high-value spell payoffs.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}, {"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}, {"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Bender's Waterskin, Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### sun_titan_blink_value

- family: misc
- hypothesis: Sun Titan plus The Mind Stone creates repeatable permanent recursion for the deck's cheap artifacts, protection, and engines without removing expensive instant/sorcery miracle payoffs.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}], "reason": "proposed cuts are registry-protected: Bender's Waterskin", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### sun_titan_cut_chimes

- family: misc
- hypothesis: Sun Titan may be better than a multiplayer mana artifact if the recursion package offsets the lost ramp.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}], "reason": "proposed cuts already have blocker evidence: Victory Chimes", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### sun_titan_cut_squelcher

- family: misc
- hypothesis: Sun Titan may be better than a narrow anti-counter creature while preserving the instant/sorcery miracle core.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`

### artifact_etb_value

- family: misc
- hypothesis: Artifact ETB cards from the Lorehold corpus may turn Mind Stone blink into mana/card velocity without cutting the miracle spell package.
- status: `skipped_cut_safety`
- cut_safety: `{"cuts": [{"best_delta_pp": 3.7, "card_name": "Bender's Waterskin", "current_lane": "early_mana", "effective_role": "ramp", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -44.45}, {"best_delta_pp": -3.7, "card_name": "Victory Chimes", "current_lane": "early_mana", "effective_role": "ramp", "reason": "one or more packages collapsed the known strong seed when cutting this slot", "status": "locked_do_not_cut", "worst_strong_seed_delta_pp": -55.56}, {"best_delta_pp": 0.0, "card_name": "Hexing Squelcher", "current_lane": "contextual", "effective_role": "creature", "reason": "registry protects this card until a same-function replacement wins a current-leader gate", "status": "protected_until_same_function_replacement_wins", "worst_strong_seed_delta_pp": -77.78}], "reason": "proposed cuts are registry-protected: Bender's Waterskin, Hexing Squelcher", "status": "blocked_cut_safety"}`
- prior_evidence: `{"matches": [], "reason": "no previous package-key or add/cut signature result", "status": "clear"}`
- allow_miracle_core_cuts: `None`
- miracle_core_cuts: `-`
- added_rule_counts: `{}`
- candidate_db: `-`
- gate_markdown: `-`
- gate_json: `-`
- gate_returncode: `None`
