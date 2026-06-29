# PGC068 Residual Runtime Family Plan

- Generated UTC: `2026-06-29T11:57:41Z`
- Baseline input: `39` cards from `annotation_runtime_batch_probe_20260629_pgc060`.
- After PGC068: `14` cards fully clean: `City of Brass`; `Clifftop Retreat`; `Dualcaster Mage`; `Elves of Deep Shadow`; `Erode`; `Inspiring Vantage`; `Mana Confluence`; `Reiterate`; `Return the Favor`; `Reverberate`; `Sundering Eruption // Volcanic Fissure`; `Sundown Pass`; `Tarnished Citadel`; `Untimely Malfunction`.
- Remaining residual: `25` cards still have at least one `annotation_only` field.
- Runtime executor value paths: `45` in the current snapshot.

## Completed Families

| Package | Family | Cards | Result |
| --- | --- | --- | --- |
| `PGC061` | basic-land compensation | `Erode`; `Sundering Eruption // Volcanic Fissure` | Promoted compensation status to runtime and validated no-override battle scenarios. |
| `PGC062` | conditional ETB tapped lands | `Clifftop Retreat`; `Inspiring Vantage`; `Sundown Pass` | Promoted checkland, fastland, and slowland land-play conditions to runtime. |
| `PGC063` | pain/five-color mana costs | `City of Brass`; `Elves of Deep Shadow`; `Mana Confluence`; `Tarnished Citadel` | Modeled damage/life costs through mana spend events. |
| `PGC064` | copy spell choose-new-targets | `Dualcaster Mage`; `Reverberate`; `Reiterate` | Added copied-spell target-selection executor. |
| `PGC065` | modal single-target stack target change | `Return the Favor`; `Untimely Malfunction` | Added generic modal target-change executor. |
| `PGC066` | target creature and nonfliers cannot block | `Untimely Malfunction`; `Sundering Eruption // Volcanic Fissure` | Added temporary can't-block state executor and declare-blockers validation. |
| `PGC067` | mana buyback optional additional cost | `Reiterate` | Added buyback cost choice and return-to-hand replacement. |
| `PGC068` | spree selected-mode cost and stack-object copy breadth | `Return the Favor` | Added selected-mode spree cost payment, stack-object copy target support, and activated/triggered ability copy validation. |

## Residual Cards

| Card | Remaining Annotation Fields |
| --- | --- |
| `Aetherflux Reservoir` | `activation_execution_status` |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `back_face.runtime_status`; `back_face_runtime_status`; `boast_runtime_status` |
| `Blind Obedience` | `extort_execution_status` |
| `Boros Charm` | `modes[0].mode_status` |
| `Drannith Magistrate` | `static_ability_status` |
| `Enduring Vitality` | `death_return_status` |
| `Flusterstorm` | `counter_unless_pays_status`; `soft_counter_payment_status`; `storm_copy_status` |
| `Force of Negation` | `alternate_cost_exile_blue_card_status` |
| `Formidable Speaker` | `activated_untap_another_permanent_status`; `etb_discard_creature_tutor_status` |
| `Goblin Engineer` | `activated_artifact_reanimation_status` |
| `Grand Abolisher` | `activated_ability_lock_status` |
| `Kinnan, Bonder Prodigy` | `activated_top_five_nonhuman_creature_to_battlefield_status` |
| `Knuckles the Echidna` | `upkeep_win_status` |
| `Magmakin Artillerist` | `cycle_trigger_status`; `cycling_status` |
| `Millikin` | `mana_source_mill_status` |
| `Professional Face-Breaker` | `combat_damage_treasure_trigger_status`; `treasure_impulse_draw_status` |
| `Ragavan, Nimble Pilferer` | `combat_damage_exile_top_opponent_library_status`; `combat_damage_treasure_trigger_status`; `dash_status`; `temporary_cast_permission_status` |
| `Ranger-Captain of Eos` | `library_shuffle_status`; `sacrifice_noncreature_silence_status` |
| `Rite of Flame` | `graveyard_named_copy_scaling_status` |
| `Skyclave Apparition` | `leave_battlefield_illusion_token_status` |
| `Storm-Kiln Artist` | `artifact_power_bonus_status`; `magecraft_treasure_status` |
| `Tablet of Discovery` | `conditional_instant_sorcery_mana_status`; `etb_milled_card_play_status` |
| `Touch the Spirit Realm` | `etb_until_source_leaves_status` |
| `Underworld Breach` | `end_step_sacrifice_status`; `escape_grant_status` |
| `Vandalblast` | `overload_status` |

## Next Batch Candidates

| Priority | Family | Cards | Required Work |
| ---: | --- | --- | --- |
| 1 | Static/cast-lock and opponent action locks | `Drannith Magistrate`; `Grand Abolisher`; `Blind Obedience` | Add runtime hooks for cast-source restrictions, opponent activated-ability timing restrictions, and extort optional payment. |
| 2 | Combat damage treasure, magecraft, and impulse engines | `Professional Face-Breaker`; `Ragavan, Nimble Pilferer`; `Storm-Kiln Artist` | Add combat-damage trigger hooks, treasure generation, temporary cast permissions, dash, and magecraft treasure triggers. |
| 3 | Alternative costs and spell-stack modifiers | `Force of Negation`; `Flusterstorm`; `Vandalblast`; `Underworld Breach`; `Rite of Flame` | Requires alternate cost, storm, overload, escape, named-card graveyard scaling, and soft-counter payment semantics. |
| 4 | Creature activated and zone recursion engines | `Goblin Engineer`; `Kinnan, Bonder Prodigy`; `Formidable Speaker`; `Enduring Vitality`; `Skyclave Apparition`; `Touch the Spirit Realm` | Requires activated ability targeting, zone tracking, temporary exile return, death triggers, and leave-battlefield token state validation. |
| 5 | Special win/resource engines | `Aetherflux Reservoir`; `Birgi, God of Storytelling // Harnfel, Horn of Bounty`; `Knuckles the Echidna`; `Millikin`; `Tablet of Discovery`; `Boros Charm`; `Ranger-Captain of Eos`; `Magmakin Artillerist` | Split into smaller packages by resource payment, modal mode execution, silence, cycling, and special win-condition families. |

## Guardrail

Do not mark a card clean if any other `annotation_only` field remains. Runtime promotion must prove the same rule through PostgreSQL source rows, SQLite/Hermes cache, canonical snapshot, `get_card_effect`, and battle execution without manual override.
