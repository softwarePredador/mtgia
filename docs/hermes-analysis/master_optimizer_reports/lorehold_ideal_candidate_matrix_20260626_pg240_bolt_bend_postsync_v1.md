# Lorehold Ideal Deck Candidate Matrix

- Generated at: `2026-06-26T10:43:09.598267+00:00`
- Status: `ready`
- Active deck id: `6`
- Lorehold deck ids: `[6, 25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg240_bolt_bend_postsync_v1_proposals.json`
- PostgreSQL writes: `False`
- Deck mutations: `False`

## Operating Decision

Use this matrix before any Lorehold swap work. Cards in
`needs_rule_before_strategy` must have XMage/ManaLoom rule confidence
closed before battle benchmarking. Cards in
`priority_benchmark_candidate` are the first safe candidates for
`slot_optimizer.py` after the baseline hash guard passes.

## Summary

- Rows: `963`
- Recommendation lanes: `{"active_low_confidence_review": 9, "core_keep": 91, "low_priority": 172, "needs_rule_before_strategy": 240, "policy_blocked": 3, "priority_benchmark_candidate": 124, "watchlist_candidate": 324}`
- Rule statuses: `{"battle_ready": 723, "blocked_missing_xmage_source": 4, "mapper_manual": 186, "no_rule_signal": 7, "runtime_needed": 1, "split_scope": 42}`
- Active profile: `{"board_wipe": 2, "draw": 27, "engine": 16, "land": 33, "protection": 18, "ramp": 53, "recursion": 6, "removal": 8, "stax": 7, "tutor": 8, "wincon": 12}`

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
| Neoform | 15.0 | tutor, draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Summons of Saruman | 14.5 | wincon | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Solphim, Mayhem Dominus | 14.0 | wincon | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Kefka, Court Mage // Kefka, Ruler of Ruin | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Morbid Opportunist | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Phyrexian Arena | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rune-Scarred Demon | 13.5 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Spiteful Visions | 13.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Valgavoth, Harrower of Souls | 13.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Infernal Grasp | 13.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Currency Converter | 12.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Experimental Overload | 12.5 | wincon | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Razaketh, the Foulblooded | 12.0 | tutor | split_scope | activated_pay_life_sacrifice_creature_any_tutor_to_hand_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Dark Deal | 11.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Firesong and Sunspeaker | 11.5 | wincon | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Suspended Sentence | 11.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Withering Torment | 11.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Disciple of Freyalise | 9.5 | draw | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Magmakin Artillerist | 9.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Malakir Rebirth // Malakir Mire | 9.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Penance | 9.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |

## Top Benchmark Candidates

