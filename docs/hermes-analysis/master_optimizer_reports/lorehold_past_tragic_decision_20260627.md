# Lorehold Past in Flames vs Tragic Arrogance Decision - 2026-06-27

- package: `core_challenge_past_over_tragic`
- add: `Past in Flames`
- cut: `Tragic Arrogance`
- source_db_mutated: `false`
- postgres_writes: `false`
- decision: `do_not_promote_current_swap`

## Why This Was Tested

The deck's core plan is to convert cheap miracle windows, rummage, topdeck setup,
and a graveyard full of used instants/sorceries into a decisive spell turn.
`Past in Flames` tests a direct graveyard-recast payoff against `Tragic
Arrogance`, a five-mana cleanup spell that is useful but less directly tied to
the win engine.

External references support testing this lane:

- Card Kingdom's spellslinger guide frames the archetype around instant/sorcery
  velocity, spell payoffs, and backup plans.
- EDHREC's upgraded red spellslinger page for `Chandra, Fire of Kaladesh` lists
  `Past in Flames` as a high-synergy instant/sorcery graveyard payoff.
- The Reddit EDH spellslinger discussion reinforces that spell-heavy commander
  decks often need a defined closing engine, not only generic interaction.

Sources checked:

- `https://blog.cardkingdom.com/spellslinger-commander-deck-building-guide/`
- `https://edhrec.com/commanders/chandra-fire-of-kaladesh/upgraded/spellslinger`
- `https://www.reddit.com/r/EDH/comments/1hkg4zg/how_do_spellslinger_decks_win/`

## Gate Evidence

| Gate | Seed | Games/Opp | Baseline | Candidate | Delta | Winota | Past Exposure | Decision Signal |
| --- | ---: | ---: | --- | --- | ---: | --- | --- | --- |
| `lorehold_past_tragic_gate_20260627_v1_games2_opp8_20260627_215724` | 42 | 2 x 8 | 3/13/0, 18.75%, avg win turn 18.67 | 5/11/0, 31.25%, avg win turn 16.00 | +12.50pp | baseline 0/2, candidate 1/2 | `cost_paid=3`, `spell_cast=3`, `spell_resolved=4`, `miracle_cast=1` | positive gate |
| `lorehold_past_tragic_gate_20260627_v2_seed7_smoke_opp8_20260627_215812` | 7 | 1 x 8 | 1/7/0, 12.50%, avg win turn 13.00 | 2/5/1, 25.00%, avg win turn 16.00 | +12.50pp | both 0/1 | `cost_paid=2`, `spell_cast=2`, `spell_resolved=2` | positive but with stall |
| `lorehold_past_tragic_gate_20260627_v3_seed99_smoke_opp8_20260627_220604` | 99 | 1 x 8 | 5/3/0, 62.50%, avg win turn 16.80 | 2/6/0, 25.00%, avg win turn 13.00 | -37.50pp | baseline 1/1, candidate 0/1 | `cost_paid=1`, `spell_cast=1`, `spell_resolved=2`, `miracle_cast=1` | negative confirmation |
| `lorehold_past_tragic_gate_20260627_v4_seed123_smoke_opp8_20260627_220625` | 123 | 1 x 8 | 1/7/0, 12.50%, avg win turn 16.00 | 0/8/0, 0.00%, avg win turn 0.00 | -12.50pp | both 0/1 | `cost_paid=1`, `spell_cast=1`, `spell_resolved=1` | negative confirmation |

Aggregate across the four completed gates: baseline `10/30/0`, 25.00% win
rate; candidate `9/30/1`, 22.50% win rate; aggregate delta `-2.50pp`.

## Interpretation

`Past in Flames` is runtime-visible and strategically aligned: it was cast and
resolved in both gates, including a miracle cast in the larger gate. It also
improved the seed-42 Winota slice from two losses to one win and one loss.

The additional seed-99 and seed-123 confirmations reversed the early positive
signal. `Past in Flames` remains coherent with the commander plan and is clearly
runtime-visible, but the exact swap over `Tragic Arrogance` is not better across
the current evidence. The aggregate result is negative and seed 99 specifically
regressed Winota from a baseline win to a candidate loss.

## Current Handling

- Keep `Past in Flames` as a coherent but unproven graveyard-recast candidate.
- Do not mutate PostgreSQL or the canonical deck yet.
- Do not promote this exact `Past in Flames` over `Tragic Arrogance` swap.
- Keep `Tragic Arrogance` as the current baseline card until the deeper gate
  proves a different replacement.
- Re-test `Past in Flames` only with a safer same-lane cut or as part of a
  broader spell-chain package that does not remove pressure cleanup.

## Next Action

Move to the next preflight-ready lane instead of spending more cycles on this
exact swap. The next practical candidates are the pressure-lane retest
`ghostly_prison_pressure_cut_promise` or the spell-payoff lane
`guttersnipe_spell_payoff_cut_prismari`, because both preserve the protected
`Hexing Squelcher`, `Bender's Waterskin`, and topdeck shell.
