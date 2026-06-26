# Lorehold Ideal Deck Candidate Matrix

- Generated at: `2026-06-26T09:34:18.364712+00:00`
- Status: `ready`
- Active deck id: `6`
- Lorehold deck ids: `[608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg237_magus_postsync_v1_proposals.json`
- PostgreSQL writes: `False`
- Deck mutations: `False`

## Operating Decision

Use this matrix before any Lorehold swap work. Cards in
`needs_rule_before_strategy` must have XMage/ManaLoom rule confidence
closed before battle benchmarking. Cards in
`priority_benchmark_candidate` are the first safe candidates for
`slot_optimizer.py` after the baseline hash guard passes.

## Summary

- Rows: `538`
- Recommendation lanes: `{"low_priority": 12, "needs_rule_before_strategy": 167, "policy_blocked": 2, "priority_benchmark_candidate": 194, "watchlist_candidate": 163}`
- Rule statuses: `{"battle_ready": 371, "blocked_missing_xmage_source": 2, "mapper_manual": 122, "split_scope": 43}`
- Active profile: `{}`

## Top Rule-First Cards

| Card | Score | Roles | Rule status | Scope/family | Next action |
| --- | ---: | --- | --- | --- | --- |
| Psychic Frog | 28.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Bloodchief Ascension | 26.0 | draw | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Tinybones, Trinket Thief | 25.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Forge Anew | 25.0 | engine, recursion | split_scope | graveyard_to_battlefield_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Whip of Erebos | 25.0 | engine, recursion | split_scope | targeted_exile_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rakdos Charm | 24.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Kederekt Parasite | 23.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Puresteel Paladin | 23.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Sram, Senior Edificer | 23.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Kefka, Court Mage // Kefka, Ruler of Ruin | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Morbid Opportunist | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Phyrexian Arena | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Spiteful Visions | 21.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Valgavoth, Harrower of Souls | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Infernal Grasp | 21.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rune-Scarred Demon | 21.0 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Currency Converter | 20.5 | ramp | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Solphim, Mayhem Dominus | 20.5 | wincon | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Dark Deal | 19.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Razaketh, the Foulblooded | 19.5 | tutor | split_scope | activated_pay_life_sacrifice_creature_any_tutor_to_hand_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Suspended Sentence | 19.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Withering Torment | 19.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Vivi Ornitier | 18.5 | ramp | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Firesong and Sunspeaker | 18.0 | wincon | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Magmakin Artillerist | 17.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Bolt Bend | 17.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Malakir Rebirth // Malakir Mire | 17.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Penance | 17.0 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Sheoldred // The True Scriptures | 16.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Deathbellow War Cry | 15.5 | tutor | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |

## Top Benchmark Candidates

| Card | Score | Roles | Decks | Rule status | Next action |
| --- | ---: | --- | --- | --- | --- |
| Lorehold, the Historian | 71.5 | draw, engine | [608, 609, 610, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Deflecting Swat | 68.0 | protection, draw | [608, 609, 611, 613, 614, 615, 616, 617, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Mizzix's Mastery | 68.0 | wincon | [608, 609, 610, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Library of Leng | 66.0 | engine, ramp | [608, 609, 610, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Enlightened Tutor | 65.5 | tutor | [608, 611, 612, 613, 614, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reforge the Soul | 65.5 | draw | [609, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Monument to Endurance | 64.5 | draw, ramp | [608, 609, 611, 613, 614, 615, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Restoration Seminar | 64.0 | engine, recursion | [609, 610, 611, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Gamble | 63.5 | tutor | [609, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Sensei's Divining Top | 62.5 | draw | [608, 609, 610, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Silence | 62.5 | protection | [612, 613, 614, 615, 616, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Teferi's Protection | 62.5 | protection | [608, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Scroll Rack | 62.0 | draw, ramp | [608, 609, 610, 611, 612, 613, 614, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Arcane Signet | 61.5 | ramp | [608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Mountain // Mountain | 61.5 | land, ramp | [608, 609, 610, 611, 613, 614, 615, 616, 617, 618, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Sol Ring | 61.5 | ramp | [608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Boros Charm | 60.5 | protection | [609, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Big Score | 60.0 | ramp | [609, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Redirect Lightning | 60.0 | protection, draw | [608, 611, 613, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Smothering Tithe | 60.0 | ramp | [608, 611, 612, 613, 614, 615, 616, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Faithless Looting | 59.5 | draw | [611, 615, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Land Tax | 59.5 | tutor | [609, 610, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Plains // Plains | 59.5 | land, ramp | [609, 610, 611, 612, 613, 614, 615, 616, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Storm-Kiln Artist | 59.5 | ramp | [608, 611, 612, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Arcane Denial | 59.0 | protection, draw | [617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Olórin's Searing Light | 59.0 | draw, removal | [609, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| The One Ring | 59.0 | protection, draw | [608, 613, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Brass's Bounty | 58.5 | ramp, wincon | [609, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Volcanic Vision | 58.5 | engine, recursion | [609, 611, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Chaos Warp | 58.0 | draw, removal | [611, 615, 616, 617, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |

## Core Keeps

| Card | Score | Roles | Rule status |
| --- | ---: | --- | --- |
