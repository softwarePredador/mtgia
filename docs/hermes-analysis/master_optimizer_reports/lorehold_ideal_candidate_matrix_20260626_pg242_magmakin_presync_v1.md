# Lorehold Ideal Deck Candidate Matrix

- Generated at: `2026-06-26T11:25:06.493576+00:00`
- Status: `ready`
- Active deck id: `6`
- Lorehold deck ids: `[6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 58, 74, 105, 617, 618, 619]`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg242_magmakin_presync_v1_proposals.json`
- PostgreSQL writes: `False`
- Deck mutations: `False`

## Operating Decision

Use this matrix before any Lorehold swap work. Cards in
`needs_rule_before_strategy` must have XMage/ManaLoom rule confidence
closed before battle benchmarking. Cards in
`priority_benchmark_candidate` are the first safe candidates for
`slot_optimizer.py` after the baseline hash guard passes.

## Summary

- Rows: `709`
- Recommendation lanes: `{"active_low_confidence_review": 9, "core_keep": 91, "low_priority": 125, "needs_rule_before_strategy": 182, "policy_blocked": 3, "priority_benchmark_candidate": 73, "watchlist_candidate": 226}`
- Rule statuses: `{"battle_ready": 526, "blocked_missing_xmage_source": 4, "mapper_manual": 133, "no_rule_signal": 3, "package_ready": 1, "split_scope": 42}`
- Active profile: `{"board_wipe": 2, "draw": 26, "engine": 16, "land": 33, "protection": 18, "ramp": 53, "recursion": 6, "removal": 8, "stax": 7, "tutor": 8, "wincon": 12}`

## Top Rule-First Cards

| Card | Score | Roles | Rule status | Scope/family | Next action |
| --- | ---: | --- | --- | --- | --- |
| Forge Anew | 21.0 | engine, recursion | split_scope | graveyard_to_battlefield_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Whip of Erebos | 21.0 | engine, recursion | split_scope | targeted_exile_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Psychic Frog | 20.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Bloodchief Ascension | 18.0 | draw | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Tinybones, Trinket Thief | 17.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rakdos Charm | 16.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Kederekt Parasite | 15.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Puresteel Paladin | 15.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Sram, Senior Edificer | 15.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Solphim, Mayhem Dominus | 14.0 | wincon | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Kefka, Court Mage // Kefka, Ruler of Ruin | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Morbid Opportunist | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Phyrexian Arena | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rune-Scarred Demon | 13.5 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Spiteful Visions | 13.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Valgavoth, Harrower of Souls | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Infernal Grasp | 13.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Currency Converter | 12.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Razaketh, the Foulblooded | 12.0 | tutor | split_scope | activated_pay_life_sacrifice_creature_any_tutor_to_hand_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Dark Deal | 11.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Firesong and Sunspeaker | 11.5 | wincon | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Suspended Sentence | 11.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Withering Torment | 11.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Disciple of Freyalise | 9.5 | draw | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Malakir Rebirth // Malakir Mire | 9.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Radiant Scrollwielder | 8.5 | wincon | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Sacrifice | 8.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Deathbellow War Cry | 8.0 | tutor | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Sheoldred // The True Scriptures | 8.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Millikin | 7.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |

## Top Benchmark Candidates

| Card | Score | Roles | Decks | Rule status | Next action |
| --- | ---: | --- | --- | --- | --- |
| Library of Leng | 66.0 | engine, ramp | [606, 607, 608, 609, 610, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Restoration Seminar | 62.0 | engine, recursion | [606, 609, 610, 611, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reforge the Soul | 61.5 | draw | [606, 607, 609, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Increasing Vengeance | 60.0 | engine | [606, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flare of Duplication | 57.0 | engine | [606, 612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Hexing Squelcher | 56.0 | protection | [58, 74, 105, 606, 607, 609, 613, 614, 615, 616, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Underworld Breach | 56.0 | engine, recursion | [58, 74, 105, 606, 612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Monument to Endurance | 54.5 | draw, ramp | [607, 608, 609, 611, 613, 614, 615, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Volcanic Vision | 54.5 | engine, recursion | [609, 611, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Big Score | 54.0 | ramp | [607, 609, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flashback | 54.0 | engine, recursion | [615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Improvisation Capstone | 54.0 | draw | [606, 607, 609, 610, 611, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pinnacle Monk // Mystic Peak | 54.0 | engine, removal, recursion | [607, 608, 609, 610, 611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pyromancer Ascension | 54.0 | engine | [608] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Electroduplicate | 53.5 | engine, wincon | [105] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Fury Storm | 53.0 | engine | [612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Noxious Revival | 53.0 | draw, engine, recursion | [58, 105] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Return the Favor | 53.0 | engine | [608, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flusterstorm | 52.5 | protection | [58] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Red Elemental Blast | 52.5 | protection | [58, 105, 612, 613, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Invoke Calamity | 52.0 | engine, recursion | [609, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Redirect Lightning | 52.0 | protection, draw | [105, 607, 608, 611, 613, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Dawn's Truce | 51.0 | protection | [607, 613, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Goblin Engineer | 51.0 | tutor, removal | [74, 608, 610, 611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Tibalt's Trickery | 50.5 | protection | [606, 607, 609, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Arcane Bombardment | 50.0 | engine | [611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Creative Technique | 50.0 | draw, engine | [607, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Demonic Tutor | 50.0 | tutor | [58, 74, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Diabolic Intent | 50.0 | tutor | [58, 74, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Formidable Speaker | 50.0 | tutor, engine | [105] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |

## Core Keeps

| Card | Score | Roles | Rule status |
| --- | ---: | --- | --- |
| Lorehold, the Historian | 79.5 | draw, engine | battle_ready |
| Mizzix's Mastery | 76.5 | draw, wincon, removal, recursion | battle_ready |
| Smothering Tithe | 76.5 | engine, ramp, wincon | battle_ready |
| Gamble | 72.0 | tutor | battle_ready |
| Mana Vault | 72.0 | draw, engine, ramp | battle_ready |
| Storm-Kiln Artist | 72.0 | engine, ramp, wincon | battle_ready |
| Urza's Saga | 71.5 | land, tutor, ramp, wincon | battle_ready |
| Esper Sentinel | 70.5 | draw, engine | battle_ready |
| Enlightened Tutor | 70.0 | tutor | battle_ready |
| Scroll Rack | 70.0 | draw, engine, ramp | battle_ready |
| Reverberate | 69.0 | engine | battle_ready |
| Teferi's Protection | 68.5 | protection | battle_ready |
| Twinflame | 68.5 | engine, wincon | battle_ready |
| Deflecting Swat | 68.0 | protection, draw | battle_ready |
| Jeska's Will | 67.5 | draw, ramp | battle_ready |
| Sensei's Divining Top | 66.5 | draw | battle_ready |
| Silence | 66.5 | protection, stax | battle_ready |
| Land Tax | 66.0 | tutor, draw, ramp | battle_ready |
| Unexpected Windfall | 65.5 | draw, ramp, wincon | battle_ready |
| Dualcaster Mage | 65.0 | engine | battle_ready |
| Reiterate | 65.0 | engine | battle_ready |
| The One Ring | 65.0 | protection, draw, engine | battle_ready |
| Boros Charm | 64.5 | protection, removal | battle_ready |
| Molten Duplication | 64.5 | engine, wincon | battle_ready |
| Wheel of Fortune | 64.5 | draw | battle_ready |
| Arcane Signet | 63.5 | ramp | battle_ready |
| Sol Ring | 63.5 | ramp | battle_ready |
| Heat Shimmer | 62.5 | engine, wincon | battle_ready |
| Faithless Looting | 61.5 | draw, recursion | battle_ready |
| Arid Mesa | 61.0 | land, ramp | battle_ready |
