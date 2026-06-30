# Lorehold Ideal Deck Candidate Matrix

- Generated at: `2026-06-30T14:28:05.617424+00:00`
- Status: `ready`
- Active deck id: `607`
- Lorehold deck ids: `[608, 609, 610, 611, 612, 613, 614, 615, 616]`
- Proposal report: `/Users/desenvolvimentomobile/.codex/worktrees/solo-consolidation-mtgia/docs/hermes-analysis/master_optimizer_reports/solo_deck_restart_20260630_next_action_planner.json`
- PostgreSQL writes: `False`
- Deck mutations: `False`

## Operating Decision

Use this matrix before any Lorehold swap work. Cards in
`needs_rule_before_strategy` must have XMage/ManaLoom rule confidence
closed before battle benchmarking. Cards in
`priority_benchmark_candidate` are the first safe candidates for
`slot_optimizer.py` after the baseline hash guard passes.

## Summary

- Rows: `348`
- Recommendation lanes: `{"low_priority": 25, "needs_rule_before_strategy": 5, "policy_blocked": 2, "priority_benchmark_candidate": 172, "watchlist_candidate": 144}`
- Rule statuses: `{"battle_ready": 340, "no_rule_signal": 5, "package_already_prepared": 3}`
- Active profile: `{}`

## Top Rule-First Cards

| Card | Score | Roles | Rule status | Scope/family | Next action |
| --- | ---: | --- | --- | --- | --- |
| Deathbellow War Cry | 21.5 | tutor | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Charmbreaker Devils | -1.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Naktamun Lorespinner // Wheel of Fortune | -2.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Karn's Sylex | -6.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |
| Karn, the Great Creator | -6.0 | unknown | no_rule_signal | - | map_or_verify_rule_before_strategy_scoring |

## Top Benchmark Candidates

| Card | Score | Roles | Decks | Rule status | Next action |
| --- | ---: | --- | --- | --- | --- |
| Lorehold, the Historian | 71.5 | draw, engine | [608, 609, 610, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Mizzix's Mastery | 68.0 | wincon | [608, 609, 610, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Library of Leng | 66.0 | engine, ramp | [608, 609, 610, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Reforge the Soul | 65.5 | draw | [609, 611, 612, 613, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Deflecting Swat | 64.0 | protection, draw | [608, 609, 611, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Restoration Seminar | 64.0 | engine, recursion | [609, 610, 611, 612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Enlightened Tutor | 63.5 | tutor | [608, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Gamble | 63.5 | tutor | [609, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Monument to Endurance | 62.5 | draw, ramp | [608, 609, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Sensei's Divining Top | 62.5 | draw | [608, 609, 610, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Teferi's Protection | 62.5 | protection | [608, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Scroll Rack | 62.0 | draw, ramp | [608, 609, 610, 611, 612, 613, 614, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Boros Charm | 60.5 | protection | [609, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Silence | 60.5 | protection | [612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Big Score | 60.0 | ramp | [609, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Arcane Signet | 59.5 | ramp | [608, 609, 610, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Land Tax | 59.5 | tutor | [609, 610, 611, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Sol Ring | 59.5 | ramp | [608, 609, 610, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Storm-Kiln Artist | 59.5 | ramp | [608, 611, 612, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Olórin's Searing Light | 59.0 | draw, removal | [609, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Brass's Bounty | 58.5 | ramp, wincon | [609, 611, 612, 613, 614, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Volcanic Vision | 58.5 | engine, recursion | [609, 611, 613, 614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Flashback | 58.0 | engine, recursion | [615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Improvisation Capstone | 58.0 | draw | [609, 610, 611, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Increasing Vengeance | 58.0 | engine | [612] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Redirect Lightning | 58.0 | protection, draw | [608, 611, 613] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Smothering Tithe | 58.0 | ramp | [608, 611, 612, 613, 614, 615, 616] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Unexpected Windfall | 58.0 | ramp | [609, 611, 613, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Currency Converter | 57.5 | draw, ramp | [614] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |
| Faithless Looting | 57.5 | draw | [611, 615] | battle_ready | run_safe_slot_benchmark_after_baseline_hash_guard |

## Core Keeps

| Card | Score | Roles | Rule status |
| --- | ---: | --- | --- |
