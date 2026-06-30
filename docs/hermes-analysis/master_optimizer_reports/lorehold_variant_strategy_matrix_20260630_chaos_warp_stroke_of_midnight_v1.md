# Lorehold Variant Strategy Matrix

- Generated at: `2026-06-30T03:49:22.463393+00:00`
- Strategy profile: `lorehold_strategy_profile_v3_2026_06_26`
- Scope: decks `607, 614, 615, 616` plus candidate v7 when available.
- Best structural deck before equal battle gate: `candidate_607_chaos_warp_stroke_of_midnight_v1`
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
| 1 | Lorehold 607 + Chaos Warp over Stroke of Midnight v1 (`candidate_607_chaos_warp_stroke_of_midnight_v1`) | 607-chaos-warp-stroke-of-midnight | 141.1 | 100.0 | 34 | 97.9% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | recursion_role, tutor_role |
| 2 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 141.0 | 100.0 | 34 | 97.9% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | recursion_role, tutor_role |
| 3 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 134.7 | 97.2 | 34 | 96.4% | Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve. | removal_role, recursion_role, tutor_role |
| 4 | VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`) | lifegain-storm-variant | 131.5 | 95.6 | 33 | 97.8% | Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers. | removal_role, protection_role, recursion_role |
| 5 | VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (`deck_616`) | burn-dragon-control-variant | 118.1 | 87.6 | 29 | 92.9% | Burn/dragon-control shell that tries to survive long enough for high-impact threats and damage finishers. | graveyard_recursion, land_role, ramp_role, recursion_role, tutor_role, low_land_count |

## 1. Lorehold 607 + Chaos Warp over Stroke of Midnight v1 (`candidate_607_chaos_warp_stroke_of_midnight_v1`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Commander intent alignment:** score `100.0`, status `aligned`.

**Intent risks:** none

**Evidence:** spell_chain_conversion=43; topdeck_miracle_setup=13; pressure_absorber=19; wincon_roles=9; key_cards=Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet

**Strengths:**
- combat pressure absorber passes (19/4)
- spell-chain conversion passes (43/12)
- hand filtering passes (16/7)
- topdeck and miracle setup passes (13/6)
- ramp density passes (18/14)
- draw density passes (14/12)
- anchors present: Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet, Rise of the Eldrazi

**Weaknesses / Risk:**
- recursion role shortfall (0/4)
- tutor role shortfall (1/4)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet, Rise of the Eldrazi, Surge to Victory, Talisman of Conviction, Arcane Signet, Fellwar Stone, Ruby Medallion

## 2. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Commander intent alignment:** score `100.0`, status `aligned`.

**Intent risks:** none

**Evidence:** spell_chain_conversion=43; topdeck_miracle_setup=12; pressure_absorber=19; wincon_roles=9; key_cards=Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet

**Strengths:**
- combat pressure absorber passes (19/4)
- spell-chain conversion passes (43/12)
- hand filtering passes (15/7)
- early setup/mana passes (36/18)
- ramp density passes (18/14)
- draw density passes (13/12)
- anchors present: Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet, Rise of the Eldrazi

**Weaknesses / Risk:**
- recursion role shortfall (0/4)
- tutor role shortfall (1/4)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet, Rise of the Eldrazi, Surge to Victory, Talisman of Conviction, Arcane Signet, Fellwar Stone, Ruby Medallion

## 3. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

**Objective:** Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.

**Commander intent alignment:** score `97.2`, status `needs_battle_proof`.

**Intent risks:** package_spell_chain_conversion_overfilled, package_pressure_absorber_shortfall, role_removal_shortfall

**Evidence:** spell_chain_conversion=50; topdeck_miracle_setup=9; pressure_absorber=10; wincon_roles=11; key_cards=Birgi, God of Storytelling // Harnfel, Horn of Bounty, Mana Vault, Perch Protection, Rise of the Eldrazi

**Strengths:**
- spell-chain conversion passes (50/12)
- hand filtering passes (18/7)
- combat pressure absorber passes (10/4)
- deterministic finisher passes (12/6)
- draw density passes (16/12)
- ramp density passes (15/14)
- anchors present: Birgi, God of Storytelling // Harnfel, Horn of Bounty, Mana Vault, Perch Protection, Rise of the Eldrazi, Arcane Signet

**Weaknesses / Risk:**
- recursion role shortfall (0/4)
- removal role shortfall (7/8)
- tutor role shortfall (3/4)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Birgi, God of Storytelling // Harnfel, Horn of Bounty, Mana Vault, Perch Protection, Rise of the Eldrazi, Arcane Signet, Seething Song, Call Forth the Tempest, Chaos Warp, Approach of the Second Sun, Beacon of Immortality

## 4. VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`)

**Objective:** Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers.

**Commander intent alignment:** score `95.6`, status `needs_battle_proof`.

**Intent risks:** package_hand_filter_overfilled, package_pressure_absorber_shortfall, package_graveyard_recursion_overfilled, role_removal_shortfall

**Evidence:** spell_chain_conversion=43; topdeck_miracle_setup=14; pressure_absorber=10; wincon_roles=11; key_cards=Aetherflux Reservoir, Flawless Maneuver, Mother of Runes, Akroma's Will

**Strengths:**
- spell-chain conversion passes (43/12)
- hand filtering passes (19/7)
- combat pressure absorber passes (10/4)
- topdeck and miracle setup passes (14/6)
- ramp density passes (22/14)
- draw density passes (17/12)
- anchors present: Aetherflux Reservoir, Flawless Maneuver, Mother of Runes, Akroma's Will, Perch Protection

**Weaknesses / Risk:**
- recursion role shortfall (0/4)
- removal role shortfall (4/8)
- protection role shortfall (9/10)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Aetherflux Reservoir, Flawless Maneuver, Mother of Runes, Akroma's Will, Perch Protection, Rise of the Eldrazi, Arcane Signet, Ruby Medallion, Seething Song, Call Forth the Tempest

## 5. VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (`deck_616`)

**Objective:** Burn/dragon-control shell that tries to survive long enough for high-impact threats and damage finishers.

**Commander intent alignment:** score `87.6`, status `needs_battle_proof`.

**Intent risks:** package_graveyard_recursion_shortfall, role_land_shortfall, role_ramp_shortfall, off_plan_cards

**Evidence:** spell_chain_conversion=36; topdeck_miracle_setup=8; pressure_absorber=17; wincon_roles=10; key_cards=Ghostly Prison, Wheel of Fortune, Rise of the Eldrazi, Worldfire

**Strengths:**
- combat pressure absorber passes (17/4)
- spell-chain conversion passes (36/12)
- hand filtering passes (16/7)
- deterministic finisher passes (10/6)
- draw density passes (16/12)
- removal density passes (13/8)
- anchors present: Ghostly Prison, Wheel of Fortune, Rise of the Eldrazi, Worldfire, Arcane Signet

**Weaknesses / Risk:**
- graveyard recursion shortfall (3/5, gap 2)
- ramp role shortfall (9/14)
- land role shortfall (29/33)
- recursion role shortfall (0/4)
- tutor role shortfall (1/4)
- low land count for Commander baseline (29)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Ghostly Prison, Wheel of Fortune, Rise of the Eldrazi, Worldfire, Arcane Signet, Chaos Warp, Soulfire Eruption, Coruscation Mage, Firesong and Sunspeaker, Guttersnipe
