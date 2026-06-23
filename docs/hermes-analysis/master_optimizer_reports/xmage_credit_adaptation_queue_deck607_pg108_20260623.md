# XMage Credit Adaptation Queue - Deck 607 PG108

Generated at: `2026-06-23T17:18:00+00:00`

Read-only artifact. `mutations_performed=[]`.

Summary: `{"exact_xmage_found": 11, "metadata_likely": 3, "new_or_extended_runtime": 9, "oracle_only_no_exact_xmage": 2, "runtime_done_pg_pending": 1, "strong_xmage_reference": 8, "total": 13}`

Policy: exact XMage class + Oracle-aligned candidate is now treated as a strong adaptation reference, not as automatic truth or PG approval.

| Rank | Card | Sev | XMage credit | Candidate | Adaptation status | Note |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | `Pearl Medallion` | `high` | `exact_xmage_strong_reference` | `static_cost_reduction` / `static_cost_reduction_for_matching_spells_v1` | `runtime_done_pg_pending` | PG108 apply/sync/re-audit remains. |
| 2 | `Bender's Waterskin` | `medium` | `exact_xmage_partial_generic` | `ramp_permanent` / `external_reference_required_ramp_permanent_variant_v1` | `metadata_scope_hash_likely` | Trusted broad ramp exists; add Oracle hash/scope if runtime covers any-color rock/untap cadence sufficiently. |
| 3 | `Victory Chimes` | `medium` | `exact_xmage_partial_generic` | `ramp_permanent` / `external_reference_required_ramp_permanent_variant_v1` | `metadata_hash_plus_scope_review` | Trusted broad ramp exists but gives chosen player colorless; verify self-use model before hash-only. |
| 4 | `Emeria's Call // Emeria, Shattered Skyclave` | `high` | `exact_xmage_strong_reference` | `token_maker` / `xmage_create_token_variant_emeriascall_v1` | `runtime_new_executor` | MDFC sorcery/land, two flying Angel Warrior tokens, non-Angel indestructible duration. |
| 5 | `Promise of Loyalty` | `high` | `exact_xmage_strong_reference` | `vow_counter_each_player_sacrifice_rest` / `each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1` | `runtime_new_executor` | Vow counter + each-player sacrifice-rest + attack restriction. |
| 6 | `Starfall Invocation` | `high` | `exact_xmage_strong_reference` | `gift_destroy_all_creatures_return_own_destroyed_creature` / `gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1` | `runtime_new_executor` | Gift branch + destroy all creatures + return own destroyed creature. |
| 7 | `The Mind Stone` | `high` | `exact_xmage_strong_reference` | `mana_rock_with_harnessed_blink` / `legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1` | `runtime_new_executor` | Mana rock plus harnessed blink end-step loop; XMage exact but not generic Mind Stone. |
| 8 | `The Scarlet Witch` | `high` | `exact_xmage_strong_reference` | `static_cost_reduction` / `static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1` | `runtime_extension_needed` | Power-based static cost reduction for instant/sorcery MV>=4. |
| 9 | `Tragic Arrogance` | `high` | `exact_xmage_strong_reference` | `selective_nonland_sacrifice` / `controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1` | `runtime_new_executor` | Per-player/type controller choice then sacrifice all other nonland permanents. |
| 10 | `Monument to Endurance` | `medium` | `exact_xmage_strong_reference` | `token_maker` / `xmage_create_token_variant_monumenttoendurance_v1` | `rule_model_conflict_review` | Current passive trusted row misses discard-trigger modal draw/treasure/life-loss behavior. |
| 11 | `Surge to Victory` | `medium` | `exact_xmage_partial_generic` | `pump_all` / `external_reference_required_pump_all_variant_v1` | `metadata_hash_plus_runtime_review` | Current pump_all trusted row misses combat-damage copy/cast branch; likely more than hash-only. |
| 12 | `Molecule Man` | `high` | `oracle_only_no_exact_xmage` | `passive` / `external_reference_required_manual_model_v1` | `oracle_only_runtime_new_executor` | No exact local XMage class; miracle grant for nonland hand cards. |
| 13 | `Thor, God of Thunder` | `high` | `oracle_only_no_exact_xmage` | `passive` / `external_reference_required_manual_model_v1` | `oracle_only_runtime_new_executor` | No exact local XMage class; ETB graveyard play permission plus noncreature spell damage trigger. |

