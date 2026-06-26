# Lorehold Candidate Hypothesis Registry 2026-06-26

- status: `active_learning_registry`
- protected_baseline: `deck_607`
- postgres_writes: `false`
- source_db_mutated: `false`

## Acceptance Rule

- candidate must tie or beat deck_607 on same real-opponent gate
- candidate must not regress the Winota matchup
- candidate must preserve or improve miracle/topdeck game frequency
- candidate must not cut pressure absorption unless replacing same function

## Tested Hypotheses

| Key | Status | Result | Learning |
| --- | --- | --- | --- |
| `candidate_v7` | `rejected` | 3W/5L/1S, WR 33.33%, Winota 0W/3L | High structural score does not beat deck_607 if the shell overfills engine/ramp and loses pressure response. |
| `candidate_607_bridge_v1` | `rejected` | 1W/8L/0S, WR 11.11%, Winota 0W/3L | Importing the v7 package as a bundle damages deck_607 execution; does not isolate Birgi. |
| `candidate_607_bridge_v2` | `rejected` | 2W/7L/0S, WR 22.22%, Winota 0W/3L | Molecule Man and The Scarlet Witch are protected plan pieces, not easy cuts. |
| `candidate_607_penance_v1` | `rejected` | 3W/6L/0S, WR 33.33%, Winota 0W/3L | Penance is coherent, but cutting pressure absorption hurt the pressure matchup. |
| `candidate_607_longshot_v1` | `rejected` | 2W/7L/0S, WR 22.22%, Winota 1W/2L | Lower-curve spell payoff did not convert better than the original high-impact finisher. |
| `candidate_607_birgi_v1` | `rejected` | 3W/6L/0S, WR 33.33%, Winota 1W/2L | Isolated Birgi sidegrade kept structural intent at 100, but reduced miracle games from 8/9 to 4/9 and topdeck games from 3/9 to 2/9 versus the same deck_607 gate. Bender's Waterskin remains protected until a same-function replacement wins. |

## Untested Queue

| Priority | Key | Proposed Swap | Why | Risk |
| --- | --- | --- | --- | --- |
| `P1` | `candidate_607_reprieve_v1` | +Reprieve; same-function protection/counter slot TBD | Cheap protection/cantrip style effect may protect conversion window without cutting pressure package. | Needs careful same-function cut; do not cut board wipe or miracle payoff. |
| `P2` | `candidate_607_galvanoth_v1` | +Galvanoth; same-function expensive topdeck/value slot TBD | Runtime has verified topdeck free-cast rule; aligns with topdeck/miracle theme. | Five-mana creature may be too slow and could reduce current pressure density. |
| `P3` | `candidate_607_ghostly_prison_v1` | +Ghostly Prison; pressure-absorber slot TBD | May improve combat pressure matchup if replacing same function only. | Can reduce spell density if cut is not same-function. |
| `P4` | `candidate_607_guttersnipe_v1` | +Guttersnipe; finisher slot TBD | Verified spell-damage payoff, but Longshot already failed a similar lane. | Likely lower priority because similar payoff lane underperformed. |

## Protected Cards

- `Molecule Man`
- `The Scarlet Witch`
- `Promise of Loyalty`
- `Tragic Arrogance`
- `Hexing Squelcher`
- `Sensei's Divining Top`
- `Scroll Rack`
- `Bender's Waterskin`
