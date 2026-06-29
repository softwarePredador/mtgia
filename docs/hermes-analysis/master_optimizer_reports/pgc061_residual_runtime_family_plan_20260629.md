# PGC061 Residual Runtime Family Plan

- Generated UTC: `2026-06-29T09:36:20+00:00`
- Baseline input: `39` cards from `annotation_runtime_batch_probe_20260629_pgc060`.
- After PGC061: `1` card fully clean (`Erode`), `38` cards still have at least one `annotation_only` field.
- Runtime executor now present in `2` cards: `Erode`; `Sundering Eruption // Volcanic Fissure` for `basic_land_compensation_status`.

## Completed Family

| Family | Cards | Result |
| --- | --- | --- |
| `basic_land_compensation_status` | `Erode`; `Sundering Eruption // Volcanic Fissure` | Promoted to `runtime_executor_v1`, synced PG -> SQLite/snapshot, and validated by no-override battle scenarios. `Sundering` remains open only for `cant_block_mode_status`. |

## Next Batch Candidates

| Priority | Family | Cards | Required Work |
| ---: | --- | --- | --- |
| 1 | Conditional ETB lands | `Clifftop Retreat`; `Inspiring Vantage`; `Sundown Pass` | The mana/land runtime already has ETB tapped state helpers, but these cards need source-specific conditions and E2E land-play scenarios before PG promotion. |
| 2 | Pain/five-color mana sources | `City of Brass`; `Elves of Deep Shadow`; `Mana Confluence`; `Tarnished Citadel` | Existing mana-source abstraction can spend conditional/life payment, but damage/life-loss on activation is not fully event-proven for all shapes. Implement/verify activation-cost events before promotion. |
| 3 | Stack copy new-target family | `Dualcaster Mage`; `Reverberate`; `Reiterate`; `Return the Favor` | Current runtime copies stack spells, but real target reassignment is not fully modeled. Do not promote `choose_new_targets_status` until target replacement is executable and audited. |
| 4 | Static/cast-lock family | `Drannith Magistrate`; `Grand Abolisher`; `Blind Obedience` | Static restrictions and extort require phase/priority and optional payment modeling; keep separate from simple spell resolution packages. |
| 5 | Treasure/combat damage engines | `Professional Face-Breaker`; `Ragavan, Nimble Pilferer`; `Storm-Kiln Artist`; `Knuckles the Echidna` | Needs combat-damage trigger hooks, temporary-cast permission, magecraft trigger, and payoff validation in battle turns. |
| 6 | Alternative costs/cost modifiers | `Force of Negation`; `Flusterstorm`; `Reiterate`; `Vandalblast`; `Underworld Breach` | Requires stack cost-selection and copy/storm/overload/escape modeling; higher blast radius than PGC061. |

## Guardrail

Do not mark a card clean if another `annotation_only` field remains. PGC061 intentionally leaves `Sundering Eruption // Volcanic Fissure` in the residual set because `cant_block_mode_status` is still annotation-only.
