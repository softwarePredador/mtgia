# PGC066 Residual Runtime Family Plan

- Generated UTC: `2026-06-29T11:14:35Z`
- Baseline input: `39` cards from `annotation_runtime_batch_probe_20260629_pgc060`.
- After PGC066: `12` cards fully clean: `City of Brass`; `Clifftop Retreat`; `Dualcaster Mage`; `Elves of Deep Shadow`; `Erode`; `Inspiring Vantage`; `Mana Confluence`; `Reverberate`; `Sundering Eruption // Volcanic Fissure`; `Sundown Pass`; `Tarnished Citadel`; `Untimely Malfunction`.
- Remaining residual: `27` cards still have at least one `annotation_only` field.
- Runtime executor value paths: `41` in the current snapshot.

## Completed Families

| Package | Family | Cards | Result |
| --- | --- | --- | --- |
| `PGC061` | `basic_land_compensation_status` | `Erode`; `Sundering Eruption // Volcanic Fissure` | Promoted to `runtime_executor_v1`, synced PG -> SQLite/snapshot, and validated by no-override battle scenarios. |
| `PGC062` | `conditional_enters_tapped_status` | `Clifftop Retreat`; `Inspiring Vantage`; `Sundown Pass` | Promoted to `runtime_executor_v1`, synced PG -> SQLite/snapshot, and validated by checkland, fastland, and slowland land-play scenarios. |
| `PGC063` | pain/five-color mana source life and damage costs | `City of Brass`; `Elves of Deep Shadow`; `Mana Confluence`; `Tarnished Citadel` | Promoted to `runtime_executor_v1`, modeled costs through `conditional_mana_modes`, synced PG -> SQLite/snapshot, and validated by spend scenarios that prove life/damage only when mana is consumed. |
| `PGC064` | copy spell choose-new-targets runtime | `Dualcaster Mage`; `Reverberate`; `Reiterate` | Added copied-spell target-selection executor, promoted `choose_new_targets_status` to `runtime_executor_v1`, synced PG -> SQLite/snapshot, and validated response plus ETB copy scenarios. `Reiterate` remains residual only for `buyback_status`. |
| `PGC065` | modal single-target stack target change runtime | `Return the Favor`; `Untimely Malfunction` | Added generic modal target-change executor, promoted `change_target_mode_status` and `redirect_target_mode_status`, synced PG -> SQLite/snapshot, validated real response scenarios, and updated XMage mapper/classifier for future batch reuse. |
| `PGC066` | target creature and nonfliers cannot block this turn | `Untimely Malfunction`; `Sundering Eruption // Volcanic Fissure` | Added temporary can't-block state executor, promoted `cant_block_mode_status`, synced PG -> SQLite/snapshot, validated declare-blockers behavior, and removed both cards from the residual set. |

## Current Clean Set

| Card | Clean Reason |
| --- | --- |
| `City of Brass` | Five-color mana mode spends now deal 1 damage through runtime cost event. |
| `Clifftop Retreat` | Conditional ETB runtime covers checkland subtype condition. |
| `Dualcaster Mage` | ETB copy now chooses legal new targets for copied targeted spells at runtime. |
| `Elves of Deep Shadow` | Black mana spend now deals 1 damage through runtime cost event. |
| `Erode` | Basic-land compensation runtime covers opponent basic replacement. |
| `Inspiring Vantage` | Conditional ETB runtime covers fastland three-land threshold. |
| `Mana Confluence` | Five-color mana mode spends now pay 1 life through runtime cost event. |
| `Reverberate` | Stack copy now chooses legal new targets for copied targeted spells at runtime. |
| `Sundering Eruption // Volcanic Fissure` | Land removal plus target-controller basic-land compensation and nonfliers-cannot-block rider now execute in battle runtime. |
| `Sundown Pass` | Conditional ETB runtime covers slowland two-land threshold. |
| `Tarnished Citadel` | Colorless mode has no life loss; colored modes deal 3 damage through runtime cost event. |
| `Untimely Malfunction` | Artifact destruction, target-change mode, and target-creature-cannot-block mode now all have runtime coverage. |

## Residual Cards

