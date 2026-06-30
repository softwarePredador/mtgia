# Lorehold Next Hypothesis Queue - 2026-06-30

- Generated at: `2026-06-30T05:16:17Z`
- Strategy audit: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260628_v2_runtime_packages.json`
- Source DB: `/Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- PostgreSQL writes: `false`
- Source DB mutated: `false`

## Summary

- Status counts: `{"tested_negative_do_not_promote": 13}`
- Gate-ready packages: `0`
- Risky same-lane-only packages: `0`
- Tested negative packages: `13`
- Blocked packages: `0`

## Queue

| Rank | Package | Status | Score | Adds | Cuts | Lane | Targets | Prior Gate | Blockers |
| ---: | --- | --- | ---: | --- | --- | --- | --- | --- | --- |
| 1 | `perch_protection_cut_avatar_wrath` | `tested_negative_do_not_promote` | 31 | Perch Protection | Avatar's Wrath | protection_window | seed_20260625_pressure_conversion, combat_pressure_life_zero | 1-2 vs 3-0 (-66.67 pp) | none |
| 2 | `akromas_will_cut_avatar_wrath` | `tested_negative_do_not_promote` | 23 | Akroma's Will | Avatar's Wrath | protection_window | seed_20260625_pressure_conversion, finisher_window | 0-3 vs 3-0 (-100.00 pp) | none |
| 3 | `silence_cut_avatar_wrath` | `tested_negative_do_not_promote` | 21 | Silence | Avatar's Wrath | protection_window | second_approach_window, decisive_spell_turn_protection | 1-2 vs 3-0 (-66.67 pp) | none |
| 4 | `dragon_rage_channeler_cut_scarlet_witch` | `tested_negative_do_not_promote` | 16 | Dragon's Rage Channeler | The Scarlet Witch | topdeck_miracle_setup | seed_7_missing_early_engine | 0-3 vs 3-0 (-100.00 pp) | none |
| 5 | `grand_abolisher_cut_mother_of_runes` | `tested_negative_do_not_promote` | 13 | Grand Abolisher | Mother of Runes | protection_window | decisive_spell_turn_protection | 0-3 vs 3-0 (-100.00 pp) | none |
| 6 | `reprieve_cut_avatar_wrath` | `tested_negative_do_not_promote` | 13 | Reprieve | Avatar's Wrath | protection_window | tempo_survival, second_approach_window | 0-3 vs 3-0 (-100.00 pp) | none |
| 7 | `guttersnipe_spell_payoff_cut_prismari` | `tested_negative_do_not_promote` | 8 | Guttersnipe | Prismari Pianist | spell_chain_conversion | topdeck_miracle_without_approach_under_pressure, spell_volume_payoff | 0-3 vs 3-0 (-100.00 pp) | none |
| 8 | `pg245_verge_rangers_topdeck_land_cut_waterskin` | `tested_negative_do_not_promote` | 8 | Verge Rangers | Bender's Waterskin | topdeck_miracle_setup | seed_7_missing_early_engine, land_drop_velocity | 0-3 vs 3-0 (-100.00 pp) | none |
| 9 | `radiant_scrollwielder_cut_scarlet_witch` | `tested_negative_do_not_promote` | 8 | Radiant Scrollwielder | The Scarlet Witch | graveyard_recursion | spell_reuse, pressure_lifegain | 1-2 vs 3-0 (-66.67 pp) | none |
| 10 | `lapse_approach_topdeck_cut_tibalts_trickery` | `tested_negative_do_not_promote` | 0 | Lapse of Certainty | Tibalt's Trickery | deterministic_finishers | second_approach_window, topdeck_miracle_setup | 1-2 vs 3-0 (-66.67 pp) | none |
| 11 | `monastery_mentor_spell_tokens_cut_prismari` | `tested_negative_do_not_promote` | 0 | Monastery Mentor | Prismari Pianist | spell_chain_conversion | combat_pressure_life_zero, spell_volume_payoff | 1-2 vs 3-0 (-66.67 pp) | none |
| 12 | `pg245_twinflame_damage_payoff_cut_thor` | `tested_negative_do_not_promote` | 0 | Twinflame Tyrant | Thor, God of Thunder | spell_chain_conversion | spell_damage_conversion, combat_damage_conversion | 4-5 vs 7-2 (-33.34 pp) | none |
| 13 | `young_pyromancer_spell_tokens_cut_prismari` | `tested_negative_do_not_promote` | 0 | Young Pyromancer | Prismari Pianist | spell_chain_conversion | combat_pressure_life_zero, early_spell_volume_payoff | 1-2 vs 3-0 (-66.67 pp) | none |

## Gate-Ready Detail

## Promotion Contract

- promotion_bar: tie or beat the Squee champion aggregate record across the same seed/opponent window
- promotion_bar: do not regress seed 42 unless a larger gate proves the strong-seed pattern moved elsewhere
- promotion_bar: do not promote from popularity or static structure without battle evidence
- promotion_bar: a negative smoke result remains no-promotion unless a specific failure classifier target explains why to override it
- must_target: seed 7: missing early topdeck/Library/Squee engine
- must_target: seed 20260625: engine appears but fails to convert Approach/topdeck loops into survival or a second win window
- must_target: combat-pressure/life-zero losses without cutting the known protection shell
- required_telemetry: miracle_cast and topdeck_manipulation_activated must not fall in the strong seed
- required_telemetry: discard_to_top_replacement should connect to survival, Approach recast, or a finisher window
- required_telemetry: spell_cast_mana_trigger or ritual_mana_added is useful only if win rate and seed-42 conversion survive
- required_telemetry: Squee value must be tied to observed graveyard entry route, not assumed discard synergy
- hard_reject_if: candidate cuts a locked/protected card without same-lane proof
- hard_reject_if: candidate only adds generic ramp/value and lowers miracle/topdeck/spell volume
- hard_reject_if: candidate wins weak seeds but collapses seed 42 in the first controlled gate
- hard_reject_if: candidate depends on a card with unresolved battle runtime/model evidence
