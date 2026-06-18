# Lorehold Battle Model Coverage Matrix - 2026-06-16

## Summary

This matrix checks the 100-card Lorehold canonical snapshot against the current
Hermes `battle_analyst_v9.py` model. It answers a different question from deck
composition: not "is the card in the recommended deck?", but "how trustworthy is
the battle behavior currently used for this card?".

Source deck:

- `docs/hermes-analysis/master_optimizer_reports/lorehold_canonical_snapshot_20260614.json`
- `docs/hermes-analysis/LOREHOLD_RECOMMENDED_DECK_RATIONALE_2026-06-16.md`

Coverage result:

- `hard_modelled`: 67 cards
- `manual_land_baseline`: 3 cards
- `hybrid_land_modelled`: 6 cards
- `fact_modelled_land`: 3 cards
- `needs_review_land_basicish`: 21 cards
- `unmodelled`: 0 cards

Risk result:

- `low`: 91 cards
- `medium`: 9 cards
- `high`: 0 cards

Interpretation:

- The whole deck was classified, not only sorceries.
- 67 cards are manually verified in the battle engine with direct effect logic.
- 3 special lands still sit at manual baseline only for trusted mana/static
  metadata.
- 6 special lands now sit one step above pure baseline: they keep trusted land
  metadata but also have a narrow executable utility line with guardrails.
- 21 remaining lands are still sourced from generated metadata. They are
  acceptable for coarse mana/deck simulation, but should not drive strong
  learning on utility-land sequencing.
- There are no Lorehold nonland cards left in `needs_review_card_rule` after
  the current promotion wave.

## Classification

- `hard_modelled`: manual rule in `known_cards_manual`, review status
  `verified`.
- `manual_land_baseline`: manual land rule with trusted mana/static metadata,
  but without full hard-modeled utility activation/trigger execution.
- `hybrid_land_modelled`: trusted land metadata plus a narrow executable
  utility line with explicit guardrails; not fully general, but no longer
  metadata-only.
- `fact_modelled_land`: land recognized from `type_line`; simple land behavior
  only.
- `needs_review_land_basicish`: land recognized, but generated metadata should
  be reviewed before strong learning.
- `unmodelled`: no usable battle effect.

## Priority Corrections

### P1 - utility land hard behavior

These lands no longer depend on generated heuristics, but some of their
strategic utility is still metadata-only rather than fully executable behavior:

- `Urza's Saga`

Action: `Urza's Saga` no longer lacks chapter behavior entirely, but it still
needs refinement before becoming a strong learning input:

- dynamic Construct sizing if artifact count changes later;
- broader Saga/generic chapter support if more Sagas start mattering;
- rerun the Lorehold audit to verify medium-risk ambiguity actually fell.

### P2 - generated baseline lands

These lands are still low-risk for mana identity, but remain generated rather
than manually verified:

- fetchlands and generic dual/fixing lands (`Arid Mesa`, `Flooded Strand`,
  `Marsh Flats`, `Prismatic Vista`, `Scalding Tarn`, `Windswept Heath`,
  `Wooded Foothills`, etc.)
- generic untapped/tapped fixing lands (`Battlefield Forge`,
  `Clifftop Retreat`, `Command Tower`, `Mana Confluence`, `Plateau`,
  `Sacred Foundry`, `Spectator Seating`, `Sundown Pass`, etc.)

## Full Matrix

