# Lorehold Card Exposure Profile - 2026-06-27

- Generated at: `2026-06-27T23:25:51Z`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_squee_equal_gate_rerun_20260627_010256_squee_goblin_nabob/knowledge_candidate.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Evidence paths scanned: `623`
- JSON files scanned: `387`
- JSONL files scanned: `236`
- Parse errors: `0`

## Card Profiles

| Card | Unique Exposure | Role | Decision | Signals | Top Events/Metrics |
| --- | ---: | --- | --- | --- | --- |
| Emeria's Call // Emeria, Shattered Skyclave | 193 | `token_protection_rebuild` | `not_safe_as_blind_cut` | board_development_tokens, discard_or_rummage_context, miracle_hit, protection_window | protection_resolved=88, tokens_created=88, turn_end=5, discard_to_top:Emeria's Call // Emeria, Shattered Skyclave=8, lorehold_rummage_to_top:Emeria's Call // Emeria, Shattered Skyclave=8, miracle:Emeria's Call // Emeria, Shattered Skyclave=19 |
| Austere Command | 2 | `board_wipe_pressure_reset` | `candidate_role_known` | pressure_reset_board_wipe | board_wipe_resolved=1, spell_resolved=1 |
| Squee, Goblin Nabob | 6660 | `recursion_engine` | `protect_current_engine` | discard_or_rummage_context, graveyard_recursion, paid_cast_exposure | airbend_creature_cast_from_exile=82, cast_announced=1538, cast_illegal=4, cost_paid=1526, creature_cast=1435, cost_paid:Squee, Goblin Nabob=992, graveyard_return:Squee, Goblin Nabob=269 |
| Volcanic Vision | 2 | `recursion_candidate` | `needs_non_squee_cut` | miracle_hit, spell_or_permanent_recursion | miracle:Volcanic Vision=2 |
| Restoration Seminar | 2 | `recursion_candidate` | `needs_non_squee_cut` | paid_cast_exposure, spell_or_permanent_recursion | cost_paid:Restoration Seminar=2 |
| Gamble | 228 | `tutor_access` | `runtime_ready_cut_sensitive` | paid_cast_exposure, tutor_access | cast_announced=10, cost_paid=8, miracle_cast=7, priority_pass=45, random_discard_after_tutor=6, cost_paid:Gamble=2 |
| Enlightened Tutor | 202 | `tutor_access` | `runtime_ready_cut_sensitive` | paid_cast_exposure, tutor_access | cast_announced=6, cost_paid=5, end_step_instant=7, miracle_cast=6, priority_pass=24, cost_paid:Enlightened Tutor=18 |

## Package Implications

- `austere_command_over_emeria`: `manual_tradeoff_only` - Emeria has measured token/protection exposure, so Austere must prove board-reset value beats rebuild/protection loss.
- `volcanic_or_restoration_over_squee`: `blocked_until_non_squee_cut` - Squee has measured graveyard-return exposure and should remain protected.
- `tutor_access`: `seed_safe_cut_required` - Tutor effects are modelable, but promotion depends on a cut model that preserves the known strong seed.

## Samples

### Emeria's Call // Emeria, Shattered Skyclave

- Decision: `not_safe_as_blind_cut`; next: test_austere_only_as_explicit_wipe_over_rebuild_tradeoff
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_reprieve_cut_avatar_wrath:Sisay, Weatherlight Captain #61 (real):0[8]` turn `8` effect `` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_game_traces.synergy_reprieve_cut_avatar_wrath:Sisay, Weatherlight Captain #61 (real):0[9]` turn `8` effect `token_maker` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[8]` turn `8` effect `` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_remaining_fixed.json` path `packages[2].gate_summary.candidate.telemetry.squee_trace_samples[9]` turn `8` effect `token_maker` metric ``
- `turn_end` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Winota, Joiner of Forces #39 (real):0[1]` turn `4` effect `` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Aang, at the Crossroads #106 (real):1[15]` turn `13` effect `` metric ``
- `tokens_created` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Aang, at the Crossroads #106 (real):1[16]` turn `13` effect `token_maker` metric ``
- `protection_resolved` from `docs/hermes-analysis/master_optimizer_reports/lorehold_brass_bounty_gate_20260627_v3_games3_opp8_20260627_212849.json` path `packages[0].gate_summary.candidate.telemetry.squee_game_traces.synergy_brass_bounty_cut_boros_signet:Sisay, Weatherlight Captain #61 (real):0[22]` turn `8` effect `` metric ``

