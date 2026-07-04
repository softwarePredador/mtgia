# Lorehold Promotion Gate Decision Audit

- Generated at: `2026-07-04T23:23:41Z`
- Status: `pass`
- Decision: `keep_protected_baseline`
- Protected baseline: `deck_607`
- Candidate keys: `["challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1"]`
- Promoted deck keys: `[]`
- Ready for real deck change: `false`
- Best challenger for package follow-up: `challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1`
- Summary: No challenger cleared aggregate, seed-window, pressure-matchup, and trace gates.
- Recommended next action: Keep deck_607 as baseline; create a narrow package test from deck_615 pressure/mana positives instead of swapping decks blindly.

## Gate Inputs

| Seed | Games/Opp | Opponents | Forced Access | Status |
| ---: | ---: | ---: | --- | --- |
| 42 | 1 | 4 | `none` | `ready` |

## Aggregate Result

| Deck | Structural Rank | Games | W | L | WR | Avg Win Turn | Early Losses | Winota W-L | Win Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1` | 1 | 4 | 1 | 3 | 25.0% | 8.0 | 3 | 1-0 | approach=1 |
| `deck_607` | 2 | 4 | 0 | 4 | 0.0% | 0.0 | 4 | 0-1 | none |

## Candidate Assessments

### challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1

- Status: `do_not_promote`
- Passes: aggregate_wins_tie_or_beat_baseline, seed_window_majority_tie_or_beat, no_pressure_matchup_regression, commander_plan_trace_present
- Blockers: head-to-head vs protected 607 not won (0/1, losses=1)

## Strategic Game Counts

| Deck | lorehold_cost_paid | lorehold_spell_cast | lorehold_upkeep_rummage | miracle_cast | topdeck_manipulation_activated | discard_to_top_replacement | birgi_spell_cast_mana | spell_cast_mana_trigger |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1` | 4 | 4 | 4 | 3 | 1 | 1 | 0 | 0 |
| `deck_607` | 4 | 4 | 2 | 2 | 1 | 0 | 0 | 0 |

## Key Card Trace And Use Evidence

### challenger_lorehold_spell_pressure_mana_conversion_deoverfill_v1

| Card | Accessed Games | Drawn Games | Near Access Games | Use Metrics |
| --- | ---: | ---: | ---: | --- |
| Approach of the Second Sun | 0 | 0 | 0 | miracle_cast=2, spell_resolved=2 |
| Rise of the Eldrazi | 0 | 0 | 0 | miracle_cast=1, removal_resolved=1, spell_resolved=1 |
| Sensei's Divining Top | 1 | 0 | 0 | topdeck_manipulation_activated=1 |
| Scroll Rack | 1 | 0 | 1 | cost_paid=1, spell_cast=1, spell_resolved=1, topdeck_manipulation_activated=3 |
| The Mind Stone | 1 | 0 | 2 | none |
| Mizzix's Mastery | 0 | 0 | 0 | cost_paid=1, miracle_cast=1, spell_cast=1, spell_resolved=1 |
| Land Tax | 0 | 0 | 0 | none |
| Library of Leng | 1 | 1 | 1 | cost_paid=1, spell_cast=1, spell_resolved=1 |
| Squee, Goblin Nabob | 0 | 0 | 0 | none |

### deck_607

| Card | Accessed Games | Drawn Games | Near Access Games | Use Metrics |
| --- | ---: | ---: | ---: | --- |
| Approach of the Second Sun | 0 | 0 | 0 | miracle_cast=1 |
| Sensei's Divining Top | 2 | 0 | 1 | cost_paid=1, spell_cast=1, spell_resolved=1, topdeck_manipulation_activated=2 |
| Scroll Rack | 1 | 0 | 0 | cost_paid=1, spell_cast=1, spell_resolved=1, topdeck_manipulation_activated=3 |
| The Mind Stone | 2 | 1 | 2 | cost_paid=1, spell_cast=1 |
| Land Tax | 1 | 1 | 2 | cost_paid=1, spell_cast=1, spell_resolved=1 |
| Library of Leng | 0 | 0 | 1 | none |
| Squee, Goblin Nabob | 0 | 0 | 0 | none |
