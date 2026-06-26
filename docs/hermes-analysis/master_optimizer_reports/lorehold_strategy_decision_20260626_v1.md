# Lorehold Strategy Decision 2026-06-26

## Executive Read

The current evidence does not support promoting `candidate_v7` as the final
Lorehold deck yet. It is the strongest structural candidate, but the equal
battle gates show that `deck_607` is the best performing structure in the
current tested window.

Recommended current direction:

- Use `deck_607` as the primary learned structure to study and evolve next.
- Use `candidate_v7` as the structural/engine reference, not as the final deck.
- Do not use `deck_6` or `deck_606` as the next optimization target without
  targeted repair; both collapsed in the 9-game finalist gate.
- Convert the next tuning pass into a `deck_607 -> v7` bridge: preserve the
  proven battle package from `deck_607`, then selectively reintroduce the v7
  cards that improved topdeck/miracle execution without weakening the Winota
  matchup.

## Evidence Sources

- Structural matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_strategy_matrix_20260626_v1.json`
- All-deck equal battle gate:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_20260626_v1.json`
- Finalist equal battle gate:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_variant_battle_gate_finalists_20260626_v1.json`
- External criteria lanes:
  [Cardsphere Commander structure](https://blog.cardsphere.com/building-a-commander-deck-part-two-structure/),
  [Card Kingdom spellslinger Commander](https://blog.cardkingdom.com/spellslinger-commander-deck-building-guide/),
  [EDHREC Lorehold](https://edhrec.com/commanders/lorehold-the-historian),
  [EDHREC Boros Miracles on a Budget](https://edhrec.com/articles/lorehold-the-historian-boros-miracles-on-a-budget),
  [Archidekt Lorehold corpus](https://archidekt.com/commanders/Lorehold%2C%20the%20Historian).

All gates were read-only:

- PostgreSQL writes: `false`
- Source SQLite mutation: `false`
- Opponents: `Vivi Ornitier #99`, `Sisay, Weatherlight Captain #61`,
  `Winota, Joiner of Forces #39`
- Opponent seed: `20260626`
- Simulation seed: `42`

## Structural Matrix Result

The structural matrix ranked `candidate_v7` first and `deck_6` second before
battle:

| Structural Rank | Deck | Score | Main Structural Read |
| ---: | --- | ---: | --- |
| 1 | `candidate_v7` | 141.7 | Best package balance, no captured structural shortfall |
| 2 | `deck_6` | 138.2 | Strong active shell, but wincon role risk |
| 3 | `deck_615` | 137.0 | Big-spells variant, but removal/recursion/tutor risks |
| 6 | `deck_607` | 135.6 | Battle variant with recursion/tutor risks |

This proved that v7 was a strong deck-on-paper. It did not prove it was the
best battle deck.

## All-Deck Gate

The initial equal gate used all registered Lorehold decks plus v7:

- Scope: `deck_6`, `606-616`, `candidate_v7`
- Games: `1` per opponent, `3` total per deck
- Result: no runtime failures

Only four decks won a game in this broad pass:

| Deck | Result | WR | Structural Rank |
| --- | ---: | ---: | ---: |
| `deck_6` | 1W/2L/0S | 33.33% | 2 |
| `deck_606` | 1W/2L/0S | 33.33% | 8 |
| `deck_607` | 1W/2L/0S | 33.33% | 6 |
| `deck_608` | 1W/2L/0S | 33.33% | 13 |
| `candidate_v7` | 0W/3L/0S | 0.00% | 1 |

This gate was too small to choose a final deck, but it was enough to identify
the finalist set and reveal that v7 needed a higher-sample check.

## Finalist Gate

The finalist gate retested the strongest observed and structural candidates:

- Scope: `deck_6`, `606`, `607`, `608`, `615`, `candidate_v7`
- Games: `3` per opponent, `9` total per deck
- Result: no runtime failures

| Battle Rank | Deck | Result | WR | Avg Win Turn | Miracle Games | Topdeck Games |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 1 | `deck_607` | 5W/4L/0S | 55.56% | 13.60 | 7/9 | 4/9 |
| 2 | `candidate_v7` | 3W/5L/1S | 33.33% | 18.00 | 6/9 | 7/9 |
| 3 | `deck_608` | 1W/8L/0S | 11.11% | 13.00 | 1/9 | 0/9 |
| 4 | `deck_615` | 1W/8L/0S | 11.11% | 18.00 | 2/9 | 1/9 |
| 5 | `deck_6` | 0W/9L/0S | 0.00% | 0.00 | 2/9 | 1/9 |
| 6 | `deck_606` | 0W/9L/0S | 0.00% | 0.00 | 3/9 | 1/9 |

