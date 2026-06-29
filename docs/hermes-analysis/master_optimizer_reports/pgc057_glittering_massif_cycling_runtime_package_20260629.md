# PGC057 Glittering Massif Cycling Runtime

Purpose: promote `Glittering Massif` cycling from annotation-only metadata to a
conservative hand-activation runtime path for deck 607 battle testing.

Evidence:

- Scryfall API artifact:
  `pgc057_glittering_massif_scryfall_oracle_20260629.json`
- XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/g/GlitteringMassif.java`

Observed rule:

- Land — Mountain Plains.
- Enters tapped.
- Taps for `{R}` or `{W}`.
- Cycling `{2}`: pay `{2}`, discard this card, draw a card.

Runtime guardrail:

- Cycling is only auto-activated when the card is not needed as the current land
  drop, the player can pay `{2}`, and the library can provide the replacement
  card.

Files:

- `pgc057_glittering_massif_cycling_runtime_precheck_20260629.sql`
- `pgc057_glittering_massif_cycling_runtime_apply_20260629.sql`
- `pgc057_glittering_massif_cycling_runtime_postcheck_20260629.sql`
- `pgc057_glittering_massif_cycling_runtime_rollback_20260629.sql`
