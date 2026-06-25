# Lorehold Ideal Deck Candidate Matrix

- Generated at: `2026-06-25T01:58:09.554789+00:00`
- Status: `ready`
- Active deck id: `6`
- Lorehold deck ids: `[606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg198_surly_badgersaur_postsync_v1_proposals.json`
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
- Recommendation lanes: `{"low_priority": 8, "needs_rule_before_strategy": 219, "policy_blocked": 2, "priority_benchmark_candidate": 197, "watchlist_candidate": 141}`
- Rule statuses: `{"battle_ready": 348, "blocked_missing_xmage_source": 4, "mapper_manual": 144, "runtime_needed": 16, "split_scope": 55}`
- Active profile: `{}`

## Top Rule-First Cards

| Card | Score | Roles | Rule status | Scope/family | Next action |
| --- | ---: | --- | --- | --- | --- |
| Psychic Frog | 28.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Bloodchief Ascension | 26.0 | draw | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Tinybones, Trinket Thief | 25.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Fable of the Mirror-Breaker // Reflection of Kiki-Jiki | 25.0 | ramp, wincon | runtime_needed | xmage_create_token_variant_fableofthemirrorbreaker_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Forge Anew | 25.0 | engine, recursion | split_scope | graveyard_to_battlefield_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Whip of Erebos | 25.0 | engine, recursion | split_scope | targeted_exile_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rakdos Charm | 24.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Kederekt Parasite | 23.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Puresteel Paladin | 23.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Sram, Senior Edificer | 23.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Taii Wakeen, Perfect Shot | 23.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Trouble in Pairs | 23.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Deflecting Palm | 23.0 | protection | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Primal Amulet // Primal Wellspring | 23.0 | ramp | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Redress Fate | 22.5 | draw | mapper_manual | xmage_reference_requires_manual_model_review_v1 | map_or_verify_rule_before_strategy_scoring |
| Starfield Shepherd | 22.5 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Bedlam Reveler | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Black Market Connections | 21.5 | ramp, wincon | runtime_needed | xmage_create_token_variant_blackmarketconnections_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Blood Sun | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Kefka, Court Mage // Kefka, Ruler of Ruin | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Morbid Opportunist | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Palantír of Orthanc | 21.5 | draw | split_scope | source_add_counters_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Phyrexian Arena | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Smuggler's Share | 21.5 | ramp, wincon | runtime_needed | xmage_create_token_variant_smugglersshare_v1 | implement_runtime_family_with_focused_test_before_swap_testing |
| Spiteful Visions | 21.5 | draw | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Valgavoth, Harrower of Souls | 21.5 | draw | split_scope | source_controller_draw_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Erode | 21.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Infernal Grasp | 21.0 | removal | split_scope | targeted_destroy_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Razorgrass Ambush // Razorgrass Field | 21.0 | removal | split_scope | targeted_damage_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |
| Rune-Scarred Demon | 21.0 | tutor | split_scope | etb_tutor_to_hand_creature_variant_v1 | split_xmage_scope_then_promote_rule_before_swap_testing |

## Top Benchmark Candidates

| Card | Score | Roles | Decks | Rule status | Next action |
| --- | ---: | --- | --- | --- | --- |
| Lorehold, the Historian | 73.5 | draw, engine | [606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Deflecting Swat | 70.0 | protection, draw | [606, 607, 608, 609, 611, 613, 614, 615, 616, 617, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Library of Leng | 70.0 | engine, ramp | [606, 607, 608, 609, 610, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Mizzix's Mastery | 70.0 | wincon | [607, 608, 609, 610, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reforge the Soul | 69.5 | draw | [606, 607, 609, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Monument to Endurance | 66.5 | draw, ramp | [607, 608, 609, 611, 613, 614, 615, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Teferi's Protection | 66.5 | protection | [606, 607, 608, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Restoration Seminar | 66.0 | engine, recursion | [606, 609, 610, 611, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Enlightened Tutor | 65.5 | tutor | [608, 611, 612, 613, 614, 615, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Sensei's Divining Top | 64.5 | draw | [606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Scroll Rack | 64.0 | draw, ramp | [607, 608, 609, 610, 611, 612, 613, 614, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Smothering Tithe | 64.0 | ramp | [606, 607, 608, 611, 612, 613, 614, 615, 616, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Gamble | 63.5 | tutor | [609, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Land Tax | 63.5 | tutor | [606, 607, 609, 610, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Boros Charm | 62.5 | protection | [606, 609, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Silence | 62.5 | protection | [612, 613, 614, 615, 616, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Big Score | 62.0 | ramp | [607, 609, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Improvisation Capstone | 62.0 | draw | [606, 607, 609, 610, 611, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Redirect Lightning | 62.0 | protection, draw | [607, 608, 611, 613, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Arcane Signet | 61.5 | ramp | [606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Jeska's Will | 61.5 | ramp | [606, 607, 608, 612, 613, 614, 615, 616, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Mountain // Mountain | 61.5 | land, ramp | [606, 607, 608, 609, 610, 611, 613, 614, 615, 616, 617, 618, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Plains // Plains | 61.5 | land, ramp | [606, 607, 609, 610, 611, 612, 613, 614, 615, 616, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Sol Ring | 61.5 | ramp | [606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Olórin's Searing Light | 61.0 | draw, removal | [606, 609, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Hexing Squelcher | 60.0 | protection | [606, 607, 609, 613, 614, 615, 616, 618] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Increasing Vengeance | 60.0 | engine | [606, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Unexpected Windfall | 60.0 | ramp | [607, 609, 611, 613, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Faithless Looting | 59.5 | draw | [611, 615, 617] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Storm-Kiln Artist | 59.5 | ramp | [608, 611, 612, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |

## Core Keeps

| Card | Score | Roles | Rule status |
| --- | ---: | --- | --- |
