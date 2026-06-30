# Lorehold Tutor/Selection Decision 2026-06-30

- Status: `rejected_keep_607_baseline`
- Scope: true tutor/selection lane after rejecting generic ramp/value swaps.
- PostgreSQL writes: `false`
- Source SQLite mutation: `false`

## Why This Test Exists

The current deckbuilding contract says the next useful Lorehold lane is not
generic ramp or value. It is either true tutor/selection that finds the
topdeck/miracle engine, or pressure-matchup improvement that does not reduce
miracle/topdeck frequency.

This run tested tutor/selection candidates while preserving protected 607
anchors:

- `Bender's Waterskin`
- `Victory Chimes`
- `Molecule Man`
- `The Scarlet Witch`
- `The Mind Stone`
- core pressure/protection cards

## Candidates Generated

| Candidate | Add | Cut | Lane |
| --- | --- | --- | --- |
| `candidate_607_enlightened_tutor_insurrection_v1` | `Enlightened Tutor` | `Insurrection` | artifact/enchantment topdeck tutor over high-cost finisher |
| `candidate_607_enlightened_tutor_creative_technique_v1` | `Enlightened Tutor` | `Creative Technique` | artifact/enchantment topdeck tutor over expensive value/free-cast spell |
| `candidate_607_gamble_storm_herd_v1` | `Gamble` | `Storm Herd` | universal tutor with discard risk over high-cost finisher |

Local source evidence:

- `Enlightened Tutor` appears in Lorehold variants `608`, `611`, `612`, `613`,
  `614`, and `615`.
- `Gamble` appears in Lorehold variants `609`, `612`, `613`, `614`, and `615`.
- `Enlightened Tutor` has active PG063 runtime:
  `artifact_enchantment_tutor_to_library_top_v1`.
- `Gamble` has verified PG070 runtime:
  `any_card_to_hand_then_random_discard_v1`.

## Structural Matrix

All three candidates passed structural screening, but structure was not enough
to promote:

| Candidate | Structural Score | Intent | Main Risks |
| --- | ---: | ---: | --- |
| `candidate_607_enlightened_tutor_insurrection_v1` | `141.373` | `100.0` | recursion_role, tutor_role |
| `candidate_607_enlightened_tutor_creative_technique_v1` | `141.261` | `100.0` | recursion_role, tutor_role |
| `candidate_607_gamble_storm_herd_v1` | `141.373` | `100.0` | recursion_role, tutor_role |
| `deck_607` | `141.036` | `100.0` | recursion_role, tutor_role |

Interpretation: tutors improve the static profile slightly, but the promotion
contract requires equal battle proof and card-use evidence.

## Equal Battle Gates

Gate shape:

- Real opponents: `8`
- Games per opponent: `3`
- Opponent seed: `20260629`
- Forced access: `none`
- Isolated deck process: `true`
- Game timeout: `45s`

### Enlightened Tutor Over Creative Technique

Smoke seed `20260630`:

| Deck | Wins | Games | WR |
| --- | ---: | ---: | ---: |
| `deck_607` | `11` | `24` | `45.83%` |
| `candidate_607_enlightened_tutor_creative_technique_v1` | `7` | `24` | `29.17%` |

Decision: reject without confirmation. `Enlightened Tutor` was accessed in
`10/24` games and cast `4` times, so the card was exercised enough for the
smoke result to matter.

### Enlightened Tutor Over Insurrection

Confirmed over seeds `20260630`, `123`, and `999` because the smoke was close.

| Deck | Wins | Games | WR | Losses | Stalls |
| --- | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | `30` | `72` | `41.67%` | `41` | `1` |
| `candidate_607_enlightened_tutor_insurrection_v1` | `25` | `72` | `34.72%` | `47` | `0` |

Seed breakdown:

| Seed | `deck_607` | Candidate |
| ---: | ---: | ---: |
| `20260630` | `11/24` | `10/24` |
| `123` | `8/24` | `7/24` |
| `999` | `11/24` | `8/24` |

Card-use evidence:

| Metric | `deck_607` | Candidate |
| --- | ---: | ---: |
| `Enlightened Tutor` accessed games | `0` | `15` |
| `Enlightened Tutor` drawn games | `0` | `9` |
| `Enlightened Tutor` spell cast | `0` | `18` |
| `Enlightened Tutor` resolved | `0` | `19` |
| `Insurrection` accessed games | `18` | `0` |
| `Insurrection` spell cast | `7` | `0` |
| `Insurrection` resolved events | `11` | `0` |

Strategic telemetry:

| Metric | `deck_607` | Candidate |
| --- | ---: | ---: |
| Miracle casts | `137` | `127` |
| Topdeck manipulation activations | `132` | `105` |
| Lorehold spell-cast events | `729` | `621` |
| Static cost-reduction total mana saved | `221` | `156` |

Decision: reject. The tutor is real and was used, but cutting `Insurrection`
reduced conversion more than the tutor improved selection.

### Gamble Over Storm Herd

Smoke seed `20260630`:

| Deck | Wins | Games | WR |
| --- | ---: | ---: | ---: |
| `deck_607` | `11` | `24` | `45.83%` |
| `candidate_607_gamble_storm_herd_v1` | `9` | `24` | `37.50%` |

Card-use evidence:

| Metric | `deck_607` | Candidate |
| --- | ---: | ---: |
| `Gamble` accessed games | `0` | `7` |
| `Gamble` spell cast | `0` | `7` |
| `Gamble` resolved | `0` | `7` |
| `Storm Herd` accessed games | `6` | `0` |
| `Storm Herd` spell cast | `2` | `0` |
| `Storm Herd` resolved events | `3` | `0` |

Decision: reject without confirmation. `Gamble` is coherent, but the smoke
started behind and `Storm Herd` had live baseline usage.

## Final Decision For This Lane

Reject the tested tutor/selection swaps. Deck `607` remains the current best
Lorehold deck and protected baseline.

The result does not mean tutors are bad in abstract. It means the tested
one-for-one cuts do not beat the current 607 shell. The current big-spell/value
cards are part of the conversion plan, not dead weight.

## Next Deckbuilding Step

Do not keep testing tutors by cutting already-used finishers or value spells.
The next useful lane is pressure-matchup improvement that does not reduce
miracle/topdeck frequency, or a tutor/selection package that adds access while
removing a demonstrably low-use nonpressure slot.
