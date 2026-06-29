# Lorehold Promotion Gate Decision Audit

- Generated at: `2026-06-29T20:01:08Z`
- Status: `pass`
- Decision: `keep_protected_baseline`
- Protected baseline: `deck_607`
- Promoted deck keys: `[]`
- Ready for real deck change: `false`
- Best challenger for package follow-up: `deck_615`
- Summary: No challenger cleared aggregate, seed-window, pressure-matchup, and trace gates.
- Recommended next action: Keep deck_607 as baseline; create a narrow package test from deck_615 pressure/mana positives instead of swapping decks blindly.

## Gate Inputs

| Seed | Games/Opp | Opponents | Forced Access | Status |
| ---: | ---: | ---: | --- | --- |
| 42 | 3 | 8 | `none` | `ready` |
| 7 | 3 | 8 | `none` | `ready` |
| 20260625 | 3 | 8 | `none` | `ready` |

## Aggregate Result

| Deck | Structural Rank | Games | W | L | WR | Avg Win Turn | Early Losses | Winota W-L | Win Reasons |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| `deck_607` | 1 | 72 | 18 | 54 | 25.0% | 15.05 | 45 | 1-8 | approach=7, elimination=11 |
| `deck_614` | 3 | 72 | 14 | 58 | 19.44% | 19.21 | 55 | 0-9 | approach=5, elimination=9 |
| `deck_615` | 2 | 72 | 16 | 56 | 22.22% | 16.12 | 45 | 3-6 | approach=4, elimination=12 |

## Candidate Assessments

### deck_614

- Status: `do_not_promote`
- Passes: commander_plan_trace_present
- Blockers: aggregate wins 14/72 below baseline 18/72; tied/beat baseline in only 1/3 seed windows; Winota, Joiner of Forces #39 (real): 0/9 below baseline 1/9; early losses 55 exceed baseline 45

### deck_615

- Status: `do_not_promote`
- Passes: seed_window_majority_tie_or_beat, no_pressure_matchup_regression, commander_plan_trace_present
- Blockers: aggregate wins 16/72 below baseline 18/72

## Strategic Game Counts

| Deck | lorehold_cost_paid | lorehold_spell_cast | lorehold_upkeep_rummage | miracle_cast | topdeck_manipulation_activated | discard_to_top_replacement | birgi_spell_cast_mana | spell_cast_mana_trigger |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | 71 | 70 | 54 | 35 | 21 | 13 | 0 | 0 |
| `deck_614` | 71 | 71 | 33 | 28 | 21 | 5 | 0 | 0 |
| `deck_615` | 72 | 72 | 50 | 38 | 19 | 7 | 9 | 9 |

## Key Card Trace And Use Evidence

### deck_607

| Card | Accessed Games | Drawn Games | Near Access Games | Use Metrics |
| --- | ---: | ---: | ---: | --- |
| Approach of the Second Sun | 23 | 10 | 26 | cost_paid=9 |
| Aetherflux Reservoir | 0 | 0 | 0 | none |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | 0 | 0 | 0 | none |
| Mana Vault | 0 | 0 | 0 | none |
| Rise of the Eldrazi | 18 | 10 | 17 | none |
| Sensei's Divining Top | 25 | 4 | 12 | topdeck=46 |
| Scroll Rack | 17 | 6 | 16 | cost_paid=6, topdeck=30 |
| The One Ring | 0 | 0 | 0 | none |
| The Mind Stone | 13 | 6 | 12 | none |
| Molecule Man | 14 | 2 | 16 | none |
| Surge to Victory | 13 | 7 | 12 | none |
| Mizzix's Mastery | 18 | 7 | 18 | none |
| Seething Song | 0 | 0 | 0 | none |
| Call Forth the Tempest | 17 | 8 | 18 | none |
| Land Tax | 24 | 13 | 22 | cost_paid=18 |
| Library of Leng | 19 | 6 | 22 | none |
| Squee, Goblin Nabob | 0 | 0 | 0 | none |

### deck_614

| Card | Accessed Games | Drawn Games | Near Access Games | Use Metrics |
| --- | ---: | ---: | ---: | --- |
| Approach of the Second Sun | 18 | 8 | 15 | miracle=7 |
| Aetherflux Reservoir | 23 | 7 | 18 | cost_paid=7 |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | 0 | 0 | 0 | none |
| Mana Vault | 0 | 0 | 0 | none |
| Rise of the Eldrazi | 17 | 6 | 14 | none |
| Sensei's Divining Top | 20 | 10 | 14 | cost_paid=30, topdeck=31 |
| Scroll Rack | 17 | 6 | 14 | cost_paid=13, topdeck=23 |
| The One Ring | 0 | 0 | 0 | none |
| The Mind Stone | 0 | 0 | 0 | none |
| Molecule Man | 0 | 0 | 0 | none |
| Surge to Victory | 0 | 0 | 0 | none |
| Mizzix's Mastery | 0 | 0 | 0 | none |
| Seething Song | 11 | 2 | 16 | cost_paid=9 |
| Call Forth the Tempest | 21 | 12 | 20 | none |
| Land Tax | 15 | 7 | 15 | none |
| Library of Leng | 19 | 6 | 16 | none |
| Squee, Goblin Nabob | 0 | 0 | 0 | none |

### deck_615

| Card | Accessed Games | Drawn Games | Near Access Games | Use Metrics |
| --- | ---: | ---: | ---: | --- |
| Approach of the Second Sun | 27 | 9 | 24 | cost_paid=6 |
| Aetherflux Reservoir | 0 | 0 | 0 | none |
| Birgi, God of Storytelling // Harnfel, Horn of Bounty | 12 | 5 | 16 | spell_cast_mana=25 |
| Mana Vault | 28 | 9 | 19 | cost_paid=20 |
| Rise of the Eldrazi | 15 | 5 | 16 | none |
| Sensei's Divining Top | 28 | 14 | 22 | cost_paid=38, topdeck=60 |
| Scroll Rack | 0 | 0 | 0 | none |
| The One Ring | 16 | 10 | 26 | cost_paid=7 |
| The Mind Stone | 0 | 0 | 0 | none |
| Molecule Man | 0 | 0 | 0 | none |
| Surge to Victory | 0 | 0 | 0 | none |
| Mizzix's Mastery | 18 | 10 | 18 | cost_paid=6 |
| Seething Song | 21 | 6 | 19 | none |
| Call Forth the Tempest | 18 | 8 | 16 | none |
| Land Tax | 19 | 6 | 20 | none |
| Library of Leng | 18 | 5 | 17 | cost_paid=8 |
| Squee, Goblin Nabob | 0 | 0 | 0 | none |