| Card | Score | Roles | Decks | Rule status | Next action |
| --- | ---: | --- | --- | --- | --- |
| Library of Leng | 66.0 | engine, ramp | [606, 607, 608, 609, 610, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flusterstorm | 64.5 | protection | [31, 54, 58, 62, 83, 84, 104] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Restoration Seminar | 62.0 | engine, recursion | [606, 609, 610, 611, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Underworld Breach | 62.0 | engine, recursion | [31, 58, 62, 74, 83, 105, 606, 612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reforge the Soul | 61.5 | draw | [606, 607, 609, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Crop Rotation | 60.0 | tutor, ramp | [25, 54, 58, 62, 84, 104, 105, 116] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Demonic Tutor | 60.0 | tutor | [25, 31, 54, 58, 74, 83, 116, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Formidable Speaker | 60.0 | tutor, engine | [25, 31, 62, 104, 105, 116] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Increasing Vengeance | 60.0 | engine | [606, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flare of Duplication | 59.0 | engine | [62, 606, 612, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Nature's Rhythm | 59.0 | tutor | [25, 31, 54, 62, 84, 116] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Big Score | 58.0 | draw, ramp | [42, 607, 609, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Vampiric Tutor | 58.0 | tutor | [31, 54, 58, 74, 83, 116, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Noxious Revival | 57.0 | draw, engine, recursion | [58, 62, 104, 105] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Finale of Devastation | 56.5 | tutor, wincon | [54, 62, 84, 104] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Mental Misstep | 56.5 | protection | [31, 54, 58, 62, 83, 84, 104] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pact of Negation | 56.5 | protection | [31, 54, 58, 62, 83, 84, 104] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Swan Song | 56.5 | protection | [31, 54, 58, 83, 84, 104, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Volcanic Vision | 56.5 | engine, removal, recursion | [42, 609, 611, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Hexing Squelcher | 56.0 | protection | [58, 62, 74, 105, 606, 607, 609, 613, 614, 615, 616, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Imperial Seal | 56.0 | tutor | [31, 54, 58, 74, 83, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Fierce Guardianship | 54.5 | protection | [31, 54, 58, 62, 83, 84, 104] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Monument to Endurance | 54.5 | draw, ramp | [607, 608, 609, 611, 613, 614, 615, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Red Elemental Blast | 54.5 | protection | [58, 83, 105, 612, 613, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Diabolic Intent | 54.0 | tutor | [31, 58, 74, 83, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flashback | 54.0 | engine, recursion | [615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Improvisation Capstone | 54.0 | draw | [606, 607, 609, 610, 611, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Mystical Tutor | 54.0 | tutor | [58, 83, 104] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pinnacle Monk // Mystic Peak | 54.0 | engine, removal, recursion | [607, 608, 609, 610, 611] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Pyromancer Ascension | 54.0 | engine | [608] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |

## Core Keeps

| Card | Score | Roles | Rule status |
| --- | ---: | --- | --- |
| Lorehold, the Historian | 79.5 | draw, engine | battle_ready |
| Smothering Tithe | 77.5 | draw, engine, ramp, wincon | battle_ready |
| Mizzix's Mastery | 76.5 | draw, wincon, removal, recursion | battle_ready |
| Mana Vault | 76.0 | draw, engine, ramp | battle_ready |
| Esper Sentinel | 74.5 | draw, engine | battle_ready |
| Enlightened Tutor | 74.0 | tutor | battle_ready |
| Gamble | 74.0 | tutor | battle_ready |
| Silence | 72.5 | protection, stax | battle_ready |
| Storm-Kiln Artist | 72.0 | engine, ramp, wincon | battle_ready |
| Urza's Saga | 71.5 | land, tutor, ramp, wincon | battle_ready |
| Scroll Rack | 70.0 | draw, engine, ramp | battle_ready |
| Reverberate | 69.0 | engine | battle_ready |
| Teferi's Protection | 68.5 | protection | battle_ready |
| Twinflame | 68.5 | engine, wincon | battle_ready |
| Wheel of Fortune | 68.5 | draw | battle_ready |
| Deflecting Swat | 68.0 | protection, draw | battle_ready |
| Jeska's Will | 67.5 | draw, ramp | battle_ready |
| The One Ring | 67.0 | protection, draw, engine | battle_ready |
| Sensei's Divining Top | 66.5 | draw | battle_ready |
| Land Tax | 66.0 | tutor, draw, ramp | battle_ready |
| Unexpected Windfall | 65.5 | draw, ramp, wincon | battle_ready |
| Dualcaster Mage | 65.0 | engine | battle_ready |
| Reiterate | 65.0 | engine | battle_ready |
| Boros Charm | 64.5 | protection, removal | battle_ready |
| Molten Duplication | 64.5 | engine, wincon | battle_ready |
| Ranger-Captain of Eos | 64.5 | tutor, protection, draw, stax | battle_ready |
| Arcane Signet | 63.5 | ramp | battle_ready |
| Fellwar Stone | 63.5 | ramp | battle_ready |
| Lotus Petal | 63.5 | ramp | battle_ready |
| Sol Ring | 63.5 | ramp | battle_ready |
