# PGC056 Pinnacle Monk MDFC Land Face Runtime

Purpose: promote the `Mystic Peak` back face of
`Pinnacle Monk // Mystic Peak` from `annotation_only` to executable battle
metadata, so deck 607 mana testing can treat the card as a real red land option.

Evidence:

- Scryfall API artifact:
  `pgc056_pinnacle_monk_scryfall_oracle_20260629.json`
- XMage source:
  `/Users/desenvolvimentomobile/Downloads/mage-master/Mage.Sets/src/mage/cards/p/PinnacleMonk.java`

Observed rule:

- Front: `Pinnacle Monk`, `{3}{R}{R}`, prowess, ETB returns target instant or
  sorcery from graveyard to hand.
- Back: `Mystic Peak`, land, may pay 3 life as it enters; otherwise enters
  tapped; taps for `{R}`.

Files:

- `pgc056_pinnacle_monk_mdfc_land_face_precheck_20260629.sql`
- `pgc056_pinnacle_monk_mdfc_land_face_apply_20260629.sql`
- `pgc056_pinnacle_monk_mdfc_land_face_postcheck_20260629.sql`
- `pgc056_pinnacle_monk_mdfc_land_face_rollback_20260629.sql`