## Details

### Pearl Medallion

- Current effects: `["ramp_permanent"]`
- Findings: `["no_trusted_executable_rule", "review_only_or_needs_review_rule"]`
- Oracle: White spells you cast cost {1} less to cast.
- XMage: status `found`, class `PearlMedallion`, signals `["cost_reduction", "static_ability"]`
- Candidate: `static_cost_reduction` / `static_cost_reduction_for_matching_spells_v1`
- Credit: `exact_xmage_strong_reference`
- Adaptation: `runtime_done_pg_pending` - PG108 apply/sync/re-audit remains.

### Bender's Waterskin

- Current effects: `["ramp_permanent"]`
- Findings: `["generic_effect_without_model_scope", "trusted_rule_without_oracle_hash"]`
- Oracle: Untap this artifact during each other player's untap step. // {T}: Add one mana of any color.
- XMage: status `found`, class `BendersWaterskin`, signals `["mana", "static_ability"]`
- Candidate: `ramp_permanent` / `external_reference_required_ramp_permanent_variant_v1`
- Credit: `exact_xmage_partial_generic`
- Adaptation: `metadata_scope_hash_likely` - Trusted broad ramp exists; add Oracle hash/scope if runtime covers any-color rock/untap cadence sufficiently.

### Victory Chimes

- Current effects: `["ramp_permanent"]`
- Findings: `["trusted_rule_without_oracle_hash"]`
- Oracle: Untap this artifact during each other player's untap step. // {T}: A player of your choice adds {C}.
- XMage: status `found`, class `VictoryChimes`, signals `["targeting", "mana", "static_ability"]`
- Candidate: `ramp_permanent` / `external_reference_required_ramp_permanent_variant_v1`
- Credit: `exact_xmage_partial_generic`
- Adaptation: `metadata_hash_plus_scope_review` - Trusted broad ramp exists but gives chosen player colorless; verify self-use model before hash-only.

### Emeria's Call // Emeria, Shattered Skyclave

- Current effects: `[]`
- Findings: `["no_active_battle_rule"]`
- Oracle: Create two 4/4 white Angel Warrior creature tokens with flying. Non-Angel creatures you control gain indestructible until your next turn. // // // As this land enters, you may pay 3 life. If you don't, it enters tapped. // {T}: Add {W}.
- XMage: status `found`, class `EmeriasCall`, signals `["token", "mana"]`
- Candidate: `token_maker` / `xmage_create_token_variant_emeriascall_v1`
- Credit: `exact_xmage_strong_reference`
- Adaptation: `runtime_new_executor` - MDFC sorcery/land, two flying Angel Warrior tokens, non-Angel indestructible duration.

### Promise of Loyalty

- Current effects: `["draw_cards"]`
- Findings: `["no_trusted_executable_rule", "review_only_or_needs_review_rule"]`
- Oracle: Each player puts a vow counter on a creature they control and sacrifices the rest. Each of those creatures can't attack you or planeswalkers you control for as long as it has a vow counter on it.
- XMage: status `found`, class `PromiseOfLoyalty`, signals `["targeting", "counter"]`
- Candidate: `vow_counter_each_player_sacrifice_rest` / `each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1`
- Credit: `exact_xmage_strong_reference`
- Adaptation: `runtime_new_executor` - Vow counter + each-player sacrifice-rest + attack restriction.

### Starfall Invocation

- Current effects: `["board_wipe"]`
- Findings: `["no_trusted_executable_rule", "review_only_or_needs_review_rule"]`
- Oracle: Gift a card (You may promise an opponent a gift as you cast this spell. If you do, they draw a card before its other effects.) // Destroy all creatures. If the gift was promised, return a creature card put into your graveyard this way to the battlefield under 
- XMage: status `found`, class `StarfallInvocation`, signals `["targeting", "condition", "gift"]`
- Candidate: `gift_destroy_all_creatures_return_own_destroyed_creature` / `gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1`
- Credit: `exact_xmage_strong_reference`
- Adaptation: `runtime_new_executor` - Gift branch + destroy all creatures + return own destroyed creature.

### The Mind Stone

