# Lorehold The One Ring Cut Decision 2026-06-30

- Status: `rejected_keep_607_baseline`
- Scope: draw/protection/value-lane tests from protected deck `607`.
- PostgreSQL writes: `false`
- Source SQLite mutation: `false`

## Why This Test Exists

The earlier 615 mana-engine candidate cut `Molecule Man` for `The One Ring`.
That comparison was invalid as final deck evidence because `Molecule Man` is a
miracle/topdeck ceiling card, while `The One Ring` is draw/protection/value.
This run retests `The One Ring` only against closer value or protection slots.

Protected cards left untouched in every `The One Ring` candidate:

- `Bender's Waterskin`
- `Victory Chimes`
- `Molecule Man`
- `The Scarlet Witch`
- `The Mind Stone`

## Candidates Generated

| Candidate | Add | Cut | Lane |
| --- | --- | --- | --- |
| `candidate_607_one_ring_creative_technique_v1` | `The One Ring` | `Creative Technique` | expensive value/free-cast |
| `candidate_607_one_ring_improvisation_capstone_v1` | `The One Ring` | `Improvisation Capstone` | exile-value/free-cast |
| `candidate_607_one_ring_redirect_lightning_v1` | `The One Ring` | `Redirect Lightning` | narrow protection/redirect |

All three candidates passed structural matrix screening at score `141.171`,
intent `100.0`, with the same high-level risks as deck `607`
(`recursion_role`, `tutor_role`).

## Smoke Gate

Gate shape:

- Real opponents: `8`
- Games per opponent: `3`
- Simulation seed: `20260630`
- Opponent seed: `20260629`
- Forced access: `none`
- Isolated deck process: `true`

| Candidate | Candidate Result | Baseline `607` Result | Decision |
| --- | ---: | ---: | --- |
| `candidate_607_one_ring_creative_technique_v1` | `10/24` | `11/24` | confirm because close |
| `candidate_607_one_ring_improvisation_capstone_v1` | `6/24` | `11/24` | reject |
| `candidate_607_one_ring_redirect_lightning_v1` | `6/24` | `11/24` | reject |

## Confirmed Gate: Creative Technique Cut

Additional seeds `123` and `999` were run only for the closest candidate,
`candidate_607_one_ring_creative_technique_v1`.

Aggregate over three seeds:

| Deck | Wins | Games | WR | Losses | Stalls |
| --- | ---: | ---: | ---: | ---: | ---: |
| `deck_607` | `30` | `72` | `41.67%` | `41` | `1` |
| `candidate_607_one_ring_creative_technique_v1` | `25` | `72` | `34.72%` | `47` | `0` |

Seed breakdown:

| Seed | `deck_607` | Candidate |
| ---: | ---: | ---: |
| `20260630` | `11/24` | `10/24` |
| `123` | `8/24` | `6/24` |
| `999` | `11/24` | `9/24` |

## Card-Use Evidence

The rejection is not caused by invisible-card sampling.

| Metric | `deck_607` | Creative-cut Candidate |
| --- | ---: | ---: |
| `The One Ring` accessed games | `0` | `24` |
| `The One Ring` drawn games | `0` | `9` |
| `The One Ring` opening-hand games | `0` | `7` |
| `The One Ring` cost paid | `0` | `42` |
| `The One Ring` spell cast | `0` | `21` |
| `The One Ring` resolved | `0` | `17` |
| `The One Ring` utility activations | `0` | `26` |
| `Creative Technique` accessed games | `19` | `0` |
| `Creative Technique` miracle casts | `4` | `0` |
| `Creative Technique` resolved events | `7` | `0` |

Strategic telemetry:

| Metric | `deck_607` | Creative-cut Candidate |
| --- | ---: | ---: |
| Miracle casts | `137` | `133` |
| Topdeck manipulation activations | `132` | `155` |
| Lorehold cost-paid events | `813` | `809` |
| Lorehold spell-cast events | `729` | `673` |
| Static cost-reduction total mana saved | `221` | `155` |

## Decision

Reject `The One Ring` for the current 607 shell.

`The One Ring` is real value in the simulator: it was cast, resolved, and
activated. The problem is fit, not access. In this Lorehold build, the original
spell/value cards and miracle/topdeck cadence still convert better than the
draw/protection artifact package.

Deck `607` remains the current best Lorehold deck and protected baseline.

## Next Deckbuilding Step

Do not retest `The One Ring` in deck `607` unless a new shell changes the role
pressure or a new source-backed candidate replaces a genuinely weaker
draw/protection slot. The next useful improvement lane is not generic value; it
is either:

- a true same-lane tutor/selection improvement that helps find topdeck/miracle
  pieces without cutting pressure cards; or
- a pressure-matchup improvement that does not reduce miracle/topdeck frequency.

Public context sources kept in the contract:

- EDHREC Lorehold commander page: `https://edhrec.com/commanders/lorehold-the-historian`
- EDHREC spellslinger Commander guide: `https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander`
- EDHREC Commander deckbuilding guide: `https://edhrec.com/articles/how-to-build-a-commander-deck`
- Archidekt Lorehold corpus: `https://archidekt.com/commanders/Lorehold%2C%20the%20Historian`
