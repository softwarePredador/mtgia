# Lorehold Deckbuilding Value Model

- generated_at: `2026-07-05T00:02:03Z`
- status: `lorehold_value_model_ready_607_remains_protected`
- postgres_writes: `false`
- source_db_mutated: `false`
- deck_607_mutated: `false`
- deck_id: `607`
- quantity_total: `100`
- commander_count: `1`
- promotion_allowed: `false`
- keep_607_as_protected_baseline: `true`
- preflight_status: `no_current_candidate_passes_miracle_access_first_preflight`
- gate_ready_now_count: `0`

## Role And Mana Model

- role_profile: `{"board_wipe": 8, "creature": 2, "draw": 9, "engine": 3, "land": 34, "protection": 12, "ramp": 15, "removal": 7, "tutor": 1, "wincon": 9}`
- land_quantity: `34`
- ramp_quantity: `15`
- mana_sources_land_plus_ramp: `49`
- land_groups: `{"basic_floor": 8, "fetch_or_search_fixing": 8, "typed_dual_or_fetch_target": 5, "untapped_or_multiplayer_fixing": 5, "utility_engine_land": 8}`
- interpretation: The 607 mana plan is not just more fast mana: it combines 34 lands, fetch/dual fixing, artifact ramp, spell ramp, and opponent-turn mana rocks that feed miracle windows.

## Value Tiers

### tier_0_protected_engine_or_anchor
- `Lorehold, the Historian` score `230` lanes `commander_center,engine,topdeck_miracle_engine` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `Land Tax` score `156` lanes `global_top_500,topdeck_miracle_engine,tutor` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `Library of Leng` score `150` lanes `artifact,engine,topdeck_miracle_engine` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `Molecule Man` score `150` lanes `draw,topdeck_miracle_engine` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `Scroll Rack` score `150` lanes `artifact,draw,topdeck_miracle_engine` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `Sensei's Divining Top` score `150` lanes `artifact,draw,topdeck_miracle_engine` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `The Mind Stone` score `150` lanes `artifact,ramp,topdeck_miracle_engine` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `The Scarlet Witch` score `150` lanes `creature,topdeck_miracle_engine` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `Mizzix's Mastery` score `141` lanes `format_staple_long_tail,instant_sorcery_spell,miracle_conversion_finisher,wincon` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `Approach of the Second Sun` score `138` lanes `instant_sorcery_spell,miracle_conversion_finisher,wincon` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `Creative Technique` score `138` lanes `draw,instant_sorcery_spell,miracle_conversion_finisher` cut_policy `no_generic_cut_same_lane_battle_proof_required`
- `Insurrection` score `138` lanes `instant_sorcery_spell,miracle_conversion_finisher,wincon` cut_policy `no_generic_cut_same_lane_battle_proof_required`

### tier_1_structural_floor
- `Urza's Saga` score `74` lanes `global_top_500,land,mana_base,topdeck_miracle_engine,utility_engine_land` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Arcane Signet` score `39` lanes `artifact,global_top_100,ramp,structural_ramp_floor` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Fellwar Stone` score `39` lanes `artifact,global_top_100,ramp,structural_ramp_floor` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Smothering Tithe` score `39` lanes `global_top_100,ramp,structural_ramp_floor` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Sol Ring` score `39` lanes `artifact,global_top_100,ramp,structural_ramp_floor` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Arid Mesa` score `37` lanes `fetch_or_search_fixing,global_top_100,land,mana_base` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Bloodstained Mire` score `37` lanes `fetch_or_search_fixing,global_top_100,land,mana_base` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Deflecting Swat` score `37` lanes `fast_pressure_guard,global_top_100,instant_sorcery_spell,protection` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Flooded Strand` score `37` lanes `fetch_or_search_fixing,global_top_100,land,mana_base` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Marsh Flats` score `37` lanes `fetch_or_search_fixing,global_top_100,land,mana_base` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Scalding Tarn` score `37` lanes `fetch_or_search_fixing,global_top_100,land,mana_base` cut_policy `protect_floor_same_role_upgrade_and_gate_required`
- `Teferi's Protection` score `37` lanes `fast_pressure_guard,global_top_100,instant_sorcery_spell,protection` cut_policy `protect_floor_same_role_upgrade_and_gate_required`

