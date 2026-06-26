# Lorehold Ideal Deck Candidate Matrix

- Generated at: `2026-06-26T03:03:01.304899+00:00`
- Status: `ready`
- Active deck id: `6`
- Lorehold deck ids: `[6, 608, 609, 610, 611, 612, 613, 614, 615, 616]`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg220_destroy_exact_lorehold_v1_proposals.json`
- PostgreSQL writes: `False`
- Deck mutations: `False`

## Operating Decision

Use this matrix before any Lorehold swap work. Cards in
`needs_rule_before_strategy` must have XMage/ManaLoom rule confidence
closed before battle benchmarking. Cards in
`priority_benchmark_candidate` are the first safe candidates for
`slot_optimizer.py` after the baseline hash guard passes.

## Summary

- Rows: `364`
- Recommendation lanes: `{"active_low_confidence_review": 15, "core_keep": 85, "low_priority": 43, "needs_rule_before_strategy": 88, "policy_blocked": 2, "priority_benchmark_candidate": 38, "watchlist_candidate": 93}`
- Rule statuses: `{"battle_ready": 276, "mapper_manual": 73, "split_scope": 15}`
- Active profile: `{"board_wipe": 2, "draw": 25, "engine": 16, "land": 33, "protection": 18, "ramp": 53, "recursion": 6, "removal": 8, "stax": 7, "tutor": 8, "wincon": 12}`

## Top Rule-First Cards

| Card | Score | Roles | Rule status | Scope/family | Next action |
| --- | ---: | --- | --- | --- | --- |
| Primal Amulet // Primal Wellspring | 15.0 | ramp | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Starfield Shepherd | 15.0 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Bedlam Reveler | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Blood Sun | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Palantír of Orthanc | 13.5 | draw | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Razorgrass Ambush // Razorgrass Field | 13.0 | removal | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Currency Converter | 12.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Firesong and Sunspeaker | 11.5 | wincon | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Galvanoth | 11.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Scholar of New Horizons | 11.0 | tutor | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Pyromancer's Goggles | 10.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Bolt Bend | 9.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Penance | 9.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Vanquish the Horde | 9.0 | ramp, board_wipe | split_scope | static_self_spell_cost_reduction_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Radiant Scrollwielder | 8.5 | wincon | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Deathbellow War Cry | 8.0 | tutor | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Coruscation Mage | 7.5 | wincon | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Magmakin Artillerist | 7.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Magus of the Wheel | 7.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Millikin | 7.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Single Combat | 7.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Star of Extinction | 7.5 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Velomachus Lorehold | 7.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Authority of the Consuls | 7.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Taunt from the Rampart | 7.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Verge Rangers | 7.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Perpetual Timepiece | 6.0 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Beacon of Immortality | 5.5 | wincon | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Tablet of Discovery | 5.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Chandra's Ignition | 5.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |

## Top Benchmark Candidates

| Card | Score | Roles | Decks | Rule status | Next action |
| --- | ---: | --- | --- | --- | --- |
| Library of Leng | 62.0 | engine, ramp | [608, 609, 610, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Restoration Seminar | 60.0 | engine, recursion | [609, 610, 611, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Increasing Vengeance | 58.0 | engine | [612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reforge the Soul | 57.5 | draw | [609, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flare of Duplication | 55.0 | engine | [612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Volcanic Vision | 54.5 | engine, recursion | [609, 611, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flashback | 54.0 | engine, recursion | [615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pyromancer Ascension | 54.0 | engine | [608] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Fury Storm | 53.0 | engine | [612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Return the Favor | 53.0 | engine | [608, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Big Score | 52.0 | ramp | [609, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Invoke Calamity | 52.0 | engine, recursion | [609, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pinnacle Monk // Mystic Peak | 52.0 | engine, removal, recursion | [608, 609, 610, 611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Monument to Endurance | 50.5 | draw, ramp | [608, 609, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Arcane Bombardment | 50.0 | engine | [611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Improvisation Capstone | 50.0 | draw | [609, 610, 611, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reckless Handling | 50.0 | tutor | [611, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Dawn's Truce | 49.0 | protection | [613, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Double Vision | 49.0 | engine | [613, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Goblin Engineer | 49.0 | tutor | [608, 610, 611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Red Elemental Blast | 48.5 | protection | [612, 613, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reprieve | 48.5 | protection | [612, 613, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Brass's Bounty | 48.0 | ramp, wincon | [609, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Creative Technique | 48.0 | draw, engine | [614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Underworld Breach | 48.0 | engine, recursion | [612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Cool but Rude | 47.0 | draw | [608, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Olórin's Searing Light | 47.0 | draw, removal | [609, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Perch Protection | 47.0 | wincon | [609, 610, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Ashling, Flame Dancer | 46.5 | wincon | [611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Wheel of Fate | 46.5 | draw | [611, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |

## Core Keeps

| Card | Score | Roles | Rule status |
| --- | ---: | --- | --- |
| Lorehold, the Historian | 77.5 | draw, engine | battle_ready |
| Mizzix's Mastery | 74.5 | draw, wincon, removal, recursion | battle_ready |
| Storm-Kiln Artist | 72.0 | engine, ramp, wincon | battle_ready |
| Smothering Tithe | 70.5 | engine, ramp, wincon | battle_ready |
| Scroll Rack | 68.0 | draw, engine, ramp | battle_ready |
| Urza's Saga | 67.5 | land, tutor, ramp, wincon | battle_ready |
| Reverberate | 67.0 | engine | battle_ready |
| Twinflame | 66.5 | engine, wincon | battle_ready |
| Enlightened Tutor | 66.0 | tutor | battle_ready |
| Gamble | 66.0 | tutor | battle_ready |
| Reiterate | 65.0 | engine | battle_ready |
| Esper Sentinel | 64.5 | draw, engine | battle_ready |
| Sensei's Divining Top | 64.5 | draw | battle_ready |
| Teferi's Protection | 64.5 | protection | battle_ready |
| Unexpected Windfall | 63.5 | draw, ramp, wincon | battle_ready |
| Dualcaster Mage | 63.0 | engine | battle_ready |
| The One Ring | 63.0 | protection, draw, engine | battle_ready |
| Boros Charm | 62.5 | protection, removal | battle_ready |
| Molten Duplication | 62.5 | engine, wincon | battle_ready |
| Silence | 62.5 | protection, stax | battle_ready |
| Deflecting Swat | 62.0 | protection, draw | battle_ready |
| Land Tax | 62.0 | tutor, draw, ramp | battle_ready |
| Arcane Signet | 61.5 | ramp | battle_ready |
| Sol Ring | 61.5 | ramp | battle_ready |
| Mana Vault | 61.0 | engine, ramp | battle_ready |
| Heat Shimmer | 60.5 | engine, wincon | battle_ready |
| Faithless Looting | 59.5 | draw, recursion | battle_ready |
| Jeska's Will | 59.5 | draw, ramp | battle_ready |
| Past in Flames | 59.0 | draw, engine, recursion | battle_ready |
| Wheel of Fortune | 58.5 | draw | battle_ready |
