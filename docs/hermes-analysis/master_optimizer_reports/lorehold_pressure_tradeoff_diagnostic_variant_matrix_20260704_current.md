# Lorehold Variant Strategy Matrix

- Generated at: `2026-07-04T22:15:31.950813+00:00`
- Strategy profile: `lorehold_strategy_profile_v3_2026_06_26`
- Scope: decks `607` plus candidate v7 when available.
- Best structural deck before equal battle gate: `candidate_607_pressure_payoff_diagnostic_tradeoff_v1`
- Commander intent: Use topdeck setup, hand filtering, and Lorehold's commander discount to cast high-impact instant/sorcery spells ahead of curve, then convert that window into a deterministic finisher while surviving fast combat pressure.

## Validation Frame

This matrix treats each Lorehold deck as a strategic hypothesis. A deck is not considered better just because it has individually strong cards; it must show a coherent plan, enough package density to execute that plan, avoid overfilled generic packages, keep enough battle-rule readiness for simulations to be meaningful, and produce a fair battle result in the next gate.

External method sources used as criteria inputs:
- [EDHREC Lorehold commander page](https://edhrec.com/commanders/lorehold-the-historian): commander-specific comparison lane for Lorehold package expectations and recurring card choices.
- [EDHREC spellslinger Commander guide](https://edhrec.com/guides/edhrec-guide-to-spellslinger-in-commander): method source for instant/sorcery-heavy shells: card flow, cheap spells, protection, recursion, and payoffs.
- [EDHREC Commander deckbuilding guide](https://edhrec.com/articles/how-to-build-a-commander-deck): baseline deck-structure guardrails for lands, ramp, draw, removal, and focused packages.
- [Archidekt Lorehold corpus](https://archidekt.com/commanders/Lorehold%2C%20the%20Historian): external corpus lane for comparing user-built Lorehold shells and recurring package choices.

## Ranked Structural Read

| Rank | Deck | Archetype | Score | Intent | Lands | Rule Ready | Objective | Main Risks |
| ---: | --- | --- | ---: | ---: | ---: | ---: | --- | --- |
| 1 | Lorehold 607 Pressure Payoff Diagnostic Tradeoff v1 (`candidate_607_pressure_payoff_diagnostic_tradeoff_v1`) | 607-pressure-payoff-diagnostic-tradeoff | 140.9 | 100.0 | 34 | 97.9% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | draw_role, recursion_role, tutor_role |
| 2 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 139.0 | 99.5 | 34 | 97.9% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | draw_role, recursion_role, tutor_role |

## 1. Lorehold 607 Pressure Payoff Diagnostic Tradeoff v1 (`candidate_607_pressure_payoff_diagnostic_tradeoff_v1`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Commander intent alignment:** score `100.0`, status `aligned`.

**Intent risks:** none

**Evidence:** spell_chain_conversion=43; topdeck_miracle_setup=11; pressure_absorber=18; wincon_roles=8; key_cards=Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet

**Strengths:**
- combat pressure absorber passes (18/4)
- spell-chain conversion passes (43/12)
- early setup/mana passes (38/18)
- topdeck and miracle setup passes (11/6)
- ramp density passes (19/14)
- protection density passes (13/10)
- anchors present: Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet, Surge to Victory

**Weaknesses / Risk:**
- recursion role shortfall (0/4)
- tutor role shortfall (1/4)
- draw role shortfall (10/12)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet, Surge to Victory, Talisman of Conviction, Arcane Signet, Fellwar Stone, Ruby Medallion, Tibalt's Trickery

## 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Commander intent alignment:** score `99.5`, status `needs_battle_proof`.

**Intent risks:** role_board_wipe_overfilled

**Evidence:** spell_chain_conversion=43; topdeck_miracle_setup=12; pressure_absorber=19; wincon_roles=9; key_cards=Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet

**Strengths:**
- combat pressure absorber passes (19/4)
- spell-chain conversion passes (43/12)
- early setup/mana passes (36/18)
- topdeck and miracle setup passes (12/6)
- ramp density passes (18/14)
- protection density passes (13/10)
- anchors present: Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet, Rise of the Eldrazi

**Weaknesses / Risk:**
- recursion role shortfall (0/4)
- tutor role shortfall (1/4)
- draw role shortfall (10/12)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet, Rise of the Eldrazi, Surge to Victory, Talisman of Conviction, Arcane Signet, Fellwar Stone, Ruby Medallion