### tier_2_commander_contextual_synergy
- `Rise of the Eldrazi` score `41` lanes `format_staple_long_tail,instant_sorcery_spell,miracle_conversion_finisher,wincon` cut_policy `same_lane_or_package_proof_required`
- `Call Forth the Tempest` score `38` lanes `board_wipe,instant_sorcery_spell,miracle_conversion_finisher` cut_policy `same_lane_or_package_proof_required`
- `Everything Comes to Dust` score `38` lanes `board_wipe,instant_sorcery_spell,miracle_conversion_finisher` cut_policy `same_lane_or_package_proof_required`
- `Hit the Mother Lode` score `38` lanes `draw,instant_sorcery_spell,miracle_conversion_finisher` cut_policy `same_lane_or_package_proof_required`
- `Surge to Victory` score `38` lanes `instant_sorcery_spell,miracle_conversion_finisher,wincon` cut_policy `same_lane_or_package_proof_required`
- `Generous Gift` score `19` lanes `global_top_100,instant_sorcery_spell,removal` cut_policy `same_lane_or_package_proof_required`
- `Path to Exile` score `19` lanes `global_top_100,instant_sorcery_spell,removal` cut_policy `same_lane_or_package_proof_required`
- `Swords to Plowshares` score `19` lanes `global_top_100,instant_sorcery_spell,removal` cut_policy `same_lane_or_package_proof_required`
- `Big Score` score `16` lanes `global_top_500,instant_sorcery_spell,ramp` cut_policy `same_lane_or_package_proof_required`
- `Jeska's Will` score `16` lanes `global_top_500,instant_sorcery_spell,ramp` cut_policy `same_lane_or_package_proof_required`
- `Stroke of Midnight` score `16` lanes `global_top_500,instant_sorcery_spell,removal` cut_policy `same_lane_or_package_proof_required`
- `Unexpected Windfall` score `16` lanes `global_top_500,instant_sorcery_spell,ramp` cut_policy `same_lane_or_package_proof_required`

### tier_3_role_filler_with_battle_context
- `Esper Sentinel` score `19` lanes `artifact,draw,global_top_100` cut_policy `review_with_exposure_trace_before_cut`
- `Artist's Talent` score `10` lanes `draw` cut_policy `review_with_exposure_trace_before_cut`
- `Hexing Squelcher` score `10` lanes `creature` cut_policy `review_with_exposure_trace_before_cut`
- `High Noon` score `10` lanes `removal` cut_policy `review_with_exposure_trace_before_cut`
- `Pinnacle Monk // Mystic Peak` score `10` lanes `engine` cut_policy `review_with_exposure_trace_before_cut`
- `Prismari Pianist` score `10` lanes `wincon` cut_policy `review_with_exposure_trace_before_cut`
- `Thor, God of Thunder` score `10` lanes `removal` cut_policy `review_with_exposure_trace_before_cut`

## Variant Watchlist