### Austere Command

- Decision: `candidate_role_known`; next: only_gate_against_emeria_if_targeting_more_board_reset_than_rebuild
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_events_20260622_190701.jsonl` path `line:1` turn `6` effect `board_wipe` metric ``
- `board_wipe_resolved` from `docs/hermes-analysis/master_optimizer_reports/austere_command_pg028_focused_events_20260622_190701.jsonl` path `line:2` turn `6` effect `` metric ``

### Squee, Goblin Nabob

- Decision: `protect_current_engine`; next: do_not_cut_for_volcanic_or_restoration_without_non_squee_package
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[14]` turn `15` effect `` metric ``
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[1]` turn `12` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[2]` turn `12` effect `creature` metric ``
- `creature_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_game_traces.deck_6:Vivi Ornitier #99 (real):0[3]` turn `12` effect `creature` metric ``
- `permanent_moved_from_battlefield` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[14]` turn `15` effect `` metric ``
- `cast_announced` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[1]` turn `12` effect `creature` metric ``
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[2]` turn `12` effect `creature` metric ``
- `creature_cast` from `docs/hermes-analysis/master_optimizer_reports/lorehold_614_615_hypothesis_gate_20260627_v1_seed42_akroma_fixed.json` path `packages[0].gate_summary.baseline.telemetry.squee_trace_samples[3]` turn `12` effect `creature` metric ``

### Volcanic Vision

- Decision: `needs_non_squee_cut`; next: find recursion cut that is not the protected Squee engine
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1.json` path `results[8].telemetry.top_cards[4]` turn `` effect `` metric `miracle:Volcanic Vision`
- `miracle` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1_partial.json` path `results[8].telemetry.top_cards[4]` turn `` effect `` metric `miracle:Volcanic Vision`

### Restoration Seminar

- Decision: `needs_non_squee_cut`; next: find recursion cut that is not the protected Squee engine
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1.json` path `results[6].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Restoration Seminar`
- `cost_paid` from `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1_partial.json` path `results[6].telemetry.top_cards[8]` turn `` effect `` metric `cost_paid:Restoration Seminar`

### Gamble

- Decision: `runtime_ready_cut_sensitive`; next: retest only with seed-safe cut model
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl` path `line:4` turn `3` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl` path `line:5` turn `3` effect `` metric ``
- `random_discard_after_tutor` from `docs/hermes-analysis/master_optimizer_reports/deck6_pg070_red_discard_runtime_focused_events_20260623_042617.jsonl` path `line:6` turn `3` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:29` turn `2` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:30` turn `2` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_100.jsonl` path `line:31` turn `2` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1005.jsonl` path `line:5` turn `1` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1005.jsonl` path `line:6` turn `1` effect `tutor` metric ``

### Enlightened Tutor

- Decision: `runtime_ready_cut_sensitive`; next: retest only with seed-safe cut model
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:174` turn `8` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:175` turn `8` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1001.jsonl` path `line:176` turn `8` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:257` turn `13` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:259` turn `13` effect `tutor` metric ``
- `tutor_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_1004.jsonl` path `line:260` turn `13` effect `` metric ``
- `spell_cast` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_101.jsonl` path `line:261` turn `12` effect `tutor` metric ``
- `spell_resolved` from `docs/hermes-analysis/master_optimizer_reports/forensic_replays/battle_forensic_seed_101.jsonl` path `line:262` turn `12` effect `tutor` metric ``
