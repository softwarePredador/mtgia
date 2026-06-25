# Lorehold Ideal Deck Candidate Matrix

- Generated at: `2026-06-25T04:09:06.386812+00:00`
- Status: `ready`
- Active deck id: `606`
- Lorehold deck ids: `[606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg202_redress_fate_postsync_v1_proposals.json`
- PostgreSQL writes: `False`
- Deck mutations: `False`

## Operating Decision

Use this matrix before any Lorehold swap work. Cards in
`needs_rule_before_strategy` must have XMage/ManaLoom rule confidence
closed before battle benchmarking. Cards in
`priority_benchmark_candidate` are the first safe candidates for
`slot_optimizer.py` after the baseline hash guard passes.

## Summary

- Rows: `567`
- Recommendation lanes: `{"active_low_confidence_review": 11, "core_keep": 69, "low_priority": 91, "needs_rule_before_strategy": 215, "policy_blocked": 2, "priority_benchmark_candidate": 87, "watchlist_candidate": 92}`
- Rule statuses: `{"battle_ready": 352, "blocked_missing_xmage_source": 4, "mapper_manual": 142, "runtime_needed": 16, "split_scope": 53}`
- Active profile: `{"board_wipe": 5, "draw": 16, "engine": 9, "land": 39, "protection": 10, "ramp": 19, "recursion": 3, "removal": 7, "tutor": 3, "wincon": 5}`

## Top Rule-First Cards

| Card | Score | Roles | Rule status | Scope/family | Next action |
| --- | ---: | --- | --- | --- | --- |
| Psychic Frog | 23.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Fable of the Mirror-Breaker // Reflection of Kiki-Jiki | 22.5 | ramp, wincon | runtime_needed | xmage_create_token_variant_fableofthemirrorbreaker_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Forge Anew | 22.5 | engine, recursion | split_scope | graveyard_to_battlefield_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Whip of Erebos | 22.5 | engine, recursion | split_scope | targeted_exile_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Bloodchief Ascension | 21.0 | draw | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Solphim, Mayhem Dominus | 20.5 | wincon | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Tinybones, Trinket Thief | 20.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Waste Not | 20.0 | wincon | runtime_needed | xmage_create_token_variant_wastenot_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Black Market Connections | 19.0 | ramp, wincon | runtime_needed | xmage_create_token_variant_blackmarketconnections_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Smuggler's Share | 19.0 | ramp, wincon | runtime_needed | xmage_create_token_variant_smugglersshare_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Kederekt Parasite | 18.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Puresteel Paladin | 18.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Sram, Senior Edificer | 18.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Firesong and Sunspeaker | 18.0 | wincon | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Starfield Shepherd | 18.0 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rakdos Charm | 17.5 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Bedlam Reveler | 16.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Blood Sun | 16.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Davros, Dalek Creator | 16.5 | wincon | runtime_needed | xmage_create_token_variant_davrosdalekcreator_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Kefka, Court Mage // Kefka, Ruler of Ruin | 16.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Morbid Opportunist | 16.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Palantír of Orthanc | 16.5 | draw | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Phyrexian Arena | 16.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Primal Amulet // Primal Wellspring | 16.5 | ramp | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rune-Scarred Demon | 16.5 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Spiteful Visions | 16.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Valgavoth, Harrower of Souls | 16.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Bone Miser | 16.0 | wincon | runtime_needed | xmage_create_token_variant_bonemiser_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Clever Concealment | 16.0 | protection | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Green Goblin, Nemesis | 16.0 | wincon | runtime_needed | xmage_create_token_variant_greengoblinnemesis_v1 | implement_runtime_family_with_focused_test_before_swap_testing |

## Top Benchmark Candidates

