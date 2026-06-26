# Lorehold External Learning 2026-06-26

- status: `research_applied_no_deck_change_promoted`
- postgres_writes: `false`
- source_db_mutated: `false`
- protected_baseline: `deck_607`
- comparison_seed: `opponent_seed=20260626`, `simulation_seed=42`
- opponent_sample: `Vivi Ornitier #99 (real)`, `Sisay, Weatherlight Captain #61 (real)`, `Winota, Joiner of Forces #39 (real)`
- games_per_opponent: `3`

## External Research Frame

Sources reviewed:

- EDHREC Lorehold commander page: `https://edhrec.com/commanders/lorehold-the-historian`
- EDHREC average Lorehold deck: `https://edhrec.com/average-decks/lorehold-the-historian`
- EDHREC spellslinger guide: `https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander`
- EDHREC Commander deckbuilding guide: `https://edhrec.com/articles/how-to-build-a-commander-deck`
- Archidekt public Lorehold commander corpus: `https://archidekt.com/commanders/Lorehold%2C%20the%20Historian`
- Reddit Lorehold discussion: `https://www.reddit.com/r/EDH/comments/1qooic0/sos_lorehold_the_historian/`

The external pattern is consistent with the local deck identity: Lorehold wants topdeck setup, hand-to-top conversion, cheap protection, cost reduction, and spell payoffs. The research did not justify adding a large new package. It pointed to small, testable ablations.

## Local Corrections From Research

The model was corrected before generating new candidates:

- `The Scarlet Witch` is not off-plan. Local `battle_card_rules` has a verified cost-reduction rule for high-mana-value instant/sorcery spells.
- `Molecule Man` is not a simple draw card. Its oracle text gives nonland cards in hand miracle `{0}`, so it is central to Lorehold's ceiling even when telemetry does not show it often.
- `Penance` is structurally aligned with Lorehold because it puts a card from hand on top of library and has a verified local battle rule.
- `Longshot, Rebel Bowman` is structurally plausible because it rewards noncreature spell volume and has a verified local battle rule.
- `Promise of Loyalty` and `Tragic Arrogance` are pressure-absorber effects, not generic draw/unknown slots.

Implemented in `lorehold_strategy_profile_v3_2026_06_26`.

## Candidate Tests

| Candidate | Swap | Structural intent | Battle result | Winota result | Decision |
| --- | --- | --- | ---: | ---: | --- |
| `deck_607` | baseline | protected baseline | `5W/4L/0S`, WR `55.56%` | `2W/1L` | keep |
| `candidate_607_penance_v1` | `+Penance`, `-Promise of Loyalty` | add topdeck/protection from external research | `3W/6L/0S`, WR `33.33%` | `0W/3L` | reject |
| `candidate_607_longshot_v1` | `+Longshot, Rebel Bowman`, `-Storm Herd` | replace expensive token finisher with lower-curve spell payoff | `2W/7L/0S`, WR `22.22%` | `1W/2L` | reject |

## What Was Learned

`Penance` looked correct on paper, but cutting a five-mana pressure spell reduced the deck's ability to survive the pressure sample. The candidate kept spell volume but lost both miracle/topdeck game frequency and the Winota matchup.

`Longshot, Rebel Bowman` looked like a better curve/payoff conversion than `Storm Herd`, but it did not improve execution. It reduced cost-paid events, spell casts, miracle games, and overall win rate.

The current `deck_607` wins because it is already balanced around a narrow but effective shell: topdeck setup plus cost reducers plus high-impact spells plus enough pressure absorption. External cards that are individually synergistic still fail if the swap removes one of the pieces that lets the shell survive.

## Current Rule

Do not promote external-learning candidates from structure alone. A candidate must:

- tie or beat `deck_607` on the same real-opponent gate,
- not regress the Winota matchup,
- preserve or improve miracle/topdeck game frequency,
- and improve the result without cutting pressure absorption from the protected baseline.

## Next Candidate Lane

Future research should prioritize swaps that do not cut survival pieces:

- test sidegrades inside the same function, not cross-function swaps,
- compare expensive finishers against cheaper finishers only when the replacement has proven runtime conversion,
- keep `Promise of Loyalty`, `Tragic Arrogance`, `The Scarlet Witch`, and `Molecule Man` protected until a same-function replacement beats them in battle.

Generated artifacts:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_penance_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_penance_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_candidate_20260626_longshot_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_607_research_battle_gate_20260626_longshot_v1.json`
- `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260626_v3.json`
