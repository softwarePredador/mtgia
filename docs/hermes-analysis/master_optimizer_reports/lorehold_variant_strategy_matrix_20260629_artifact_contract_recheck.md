# Lorehold Variant Strategy Matrix

- Generated at: `2026-06-29T19:40:40.661155+00:00`
- Strategy profile: `lorehold_strategy_profile_v3_2026_06_26`
- Scope: decks `607, 608, 609, 610, 611, 612, 613, 614, 615, 616` plus candidate v7 when available.
- Best structural deck before equal battle gate: `deck_607`
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
| 1 | VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`) | battle-variant | 141.0 | 100.0 | 34 | 97.9% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | recursion_role, tutor_role |
| 2 | VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`) | spell-copy-big-spells-variant | 134.7 | 97.2 | 34 | 96.4% | Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve. | removal_role, recursion_role, tutor_role |
| 3 | VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`) | lifegain-storm-variant | 131.5 | 95.6 | 33 | 97.8% | Lifegain/storm shell that tries to convert repeated spell casts into life-buffered combo finishers. | removal_role, protection_role, recursion_role |
| 4 | VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (`deck_613`) | spell-copy-control-variant | 121.3 | 86.1 | 32 | 97.8% | Spell-copy control shell that tries to trade resources, protect a window, then convert copied spells into a win. | land_role, removal_role, recursion_role |
| 5 | VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (`deck_609`) | battle-variant | 120.0 | 89.9 | 30 | 97.8% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | land_role, protection_role, recursion_role, low_land_count |
| 6 | VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (`deck_616`) | burn-dragon-control-variant | 118.1 | 87.6 | 29 | 92.9% | Burn/dragon-control shell that tries to survive long enough for high-impact threats and damage finishers. | graveyard_recursion, land_role, ramp_role, recursion_role, tutor_role, low_land_count |
| 7 | VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 (`deck_611`) | big-spells-variant | 107.9 | 79.5 | 34 | 97.8% | Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve. | protection_window, removal_role, protection_role, recursion_role |
| 8 | VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (`deck_610`) | artifact-control-variant | 95.0 | 72.1 | 30 | 86.3% | Artifact-control shell that tries to slow combat, build mana/artifact advantage, then win through compact spell or artifact payoff lines. | protection_window, deterministic_finisher, land_role, draw_role, removal_role, protection_role, recursion_role, wincon_role |
| 9 | VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (`deck_612`) | spell-copy-combo-variant | 92.1 | 72.2 | 27 | 97.0% | Spell-copy combo shell that prioritizes copy effects and burst mana to assemble deterministic spell-chain wins. | protection_window, land_role, draw_role, removal_role, protection_role, recursion_role, tutor_role, low_land_count |
| 10 | VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (`deck_608`) | battle-variant | 85.1 | 66.6 | 31 | 95.6% | Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains. | protection_window, deterministic_finisher, land_role, removal_role, protection_role, recursion_role, board_wipe_role, wincon_role |

## 1. VARIANT Lorehold Variant 02 - Rafael Paste 2026-06-23 (`deck_607`)

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

## 2. VARIANT Lorehold Variant 10 - Rafael Paste 2026-06-24 (`deck_615`)

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

## 3. VARIANT Lorehold Variant 09 - Rafael Paste 2026-06-24 (`deck_614`)

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

## 4. VARIANT Lorehold Variant 08 - Rafael Paste 2026-06-24 (`deck_613`)

**Objective:** Spell-copy control shell that tries to trade resources, protect a window, then convert copied spells into a win.

**Commander intent alignment:** score `86.1`, status `needs_battle_proof`.

**Intent risks:** package_topdeck_miracle_setup_overfilled, package_hand_filter_overfilled, package_pressure_absorber_shortfall, role_land_shortfall, role_draw_overfilled, role_removal_shortfall

**Evidence:** spell_chain_conversion=45; topdeck_miracle_setup=20; pressure_absorber=9; wincon_roles=8; key_cards=Ghostly Prison, Lotus Petal, Mana Vault, Perch Protection

**Strengths:**
- spell-chain conversion passes (45/12)
- hand filtering passes (26/7)
- topdeck and miracle setup passes (20/6)
- combat pressure absorber passes (9/4)
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

**Key Cards:** Ghostly Prison, Lotus Petal, Mana Vault, Perch Protection, Rise of the Eldrazi, Arcane Signet, Call Forth the Tempest, Penance, Soulfire Eruption, Approach of the Second Sun

## 5. VARIANT Lorehold Variant 04 - Rafael Paste 2026-06-24 (`deck_609`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Commander intent alignment:** score `89.9`, status `needs_battle_proof`.

**Intent risks:** package_hand_filter_overfilled, package_spell_chain_conversion_overfilled, package_graveyard_recursion_overfilled, package_deterministic_finisher_shortfall, role_land_shortfall, role_draw_overfilled, role_tutor_overfilled, off_plan_cards

**Evidence:** spell_chain_conversion=47; topdeck_miracle_setup=14; pressure_absorber=12; wincon_roles=7; key_cards=Mother of Runes, Wheel of Misfortune, Giver of Runes, Wheel of Fortune

**Strengths:**
- spell-chain conversion passes (47/12)
- hand filtering passes (24/7)
- combat pressure absorber passes (12/4)
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

## 6. VARIANT Lorehold Variant 11 - Rafael Paste 2026-06-24 (`deck_616`)

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

## 7. VARIANT Lorehold Variant 06 - Rafael Paste 2026-06-24 (`deck_611`)

**Objective:** Big-spells shell that leans on Lorehold's miracle discount to cast expensive effects ahead of curve.

**Commander intent alignment:** score `79.5`, status `needs_battle_proof`.

**Intent risks:** package_topdeck_miracle_setup_overfilled, package_hand_filter_overfilled, package_protection_window_shortfall, package_pressure_absorber_shortfall, package_graveyard_recursion_overfilled, role_draw_overfilled, role_removal_shortfall, role_protection_shortfall

**Evidence:** spell_chain_conversion=44; topdeck_miracle_setup=17; pressure_absorber=8; wincon_roles=10; key_cards=Boros Signet, Perch Protection, Rise of the Eldrazi, Talisman of Conviction

**Strengths:**
- hand filtering passes (28/7)
- spell-chain conversion passes (44/12)
- topdeck and miracle setup passes (17/6)
- graveyard recursion passes (11/5)
- draw density passes (26/12)
- ramp density passes (19/14)
- anchors present: Boros Signet, Perch Protection, Rise of the Eldrazi, Talisman of Conviction, Arcane Signet

**Weaknesses / Risk:**
- protection window shortfall (7/10, gap 3)
- protection role shortfall (3/10)
- removal role shortfall (3/8)
- recursion role shortfall (0/4)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind

**Key Cards:** Boros Signet, Perch Protection, Rise of the Eldrazi, Talisman of Conviction, Arcane Signet, Fellwar Stone, Ruby Medallion, Call Forth the Tempest, Chaos Warp, Penance

## 8. VARIANT Lorehold Variant 05 - Rafael Paste 2026-06-24 (`deck_610`)

**Objective:** Artifact-control shell that tries to slow combat, build mana/artifact advantage, then win through compact spell or artifact payoff lines.

**Commander intent alignment:** score `72.1`, status `needs_battle_proof`.

**Intent risks:** package_topdeck_miracle_setup_overfilled, package_protection_window_shortfall, package_graveyard_recursion_overfilled, package_deterministic_finisher_shortfall, role_land_shortfall, role_removal_shortfall, role_protection_shortfall, role_wincon_shortfall, off_plan_cards

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
- battle-rule readiness below 90% (86.3%)

**Next Validation:**
- run equal battle gate against the same opponent set and seed window
- inspect decision trace for whether Lorehold casts discounted miracle spells before falling behind
- verify that win lines are deterministic enough instead of only value-positive
- close missing battle-rule/runtime gaps before trusting battle outcomes

**Key Cards:** Crawlspace, Silent Arbiter, Perch Protection, Arcane Signet, Fellwar Stone, Call Forth the Tempest, Approach of the Second Sun, Beacon of Immortality, Invincible Hymn, Mizzix's Mastery

## 9. VARIANT Lorehold Variant 07 - Rafael Paste 2026-06-24 (`deck_612`)

**Objective:** Spell-copy combo shell that prioritizes copy effects and burst mana to assemble deterministic spell-chain wins.

**Commander intent alignment:** score `72.2`, status `needs_battle_proof`.

**Intent risks:** package_topdeck_miracle_setup_shortfall, package_hand_filter_shortfall, package_protection_window_shortfall, package_pressure_absorber_shortfall, package_graveyard_recursion_overfilled, package_deterministic_finisher_overfilled, role_land_shortfall, role_draw_shortfall, role_removal_shortfall, role_protection_shortfall, role_wincon_overfilled, off_plan_cards

**Evidence:** spell_chain_conversion=42; topdeck_miracle_setup=6; pressure_absorber=6; wincon_roles=13; key_cards=Birgi, God of Storytelling // Harnfel, Horn of Bounty, Wheel of Fortune, Mana Vault, Purphoros, God of the Forge

**Strengths:**
- spell-chain conversion passes (42/12)
- deterministic finisher passes (15/6)
- early setup/mana passes (41/18)
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

## 10. VARIANT Lorehold Variant 03 - Rafael Paste 2026-06-23 (`deck_608`)

**Objective:** Miracle spellslinger shell that uses topdeck setup and hand filtering to turn Lorehold's commander text into discounted spell chains.

**Commander intent alignment:** score `66.6`, status `needs_battle_proof`.

**Intent risks:** package_spell_chain_conversion_shortfall, package_protection_window_shortfall, package_pressure_absorber_shortfall, package_deterministic_finisher_shortfall, role_land_shortfall, role_draw_overfilled, role_removal_shortfall, role_board_wipe_shortfall, role_protection_shortfall, role_wincon_shortfall, off_plan_cards

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