- Current effects: `[]`
- Findings: `["no_active_battle_rule"]`
- Oracle: Indestructible // {T}: Add {W}. // {5}{W}, {T}: Harness The Mind Stone. (Once harnessed, its ∞ ability is active.) // ∞ — At the beginning of your end step, exile up to one other target nonland permanent you control, then return that card to the battlefield un
- XMage: status `found`, class `TheMindStone`, signals `["targeting", "mana", "static_ability", "triggered_ability", "activated_ability"]`
- Candidate: `mana_rock_with_harnessed_blink` / `legendary_artifact_mana_harness_and_end_step_blink_other_nonland_permanent_v1`
- Credit: `exact_xmage_strong_reference`
- Adaptation: `runtime_new_executor` - Mana rock plus harnessed blink end-step loop; XMage exact but not generic Mind Stone.

### The Scarlet Witch

- Current effects: `[]`
- Findings: `["no_active_battle_rule"]`
- Oracle: Instant and sorcery spells you cast with mana value 4 or greater cost {X} less to cast, where X is The Scarlet Witch's power.
- XMage: status `found`, class `TheScarletWitch`, signals `["static_ability"]`
- Candidate: `static_cost_reduction` / `static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1`
- Credit: `exact_xmage_strong_reference`
- Adaptation: `runtime_extension_needed` - Power-based static cost reduction for instant/sorcery MV>=4.

### Tragic Arrogance

- Current effects: `[]`
- Findings: `["no_active_battle_rule"]`
- Oracle: For each player, you choose from among the permanents that player controls an artifact, a creature, an enchantment, and a planeswalker. Then each player sacrifices all other nonland permanents they control.
- XMage: status `found`, class `TragicArrogance`, signals `["targeting"]`
- Candidate: `selective_nonland_sacrifice` / `controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1`
- Credit: `exact_xmage_strong_reference`
- Adaptation: `runtime_new_executor` - Per-player/type controller choice then sacrifice all other nonland permanents.

### Monument to Endurance

- Current effects: `["passive"]`
- Findings: `["trusted_rule_without_oracle_hash"]`
- Oracle: Whenever you discard a card, choose one that hasn't been chosen this turn — // • Draw a card. // • Create a Treasure token. // • Each opponent loses 3 life.
- XMage: status `found`, class `MonumentToEndurance`, signals `["token", "draw", "triggered_ability"]`
- Candidate: `token_maker` / `xmage_create_token_variant_monumenttoendurance_v1`
- Credit: `exact_xmage_strong_reference`
- Adaptation: `rule_model_conflict_review` - Current passive trusted row misses discard-trigger modal draw/treasure/life-loss behavior.

### Surge to Victory

- Current effects: `["pump_all"]`
- Findings: `["trusted_rule_without_oracle_hash"]`
- Oracle: Exile target instant or sorcery card from your graveyard. Creatures you control get +X/+0 until end of turn, where X is that card's mana value. Whenever a creature you control deals combat damage to a player this turn, copy the exiled card. You may cast the co
- XMage: status `found`, class `SurgeToVictory`, signals `["targeting", "triggered_ability"]`
- Candidate: `pump_all` / `external_reference_required_pump_all_variant_v1`
- Credit: `exact_xmage_partial_generic`
- Adaptation: `metadata_hash_plus_runtime_review` - Current pump_all trusted row misses combat-damage copy/cast branch; likely more than hash-only.

### Molecule Man

- Current effects: `[]`
- Findings: `["no_active_battle_rule"]`
- Oracle: Nonland cards in your hand have miracle {0}. (You may cast a card for its miracle cost when you draw it if it's the first card you drew this turn.)
- XMage: status `not_found`, class `None`, signals `[]`
- Candidate: `passive` / `external_reference_required_manual_model_v1`
- Credit: `oracle_only_no_exact_xmage`
- Adaptation: `oracle_only_runtime_new_executor` - No exact local XMage class; miracle grant for nonland hand cards.

### Thor, God of Thunder

- Current effects: `[]`
- Findings: `["no_active_battle_rule"]`
- Oracle: Flying // When Thor enters, exile target Equipment, instant, or sorcery card from your graveyard. Until the end of your next turn, you may play that card. // Whenever you cast a noncreature spell, Thor deals damage equal to that spell's mana value to any targe
- XMage: status `not_found`, class `None`, signals `[]`
- Candidate: `passive` / `external_reference_required_manual_model_v1`
- Credit: `oracle_only_no_exact_xmage`
- Adaptation: `oracle_only_runtime_new_executor` - No exact local XMage class; ETB graveyard play permission plus noncreature spell damage trigger.