- `Enlightened Tutor` variants `6` status `prior_tested_reject_or_caveat_do_not_auto_include` reason: coherent tutor, but tested 607 cuts lost natural confirmation
- `Gamble` variants `5` status `prior_tested_reject_or_caveat_do_not_auto_include` reason: coherent tutor, but tested 607 cuts lost natural confirmation
- `Storm-Kiln Artist` variants `5` status `prior_tested_reject_or_caveat_do_not_auto_include` reason: real runtime signal, but Arcane Signet replacement regressed fast pressure
- `Birgi, God of Storytelling // Harnfel, Horn of Bounty` variants `3` status `prior_tested_reject_or_caveat_do_not_auto_include` reason: same-macro signal but not confirmed as final 607 change
- `Mana Vault` variants `3` status `prior_tested_reject_or_caveat_do_not_auto_include` reason: internally available and runtime-modeled, but one-card Bender's Waterskin replacement lost
- `The One Ring` variants `3` status `prior_tested_reject_or_caveat_do_not_auto_include` reason: internally available and runtime-modeled, but tested value/draw cuts lost to 607
- `Cloud Key` variants `1` status `prior_tested_reject_or_caveat_do_not_auto_include` reason: lost same-lane Bender's Waterskin benchmark and regressed miracle cadence
- `Electro, Assaulting Battery` variants `1` status `prior_tested_reject_or_caveat_do_not_auto_include` reason: lost same-lane Bender's Waterskin benchmark and regressed Winota
- `Possibility Storm` variants `1` status `prior_tested_reject_or_caveat_do_not_auto_include` reason: same-lane Creative Technique benchmark lost and had weak used-game outcome sample
- `Plateau` variants `7` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Apex of Power` variants `6` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Brass's Bounty` variants `6` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Clifftop Retreat` variants `6` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Perch Protection` variants `6` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Boros Charm` variants `5` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Silence` variants `5` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Austere Command` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Boseiju, Who Shelters All` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Dance with Calamity` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Galvanoth` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Goldspan Dragon` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Invoke Calamity` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Longshot, Rebel Bowman` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Olórin's Searing Light` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Penance` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Restoration Seminar` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Rugged Prairie` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Sundown Pass` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Valakut Awakening // Valakut Stoneforge` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Volcanic Vision` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Wheel of Fortune` variants `4` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Boros Garrison` variants `3` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Cavern of Souls` variants `3` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Chaos Warp` variants `3` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Deflecting Palm` variants `3` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Dragon's Rage Channeler` variants `3` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Dualcaster Mage` variants `3` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Goblin Engineer` variants `3` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Goliath Daydreamer` variants `3` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof
- `Grand Abolisher` variants `3` status `watchlist_unproven_do_not_auto_include` reason: appears in variants but lacks current 607 safe-cut and equal-gate proof

## Policy

- lands: Protect the 34-land mana foundation unless a same-function mana-source model and battle gate prove improvement.
- ramp: Prefer ramp that preserves commander timing and opponent-turn miracle windows; fast mana alone is not sufficient.
- artifacts: Artifact value is high only when it serves topdeck, miracle, ramp timing, or protection lanes.
- staples: Global staples are candidates or floors, not automatic cuts over protected commander engines.
- cuts: Any cut must be same-lane or package-declared and must satisfy miracle_access_first_shell_v1 before natural gate.

## External Research

- Wizards Commander format: https://magic.wizards.com/en/formats/commander
  - Official format and color identity are entry gates, not proof of card quality.
- Scryfall Lorehold Oracle: https://scryfall.com/card/sos/201/lorehold-the-historian
  - Lorehold grants miracle to instants and sorceries and rummages on each opponent upkeep.
- EDHREC Optimized Topdeck Lorehold: https://edhrec.com/commanders/lorehold-the-historian/optimized/topdeck
  - Current commander-context signal is Topdeck plus Spellslinger; Scroll Rack and Sensei's Top are high-synergy cards.
- EDHREC Miracles Every Turn: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander
  - Library of Leng plus upkeep rummage is a core miracle setup pattern.
- EDHREC Ramp in Commander: https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander
  - Ramp is about outpacing the curve; in Lorehold it must also preserve commander timing and miracle cadence.
- Card Kingdom ramp/draw article: https://blog.cardkingdom.com/whats-better-in-commander-card-draw-or-ramp/
  - Ramp and draw are structural pillars, but pillar counts do not replace commander-specific package proof.

## Decision

- current_best_baseline: `deck_607`
- reason: Current evidence has no gate-ready challenger, and the protected 607 list preserves the strongest combination of mana foundation, topdeck/miracle anchors, protection, and proven finishers.
- next_action: `use_value_model_to_design_multi_card_shell_or_forced_access_diagnostic_before_any_natural_gate`
