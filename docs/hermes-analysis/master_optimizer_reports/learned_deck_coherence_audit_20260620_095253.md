# Learned Deck Coherence Audit

- Generated at: `2026-06-20T09:52:51.281581+00:00`
- Active learned decks checked: `60`
- High issues: `167`
- Medium issues: `12`

## PostgreSQL Oracle Structure

- Total cards in `card_intelligence_snapshot`: `34329`
- Oracle-structured cards: `33966`
- Oracle-structured rate: `0.9894`
- Missing `oracle_id`: `4`
- Missing `oracle_text`: `360`
- Missing `type_line`: `1`

Sample unstructured cards:
- `A-Alrund's Epiphany`: oracle_id `no`, oracle_text `yes`, type_line `yes`
- `Aegis Turtle`: oracle_id `yes`, oracle_text `no`, type_line `yes`
- `Ageless Guardian`: oracle_id `yes`, oracle_text `no`, type_line `yes`
- `Alaborn Trooper`: oracle_id `yes`, oracle_text `no`, type_line `yes`
- `Alpha Myr`: oracle_id `yes`, oracle_text `no`, type_line `yes`
- `Alpha Tyrranax`: oracle_id `yes`, oracle_text `no`, type_line `yes`
- `Alpine Grizzly`: oracle_id `yes`, oracle_text `no`, type_line `yes`
- `Amphin Cutthroat`: oracle_id `yes`, oracle_text `no`, type_line `yes`
- `Ancient Brontodon`: oracle_id `yes`, oracle_text `no`, type_line `yes`
- `Ancient Carp`: oracle_id `yes`, oracle_text `no`, type_line `yes`

## Source Summary

| Source | Active | High | Medium | Land Metadata Mismatch | Deck Qty Bad | Commander Qty Bad | Partner Gap | Off Color | Land Review | Missing Oracle Text |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| edhrec | 7 | 13 | 3 | 5 | 1 | 1 | 0 | 0 | 0 | 0 |
| hermes | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| pg_meta_decks | 52 | 154 | 9 | 52 | 0 | 0 | 0 | 0 | 8 | 0 |

## Combined Commander Identity Models

| Commander | Source | Status | Combined Identity | Components |
| --- | --- | --- | --- | --- |
| Akiri, Line-Slinger | learned_deck:112 | combined_identity_inferred | GRUW | Thrasios, Triton Hero |
| Dargo, the Shipwrecker | learned_deck:93 | combined_identity_inferred | BRW | Tymna the Weaver |
| Ishai, Ojutai Dragonspeaker | learned_deck:110 | combined_identity_inferred | RUW | Rograkh, Son of Rohgahh |
| Jeska, Thrice Reborn | learned_deck:100 | combined_identity_inferred | BRW | Tymna the Weaver |
| K-9, Mark I | learned_deck:116 | combined_identity_inferred | GRUW | The Fourteenth Doctor |
| Krark, the Thumbless | learned_deck:173 | combined_identity_inferred | RU | Sakashima of a Thousand Faces // Sakashima of a Thousand Faces |
| Kraum, Ludevic's Opus | learned_deck:89 | combined_identity_inferred | BRUW | Tymna the Weaver |
| Malcolm, Keen-Eyed Navigator | learned_deck:90 | combined_identity_inferred | BRU | Vial Smasher the Fierce, Kediss, Emberclaw Familiar |
| Rograkh, Son of Rohgahh | learned_deck:85 | combined_identity_inferred | BRU | Silas Renn, Seeker Adept |
| Thrasios, Triton Hero | learned_deck:87 | combined_identity_inferred | GUW | Yoshimaru, Ever Faithful |

## Lorehold Deck 6

