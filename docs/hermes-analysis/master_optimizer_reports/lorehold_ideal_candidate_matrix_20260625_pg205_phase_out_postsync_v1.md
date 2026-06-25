# Lorehold Ideal Deck Candidate Matrix

- Generated at: `2026-06-25T06:14:44.861981+00:00`
- Status: `ready`
- Active deck id: `607`
- Lorehold deck ids: `[6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg205_phase_out_postsync_v1_proposals.json`
- PostgreSQL writes: `False`
- Deck mutations: `False`

## Operating Decision

Use this matrix before any Lorehold swap work. Cards in
`needs_rule_before_strategy` must have XMage/ManaLoom rule confidence
closed before battle benchmarking. Cards in
`priority_benchmark_candidate` are the first safe candidates for
`slot_optimizer.py` after the baseline hash guard passes.

## Summary

- Rows: `580`
- Recommendation lanes: `{"active_low_confidence_review": 14, "core_keep": 78, "low_priority": 85, "needs_rule_before_strategy": 210, "policy_blocked": 2, "priority_benchmark_candidate": 77, "watchlist_candidate": 114}`
- Rule statuses: `{"battle_ready": 370, "blocked_missing_xmage_source": 4, "mapper_manual": 137, "runtime_needed": 16, "split_scope": 53}`
- Active profile: `{"board_wipe": 6, "draw": 20, "engine": 7, "land": 34, "protection": 12, "ramp": 45, "recursion": 3, "removal": 11, "tutor": 2, "unknown": 2, "wincon": 13}`

## Top Rule-First Cards

| Card | Score | Roles | Rule status | Scope/family | Next action |
| --- | ---: | --- | --- | --- | --- |
| Forge Anew | 22.5 | engine, recursion | split_scope | graveyard_to_battlefield_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Whip of Erebos | 22.5 | engine, recursion | split_scope | targeted_exile_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Psychic Frog | 20.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Starfield Shepherd | 19.5 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Bloodchief Ascension | 18.0 | draw | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rune-Scarred Demon | 18.0 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Tinybones, Trinket Thief | 17.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Razaketh, the Foulblooded | 16.5 | tutor | split_scope | activated_pay_life_sacrifice_creature_any_tutor_to_hand_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rakdos Charm | 16.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Kederekt Parasite | 15.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Puresteel Paladin | 15.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Scholar of New Horizons | 15.5 | tutor | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Sram, Senior Edificer | 15.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Primal Amulet // Primal Wellspring | 15.0 | ramp | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Molten Gatekeeper | 14.5 | engine, recursion | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Bedlam Reveler | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Blood Sun | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Kefka, Court Mage // Kefka, Ruler of Ruin | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Morbid Opportunist | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Palantír of Orthanc | 13.5 | draw | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Phyrexian Arena | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Spiteful Visions | 13.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Valgavoth, Harrower of Souls | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Erode | 13.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Fable of the Mirror-Breaker // Reflection of Kiki-Jiki | 13.0 | ramp, wincon | runtime_needed | xmage_create_token_variant_fableofthemirrorbreaker_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Infernal Grasp | 13.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Razorgrass Ambush // Razorgrass Field | 13.0 | removal | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Currency Converter | 12.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Deathbellow War Cry | 12.5 | tutor | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Solphim, Mayhem Dominus | 12.5 | wincon | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |

## Top Benchmark Candidates

