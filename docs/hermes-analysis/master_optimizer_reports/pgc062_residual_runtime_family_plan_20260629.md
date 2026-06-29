# PGC062 Residual Runtime Family Plan

- Generated UTC: `2026-06-29T09:56:00+00:00`
- Baseline input: `39` cards from `annotation_runtime_batch_probe_20260629_pgc060`.
- After PGC062: `4` cards fully clean: `Clifftop Retreat`; `Erode`; `Inspiring Vantage`; `Sundown Pass`.
- Remaining residual: `35` cards still have at least one `annotation_only` field.
- Runtime executor present count: `5` promoted executor fields across the residual baseline.

## Completed Families

| Package | Family | Cards | Result |
| --- | --- | --- | --- |
| `PGC061` | `basic_land_compensation_status` | `Erode`; `Sundering Eruption // Volcanic Fissure` | Promoted to `runtime_executor_v1`, synced PG -> SQLite/snapshot, and validated by no-override battle scenarios. `Sundering` remains open only for `cant_block_mode_status`. |
| `PGC062` | `conditional_enters_tapped_status` | `Clifftop Retreat`; `Inspiring Vantage`; `Sundown Pass` | Promoted to `runtime_executor_v1`, synced PG -> SQLite/snapshot, and validated by checkland, fastland, and slowland land-play scenarios. |

## Current Clean Set

| Card | Clean Reason |
| --- | --- |
| `Clifftop Retreat` | Conditional ETB runtime covers checkland subtype condition. |
| `Erode` | Basic-land compensation runtime covers opponent basic replacement. |
| `Inspiring Vantage` | Conditional ETB runtime covers fastland three-land threshold. |
| `Sundown Pass` | Conditional ETB runtime covers slowland two-land threshold. |

## Next Batch Candidates

| Priority | Family | Cards | Required Work |
| ---: | --- | --- | --- |
| 1 | Pain/five-color mana source costs | `City of Brass`; `Elves of Deep Shadow`; `Mana Confluence`; `Tarnished Citadel` | Generalize mana activation costs that cause damage, life payment, or colored-mana life loss. Validate event emission, life totals, and mana pool changes through no-override activation scenarios before PG promotion. |
| 2 | Stack copy and target rewrite | `Dualcaster Mage`; `Reverberate`; `Reiterate`; `Return the Favor` | Current copy handling is not enough for safe promotion when target reassignment, buyback, copied activated/triggered abilities, or spree costs are involved. Implement auditable target selection and copied-object identity first. |
| 3 | Static/cast-lock and optional tax | `Drannith Magistrate`; `Grand Abolisher`; `Blind Obedience` | Requires runtime hooks for cast-source restrictions, opponent activated-ability timing restrictions, and extort optional payments. Keep separated from normal spell-resolution packages. |
| 4 | Treasure/combat damage engines | `Professional Face-Breaker`; `Ragavan, Nimble Pilferer`; `Storm-Kiln Artist`; `Knuckles the Echidna` | Needs combat-damage trigger hooks, treasure generation, temporary cast permissions, magecraft triggers, and payoff validation in real turn flows. |
| 5 | Alternative costs and spell-cost modifiers | `Force of Negation`; `Flusterstorm`; `Reiterate`; `Vandalblast`; `Underworld Breach` | Requires stack cost-selection, storm, overload, buyback, escape, and counter-payment semantics. Higher blast radius; should come after smaller executor families are stable. |
| 6 | Creature activated and zone recursion engines | `Goblin Engineer`; `Kinnan, Bonder Prodigy`; `Formidable Speaker`; `Enduring Vitality`; `Skyclave Apparition`; `Touch the Spirit Realm` | Requires activated ability targeting, zone tracking, temporary exile return, death triggers, and leave-battlefield token state validation. |

## Guardrail

Do not mark a card clean if any other `annotation_only` field remains. Runtime promotion must prove the same rule through PostgreSQL source rows, SQLite/Hermes cache, canonical snapshot, `get_card_effect`, and battle execution without manual override.
