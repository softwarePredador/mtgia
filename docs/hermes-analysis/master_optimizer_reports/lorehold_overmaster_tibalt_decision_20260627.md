# Lorehold Overmaster vs Tibalt's Trickery Decision - 2026-06-27

- package: `overmaster_protect_draw_cut_tibalts_trickery`
- add: `Overmaster`
- cut: `Tibalt's Trickery`
- source_db_mutated: `false`
- postgres_writes: `false`
- decision: `do_not_promote_yet`

## Why This Was Tested

The Lorehold plan is a Boros spellslinger / miracle shell: cheap spell velocity,
topdeck setup, and a protected decisive instant or sorcery matter more than a
generic pile of reactive cards.

External deckbuilding references support the hypothesis but not automatic
promotion:

- Card Kingdom's spellslinger guide frames the archetype as gaining advantage
  from instants/sorceries, often by chaining spells into a payoff, and stresses
  choosing a coherent proactive or reactive plan.
- The same guide argues for backup payoffs and critical instant/sorcery density,
  which matches testing cheap cantrip/protection over a swingier counter slot.
- mtg.wtf / Gatherer-linked card text confirms `Overmaster` is a one-mana
  sorcery that protects the next instant or sorcery this turn and draws a card.
- EDHREC's upgraded spellslinger page for `Chandra, Fire of Kaladesh` shows
  `Past in Flames` as a high-synergy red spellslinger card, so the next lane
  should test graveyard recast separately rather than forcing it into this
  protection-slot decision.
- A Reddit EDH discussion on spellslinger wins reinforces that spell decks
  commonly close through combo/direct-damage/token bursts, matching Lorehold's
  need to protect the decisive turn instead of drifting into generic defense.

Sources checked:

- `https://blog.cardkingdom.com/spellslinger-commander-deck-building-guide/`
- `https://www.mtg.wtf/card/tor/104/Overmaster`
- `https://edhrec.com/commanders/chandra-fire-of-kaladesh/upgraded/spellslinger`
- `https://www.reddit.com/r/EDH/comments/1hkg4zg/how_do_spellslinger_decks_win/`

## Gate Evidence

| Gate | Seed | Games/Opp | Baseline | Candidate | Delta | Winota | Overmaster Exposure | Decision Signal |
| --- | ---: | ---: | --- | --- | ---: | --- | --- | --- |
| `lorehold_overmaster_tibalt_gate_20260627_v2_smoke_opp8_20260627_215233` | 42 | 1 x 8 | 2/6/0, 25.00%, avg win turn 22.50 | 4/4/0, 50.00%, avg win turn 19.50 | +25.00pp | loss turn 8 -> win turn 15 | `cost_paid=2`, `spell_cast=2`, `spell_resolved=3`, `draw_cards=3`, `miracle_cast=1` | positive smoke |
| `lorehold_overmaster_tibalt_gate_20260627_v3_seed7_smoke_opp8_20260627_215341` | 7 | 1 x 8 | 1/7/0, 12.50%, avg win turn 13.00 | 3/5/0, 37.50%, avg win turn 13.67 | +25.00pp | loss turn 6 -> win turn 12 | `cost_paid=2`, `spell_cast=2`, `spell_resolved=3`, `draw_cards=3`, `miracle_cast=1` | positive smoke |
| `lorehold_overmaster_tibalt_gate_20260627_v4_games2_opp8_20260627_215440` | 42 | 2 x 8 | 3/13/0, 18.75%, avg win turn 18.67 | 2/14/0, 12.50%, avg win turn 20.00 | -6.25pp | both lose; baseline turn 7/9, candidate turn 7/7 | `cost_paid=5`, `spell_cast=5`, `spell_resolved=5`, `draw_cards=5` | reject current swap |

## Interpretation

`Overmaster` is real in the runtime: it was cast, resolved, drew cards, and in
the smoke gates correlated with higher miracle/topdeck activity and two Winota
turnarounds.

The stronger `2 x 8` gate rejects the current exact swap. The candidate improved
miracle/topdeck rates but still lost more games and did not preserve the Winota
matchup under the larger sample. That means the card is strategically plausible,
but `Tibalt's Trickery` is not a proven safe cut.

## Current Handling

- Do not promote `Overmaster` over `Tibalt's Trickery` into the current best
  Lorehold list.
- Keep `Overmaster` as `needs_rework_same_function_cut`.
- Keep `Tibalt's Trickery` protected until a same-function replacement wins a
  larger gate.
- Use the next strategy lane for `Past in Flames` against `Tragic Arrogance`,
  because that package passes cut-safety and tests graveyard recast without
  cutting protected `Hexing Squelcher` or `Bender's Waterskin`.

## Next Action

Run `core_challenge_past_over_tragic` before revisiting Overmaster. It is the
cleaner spellslinger improvement test now because external references support
graveyard recast as a red spellslinger payoff and the local cut-safety report
does not block `Tragic Arrogance` as the comparison slot.