| # | Card | Type | Role | Battle effect | Source | Review | Status | Risk |
| ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Lorehold, the Historian | Legendary Creature - Elder Dragon | commander | commander | known_cards_manual | verified | hard_modelled | low |
| 2 | Ancient Den | Artifact Land | land | land | known_cards_manual | verified | manual_land_baseline | low |
| 3 | Ancient Tomb | Land | land | land | known_cards_manual | verified | hybrid_land_modelled | medium |
| 4 | Arid Mesa | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 5 | Battlefield Forge | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 6 | Bloodstained Mire | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 7 | City of Brass | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 8 | Clifftop Retreat | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 9 | Command Tower | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 10 | Elegant Parlor | Land - Mountain Plains | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 11 | Flooded Strand | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 12 | Gemstone Caverns | Legendary Land | land | land | known_cards_manual | verified | manual_land_baseline | medium |
| 13 | Great Furnace | Artifact Land | land | land | known_cards_manual | verified | manual_land_baseline | low |
| 14 | Hall of Heliod's Generosity | Legendary Land | land | land | known_cards_manual | verified | hybrid_land_modelled | medium |
| 15 | Inspiring Vantage | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 16 | Inventors' Fair | Legendary Land | land | land | known_cards_manual | verified | hybrid_land_modelled | medium |
| 17 | Mana Confluence | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 18 | Marsh Flats | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 19 | Mountain // Mountain | Basic Land - Mountain | land | land | type_line_land | fact | fact_modelled_land | low |
| 20 | Needleverge Pathway // Pillarverge Pathway | Land | land | land | type_line_land | fact | fact_modelled_land | low |
| 21 | Plains // Plains | Basic Land - Plains | land | land | type_line_land | fact | fact_modelled_land | low |
| 22 | Plateau | Land - Mountain Plains | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 23 | Prismatic Vista | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 24 | Rugged Prairie | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 25 | Sacred Foundry | Land - Mountain Plains | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 26 | Scalding Tarn | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 27 | Spectator Seating | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 28 | Sunbaked Canyon | Land | land | land | known_cards_manual | verified | hybrid_land_modelled | medium |
| 29 | Sunbillow Verge | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 30 | Sundown Pass | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 31 | Urza's Saga | Enchantment Land - Urza's Saga | land | land | known_cards_manual | verified | hybrid_land_modelled | medium |
| 32 | War Room | Land | land | land | known_cards_manual | verified | hybrid_land_modelled | medium |
| 33 | Windswept Heath | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 34 | Wooded Foothills | Land | land | land | known_cards_generated | needs_review | needs_review_land_basicish | low |
| 35 | Lotus Petal | Artifact | ramp | ramp_ritual | known_cards_manual | verified | hard_modelled | low |
| 36 | Mox Amber | Legendary Artifact | ramp | ramp_permanent | known_cards_manual | verified | hard_modelled | low |
| 37 | Enlightened Tutor | Instant | tutor | tutor | known_cards_manual | verified | hard_modelled | low |
| 38 | Esper Sentinel | Artifact Creature - Human Soldier | draw | draw_engine | known_cards_manual | verified | hard_modelled | low |
| 39 | Faithless Looting | Sorcery | draw | draw_cards | known_cards_manual | verified | hard_modelled | low |
| 40 | Gamble | Sorcery | tutor | tutor | known_cards_manual | verified | hard_modelled | low |
| 41 | Giver of Runes | Creature - Kor Cleric | protection | creature | known_cards_manual | verified | hard_modelled | low |
| 42 | Land Tax | Enchantment | tutor | passive | known_cards_manual | verified | hard_modelled | low |
| 43 | Mana Vault | Artifact | ramp | ramp_permanent | known_cards_manual | verified | hard_modelled | low |
| 44 | Mother of Runes | Creature - Human Cleric | protection | creature | known_cards_manual | verified | hard_modelled | low |
| 45 | Orim's Chant | Instant | protection | silence_spell | known_cards_manual | verified | hard_modelled | low |
| 46 | Path to Exile | Instant | removal | remove_creature | known_cards_manual | verified | hard_modelled | low |
| 47 | Pyroblast | Instant | protection | counter | known_cards_manual | verified | hard_modelled | low |
| 48 | Rite of Flame | Sorcery | ramp | ramp_ritual | known_cards_manual | verified | hard_modelled | low |
| 49 | Sensei's Divining Top | Artifact | draw | topdeck_manipulation | known_cards_manual | verified | hard_modelled | low |
| 50 | Silence | Instant | protection | silence_spell | known_cards_manual | verified | hard_modelled | low |
| 51 | Sol Ring | Artifact | unknown | ramp_permanent | known_cards_manual | verified | hard_modelled | low |
| 52 | Swords to Plowshares | Instant | removal | remove_creature | known_cards_manual | verified | hard_modelled | low |
| 53 | Arcane Signet | Artifact | ramp | ramp_permanent | known_cards_manual | verified | hard_modelled | low |
| 54 | Boros Charm | Instant | protection | modal_boros_charm | known_cards_manual | verified | hard_modelled | low |
| 55 | Boros Signet | Artifact | ramp | ramp_permanent | known_cards_manual | verified | hard_modelled | low |
| 56 | Drannith Magistrate | Creature - Human Wizard | protection | passive | known_cards_manual | verified | hard_modelled | low |
| 57 | Fellwar Stone | Artifact | ramp | ramp_permanent | known_cards_manual | verified | hard_modelled | low |
| 58 | Grand Abolisher | Creature - Human Cleric | protection | silence_opponents | known_cards_manual | verified | hard_modelled | low |
| 59 | Lightning Greaves | Artifact - Equipment | protection | equipment_haste_shroud | known_cards_manual | verified | hard_modelled | low |
| 60 | Molten Duplication | Sorcery | wincon | token_maker | known_cards_manual | verified | hard_modelled | low |
| 61 | Reverberate | Instant | engine | copy_spell | known_cards_manual | verified | hard_modelled | low |
| 62 | Ruby Medallion | Artifact | ramp | ramp_engine | known_cards_manual | verified | hard_modelled | low |
| 63 | Scroll Rack | Artifact | draw | topdeck_manipulation | known_cards_manual | verified | hard_modelled | low |
| 64 | Talisman of Conviction | Artifact | ramp | ramp_permanent | known_cards_manual | verified | hard_modelled | low |
| 65 | Twinflame | Sorcery | wincon | token_maker | known_cards_manual | verified | hard_modelled | low |
| 66 | Birgi, God of Storytelling // Harnfel, Horn of Bounty | Legendary Creature - God | ramp | ramp_engine | known_cards_manual | verified | hard_modelled | low |
| 67 | Deflecting Swat | Instant | protection | redirect_removal | known_cards_manual | verified | hard_modelled | low |
| 68 | Dualcaster Mage | Creature - Human Wizard | engine | copy_spell | known_cards_manual | verified | hard_modelled | low |
| 69 | Electroduplicate | Sorcery | wincon | copy_creature_token | known_cards_manual | verified | hard_modelled | low |
| 70 | Flawless Maneuver | Instant | protection | indestructible | known_cards_manual | verified | hard_modelled | low |
| 71 | Generous Gift | Instant | removal | remove_permanent | known_cards_manual | verified | hard_modelled | low |
| 72 | Guttersnipe | Creature - Goblin Shaman | wincon | creature | known_cards_manual | verified | hard_modelled | low |
| 73 | Heat Shimmer | Sorcery | wincon | token_maker | known_cards_manual | verified | hard_modelled | low |
| 74 | Imperial Recruiter | Creature - Human Advisor | tutor | creature | known_cards_manual | verified | hard_modelled | low |
| 75 | Jeska's Will | Sorcery | ramp | ramp_ritual | known_cards_manual | verified | hard_modelled | low |
| 76 | Monument to Endurance | Artifact | ramp | passive | known_cards_manual | verified | hard_modelled | low |
| 77 | Ranger-Captain of Eos | Creature - Human Soldier Ranger | protection | creature | known_cards_manual | verified | hard_modelled | low |
| 78 | Recruiter of the Guard | Creature - Human Soldier | tutor | creature | known_cards_manual | verified | hard_modelled | low |
| 79 | Reiterate | Instant | engine | copy_spell | known_cards_manual | verified | hard_modelled | low |
| 80 | Seething Song | Instant | ramp | ramp_ritual | known_cards_manual | verified | hard_modelled | low |
| 81 | Teferi's Protection | Instant | protection | phase_out | known_cards_manual | verified | hard_modelled | low |
| 82 | Valakut Awakening // Valakut Stoneforge | Instant | draw | hand_filter | known_cards_manual | verified | hard_modelled | low |
| 83 | Victory Chimes | Artifact | draw | draw_engine | known_cards_manual | verified | hard_modelled | low |
| 84 | Wheel of Fortune | Sorcery | draw | draw_cards | known_cards_manual | verified | hard_modelled | low |
| 85 | Wheel of Misfortune | Sorcery | draw | draw_cards | known_cards_manual | verified | hard_modelled | low |
| 86 | Aetherflux Reservoir | Artifact | wincon | finisher | known_cards_manual | verified | hard_modelled | low |
| 87 | Mizzix's Mastery | Sorcery | wincon | overload_recursion | known_cards_manual | verified | hard_modelled | low |
| 88 | Past in Flames | Sorcery | engine | recursion | known_cards_manual | verified | hard_modelled | low |
| 89 | Smothering Tithe | Enchantment | ramp | ramp_engine | known_cards_manual | verified | hard_modelled | low |
| 90 | Storm-Kiln Artist | Creature - Dwarf Shaman | ramp | creature | known_cards_manual | verified | hard_modelled | low |
| 91 | The One Ring | Legendary Artifact | draw | draw_engine | known_cards_manual | verified | hard_modelled | low |
| 92 | Unexpected Windfall | Instant | ramp | treasure_maker | known_cards_manual | verified | hard_modelled | low |
| 93 | Mana Geyser | Sorcery | ramp | ramp_ritual | known_cards_manual | verified | hard_modelled | low |
| 94 | Fiery Emancipation | Enchantment | wincon | passive | known_cards_manual | verified | hard_modelled | low |
| 95 | Rite of the Dragoncaller | Enchantment | wincon | token_maker | known_cards_manual | verified | hard_modelled | low |
| 96 | Approach of the Second Sun | Sorcery | wincon | approach | known_cards_manual | verified | hard_modelled | low |
| 97 | Blasphemous Act | Sorcery | board_wipe | board_wipe | known_cards_manual | verified | hard_modelled | low |
| 98 | Worldfire | Sorcery | wincon | worldfire_reset | curated | verified | hard_modelled | medium |
| 99 | Storm Herd | Sorcery | wincon | token_maker | known_cards_manual | verified | hard_modelled | low |
| 100 | Rise of the Eldrazi | Sorcery | protection | extra_turn | known_cards_manual | verified | hard_modelled | low |