| Card | Score | Roles | Decks | Rule status | Next action |
| --- | ---: | --- | --- | --- | --- |
| Enlightened Tutor | 64.5 | tutor | [6, 608, 611, 612, 613, 614, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Restoration Seminar | 63.5 | engine, recursion | [606, 609, 610, 611, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Gamble | 62.5 | tutor | [6, 609, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Storm-Kiln Artist | 62.5 | engine, ramp, wincon | [6, 608, 611, 612, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reverberate | 61.0 | engine | [6, 606, 612, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Increasing Vengeance | 60.0 | engine | [606, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| The One Ring | 58.5 | protection, draw, engine | [6, 608, 613, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Boros Charm | 58.0 | protection, removal | [6, 606, 609, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Silence | 58.0 | protection, stax | [6, 612, 613, 614, 615, 616, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flare of Duplication | 57.0 | engine | [606, 612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Mana Vault | 57.0 | engine, ramp | [6, 606, 612, 613, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reiterate | 57.0 | engine | [6, 612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Twinflame | 57.0 | engine, wincon | [6, 611, 612, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Volcanic Vision | 56.0 | engine, recursion | [609, 611, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flashback | 55.5 | engine, recursion | [615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Dualcaster Mage | 55.0 | engine | [6, 611, 612, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Faithless Looting | 55.0 | draw, recursion | [6, 611, 615, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Past in Flames | 54.5 | draw, engine, recursion | [6, 606, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reckless Handling | 54.5 | tutor | [611, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pyromancer Ascension | 54.0 | engine | [608] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Goblin Engineer | 53.5 | tutor | [608, 610, 611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Invoke Calamity | 53.5 | engine, recursion | [609, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Fury Storm | 53.0 | engine | [612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Molten Duplication | 53.0 | engine, wincon | [6, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Return the Favor | 53.0 | engine | [608, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Wheel of Fortune | 52.5 | draw | [6, 606, 608, 609, 612, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| The Soul Stone | 51.5 | engine, ramp, recursion | [618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Underworld Breach | 51.5 | engine, recursion | [606, 612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Heat Shimmer | 51.0 | engine, wincon | [6, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | 50.5 | engine, ramp | [6, 608, 612, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |

## Core Keeps

| Card | Score | Roles | Rule status |
| --- | ---: | --- | --- |
| Lorehold, the Historian | 79.5 | draw, engine | battle_ready |
| Mizzix's Mastery | 76.5 | draw, wincon, removal, recursion | battle_ready |
| Smothering Tithe | 75.0 | engine, ramp, wincon | battle_ready |
| Urza's Saga | 74.5 | land, tutor, ramp, wincon | battle_ready |
| Library of Leng | 74.0 | engine, ramp | battle_ready |
| Land Tax | 70.5 | tutor, draw, ramp | battle_ready |
| Scroll Rack | 70.0 | draw, engine, ramp | battle_ready |
| Teferi's Protection | 70.0 | protection | battle_ready |
| Deflecting Swat | 69.5 | protection, draw | battle_ready |
| Reforge the Soul | 69.5 | draw | battle_ready |
| Esper Sentinel | 68.5 | draw, engine | battle_ready |
| Sensei's Divining Top | 66.5 | draw | battle_ready |
| Jeska's Will | 65.5 | draw, ramp | battle_ready |
| Unexpected Windfall | 64.0 | draw, ramp, wincon | battle_ready |
| Arcane Signet | 63.5 | ramp | battle_ready |
| Pinnacle Monk // Mystic Peak | 63.5 | engine, removal, recursion | battle_ready |
| Sol Ring | 63.5 | ramp | battle_ready |
| Monument to Endurance | 62.5 | draw, ramp | battle_ready |
| Big Score | 62.0 | ramp | battle_ready |
| Elegant Parlor | 62.0 | land, ramp, recursion | battle_ready |
| Improvisation Capstone | 62.0 | draw | battle_ready |
| Hexing Squelcher | 61.5 | protection | battle_ready |
| Arid Mesa | 61.0 | land, ramp | battle_ready |
| Dawn's Truce | 60.5 | protection | battle_ready |
| Tibalt's Trickery | 60.0 | protection | battle_ready |
| Command Tower | 59.5 | land, ramp | battle_ready |
| Mountain // Mountain | 59.5 | land, ramp | battle_ready |
| Plains // Plains | 59.5 | land, ramp | battle_ready |
| Redirect Lightning | 59.5 | protection, draw | battle_ready |
| Sacred Foundry | 59.5 | land, ramp | battle_ready |