`deck_607` is the only finalist above 50% in this gate. It also won against
all three opponent lanes:

- Vivi: `1W/2L`
- Sisay: `2W/1L`
- Winota: `2W/1L`

`candidate_v7` was second and showed real engine execution, but it failed the
Winota lane:

- Vivi: `1W/2L`
- Sisay: `2W/0L/1S`
- Winota: `0W/3L`

## Strategic Interpretation

`deck_607` appears to be the current best battle structure because it combines
enough miracle execution with more practical interaction:

- `23` miracle casts in the finalist gate.
- Miracle happened in `7/9` games.
- It won by both `Approach of the Second Sun` and elimination.
- It had `16` removal by battle shape, more than v7's `10`.
- It beat Winota `2/3`, which is the matchup where v7 failed `0/3`.

This also matches the current external Lorehold framing: Lorehold's commander
text wants first-draw miracle windows and repeated opponent-upkeep rummage, but
the deck still needs enough interaction to survive until those windows matter.

`candidate_v7` is still useful, but the evidence says it is over-weighted
toward engine density relative to matchup conversion:

- It had `24` miracle casts and topdeck manipulation in `7/9` games.
- It still finished only `3W/5L/1S`.
- Its wins came against Vivi and Sisay, not Winota.
- Therefore the issue is not simply "can the deck execute miracle"; the issue
  is whether that execution turns into survival and wins against pressure.

`deck_6` is not the best current structure under this gate:

- It went `0W/9L` in the finalist gate.
- It only produced miracle games in `2/9`.
- Its active shell still has useful anchors, but the battle result does not
  justify using it as the next deck reference.

## Deck 607 vs Candidate v7 Learning

Cards present in `deck_607` and absent from v7 are the first place to inspect
for practical battle pressure and conversion:

- Board wipes / pressure answers: `Avatar's Wrath`, `Call Forth the Tempest`,
  `Everything Comes to Dust`, `Farewell`, `Fated Clash`, `Promise of Loyalty`,
  `Starfall Invocation`, `Winds of Abandon`.
- Spot interaction / protection: `Generous Gift`, `Stroke of Midnight`,
  `Dawn's Truce`, `Swiftfoot Boots`, `Tibalt's Trickery`.
- Big conversion / finishers: `Insurrection`, `Rise of the Eldrazi`,
  `Storm Herd`, `Surge to Victory`, `Tempt with Bunnies`.
- Mana and support: `Victory Chimes`, `Pearl Medallion`, `Monument to
  Endurance`, `Bender's Waterskin`.

Cards present in v7 and absent from `deck_607` are still valuable, but should
be reintroduced only when they improve conversion or shore up the Winota lane:

- Engine/combo: `Aetherflux Reservoir`, `Birgi`, `Dualcaster Mage`,
  `Heat Shimmer`, `Molten Duplication`, `Past in Flames`, `Reiterate`,
  `Twinflame`, `Storm-Kiln Artist`.
- Protection/stax: `Drannith Magistrate`, `Grand Abolisher`, `Ghostly Prison`,
  `Magus of the Moat`, `Orim's Chant`, `Ranger-Captain of Eos`, `Silence`,
  `Silent Arbiter`, `Sphere of Safety`, `Windborn Muse`.
- Tutors/card flow: `Enlightened Tutor`, `Gamble`, `Imperial Recruiter`,
  `Recruiter of the Guard`, `Wheel of Fortune`, `Wheel of Misfortune`,
  `The One Ring`.

The next candidate should not blindly merge these lists. It should start from
`deck_607`, protect the interaction density that won the gate, and only import
v7 engines that increase kill conversion without lowering survival.

## Decision

Current recommendation:

1. Promote `deck_607` to the next working reference for Lorehold strategy
   learning.
2. Keep `candidate_v7` as a high-value engine package, but mark it as
   `needs_winota_pressure_repair` before any promotion.
3. Do not treat the structural score alone as the final selector.
4. Build the next candidate from `deck_607` plus targeted v7 engine upgrades,
   then rerun the same finalist gate.

## Next Required Work

- Generate a `deck_607_bridge_v1` candidate.
- Preserve `deck_607` pressure/removal density first.
- Add only a small number of v7 engine cards at a time.
- Rerun the finalist gate with the same opponents, `opponent_seed=20260626`,
  and `simulation_seed=42`.
- If the bridge beats `deck_607` while retaining Winota performance, promote it
  as the new Lorehold working structure.