## Required Next Slice

Update 2026-06-16:

- `Ancient Tomb` now has executable precombat contextual fast-mana activation:
  baseline colorless mana stays trusted, and the second colorless is granted
  only when paying 2 life unlocks a commander/spell materially.
- `War Room` now has executable postcombat card-draw activation with
  life-safety guardrails.
- `Sunbaked Canyon` now has executable sacrifice-to-draw activation with
  minimum-land guardrails.
- `Inventors' Fair` now has executable upkeep life-gain and artifact-tutor
  activation with artifact-threshold and mana guardrails.
- `Hall of Heliod's Generosity` now has executable graveyard-to-top enchantment
  recursion with color/cost guardrails.
- `Urza's Saga` now enters with chapter state, advances chapters on upkeep,
  creates a guarded Construct on chapter II, and resolves a safe cmc<=1
  artifact tutor line on chapter III before SBA sacrifice.

1. Refine the remaining `Urza's Saga` gap:
   - dynamic Construct scaling after later artifact-count changes;
   - broader Saga/chapter generalization only if other Sagas start affecting
     learning materially.
2. Review remaining generated fixing/fetch lands only if they start affecting
   a learner or replay critic materially.
3. Rerun the Lorehold battle audit and compare the matrix. Target: keep
   `needs_review_card_rule` at `0` and reduce medium-risk utility-land
   ambiguity before using the deck for stronger learning loops.
