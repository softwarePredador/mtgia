# Lorehold Variant Strategy Matrix

- Generated at: `2026-06-26T15:05:48.511531+00:00`
- Strategy profile: `lorehold_strategy_profile_v1_2026_06_26`
- Scope: decks `6, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616` plus candidate v7 when available.
- Best structural deck before equal battle gate: `candidate_v7`

## Validation Frame

This matrix treats each Lorehold deck as a strategic hypothesis. A deck is not considered better just because it has individually strong cards; it must show a coherent plan, enough package density to execute that plan, enough battle-rule readiness for simulations to be meaningful, and a fair battle result in the next gate.

External method sources used as criteria inputs:
- [Cardsphere Commander structure guide](https://blog.cardsphere.com/building-a-commander-deck-part-two-structure/): mana base, ramp/draw/removal/package balance should be validated as a deck structure, not only as individual card quality.
- [Card Kingdom spellslinger Commander guide](https://blog.cardkingdom.com/spellslinger-commander-deck-building-guide/): instant/sorcery-heavy decks need cheap interaction, card flow, cost reduction, recursion, and payoffs.
- [EDHREC Lorehold commander page](https://edhrec.com/commanders/lorehold-the-historian): external comparison source for commonly played Lorehold cards and commander-specific package signals.
- [Archidekt Lorehold corpus](https://archidekt.com/commanders/Lorehold%2C%20the%20Historian): external corpus lane for comparing user-built Lorehold shells and recurring package choices.

## Ranked Structural Read

| Rank | Deck | Archetype | Score | Lands | Rule Ready | Objective | Main Risks |
| ---: | --- | --- | ---: | ---: | ---: | --- | --- |
| 1 | Lorehold strategy-first candidate v7 (`candidate_v7`) | strategy-first-candidate | 141.7 | 33 | 100.0% | Strategy-first miracle spellslinger control/combo shell that preserves the active core while tuning lands and package balance. | none |
| 2 | Runtime Lorehold Learned 19e93de3cca (`deck_6`) | unknown | 138.2 | 33 | 100.0% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | wincon_role |
| 3 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 137.0 | 34 | 100.0% | Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve. | removal_role, recursion_role, tutor_role |
| 4 | VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (`deck_613`) | spell-copy-control-variant | 136.7 | 32 | 100.0% | Spell-copy control shell that tries to trade resources, protect a window, then convert copied spells into a win. | land_role, removal_role, recursion_role |
| 5 | VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`) | lifegain-storm-variant | 136.0 | 33 | 100.0% | Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers. | removal_role, protection_role, recursion_role |
| 6 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 135.6 | 34 | 97.9% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | recursion_role, tutor_role |
| 7 | VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (`deck_609`) | battle-variant | 132.8 | 30 | 100.0% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | land_role, protection_role, recursion_role, low_land_count |
| 8 | VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 (`deck_606`) | submitted-variant | 125.2 | 39 | 100.0% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | deterministic_finisher, removal_role, protection_role, recursion_role, tutor_role, wincon_role, high_land_count |
| 9 | VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 (`deck_611`) | big-spells-variant | 123.4 | 34 | 100.0% | Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve. | protection_window, removal_role, protection_role, recursion_role |
| 10 | VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (`deck_616`) | burn-dragon-control-variant | 119.2 | 29 | 85.7% | Burn/dragon-control shell that tries to survive long enough for high-impact threats and damage finishers. | graveyard_recursion, land_role, ramp_role, recursion_role, tutor_role, battle_rule_readiness, low_land_count |
| 11 | VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (`deck_610`) | artifact-control-variant | 112.8 | 30 | 85.3% | Artifact-control shell that tries to slow combat, build mana/artifact advantage, then win through compact spell or artifact payoff lines. | protection_window, deterministic_finisher, land_role, draw_role, removal_role, protection_role, recursion_role, wincon_role |
| 12 | VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (`deck_612`) | spell-copy-combo-variant | 111.3 | 27 | 93.0% | Spell-copy combo shell that prioritizes copy effects and burst mana to assemble deterministic spell-chain wins. | protection_window, land_role, draw_role, removal_role, protection_role, recursion_role, tutor_role, low_land_count |
| 13 | VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (`deck_608`) | battle-variant | 106.6 | 31 | 98.5% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | protection_window, deterministic_finisher, land_role, removal_role, protection_role, recursion_role, board_wipe_role, wincon_role |

## 1. Lorehold strategy-first candidate v7 (`candidate_v7`)

**Objective:** Strategy-first miracle spellslinger control/combo shell that preserves the active core while tuning lands and package balance.

**Evidence:** spell_chain_conversion=52; topdeck_miracle_setup=10; pressure_absorber=22; wincon_roles=12; key_cards=Aetherflux Reservoir, Magus of the Moat, Sphere of Safety, Drannith Magistrate

**Strengths:**
- combat pressure absorber passes (22/4)
- spell-chain conversion passes (52/12)
- early setup/mana passes (73/18)
- hand filtering passes (28/7)
- ramp density passes (52/14)
- draw density passes (26/12)
- anchors present: Aetherflux Reservoir, Magus of the Moat, Sphere of Safety, Drannith Magistrate, Windborn Muse

**Weaknesses / Risk:**
- none captured

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Aetherflux Reservoir, Magus of the Moat, Sphere of Safety, Drannith Magistrate, Windborn Muse, Get Lost, Flawless Maneuver, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Crawlspace, Silent Arbiter

## 2. Runtime Lorehold Learned 19e93de3cca (`deck_6`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Evidence:** spell_chain_conversion=51; topdeck_miracle_setup=9; pressure_absorber=22; wincon_roles=1; key_cards=Aetherflux Reservoir, Magus of the Moat, Sphere of Safety, Drannith Magistrate

**Strengths:**
- combat pressure absorber passes (22/4)
- spell-chain conversion passes (51/12)
- early setup/mana passes (73/18)
- hand filtering passes (23/7)
- ramp density passes (51/14)
- draw density passes (20/12)
- anchors present: Aetherflux Reservoir, Magus of the Moat, Sphere of Safety, Drannith Magistrate, Windborn Muse

**Weaknesses / Risk:**
- wincon role shortfall (1/6)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Aetherflux Reservoir, Magus of the Moat, Sphere of Safety, Drannith Magistrate, Windborn Muse, Flawless Maneuver, Birgi, God of Storytelling // Harnfel, Horn of Bounty, Crawlspace, Silent Arbiter, Get Lost

## 3. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

**Objective:** Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.

**Evidence:** spell_chain_conversion=47; topdeck_miracle_setup=9; pressure_absorber=10; wincon_roles=11; key_cards=Birgi, God of Storytelling // Harnfel, Horn of Bounty, Mana Vault, Perch Protection, Rise of the Eldrazi

**Strengths:**
- spell-chain conversion passes (47/12)
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

## 4. VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (`deck_613`)

**Objective:** Spell-copy control shell that tries to trade resources, protect a window, then convert copied spells into a win.

**Evidence:** spell_chain_conversion=43; topdeck_miracle_setup=20; pressure_absorber=8; wincon_roles=8; key_cards=Ghostly Prison, Lotus Petal, Mana Vault, Perch Protection

**Strengths:**
- hand filtering passes (26/7)
- spell-chain conversion passes (43/12)
- topdeck and miracle setup passes (20/6)
- early setup/mana passes (38/18)
- draw density passes (24/12)
- ramp density passes (19/14)
- anchors present: Ghostly Prison, Lotus Petal, Mana Vault, Perch Protection, Rise of the Eldrazi

**Weaknesses / Risk:**
- recursion role shortfall (0/4)
- removal role shortfall (4/8)
- land role shortfall (32/33)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Ghostly Prison, Lotus Petal, Mana Vault, Perch Protection, Rise of the Eldrazi, Arcane Signet, Call Forth the Tempest, Soulfire Eruption, Approach of the Second Sun, Brass's Bounty

## 5. VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`)

**Objective:** Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers.

**Evidence:** spell_chain_conversion=42; topdeck_miracle_setup=14; pressure_absorber=9; wincon_roles=11; key_cards=Aetherflux Reservoir, Flawless Maneuver, Mother of Runes, Akroma's Will

**Strengths:**
- spell-chain conversion passes (42/12)
- hand filtering passes (19/7)
- topdeck and miracle setup passes (14/6)
- combat pressure absorber passes (9/4)
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

## 6. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Evidence:** spell_chain_conversion=41; topdeck_miracle_setup=11; pressure_absorber=18; wincon_roles=9; key_cards=Flawless Maneuver, Mother of Runes, Giver of Runes, Boros Signet

**Strengths:**
- combat pressure absorber passes (18/4)
- spell-chain conversion passes (41/12)
- hand filtering passes (15/7)
- early setup/mana passes (35/18)
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

## 7. VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (`deck_609`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Evidence:** spell_chain_conversion=47; topdeck_miracle_setup=14; pressure_absorber=11; wincon_roles=7; key_cards=Mother of Runes, Wheel of Misfortune, Giver of Runes, Wheel of Fortune

**Strengths:**
- spell-chain conversion passes (47/12)
- hand filtering passes (24/7)
- combat pressure absorber passes (11/4)
- graveyard recursion passes (13/5)
- draw density passes (22/12)
- ramp density passes (15/14)
- anchors present: Mother of Runes, Wheel of Misfortune, Giver of Runes, Wheel of Fortune, Boros Signet

**Weaknesses / Risk:**
- recursion role shortfall (0/4)
- land role shortfall (30/33)
- protection role shortfall (8/10)
- low land count for Commander baseline (30)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Mother of Runes, Wheel of Misfortune, Giver of Runes, Wheel of Fortune, Boros Signet, Perch Protection, Rise of the Eldrazi, Talisman of Conviction, Arcane Signet, Fellwar Stone

## 8. VARIANT Lorehold Variant 01 - Rafael Paste 2026-06-22 (`deck_606`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Evidence:** spell_chain_conversion=38; topdeck_miracle_setup=12; pressure_absorber=13; wincon_roles=5; key_cards=Flawless Maneuver, Wheel of Fortune, Mana Vault, Boros Signet

**Strengths:**
- combat pressure absorber passes (13/4)
- spell-chain conversion passes (38/12)
- hand filtering passes (17/7)
- early setup/mana passes (38/18)
- ramp density passes (19/14)
- draw density passes (16/12)
- anchors present: Flawless Maneuver, Wheel of Fortune, Mana Vault, Boros Signet, Rise of the Eldrazi

**Weaknesses / Risk:**
- deterministic finisher shortfall (5/6, gap 1)
- recursion role shortfall (0/4)
- protection role shortfall (9/10)
- removal role shortfall (7/8)
- tutor role shortfall (3/4)
- wincon role shortfall (5/6)
- high land count can crowd nonland engine slots (39)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind
- verify that win lines are deterministic enough instead of only value-positive

**Key Cards:** Flawless Maneuver, Wheel of Fortune, Mana Vault, Boros Signet, Rise of the Eldrazi, Talisman of Conviction, Arcane Signet, Soulfire Eruption, Tibalt's Trickery, Reverse the Sands

## 9. VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 (`deck_611`)

**Objective:** Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.

**Evidence:** spell_chain_conversion=42; topdeck_miracle_setup=17; pressure_absorber=7; wincon_roles=10; key_cards=Boros Signet, Perch Protection, Rise of the Eldrazi, Talisman of Conviction

**Strengths:**
- hand filtering passes (28/7)
- spell-chain conversion passes (42/12)
- topdeck and miracle setup passes (17/6)
- graveyard recursion passes (11/5)
- draw density passes (26/12)
- ramp density passes (19/14)
- anchors present: Boros Signet, Perch Protection, Rise of the Eldrazi, Talisman of Conviction, Arcane Signet

**Weaknesses / Risk:**
- protection window shortfall (5/10, gap 5)
- protection role shortfall (3/10)
- removal role shortfall (3/8)
- recursion role shortfall (0/4)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Boros Signet, Perch Protection, Rise of the Eldrazi, Talisman of Conviction, Arcane Signet, Fellwar Stone, Ruby Medallion, Call Forth the Tempest, Chaos Warp, Ashling, Flame Dancer

## 10. VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (`deck_616`)

**Objective:** Burn/dragon-control shell that tries to survive long enough for high-impact threats and damage finishers.

**Evidence:** spell_chain_conversion=35; topdeck_miracle_setup=8; pressure_absorber=17; wincon_roles=10; key_cards=Ghostly Prison, Wheel of Fortune, Rise of the Eldrazi, Worldfire

**Strengths:**
- combat pressure absorber passes (17/4)
- spell-chain conversion passes (35/12)
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
- battle-rule readiness below 90% (85.7%)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind
- close missing battle-rule/runtime gaps before trusting battle outcomes

**Key Cards:** Ghostly Prison, Wheel of Fortune, Rise of the Eldrazi, Worldfire, Arcane Signet, Chaos Warp, Soulfire Eruption, Coruscation Mage, Firesong and Sunspeaker, Guttersnipe

## 11. VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (`deck_610`)

**Objective:** Artifact-control shell that tries to slow combat, build mana/artifact advantage, then win through compact spell or artifact payoff lines.

**Evidence:** spell_chain_conversion=32; topdeck_miracle_setup=21; pressure_absorber=13; wincon_roles=5; key_cards=Crawlspace, Silent Arbiter, Perch Protection, Arcane Signet

**Strengths:**
- graveyard recursion passes (20/5)
- topdeck and miracle setup passes (21/6)
- combat pressure absorber passes (13/4)
- spell-chain conversion passes (32/12)
- ramp density passes (20/14)
- board_wipe density passes (6/2)
- anchors present: Crawlspace, Silent Arbiter, Perch Protection, Arcane Signet, Fellwar Stone

**Weaknesses / Risk:**
- protection window shortfall (7/10, gap 3)
- deterministic finisher shortfall (5/6, gap 1)
- protection role shortfall (4/10)
- removal role shortfall (3/8)
- recursion role shortfall (0/4)
- land role shortfall (30/33)
- draw role shortfall (11/12)
- wincon role shortfall (5/6)
- low land count for Commander baseline (30)
- battle-rule readiness below 90% (85.3%)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind
- verify that win lines are deterministic enough instead of only value-positive
- close missing battle-rule/runtime gaps before trusting battle outcomes

**Key Cards:** Crawlspace, Silent Arbiter, Perch Protection, Arcane Signet, Fellwar Stone, Call Forth the Tempest, Approach of the Second Sun, Beacon of Immortality, Invincible Hymn, Mizzix's Mastery

## 12. VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (`deck_612`)

**Objective:** Spell-copy combo shell that prioritizes copy effects and burst mana to assemble deterministic spell-chain wins.

**Evidence:** spell_chain_conversion=41; topdeck_miracle_setup=6; pressure_absorber=6; wincon_roles=13; key_cards=Birgi, God of Storytelling // Harnfel, Horn of Bounty, Wheel of Fortune, Mana Vault, Purphoros, God of the Forge

**Strengths:**
- spell-chain conversion passes (41/12)
- deterministic finisher passes (15/6)
- early setup/mana passes (40/18)
- graveyard recursion passes (11/5)
- ramp density passes (22/14)
- wincon density passes (13/6)
- anchors present: Birgi, God of Storytelling // Harnfel, Horn of Bounty, Wheel of Fortune, Mana Vault, Purphoros, God of the Forge, Arcane Signet

**Weaknesses / Risk:**
- protection window shortfall (8/10, gap 2)
- removal role shortfall (1/8)
- land role shortfall (27/33)
- protection role shortfall (5/10)
- draw role shortfall (8/12)
- recursion role shortfall (0/4)
- tutor role shortfall (2/4)
- low land count for Commander baseline (27)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Birgi, God of Storytelling // Harnfel, Horn of Bounty, Wheel of Fortune, Mana Vault, Purphoros, God of the Forge, Arcane Signet, Ruby Medallion, Seething Song, Call Forth the Tempest, Agate Instigator, Ancient Gold Dragon

## 13. VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (`deck_608`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Evidence:** spell_chain_conversion=25; topdeck_miracle_setup=9; pressure_absorber=5; wincon_roles=2; key_cards=Birgi, God of Storytelling // Harnfel, Horn of Bounty, Wheel of Fortune, Lotus Petal, Angel's Grace

**Strengths:**
- spell-chain conversion passes (25/12)
- hand filtering passes (14/7)
- graveyard recursion passes (9/5)
- early setup/mana passes (32/18)
- draw density passes (32/12)
- ramp density passes (20/14)
- anchors present: Birgi, God of Storytelling // Harnfel, Horn of Bounty, Wheel of Fortune, Lotus Petal, Angel's Grace, Talisman of Conviction

**Weaknesses / Risk:**
- protection window shortfall (4/10, gap 6)
- deterministic finisher shortfall (3/6, gap 3)
- protection role shortfall (4/10)
- recursion role shortfall (0/4)
- wincon role shortfall (2/6)
- removal role shortfall (5/8)
- board_wipe role shortfall (0/2)
- land role shortfall (31/33)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind
- verify that win lines are deterministic enough instead of only value-positive

**Key Cards:** Birgi, God of Storytelling // Harnfel, Horn of Bounty, Wheel of Fortune, Lotus Petal, Angel's Grace, Talisman of Conviction, Arcane Signet, Ruby Medallion, Mizzix's Mastery, Twinflame Tyrant, Cori Mountain Monastery