| Card | Score | Roles | Decks | Rule status | Next action |
| --- | ---: | --- | --- | --- | --- |
| Mizzix's Mastery | 70.0 | wincon | [607, 608, 609, 610, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Enlightened Tutor | 61.0 | tutor | [608, 611, 612, 613, 614, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Gamble | 59.0 | tutor | [609, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Monument to Endurance | 59.0 | draw, ramp | [607, 608, 609, 611, 613, 614, 615, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Silence | 59.0 | protection | [612, 613, 614, 615, 616, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Redirect Lightning | 57.5 | protection, draw | [607, 608, 611, 613, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pinnacle Monk // Mystic Peak | 57.0 | engine, removal, recursion | [607, 608, 609, 610, 611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Scroll Rack | 56.5 | draw, ramp | [607, 608, 609, 610, 611, 612, 613, 614, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Brass's Bounty | 56.0 | ramp, wincon | [609, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Volcanic Vision | 56.0 | engine, recursion | [609, 611, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Big Score | 55.5 | ramp | [607, 609, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Dawn's Truce | 55.5 | protection | [607, 613, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flashback | 55.5 | engine, recursion | [615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reiterate | 55.0 | engine | [612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Akroma's Will | 54.5 | protection, wincon | [614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Arcane Denial | 54.5 | protection, draw | [617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Faithless Looting | 54.5 | draw | [611, 615, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| The One Ring | 54.5 | protection, draw | [608, 613, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pyromancer Ascension | 54.0 | engine | [608] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Esper Sentinel | 53.5 | draw | [607, 609, 611, 613, 614, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Invoke Calamity | 53.5 | engine, recursion | [609, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Perch Protection | 53.5 | wincon | [609, 610, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Surge to Victory | 53.5 | wincon, removal | [607] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Unexpected Windfall | 53.5 | ramp | [607, 609, 611, 613, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Ashling, Flame Dancer | 53.0 | wincon | [611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Creative Technique | 53.0 | draw, engine | [607, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Dualcaster Mage | 53.0 | engine | [611, 612, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Fury Storm | 53.0 | engine | [612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reckless Handling | 53.0 | tutor | [611, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Red Elemental Blast | 53.0 | protection | [612, 613, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |

## Core Keeps

| Card | Score | Roles | Rule status |
| --- | ---: | --- | --- |
| Lorehold, the Historian | 82.5 | draw, engine | battle_ready |
| Deflecting Swat | 75.5 | protection, draw | battle_ready |
| Library of Leng | 75.5 | engine, ramp | battle_ready |
| Reforge the Soul | 72.5 | draw | battle_ready |
| Restoration Seminar | 71.5 | engine, recursion | battle_ready |
| Teferi's Protection | 71.0 | protection | battle_ready |
| Sensei's Divining Top | 69.5 | draw | battle_ready |
| Increasing Vengeance | 68.0 | engine | battle_ready |
| Boros Charm | 67.0 | protection | battle_ready |
| Land Tax | 67.0 | tutor | battle_ready |
| Reverberate | 67.0 | engine | battle_ready |
| Smothering Tithe | 65.5 | ramp | battle_ready |
| Arcane Signet | 65.0 | ramp | battle_ready |
| Flare of Duplication | 65.0 | engine | battle_ready |
| Improvisation Capstone | 65.0 | draw | battle_ready |
| Sol Ring | 65.0 | ramp | battle_ready |
| Hexing Squelcher | 64.5 | protection | battle_ready |
| Jeska's Will | 63.0 | ramp | battle_ready |
| Tibalt's Trickery | 63.0 | protection | battle_ready |
| Rise of the Eldrazi | 62.0 | wincon, removal | battle_ready |
| Olórin's Searing Light | 61.5 | draw, removal | battle_ready |
| Wheel of Fortune | 61.5 | draw | battle_ready |
| Mountain // Mountain | 61.0 | land, ramp | battle_ready |
| Plains // Plains | 61.0 | land, ramp | battle_ready |
| Past in Flames | 59.5 | engine, recursion | battle_ready |
| Underworld Breach | 59.5 | engine, recursion | battle_ready |
| Valakut Awakening // Valakut Stoneforge | 59.5 | draw | battle_ready |
| Flawless Maneuver | 59.0 | protection | battle_ready |
| Hit the Mother Lode | 59.0 | draw, ramp | battle_ready |
| Lightning Greaves | 58.5 | protection | battle_ready |
