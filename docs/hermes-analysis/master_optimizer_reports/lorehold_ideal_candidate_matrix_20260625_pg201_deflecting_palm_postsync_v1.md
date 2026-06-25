# Lorehold Ideal Deck Candidate Matrix

- Generated at: `2026-06-25T03:28:04.992602+00:00`
- Status: `ready`
- Active deck id: `6`
- Lorehold deck ids: `[606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619]`
- Proposal report: `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260625_pg201_deflecting_palm_postsync_v1_proposals.json`
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
- Recommendation lanes: `{"low_priority": 37, "needs_rule_before_strategy": 104, "policy_blocked": 2, "priority_benchmark_candidate": 199, "watchlist_candidate": 225}`
- Rule statuses: `{"battle_ready": 351, "no_rule_signal": 104, "package_already_prepared": 112}`
- Active profile: `{}`

## Top Rule-First Cards

| Card | Score | Roles | Rule status | Scope/family | Next action |
| --- | ---: | --- | --- | --- | --- |
| Redress Fate | 28.5 | draw | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Molecule Man | 24.5 | draw | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Scholar of New Horizons | 24.5 | tutor | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Deathbellow War Cry | 21.5 | tutor | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Millikin | 21.5 | ramp | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Starfield Shepherd | 20.5 | tutor | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Bedlam Reveler | 19.5 | draw | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Blood Sun | 19.5 | draw | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Thor, God of Thunder | 14.0 | removal | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Unstable Glyphbridge // Sandswirl Wanderglyph | 8.0 | board_wipe | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Wild Ricochet | 6.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Tinybones, Bauble Burglar | 1.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Tinybones, Trinket Thief | 0.5 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Leyline Dowser | 0.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Teferi's Time Twist | 0.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| The Seriema | -0.5 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Cemetery Gatekeeper | -1.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Charmbreaker Devils | -1.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Codex Shredder | -1.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Open the Vaults | -1.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Wand of Vertebrae | -1.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Davros, Dalek Creator | -1.5 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Words of Waste | -1.5 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Alicia Masters, Skilled Sculptor | -2.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Chaos Wand | -2.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Green Goblin, Nemesis | -2.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Liliana's Caress | -2.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Mjölnir, Hammer of Thor | -2.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Naktamun Lorespinner // Wheel of Fortune | -2.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Prototype Portal | -2.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |

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
