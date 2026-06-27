# Lorehold Past in Flames vs Tragic Arrogance Decision - 2026-06-27

- package: `core_challenge_past_over_tragic`
- add: `Past in Flames`
- cut: `Tragic Arrogance`
- source_db_mutated: `false`
- postgres_writes: `false`
- decision: `promote_to_deeper_gate`

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

## Interpretation

`Past in Flames` is runtime-visible and strategically aligned: it was cast and
resolved in both gates, including a miracle cast in the larger gate. It also
improved the seed-42 Winota slice from two losses to one win and one loss.

This is not yet enough to replace `Tragic Arrogance` in the canonical best list.
The second seed confirms win-rate lift but includes one stall, does not improve
Winota, and slightly lowers topdeck-manipulation frequency. The correct handling
is deeper confirmation, not immediate promotion.

## Current Handling

- Keep `Past in Flames` as the strongest current improvement candidate.
- Do not mutate PostgreSQL or the canonical deck yet.
- Promote this exact package to a deeper multi-seed gate.
- Keep `Tragic Arrogance` as the current baseline card until the deeper gate
  proves the replacement.

## Next Action

Run `core_challenge_past_over_tragic` on a larger confirmation grid before
testing more speculative spell payoffs. A `3 x 8` seed-99 attempt was started
with stem `lorehold_past_tragic_gate_20260627_v3_seed99_games3_opp8`, but it did
not finish in the interactive time window and its partial artifacts were
removed. It is not evidence.

Recommended retry:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/lorehold_synergy_package_gate.py \
  --packages core_challenge_past_over_tragic \
  --games 3 \
  --opponent-limit 8 \
  --simulation-seed 99 \
  --opponent-seed 20260626 \
  --game-timeout-seconds 60 \
  --cut-safety-report docs/hermes-analysis/master_optimizer_reports/lorehold_strategy_learning_audit_20260627_v3.json \
  --ignore-prior-results \
  --stem lorehold_past_tragic_gate_20260627_v3_seed99_games3_opp8
```
