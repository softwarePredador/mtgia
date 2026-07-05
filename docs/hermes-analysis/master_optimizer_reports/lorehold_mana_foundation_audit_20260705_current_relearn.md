# Lorehold Mana Foundation Audit

- generated_at: `2026-07-05T02:57:43Z`
- deck_id: `607`
- status: `mana_foundation_pass_with_watch_items`
- postgres_writes: `false`
- source_db_mutated: `false`

## Summary

- lands: `34`
- ramp: `15`
- total mana package including Land Tax: `50`
- early foundation pieces: `8`
- true early mana pieces: `6`
- red sources: `24`
- white sources: `25`
- blockers: `none`
- watch items: `colorless_utility_land_pressure, tapped_land_tempo_pressure, late_or_contextual_ramp_should_not_be_counted_as_opening_fixing`

## Ramp Classes

| Class | Count |
| --- | ---: |
| `burst_or_treasure_ramp` | 4 |
| `early_colorless_acceleration` | 1 |
| `early_cost_reducer` | 2 |
| `early_recurring_colored_mana` | 5 |
| `table_tax_treasure_engine` | 1 |
| `turn_cycle_miracle_mana` | 2 |

## Candidate Staples

| Card | Legal | In 607 | EDHREC Lorehold | Local decision |
| --- | --- | --- | ---: | --- |
| Mana Vault | `legal` | `false` | 5.8% | `blocked_for_current_known_cuts` |
| The One Ring | `legal` | `false` | 8.4% | `blocked_for_current_607_shell` |

## Variant Comparison

| Deck | Lands | Ramp | Draw | Removal | Protection | Avg nonland CMC |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 606 | 39 | 17 | 13 | 4 | 7 | 3.66 |
| 607 | 34 | 15 | 9 | 7 | 12 | 3.88 |
| 608 | 31 | 18 | 31 | 4 | 2 | 2.96 |
| 609 | 30 | 11 | 20 | 6 | 7 | 3.74 |
| 610 | 30 | 17 | 10 | 3 | 2 | 3.79 |
| 611 | 34 | 15 | 24 | 1 | 1 | 4.23 |
| 612 | 27 | 18 | 7 | 1 | 5 | 3.27 |
| 613 | 32 | 15 | 22 | 1 | 8 | 3.71 |
| 614 | 33 | 19 | 14 | 1 | 7 | 3.93 |
| 615 | 34 | 12 | 14 | 4 | 9 | 3.68 |
| 616 | 29 | 8 | 15 | 10 | 9 | 3.97 |

## Learning Sources

- Wizards Commander format: https://magic.wizards.com/en/formats/commander
- EDHREC ramp guide: https://edhrec.com/guides/the-edhrec-guide-to-ramp-in-commander
- EDHREC Commander deckbuilding guide: https://edhrec.com/articles/how-to-build-a-commander-deck
- EDHREC Lorehold commander page: https://edhrec.com/commanders/lorehold-the-historian

## Next Actions

- Do not repeat Mana Vault over Arcane Signet or Bender's Waterskin without a new cut hypothesis.
- Do not retest The One Ring in protected 607 unless a new shell changes draw/protection pressure.
- Next mana work should test only named same-lane changes that preserve Boros fixing and miracle cadence.