| Card | Remaining Annotation Fields | Runtime Fields Already Present |
| --- | --- | --- |
| `Aetherflux Reservoir` | `activation_execution_status` | - |
| `Birgi, God of Storytelling // Harnfel, Horn of Bounty` | `back_face.runtime_status`; `back_face_runtime_status`; `boast_runtime_status` | - |
| `Blind Obedience` | `extort_execution_status` | - |
| `Boros Charm` | `modes[0].mode_status` | - |
| `Drannith Magistrate` | `static_ability_status` | - |
| `Enduring Vitality` | `death_return_status` | - |
| `Flusterstorm` | `counter_unless_pays_status`; `soft_counter_payment_status`; `storm_copy_status` | - |
| `Force of Negation` | `alternate_cost_exile_blue_card_status` | - |
| `Formidable Speaker` | `activated_untap_another_permanent_status`; `etb_discard_creature_tutor_status` | - |
| `Goblin Engineer` | `activated_artifact_reanimation_status` | - |
| `Grand Abolisher` | `activated_ability_lock_status` | - |
| `Kinnan, Bonder Prodigy` | `activated_top_five_nonhuman_creature_to_battlefield_status` | - |
| `Knuckles the Echidna` | `upkeep_win_status` | - |
| `Magmakin Artillerist` | `cycle_trigger_status`; `cycling_status` | - |
| `Millikin` | `mana_source_mill_status` | - |
| `Professional Face-Breaker` | `combat_damage_treasure_trigger_status`; `treasure_impulse_draw_status` | - |
| `Ragavan, Nimble Pilferer` | `combat_damage_exile_top_opponent_library_status`; `combat_damage_treasure_trigger_status`; `dash_status`; `temporary_cast_permission_status` | - |
| `Ranger-Captain of Eos` | `library_shuffle_status`; `sacrifice_noncreature_silence_status` | - |
| `Reiterate` | `buyback_status` | `choose_new_targets_status`; `copy_target_selection_status` |
| `Return the Favor` | `copy_activated_triggered_ability_status`; `spree_additional_cost_status` | `change_target_mode_status` |
| `Rite of Flame` | `graveyard_named_copy_scaling_status` | - |
| `Skyclave Apparition` | `leave_battlefield_illusion_token_status` | - |
| `Storm-Kiln Artist` | `artifact_power_bonus_status`; `magecraft_treasure_status` | - |
| `Tablet of Discovery` | `conditional_instant_sorcery_mana_status`; `etb_milled_card_play_status` | - |
| `Touch the Spirit Realm` | `etb_until_source_leaves_status` | - |
| `Underworld Breach` | `end_step_sacrifice_status`; `escape_grant_status` | - |
| `Vandalblast` | `overload_status` | - |

## Next Batch Candidates

| Priority | Family | Cards | Required Work |
| ---: | --- | --- | --- |
| 1 | Buyback and spree cost selection | `Reiterate`; `Return the Favor` | Model optional additional costs, cost payment, and post-resolution zone behavior. Validate through cast-cost lock, payment, resolution, and retained-card behavior for buyback. |
| 2 | Static/cast-lock and opponent action locks | `Drannith Magistrate`; `Grand Abolisher`; `Blind Obedience` | Add runtime hooks for cast-source restrictions, opponent activated-ability timing restrictions, and extort optional payment. Validate through attempted illegal cast/activation plus optional payment outcomes. |
| 3 | Combat damage treasure and impulse engines | `Professional Face-Breaker`; `Ragavan, Nimble Pilferer`; `Storm-Kiln Artist` | Add combat-damage trigger hooks, treasure generation, temporary cast permissions, and magecraft triggers. Validate in real combat and postcombat cast windows. |
| 4 | Alternative costs and spell-stack modifiers | `Force of Negation`; `Flusterstorm`; `Vandalblast`; `Underworld Breach`; `Rite of Flame` | Requires stack cost-selection, storm, overload, escape, named-card graveyard scaling, and counter-payment semantics. Higher blast radius; keep after smaller executor families are stable. |
| 5 | Creature activated and zone recursion engines | `Goblin Engineer`; `Kinnan, Bonder Prodigy`; `Formidable Speaker`; `Enduring Vitality`; `Skyclave Apparition`; `Touch the Spirit Realm` | Requires activated ability targeting, zone tracking, temporary exile return, death triggers, and leave-battlefield token state validation. |

## Guardrail

Do not mark a card clean if any other `annotation_only` field remains. Runtime promotion must prove the same rule through PostgreSQL source rows, SQLite/Hermes cache, canonical snapshot, `get_card_effect`, and battle execution without manual override.
