# PGC063 Residual Runtime Family Plan

- Generated UTC: `2026-06-29T10:11:00+00:00`
- Baseline input: `39` cards from `annotation_runtime_batch_probe_20260629_pgc060`.
- After PGC063: `8` cards fully clean: `City of Brass`; `Clifftop Retreat`; `Elves of Deep Shadow`; `Erode`; `Inspiring Vantage`; `Mana Confluence`; `Sundown Pass`; `Tarnished Citadel`.
- Remaining residual: `31` cards still have at least one `annotation_only` field.
- Runtime executor present count: `31` runtime value paths in the current snapshot, including per-mode `conditional_mana_modes` entries.

## Completed Families

| Package | Family | Cards | Result |
| --- | --- | --- | --- |
| `PGC061` | `basic_land_compensation_status` | `Erode`; `Sundering Eruption // Volcanic Fissure` | Promoted to `runtime_executor_v1`, synced PG -> SQLite/snapshot, and validated by no-override battle scenarios. `Sundering` remains open only for `cant_block_mode_status`. |
| `PGC062` | `conditional_enters_tapped_status` | `Clifftop Retreat`; `Inspiring Vantage`; `Sundown Pass` | Promoted to `runtime_executor_v1`, synced PG -> SQLite/snapshot, and validated by checkland, fastland, and slowland land-play scenarios. |
| `PGC063` | pain/five-color mana source life and damage costs | `City of Brass`; `Elves of Deep Shadow`; `Mana Confluence`; `Tarnished Citadel` | Promoted to `runtime_executor_v1`, modeled costs through `conditional_mana_modes`, synced PG -> SQLite/snapshot, and validated by spend scenarios that prove life/damage only when mana is consumed. |

## Current Clean Set

| Card | Clean Reason |
| --- | --- |
| `City of Brass` | Five-color mana mode spends now deal 1 damage through runtime cost event. |
| `Clifftop Retreat` | Conditional ETB runtime covers checkland subtype condition. |
| `Elves of Deep Shadow` | Black mana spend now deals 1 damage through runtime cost event. |
| `Erode` | Basic-land compensation runtime covers opponent basic replacement. |
| `Inspiring Vantage` | Conditional ETB runtime covers fastland three-land threshold. |
| `Mana Confluence` | Five-color mana mode spends now pay 1 life through runtime cost event. |
| `Sundown Pass` | Conditional ETB runtime covers slowland two-land threshold. |
| `Tarnished Citadel` | Colorless mode has no life loss; colored modes deal 3 damage through runtime cost event. |

## Next Batch Candidates

| Priority | Family | Cards | Required Work |
| ---: | --- | --- | --- |
| 1 | Stack copy and target rewrite | `Dualcaster Mage`; `Reverberate`; `Reiterate`; `Return the Favor` | Implement auditable copied-object identity, copied spell/ability target selection, buyback retention, and spree/copy mode separation. Do not promote if target rewrite remains only declarative. |
| 2 | Static/cast-lock and optional tax | `Drannith Magistrate`; `Grand Abolisher`; `Blind Obedience` | Add runtime hooks for cast-source restrictions, opponent activated-ability timing restrictions, and extort optional payment. Validate through cast/activation attempts, not only passive lookup. |
| 3 | Treasure/combat damage engines | `Professional Face-Breaker`; `Ragavan, Nimble Pilferer`; `Storm-Kiln Artist`; `Knuckles the Echidna` | Needs combat-damage trigger hooks, treasure generation, temporary cast permissions, magecraft triggers, and payoff validation in real turn flows. |
| 4 | Alternative costs and spell-cost modifiers | `Force of Negation`; `Flusterstorm`; `Reiterate`; `Vandalblast`; `Underworld Breach` | Requires stack cost-selection, storm, overload, buyback, escape, and counter-payment semantics. Higher blast radius; keep after smaller executor families are stable. |
| 5 | Creature activated and zone recursion engines | `Goblin Engineer`; `Kinnan, Bonder Prodigy`; `Formidable Speaker`; `Enduring Vitality`; `Skyclave Apparition`; `Touch the Spirit Realm` | Requires activated ability targeting, zone tracking, temporary exile return, death triggers, and leave-battlefield token state validation. |

## Guardrail

Do not mark a card clean if any other `annotation_only` field remains. Runtime promotion must prove the same rule through PostgreSQL source rows, SQLite/Hermes cache, canonical snapshot, `get_card_effect`, and battle execution without manual override.