- Active learned source ref: `learned_deck:82`
- Active learned row id: `f46c0421-71b4-4de3-bb79-05a916b4988b`
- SQLite deck id: `6`
- SQLite linked PG deck id: `528c877f-f829-4207-95e6-73981776c323`
- PG saved deck rows: `100`
- PG saved deck lands: `33`
- Active metadata lands: `33`
- Derived learned lands: `33`
- Active missing Commander legalities: `none`
- Active assumed Commander legalities: `Command Tower, Sol Ring`
- PG saved missing Commander legalities: `none`
- PG saved assumed Commander legalities: `Command Tower, Sol Ring`
- No-premium-Mox violations: `0`
- Strategy package pass: `yes`
- Name diff active -> SQLite: `0`
- Name diff active -> PG: `0`

## Lorehold Strategy Checks

| Package | Present | Minimum | Missing | Status |
| --- | ---: | ---: | --- | --- |
| Commander identity | 1 | 1 | - | pass |
| Copy combo core | 7 | 4 | - | pass |
| Topdeck/miracle setup | 5 | 3 | - | pass |
| Graveyard/spell value | 5 | 4 | Wheel of Misfortune | pass |
| Big spell finishers | 7 | 4 | - | pass |
| Protection/stack control | 10 | 6 | - | pass |
| Mana acceleration | 14 | 10 | - | pass |

- Forbidden Premium Mox present: `none`

## Top Issues

- `Aang, at the Crossroads` / `learned_deck:105`: high `3`, medium `1`; all_core_metadata_zero, land_count_low_review, metadata_total_lands_mismatch, metadata_zero_lands
- `Brigid, Clachan's Heart` / `learned_deck:150`: high `3`, medium `1`; all_core_metadata_zero, land_count_low_review, metadata_total_lands_mismatch, metadata_zero_lands
- `Krark, the Thumbless` / `learned_deck:173`: high `3`, medium `1`; all_core_metadata_zero, land_count_low_review, metadata_total_lands_mismatch, metadata_zero_lands
- `Lumra, Bellow of the Woods` / `learned_deck:131`: high `3`, medium `1`; all_core_metadata_zero, land_count_high_review, metadata_total_lands_mismatch, metadata_zero_lands
- `Ral, Monsoon Mage` / `learned_deck:104`: high `3`, medium `1`; all_core_metadata_zero, land_count_low_review, metadata_total_lands_mismatch, metadata_zero_lands
- `Rowan, Scion of War` / `learned_deck:114`: high `3`, medium `1`; all_core_metadata_zero, land_count_low_review, metadata_total_lands_mismatch, metadata_zero_lands
- `Selvala, Explorer Returned` / `learned_deck:137`: high `3`, medium `1`; all_core_metadata_zero, land_count_low_review, metadata_total_lands_mismatch, metadata_zero_lands
- `Akiri, Line-Slinger` / `learned_deck:112`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Arcum Dagsson` / `learned_deck:135`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Dargo, the Shipwrecker` / `learned_deck:93`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Dihada, Binder of Wills` / `learned_deck:111`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Elsha of the Infinite` / `learned_deck:178`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Etali, Primal Conqueror` / `learned_deck:149`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Falco Spara, Pactweaver` / `learned_deck:125`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Grand Arbiter Augustin IV` / `learned_deck:6`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Grist, the Hunger Tide` / `learned_deck:148`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Gwen Stacy` / `learned_deck:147`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Inalla, Archmage Ritualist` / `learned_deck:126`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Ishai, Ojutai Dragonspeaker` / `learned_deck:110`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands
- `Jeska, Thrice Reborn` / `learned_deck:100`: high `3`, medium `0`; all_core_metadata_zero, metadata_total_lands_mismatch, metadata_zero_lands

## Recommended Next Adjustments

1. Continue re-deriving and backfilling active learned-deck metadata mismatches with explicit mutation approval.
2. Keep Lorehold learned deck 82 under no-swap monitoring; current metadata and strategy package checks pass.
3. Continue broader semantic/function-tag backfill for non-Lorehold learned decks using dry-run plans first.
4. Treat missing legality rows separately from real illegality or off-color violations.
5. Persist partner/background identity for decks where inferred partner colors explain off-color candidates.
6. No current off-color cards remain after partner/deck-name inference; keep monitoring new audit artifacts.
7. Keep Lorehold no-premium-Mox policy scoped to Lorehold until a bracket/product policy exists.
