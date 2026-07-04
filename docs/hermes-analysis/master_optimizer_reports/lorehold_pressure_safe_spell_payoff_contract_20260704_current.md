# Lorehold Pressure-Safe Spell-Payoff Contract

- Generated at: `2026-07-04T22:00:00Z`
- PostgreSQL writes: `false`
- Source DB mutated: `false`
- Deck 607 mutated: `false`
- Diagnostic planner: `docs/hermes-analysis/master_optimizer_reports/lorehold_diagnostic_contract_planner_20260704_current.json`
- Knowledge DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Current champion: `deck_607`
- Decision status: `preflight_pass_cut_pool_required`
- Ready deck changes: `0`
- Ready for cut-pool resolver: `true`
- Legal variant generation allowed now: `false`
- Natural battle gate allowed now: `false`
- Recommended next action: `build_pressure_safe_cut_pool_resolver_before_variant_battle`

## Primary Package Preflight

| Card | Role | Oracle | Commander | Battle rules | In 607 | Status |
| --- | --- | --- | --- | ---: | --- | --- |
| Monastery Mentor | `token_pressure_spell_payoff` | `present` | `legal` | 1 | `false` | `pass` |
| Young Pyromancer | `low_curve_token_pressure_payoff` | `present` | `legal` | 1 | `false` | `pass` |
| Guttersnipe | `noncombat_spell_pressure_payoff` | `present` | `legal` | 1 | `false` | `pass` |
| Storm-Kiln Artist | `spell_payoff_mana_extension` | `present` | `legal` | 1 | `false` | `pass` |

## Cut Status

- Named cuts: `0`
- Required cuts: `4`
- Cut plan safe: `false`

## Current 607 Role Counts

`{"board_wipe": 8, "creature": 2, "draw": 9, "engine": 3, "land": 34, "protection": 12, "ramp": 15, "removal": 7, "tutor": 1, "wincon": 9}`

## Protected 607 Anchors

- Bender's Waterskin
- Victory Chimes
- Molecule Man
- The Scarlet Witch
- The Mind Stone
- Insurrection
- Storm Herd
- Creative Technique
- Sensei's Divining Top
- Scroll Rack
- Land Tax
- Approach of the Second Sun

## Cut Policy

- No protected 607 anchor can be used as a generic cut.
- Do not cut below the current 607 land floor before a full-shell matrix proves curve safety.
- Do not cut core ramp, topdeck/miracle setup, or protection to add pressure unless the cut is same-lane and trace-supported.
- The first legal variant needs exactly four named cuts for the four-card primary pressure package.
- A cut is not safe because a replacement is famous; it is safe only after role, source, and battle trace evidence align.

## Battle Gate Contract

- Create a legal decklist copy; deck 607 itself remains unchanged.
- Run structure matrix first; reject variants that regress lands, ramp, miracle/topdeck, or pressure-survival floors.
- Only after the matrix passes, run an equal opponent and seed gate against 607.
- Promotion requires tying or beating 607 overall and no Winota/fast-pressure regression.
- Card-level claims require direct draw/cast/trigger/use events for each included pressure payoff.

## Secondary Research Queue

- Goldspan Dragon: `pass`, commander `legal`, verified auto rules `1`
- Dragon's Rage Channeler: `pass`, commander `legal`, verified auto rules `1`
- Burning Prophet: `blocked`, commander `legal`, verified auto rules `0`
- Velomachus Lorehold: `pass`, commander `legal`, verified auto rules `1`

## External Pressure Sources

- `gametyrant_lorehold_deck_tech_pressure_payoffs`: https://gametyrant.com/news/how-to-build-a-lorehold-the-historian-commander-deck-deck-tech - Public Lorehold pressure advice specifically calls out token and damage spell payoffs such as Monastery Mentor, Young Pyromancer, Guttersnipe, and Storm-Kiln Artist.
- `edhrec_core_lorehold_spellslinger`: https://edhrec.com/commanders/lorehold-the-historian/core/spellslinger - The public core page frames Lorehold in Topdeck, Spellslinger, Discard, and Reanimator lanes, which matches the internal role gates.
- `coolstuffinc_lorehold_2026`: https://www.coolstuffinc.com/a/stephenjohnson-04202026-lorehold-the-historian-commander - Recent public analysis reinforces Lorehold's flying, haste, miracle, rummage, and possible token-swarm pressure identity.
- `edhrec_miracles_every_turn`: https://edhrec.com/articles/miracles-every-turn-with-lorehold-the-historian-in-commander - The commander identity remains miracle timing plus rummage; pressure cards must not dilute the topdeck/miracle floor.

## Method Notes

- This contract reads SQLite and existing reports only; it does not write PostgreSQL, SQLite, deck rows, or decklists.
- The local card preflight passing does not mean the deck should change; it only means the cut-pool resolver is the next real blocker.
- The One Ring and Mana Vault remain outside this contract because prior internal testing did not prove seed-safe cuts for the protected 607 shell.
