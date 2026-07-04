# XMage Global All-Card Completion Goal - 2026-07-01

Status: `active_operational_goal`.

This goal supersedes stale numeric baselines inside thread-level goal text. The
thread goal remains active, but execution must use the current post-PG372
baseline and the stop criteria below.

This is the global control plane for the remaining card-rule work. Individual
PG waves are implementation cycles inside this goal; they are not separate
goals and they do not redefine the stopping point.

## Objective

Finish the global XMage -> ManaLoom card-rule adaptation for every applicable
ManaLoom all-card/Commander-legal battle-gap identity without switching back to
card-by-card semantic approval.

Resolved local XMage source is accepted as final card-behavior truth. ManaLoom
work is adapter/runtime translation, exact-scope validation, PostgreSQL
promotion, Hermes/SQLite sync, and audit evidence.

## Current Baseline

Source artifacts:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg331_creature_dies_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg331_creature_dies_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg332_graveyard_exile_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg332_graveyard_exile_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg333_graveyard_self_return_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg333_graveyard_self_return_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg334_graveyard_to_library_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg334_graveyard_to_library_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg335_battlefield_counter_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg335_battlefield_counter_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg336_activated_graveyard_to_library_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg336_activated_graveyard_to_library_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg337_etb_graveyard_to_library_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg337_etb_graveyard_to_library_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg338_reveal_library_pick_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg338_reveal_library_pick_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg339_etb_library_pick_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg339_etb_library_pick_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg340_spell_cast_draw_engine_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg340_spell_cast_draw_engine_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg341_recursion_auxiliary_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg341_recursion_auxiliary_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg342_recursion_exile_self_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg342_recursion_exile_self_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg343_recursion_mill_return_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg343_recursion_mill_return_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg344_static_graveyard_count_pt_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg344_static_graveyard_count_pt_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg345_static_graveyard_threshold_boost_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg345_static_graveyard_threshold_boost_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg346_static_graveyard_count_boost_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg346_static_graveyard_count_boost_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg347_activated_graveyard_to_owner_library_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg347_activated_graveyard_to_owner_library_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg348_activated_graveyard_to_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg348_activated_graveyard_to_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg355_destroy_restricted_target_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg355_destroy_restricted_target_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg356_etb_graveyard_to_library_extended_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg356_etb_graveyard_to_library_extended_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg357_dies_recursion_keyword_fix_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg357_dies_recursion_keyword_fix_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg358_returned_pastcaller_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg358_returned_pastcaller_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg359_aphetto_shared_type_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg359_aphetto_shared_type_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg360_static_graveyard_extended_filters_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg360_static_graveyard_extended_filters_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg362_recursion_x_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg362_recursion_x_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg363_recursion_x_exile_self_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg363_recursion_x_exile_self_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg364_multi_target_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg364_multi_target_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg365_battlefield_recursion_constraints_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg365_battlefield_recursion_constraints_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg366_activated_draw_costs_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg366_activated_draw_costs_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg367_return_all_graveyard_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg367_return_all_graveyard_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg368_graveyard_exile_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg368_graveyard_exile_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg369_activated_recursion_costs_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg369_activated_recursion_costs_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg370_static_token_keywords_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg370_static_token_keywords_wave_commander_legal.md`
- `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`

Post-PG370 counts:

- all known cards: `34331`
- all-card readiness `battle_and_oracle_ready`: `2552`
- all-card readiness `battle_family_mapper_required`: `29995`
- all-card readiness `snapshot_has_verified_rule`: `3700`
- target battle-gap identities in authoritative queue: `27072`
- XMage authoritative source resolved: `26758`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26758`
- adapter work-unit keys: `11429`

Post-PG372 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg372_boost_draw_spell_wave_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg372_boost_draw_spell_wave_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg372_supported_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg371_pg372_composite_resolution_waves_apply_evidence.md`
- target battle-gap identities in authoritative queue: `27057`
- XMage authoritative source resolved: `26743`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26743`
- adapter work-unit keys: `11429`
- final PG-Hermes-SQLite contract audit after docs update: `49/49` pass
- delta since post-PG370: `15` identities promoted

Post-PG373 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg373_destroy_draw_spell_wave_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg373_destroy_draw_spell_wave_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg373_supported_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg373_destroy_draw_spell_wave_apply_evidence.md`
- target battle-gap identities in authoritative queue: `27050`
- XMage authoritative source resolved: `26736`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26736`
- adapter work-unit keys: `11429`
- final PG-Hermes-SQLite contract audit: `49/49` pass
- delta since post-PG372: `7` identities promoted

Post-PG374 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg374_bounce_draw_spell_wave_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg374_bounce_draw_spell_wave_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg374_supported_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg374_bounce_draw_spell_wave_apply_evidence.md`
- target battle-gap identities in authoritative queue: `27045`
- XMage authoritative source resolved: `26731`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26731`
- adapter work-unit keys: `11429`
- final PG-Hermes-SQLite contract audit: `49/49` pass
- delta since post-PG373: `5` identities promoted

Post-PG375 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg375_counter_draw_new_server_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg375_counter_draw_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg375_counter_draw_new_server_supported_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg375_xmage_counter_draw_spell_wave_package.md`
- target battle-gap identities in authoritative queue: `27039`
- XMage authoritative source resolved: `26725`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26725`
- adapter work-unit keys: `11429`
- final PG-Hermes-SQLite contract audit: `status=pass`, `49 pass`, `1 warn`
  (`deck_id_607_has_no_pg_deck_id_note`, unrelated to PG375)
- delta since post-PG374: `6` identities promoted

Post-PG376 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg376_scry_damage_draw_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg376_scry_damage_draw_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg376_scry_damage_draw_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg376_scry_damage_draw_new_server_e2e.md`
- promoted families:
  - `xmage_fixed_scry_and_draw_cards_spell_v1` for `9` fixed scry/draw spells:
    `Behold the Multiverse`, `Deliberate`, `Foresee`, `Introduction to Prophecy`,
    `Opt`, `Preordain`, `Scour All Possibilities`, `Serum Visions`, and
    `Tamiyo's Epiphany`.
  - `xmage_fixed_damage_target_and_draw_card_spell_v1` for `3` fixed damage/draw
    spells: `Ember Shot`, `Playful Shove`, and `Zap`.
- target battle-gap identities in authoritative queue: `27027`
- XMage authoritative source resolved: `26713`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26713`
- adapter work-unit keys: `11429`
- final PG-Hermes-SQLite contract audit: `status=pass`, `49 pass`, `1 warn`
  (`deck_id_607_has_no_pg_deck_id_note`, unrelated to PG376)
- final supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg376_scry_damage_draw_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7784` considered supported rows.
- delta since post-PG375: `12` identities promoted.

Post-PG377 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg377_keyword_reminder_new_server_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg377_keyword_reminder_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg377_keyword_reminder_new_server_supported_recheck.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg377_xmage_keyword_reminder_wave_package_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg377_keyword_reminder_new_server_e2e.md`
- promoted families:
  - `xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1` for
    `25` fixed target-creature boost plus keyword-until-EOT spells.
  - `xmage_permanent_simple_activated_target_keyword_until_eot_v1` for `7`
    permanents with simple activated target-creature keyword-until-EOT
    abilities.
- implementation change:
  - the exact-scope splitter now strips Oracle reminder text in parenthetical
    clauses for the keyword-until-EOT mapper path. This fixed false blockers
    such as `Bloodlust Inciter`, `Axgard Cavalry`, `Brute Strength`, and
    `Beaming Defiance` without broadening the executable runtime scope.
- target battle-gap identities in authoritative queue: `26995`
- XMage authoritative source resolved: `26681`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26681`
- adapter work-unit keys: `11429`
- final PG-Hermes-SQLite contract audit: `status=pass`, `49 pass`, `1 warn`
  (`deck_id_607_has_no_pg_deck_id_note`, unrelated to PG377)
- final supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg377_keyword_reminder_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7752` considered supported rows.
- delta since post-PG376: `32` identities promoted.

Post-PG378 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg378_target_keyword_constraints_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg378_xmage_target_keyword_constraints_wave_package_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg378_target_keyword_constraints_new_server_e2e.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg378_target_keyword_constraints_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg378_target_keyword_constraints_new_server_supported_recheck.md`
- promoted family:
  - `xmage_permanent_simple_activated_target_keyword_until_eot_v1` for `16`
    permanents with exact XMage/Oracle target constraints: subtype/permanent,
    combat-state subtype, color filters, `power_min`, `power_max`, and
    `exclude_source`.
- implementation change:
  - the battle target legality contract now supports target subtypes and
    generic supertypes, and activated target-keyword selection can target
    noncreature permanents when the exact XMage filter says `TargetPermanent`.
  - the exact-scope splitter now compares full `target_constraints` from XMage
    source and Oracle text before package generation.
- target battle-gap identities in authoritative queue: `26979`
- XMage authoritative source resolved: `26665`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26665`
- adapter work-unit keys: `11429`
- final PG-Hermes-SQLite contract audit: `status=pass`, `49 pass`, `1 warn`
  (`deck_id_607_has_no_pg_deck_id_note`, unrelated to PG378)
- final supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg378_target_keyword_constraints_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7736` considered supported rows.
- delta since post-PG377: `16` identities promoted.

Post-PG379 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg379_fixed_damage_sacrifice_cost_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg379_fixed_damage_sacrifice_cost_new_server_package_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg379_fixed_damage_sacrifice_cost_new_server_e2e.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server_supported_recheck.md`
- promoted family:
  - `xmage_fixed_damage_target_spell_v1` for `5` fixed `DamageTargetEffect`
    spells with exact XMage `SacrificeTargetCost` support: `Collateral Damage`,
    `Fiery Conclusion`, `Magma Rift`, `Reckless Abandon`, and `Shard Volley`.
- implementation change:
  - the runtime now handles generic spell additional-cost payment for
    `requires_sacrifice_land` and marks paid additional costs to avoid double
    payment on stack resolution.
  - the exact-scope splitter now admits fixed direct-damage spells with
    supported `sacrifice_creature` or `sacrifice_land` additional costs, while
    blocking unsupported mixed costs such as creature-or-enchantment,
    artifact-or-creature, permanent, subtype-only, and discard/random variants.
- target battle-gap identities in authoritative queue: `26974`
- XMage authoritative source resolved: `26660`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26660`
- adapter work-unit keys: `11429`
- final PG-Hermes-SQLite contract audit: `status=pass`, `49 pass`, `1 warn`
  (`deck_id_607_has_no_pg_deck_id_note`, unrelated to PG379)
- final supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7731` considered supported rows.
- delta since post-PG378: `5` identities promoted.

Post-PG380 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg380_activated_draw_discard_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg380_activated_draw_discard_new_server_package_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg380_activated_draw_discard_new_server_e2e.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg380_activated_draw_discard_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg380_activated_draw_discard_new_server_supported_recheck.md`
- promoted family:
  - `xmage_permanent_simple_activated_draw_discard_v1` for `15` exact
    `DrawDiscardControllerEffect + SimpleActivatedAbility` permanents:
    `Bloodfire Mentor`, `Captain of Umbar`, `Dragonborn Looter`,
    `Emmessi Tome`, `Erratic Visionary`, `Facet Reader`,
    `Hapless Researcher`, `Jalum Tome`, `Magus of the Bazaar`,
    `Merfolk Looter`, `Research Assistant`, `Soothsayer Adept`,
    `Teferi's Protege`, `Thought Courier`, and `Unfulfilled Desires`.
- implementation change:
  - the runtime now executes generic `activated_draw_discard` permanents,
    including cost payment, draw, discard, discard-trigger resolution, and
    source self-sacrifice.
  - the exact-scope splitter now admits only fixed draw/discard counts with
    supported mana/tap/life/source-sacrifice activation costs; `Maestros
    Initiate` remains blocked as
    `activated_draw_discard_oracle_cost_not_supported`.
  - package E2E expected-field checks now include activated ability fields, so
    runtime validation checks counts/cost/tap/sacrifice semantics, not only
    scope.
- target battle-gap identities in authoritative queue: `26959`
- XMage authoritative source resolved: `26645`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26645`
- adapter work-unit keys: `11429`
- final supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg380_activated_draw_discard_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7732` considered supported rows.
- final audits:
  - strategy consistency:
    `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg380_activated_draw_discard_new_server.md`
    -> `status=pass`, `26/26` pass.
  - operational surface alignment:
    `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg380_activated_draw_discard_new_server.md`
    -> `status=pass`.
  - legacy contamination:
    `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg380_activated_draw_discard_new_server.md`
    -> `status=pass`.
  - PG-Hermes-SQLite contract:
    `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg380_clean_new_server.md`
    -> `status=pass`, `50/50` pass.
- contract cleanup:
  - backfilled missing `oracle_hash` on the new PostgreSQL target for the
    trusted executable curated rules of `Angel's Grace` and `Seething Song`
    from `cards.oracle_text`.
  - synced those rules back to Hermes/SQLite.
  - linked SQLite deck `607` to PostgreSQL deck
    `8938b746-1a9e-46ce-b0d9-c2ec932ddddd` after exact 94-row/100-card parity
    comparison.
- delta since post-PG379: `15` identities promoted.

Post-PG381 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg381_activate_as_sorcery_recursion_battlefield_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg381_activate_as_sorcery_recursion_battlefield_new_server_package_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg381_activate_as_sorcery_recursion_battlefield_new_server_e2e.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg381_activate_as_sorcery_recursion_battlefield_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg381_activate_as_sorcery_recursion_battlefield_new_server_supported_recheck.md`
- promoted family:
  - `xmage_permanent_simple_activated_graveyard_to_battlefield_v1` for `2`
    exact `ReturnFromGraveyardToBattlefieldTargetEffect` permanents with
    `ActivateAsSorceryActivatedAbility`, fixed `{3}{B}` activation cost,
    source self-sacrifice, and target creature card in your graveyard:
    `Bonecaller Cleric` and `Valgavoth's Faithful`.
- implementation change:
  - the exact-scope splitter now treats `ActivateAsSorceryActivatedAbility` as
    a supported activated-recursion timing only when the Oracle text/source
    agreement proves `Activate only as a sorcery.`
  - effect JSON records `activation_timing = sorcery`, so the runtime/package
    gate distinguishes sorcery-speed activated recursion from ordinary simple
    activated recursion.
  - variable-X or mana-value constrained neighbors, including `Sidisi, Regent
    of the Mire`, remain blocked instead of being promoted into this package.
- target battle-gap identities in authoritative queue: `26957`
- XMage authoritative source resolved: `26643`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26643`
- adapter work-unit keys: `11429`
- final supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg381_activate_as_sorcery_recursion_battlefield_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7730` considered supported rows.
- final audits:
  - strategy consistency:
    `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg381_activate_as_sorcery_recursion_battlefield_new_server.md`
    -> `status=pass`, `26/26` pass.
  - operational surface alignment:
    `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg381_activate_as_sorcery_recursion_battlefield_new_server.md`
    -> `status=pass`.
  - legacy contamination:
    `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg381_activate_as_sorcery_recursion_battlefield_new_server.md`
    -> `status=pass`.
  - PG-Hermes-SQLite contract:
    `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg381_activate_as_sorcery_recursion_battlefield_new_server.md`
    -> `status=pass`, `50/50` pass.
- delta since post-PG380: `2` identities promoted.

Post-PG382 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg382_draw_additional_cost_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg382_draw_additional_cost_new_server_package_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg382_draw_additional_cost_new_server_e2e.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg382_draw_additional_cost_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg382_draw_additional_cost_new_server_supported_recheck.md`
- promoted family:
  - `xmage_fixed_source_controller_draw_spell_v1` for `9` exact
    `DrawCardSourceControllerEffect` spells with fixed draw count and supported
    additional costs: `Altar's Reap`, `Blood Divination`,
    `Corrupted Conviction`, `Magmatic Insight`, `Skulltap`,
    `Tormenting Voice`, `Village Rites`, `Vivisection`, and `Wild Guess`.
- implementation change:
  - the exact-scope splitter now accepts fixed draw spells with only these
    runtime-supported additional costs: sacrifice one creature, discard one
    card, or discard one land card.
  - costs such as sacrifice two creatures, sacrifice artifact-or-creature,
    sacrifice creature-or-land, tap four creatures, put a -1/-1 counter, and
    variable draw remain blocked as `draw_additional_cost_not_supported`.
  - runtime coverage is reused from `pay_additional_card_costs`; focused tests
    now prove draw resolution pays sacrifice/discard before drawing.
- target battle-gap identities in authoritative queue: `26948`
- XMage authoritative source resolved: `26634`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26634`
- adapter work-unit keys: `11429`
- final supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg382_draw_additional_cost_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7721` considered supported rows.
- final audits:
  - strategy consistency:
    `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg382_draw_additional_cost_new_server.md`
    -> `status=pass`, `26/26` pass.
  - operational surface alignment:
    `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg382_draw_additional_cost_new_server.md`
    -> `status=pass`.
  - legacy contamination:
    `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg382_draw_additional_cost_new_server.md`
    -> `status=pass`.
  - PG-Hermes-SQLite contract:
    `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg382_draw_additional_cost_new_server.md`
    -> `status=pass`, `50/50` pass.
- delta since post-PG381: `9` identities promoted.

Post-PG383 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg383_target_effect_scry_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg383_target_effect_scry_new_server_package_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg383_target_effect_scry_new_server_e2e.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg383_target_effect_scry_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg383_target_effect_scry_new_server_supported_recheck.md`
- promoted families:
  - `xmage_fixed_damage_target_and_scry_spell_v1` for `8` exact
    `DamageTargetEffect + ScryEffect` spells.
  - `xmage_destroy_target_and_scry_spell_v1` for `8` exact
    `DestroyTargetEffect + ScryEffect` spells.
  - `xmage_return_target_to_hand_and_scry_spell_v1` for `2` exact
    `ReturnToHandTargetEffect + ScryEffect` spells.
- promoted cards: `Artisan's Sorrow`, `Bolt of Keranos`,
  `Expose to Daylight`, `Fateful End`, `Get the Point`, `Guiding Bolt`,
  `Jaya's Firenado`, `Jaya's Greeting`, `Lightning Javelin`, `Magma Jet`,
  `Piercing Light`, `Rubble Reading`, `Select for Inspection`,
  `Skywhaler's Shot`, `Spark Jolt`, `Tel-Jilad Justice`,
  `Vanquish the Foul`, and `Voyage's End`.
- implementation change:
  - the exact-scope splitter now recognizes same-spell target effects followed
    by fixed `ScryEffect` and emits composite runtime rules instead of treating
    those cards as isolated manual exceptions.
  - supported components are fixed target damage, supported destroy target, and
    supported return-to-hand target plus fixed scry.
  - `exile + scry` parsing is present, but the current safe queue had no exact
    promotable cards because the remaining candidates require target
    constraints outside this package.
  - the `creature_power_3_or_greater` target constraint is now represented as
    structured `power_min=3`.
- target battle-gap identities in authoritative queue: `26930`
- XMage authoritative source resolved: `26616`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26616`
- adapter work-unit keys: `11429`
- final supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg383_target_effect_scry_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7703` considered supported rows.
- final audits:
  - strategy consistency:
    `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg383_target_effect_scry_new_server.md`
    -> `status=pass`, `26/26` pass.
  - operational surface alignment:
    `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg383_target_effect_scry_new_server.md`
    -> `status=pass`.
  - legacy contamination:
    `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg383_target_effect_scry_new_server.md`
    -> `status=pass`.
  - PG-Hermes-SQLite contract:
    `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg383_target_effect_scry_new_server.md`
    -> `status=pass`, `50/50` pass.
- delta since post-PG382: `18` identities promoted.

Post-PG384 update:

- source artifacts:
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg384_destroy_additional_cost_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg384_additional_cost_spell_runtime_new_server_package_package.md`
  - `docs/hermes-analysis/master_optimizer_reports/pg384_additional_cost_spell_runtime_new_server_e2e.md`
  - `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg384_additional_cost_spell_runtime_new_server.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg384_additional_cost_spell_runtime_new_server_commander_legal.md`
  - `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg384_additional_cost_spell_runtime_new_server_supported_recheck.md`
- promoted families:
  - `xmage_fixed_damage_target_spell_v1` for `5` exact fixed damage spells
    with supported additional costs.
  - `xmage_destroy_target_spell_v1` for `4` exact destroy-target spells with
    supported additional costs.
  - `xmage_fixed_source_controller_draw_spell_v1` for `3` exact fixed draw
    spells with supported additional costs.
- promoted cards: `Acceptable Losses`, `Artillerize`, `Bone Splinters`,
  `Costly Plunder`, `Embrace Oblivion`, `Eviscerator's Insight`,
  `Improvised Club`, `Morbid Curiosity`, `Powerstone Fracture`, `Raze`,
  `Sonic Burst`, and `Sonic Seizure`.
- implementation change:
  - the exact-scope splitter now reuses one supported spell-additional-cost
    mapper across fixed damage, fixed draw, and destroy-target spell scopes.
  - supported costs for this mapper are discard a card, discard a land,
    sacrifice a creature, sacrifice a land, and sacrifice an artifact or
    creature when XMage source and Oracle text agree exactly.
  - the battle runtime now pays `requires_sacrifice_artifact_or_creature` and
    pays additional costs before resolving destroy/remove effects.
- target battle-gap identities in authoritative queue: `26918`
- XMage authoritative source resolved: `26604`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26604`
- adapter work-unit keys: `11429`
- final supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg384_additional_cost_spell_runtime_new_server_supported_recheck.md`
  returned `proposal_count=0` over `7691` considered supported rows.
- final audits:
  - strategy consistency:
    `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_pg384_additional_cost_spell_runtime_new_server.md`
    -> `status=pass`, `26/26` pass.
  - operational surface alignment:
    `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_pg384_additional_cost_spell_runtime_new_server.md`
    -> `status=pass`.
  - legacy contamination:
    `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_pg384_additional_cost_spell_runtime_new_server.md`
    -> `status=pass`.
  - PG-Hermes-SQLite contract:
    `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_pg384_additional_cost_spell_runtime_new_server.md`
    -> `status=pass`, `50/50` pass.
- delta since post-PG383: `12` identities promoted.

## Latest Goal Recheck - 2026-07-02

Current thread goal text still mentions the older post-PG284 baseline. That is
historical only. The active execution baseline is the post-PG384 queue above.

## General Goal Contract - 2026-07-02

Treat this file as the active stop contract for the all-card work. The Codex
thread goal may contain older counts, but execution stops only when a freshly
generated queue proves the terminal stop definition below.

Current post-PG384 control numbers:

- target battle-gap identities: `26918`
- XMage-resolved authoritative source identities: `26604`
- local XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26604`
- adapter work-unit keys: `11429`

Operational goal:

1. Continue applying exact XMage-derived subpatterns until
   `xmage_authoritative_adapter_required_count = 0`.
2. Keep `xmage_authoritative_parser_gap_count = 0`; any new parser gap blocks
   completion until fixed or classified with evidence.
3. Close the `314` missing-source exceptions in a separate official/Forge/manual
   lane; do not mix them into the XMage-resolved adapter queue.
4. Do not switch scope back to Lorehold, deck `607`, saved decks, or the current
   registered decks. Those are QA seeds only.
5. Every promoted rule must have runtime support, focused tests, PostgreSQL
   precheck/apply/postcheck evidence, Hermes/SQLite sync, canonical snapshot
   visibility, audit pass, and commit/push evidence.

Next executable cycle:

1. Start from
   `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg384_additional_cost_spell_runtime_new_server_commander_legal.json`.
2. The current exact splitter returns `0` batch-safe proposals after PG384, so
   the next cycle must add a new mapper/runtime subpattern before package
   generation.
3. Preferred next analysis lanes, in order:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1820`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1619`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1114`), `direct_damage::targeted_damage_variant_v1` (`888`), and
   `add_counters::source_add_counters_variant_v1` (`795`).
4. Promote only a narrow subpattern whose ManaLoom runtime behavior is already
   implemented or implemented in the same cycle.
5. If a proposed lane cannot prove Oracle/source/runtime agreement, record the
   blocker counts and move to the next lane without creating manual per-card
   rules.

PG374 completion and PG375 starting hypothesis:

1. PG373 promoted the exact
   `DestroyTargetEffect + DrawCardSourceControllerEffect` subset as
   `xmage_destroy_target_and_draw_card_spell_v1`, covering `7` fixed
   destroy-target plus draw-card spells.
2. PG374 promoted the exact
   `ReturnToHandTargetEffect + DrawCardSourceControllerEffect` subset as
   `xmage_return_target_to_hand_and_draw_card_spell_v1`, covering `5` fixed
   return-target-to-hand plus draw-card spells. The promoted cards were
   `Drag Under`, `Galestrike`, `Leave in the Dust`, `Repulse`, and
   `Symbol of Unsummoning`. `Read the Tides` remained blocked as modal/up-to,
   and `Repeal` remained blocked as an X/target-adjusted spell.
3. The lane must still be split by XMage effect signature before any PostgreSQL
   package. Current measured subpatterns from the post-PG372 analysis included:
   `DiscardControllerEffect + DrawCardSourceControllerEffect` (`13` rows),
   `DestroyTargetEffect + DrawCardSourceControllerEffect` (`12` rows),
   `CounterTargetEffect + DrawCardSourceControllerEffect` (`11` rows),
   `DamageTargetEffect + DrawCardSourceControllerEffect` (`10` rows),
   `DrawCardSourceControllerEffect + ScryEffect` (`8` rows), and
   `DrawCardSourceControllerEffect + ReturnToHandTargetEffect` (`7` rows).
   After PG373, the exact destroy-target subset is exhausted in the supported
   splitter. After PG374, the exact return-target-to-hand plus draw-card subset
   is exhausted in the supported splitter and `draw_effect_class_not_pure`
   stands at `522`.
4. Promote only exact fixed subsets from those signatures. Variable `X`, modal
   spells, dynamic card counts, optional discard clauses, unsupported target
   restrictions, and conditionally-derived amounts remain blocked until their
   own mapper/runtime subpattern exists.
5. The first PG375 candidate should be the highest-confidence subpattern whose
   component effects are already supported by `composite_resolution` or can be
   added with a focused runtime test in the same cycle. If that fails, preserve
   blocker evidence and try the next measured subpattern; do not hand-write
   individual card rules.

PG375 completion and PG376 starting hypothesis:

1. PG375 promoted the exact
   `CounterTargetEffect + DrawCardSourceControllerEffect` subset as
   `xmage_counter_target_and_draw_card_spell_v1`, covering `6` fixed
   counter-target spell plus draw-card spells: `Bone to Ash`, `Contradict`,
   `Dismiss`, `Exclude`, `Halt Order`, and `Scatter Arc`.
2. `Bind`, `Squelch`, `Confound`, `Hindering Light`, `Keep Safe`,
   `Laquatus's Disdain`, and `School Daze` remain blocked by unsupported
   target type/restriction or modal text, not by missing XMage source.
3. The next cycle should continue splitting `draw_effect_class_not_pure`
   (`511` blockers) unless a measured lane with higher safe reuse appears in
   the refreshed queue.

PG376 completion and PG377 starting hypothesis:

1. PG376 promoted `12` composite draw spell rules on the new server:
   `9` fixed scry/draw spells and `3` fixed damage/draw spells.
2. PG376 added runtime support for `scry` and `direct_damage` components inside
   `composite_resolution`, with focused runtime tests proving ordered scry/draw
   and damage/draw resolution without double-moving the source spell.
3. Dynamic or conditional neighbors remain blocked: `Ugin's Insight` by dynamic
   `Scry X`; `Incinerating Blast`, `Needle Drop`, `Tweeze`,
   `Invoke the Firemind`, `Master the Way`, and `Stensia Banquet` by optional,
   conditional, modal, or dynamic damage/draw behavior.
4. The post-PG376 supported splitter returns `0` batch-safe proposals, so PG377
   must implement another narrow subpattern before any PostgreSQL package.
5. The next highest measured blockers remain `draw_effect_class_not_pure`
   (`492`), `mana_source_effect_class_not_simple` (`303`), and
   `not_instant_or_sorcery_spell` (`3946`) split by reusable XMage signatures.

PG377 completion and PG378 starting hypothesis:

1. PG377 promoted `32` keyword-until-EOT rules on the new server:
   `25` fixed target-creature boost plus keyword spells and `7` simple
   activated target-creature keyword permanents.
2. PG377 did not add a new runtime executor. It corrected the exact-scope
   Oracle parser so reminder text in parentheses no longer blocks otherwise
   exact XMage/source/runtime agreement.
3. Tests passed: splitter `296`, exact runtime `175`, E2E package validation
   `status=pass`, and PG/Hermes/SQLite contract audit `status=pass`.
4. The post-PG377 supported splitter returns `0` batch-safe proposals, so PG378
   must implement another narrow subpattern before PostgreSQL package
   generation.
5. The largest remaining work units are now:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1822`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1634`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1130`), `direct_damage::targeted_damage_variant_v1` (`906`), and
   `add_counters::source_add_counters_variant_v1` (`795`).

PG378 completion and PG379 starting hypothesis:

1. PG378 promoted `16` constrained activated target-keyword permanents on the
   new server. The promoted target contracts cover subtype/permanent targets,
   attacking subtype targets, color-filtered creature targets, `power_min`,
   `power_max`, and `exclude_source`.
2. PG378 added runtime support for subtype/supertype target legality and
   allowed activated keyword selection to consider noncreature permanents when
   the exact target type is `permanent`.
3. Tests passed: splitter `302`, exact runtime `178`, py_compile, E2E package
   validation `status=pass`, and PG/Hermes/SQLite contract audit
   `status=pass`.
4. The post-PG378 supported splitter returns `0` batch-safe proposals, so
   PG379 must implement another narrow subpattern before PostgreSQL package
   generation.
5. The largest remaining work units are now:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1822`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1634`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1114`), `direct_damage::targeted_damage_variant_v1` (`906`), and
   `add_counters::source_add_counters_variant_v1` (`795`).

PG379 completion and PG380 starting hypothesis:

1. PG379 promoted `5` fixed direct-damage spells with exact XMage
   `SacrificeTargetCost` support on the new server: `Collateral Damage`,
   `Fiery Conclusion`, `Magma Rift`, `Reckless Abandon`, and `Shard Volley`.
2. PG379 added runtime payment for spell additional-cost land sacrifice and
   guarded spell resolution against double payment after stack execution.
3. Tests passed: splitter `305`, exact runtime `180`, py_compile, E2E package
   validation `status=pass`, and PG/Hermes/SQLite contract audit
   `status=pass`.
4. The post-PG379 supported splitter returns `0` batch-safe proposals, so PG380
   must implement another narrow subpattern before PostgreSQL package
   generation.
5. The largest remaining work units are now:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1822`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1634`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1114`), `direct_damage::targeted_damage_variant_v1` (`901`), and
   `add_counters::source_add_counters_variant_v1` (`795`).

PG380 completion and PG381 starting hypothesis:

1. PG380 promoted `15` exact permanent activated draw-discard rules on the new
   server after adding
   `xmage_permanent_simple_activated_draw_discard_v1` to mapper/runtime/tests.
2. Tests passed: splitter `309`, exact runtime `183`, package builder,
   py_compile, and E2E package validation `status=pass`.
3. Post-PG380 governance passed with strategy consistency `26/26`,
   operational surface `pass`, legacy contamination `pass`, and
   PG-Hermes-SQLite contract `50/50` pass against the new server.
4. The post-PG380 supported splitter returns `0` batch-safe proposals, so PG381
   must implement another narrow subpattern before PostgreSQL package
   generation.
5. The largest remaining work units are now:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1822`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1619`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1114`), `direct_damage::targeted_damage_variant_v1` (`901`), and
   `add_counters::source_add_counters_variant_v1` (`795`).

PG381 completion and PG382 starting hypothesis:

1. PG381 promoted `2` exact permanent activated graveyard-to-battlefield rules
   on the new server after extending the mapper/runtime contract for
   sorcery-speed activated recursion.
2. Tests passed: splitter `310`, exact runtime `184`, package builder,
   py_compile, and E2E package validation `status=pass`.
3. Post-PG381 governance passed with strategy consistency `26/26`,
   operational surface `pass`, legacy contamination `pass`, and
   PG-Hermes-SQLite contract `50/50` pass against the new server.
4. The post-PG381 supported splitter returns `0` batch-safe proposals, so
   PG382 must implement another narrow subpattern before PostgreSQL package
   generation.
5. The largest remaining work units are now:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1820`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1619`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1114`), `direct_damage::targeted_damage_variant_v1` (`901`), and
   `add_counters::source_add_counters_variant_v1` (`795`).

PG382 completion and PG383 starting hypothesis:

1. PG382 promoted `9` fixed draw spells with supported additional costs on the
   new server. This was selected after confirming the post-PG381 splitter had
   no batch-safe proposal and the largest recursion residuals required broader
   cost/condition modeling before safe promotion.
2. Tests passed: splitter `314`, exact runtime `186`, package builder,
   py_compile, and E2E package validation `status=pass`.
3. Post-PG382 governance passed with strategy consistency `26/26`,
   operational surface `pass`, legacy contamination `pass`, and
   PG-Hermes-SQLite contract `50/50` pass against the new server.
4. The post-PG382 supported splitter returns `0` batch-safe proposals, so
   PG383 must implement another narrow subpattern before PostgreSQL package
   generation.
5. The largest remaining work units are now:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1820`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1619`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1114`), `direct_damage::targeted_damage_variant_v1` (`901`), and
   `add_counters::source_add_counters_variant_v1` (`795`). The
   `draw_cards::xmage_draw_card_variant_review_v1` residual is now `627`.

PG383 completion and PG384 starting hypothesis:

1. PG383 promoted `18` target-effect plus fixed-scry spells on the new server:
   `8` damage+scry, `8` destroy+scry, and `2` bounce+scry cards.
2. The implementation reuses the existing composite battle runtime and extends
   the exact splitter with source/Oracle agreement checks for fixed `ScryEffect`
   components and structured `power_min=3` target constraints.
3. Tests passed: splitter `320`, exact runtime `187`, package builder,
   py_compile, and E2E package validation `status=pass`.
4. Post-PG383 governance passed with strategy consistency `26/26`,
   operational surface `pass`, legacy contamination `pass`, and
   PG-Hermes-SQLite contract `50/50` pass against the new server.
5. The post-PG383 supported splitter returns `0` batch-safe proposals over
   `7703` considered supported rows, so PG384 must implement another narrow
   subpattern before PostgreSQL package generation.
6. The largest remaining work units are now:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1820`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1619`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1114`), `direct_damage::targeted_damage_variant_v1` (`893`),
   `add_counters::source_add_counters_variant_v1` (`795`),
   `life_gain::xmage_life_gain_variant_review_v1` (`735`),
   `draw_cards::xmage_draw_card_variant_review_v1` (`627`),
   `removal_destroy::targeted_destroy_variant_v1` (`616`), and
   `tutor::xmage_library_search_variant_review_v1` (`613`).

PG384 completion and PG385 starting hypothesis:

1. PG384 promoted `12` additional-cost spells on the new server:
   `5` fixed damage, `4` destroy-target, and `3` fixed draw cards.
2. The implementation made spell additional-cost mapping reusable across these
   exact scopes and added runtime payment for sacrifice artifact or creature
   plus destroy/remove spell costs.
3. Tests passed: splitter `323`, exact runtime `189`, package builder,
   py_compile, and E2E package validation `status=pass`.
4. Post-PG384 governance passed with strategy consistency `26/26`,
   operational surface `pass`, legacy contamination `pass`, and
   PG-Hermes-SQLite contract `50/50` pass against the new server.
5. The post-PG384 supported splitter returns `0` batch-safe proposals over
   `7691` considered supported rows, so PG385 must implement another narrow
   subpattern before PostgreSQL package generation.
6. The largest remaining work units are now:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1820`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1619`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1114`), `direct_damage::targeted_damage_variant_v1` (`888`),
   `add_counters::source_add_counters_variant_v1` (`795`),
   `life_gain::xmage_life_gain_variant_review_v1` (`735`),
   `draw_cards::xmage_draw_card_variant_review_v1` (`624`),
   `removal_destroy::targeted_destroy_variant_v1` (`612`), and
   `tutor::xmage_library_search_variant_review_v1` (`613`).

PG385 completion and PG386 starting hypothesis:

1. PG385 promoted `9` fixed draw/discard spells on the new server:
   `Ancestral Reminiscence`, `Careful Study`, `Catalog`, `Enhanced Awareness`,
   `Prying Eyes`, `Rain of Revelation`, `Romantic Rendezvous`, `Sift`, and
   `Thoughtflare`.
2. The implementation added exact `xmage_fixed_draw_discard_spell_v1` mapping
   for fixed `DrawDiscardControllerEffect` and fixed
   `DrawCardSourceControllerEffect + DiscardControllerEffect` spell pairs,
   requiring Oracle/source agreement on draw count, discard count, and order.
3. Runtime now resolves both `draw_then_discard` and `discard_then_draw`,
   emits `draw_discard_spell_resolved`, and keeps random-discard metadata
   available for XMage pair effects that require it.
4. Tests passed: splitter `327`, exact runtime `191`, sync selection `19`,
   py_compile, and E2E package validation `status=pass`.
5. PostgreSQL on the new server applied `9` upserts with `0` shadow rows
   deprecated; postcheck verified `9/9`; Hermes/SQLite sync loaded `9` PG rows,
   updated `9` SQLite rows, and exported `5137` canonical snapshot rows.
6. Post-PG385 governance passed with strategy consistency `26/26`,
   operational surface `pass`, and PG-Hermes-SQLite contract `50/50` pass
   against `127.0.0.1:15432/halder`.
7. The post-PG385 supported splitter returns `0` batch-safe proposals over
   `7682` considered supported rows, so PG386 must implement another narrow
   subpattern before PostgreSQL package generation.
8. The largest remaining work units are now:
   `recursion::xmage_graveyard_return_variant_review_v1` (`1820`),
   `draw_engine::xmage_draw_card_variant_review_v1` (`1619`),
   `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
   (`1114`), `direct_damage::targeted_damage_variant_v1` (`888`),
   `add_counters::source_add_counters_variant_v1` (`795`),
   `life_gain::xmage_life_gain_variant_review_v1` (`735`),
   `draw_cards::xmage_draw_card_variant_review_v1` (`615`),
   `removal_destroy::targeted_destroy_variant_v1` (`612`), and
   `tutor::xmage_library_search_variant_review_v1` (`613`).

Fresh alignment evidence:

- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_pg385_draw_discard_spell_runtime_new_server_docs_after_update.md`
  passed with `50/50`.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_pg385_draw_discard_spell_runtime_new_server_docs_after_update.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_pg385_draw_discard_spell_runtime_new_server_docs_after_update.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server_docs_after_update.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server.md`
  passed with `49` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg378_target_keyword_constraints_new_server.md`
  passed with `49` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg378_target_keyword_constraints_new_server_docs_after_update.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg378_target_keyword_constraints_new_server_docs_after_update.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg378_target_keyword_constraints_new_server_docs_after_update.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg377_keyword_reminder_new_server.md`
  passed with `49` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg377_keyword_reminder_new_server_docs_after_update.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg377_keyword_reminder_new_server_docs_after_update.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg377_keyword_reminder_new_server_docs_after_update.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg376_scry_damage_draw_new_server.md`
  passed with `49` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg376_scry_damage_draw_new_server_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg376_scry_damage_draw_new_server_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg376_scry_damage_draw_new_server_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg374_bounce_draw_spell_wave_final.md`
  passed with `49/49` checks.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg374_bounce_draw_spell_wave_docs_after_update.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg374_bounce_draw_spell_wave_docs_after_update.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg374_bounce_draw_spell_wave_docs_after_update.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg373_destroy_draw_spell_wave_final.md`
  passed with `49/49` checks.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg373_destroy_draw_spell_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg373_destroy_draw_spell_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg373_destroy_draw_spell_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_goal_next_step_recheck.md`
  passed with `26/26` checks after the PG373 starting hypothesis update.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_goal_next_step_recheck.md`
  passed after the PG373 starting hypothesis update.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_goal_general_recheck.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_goal_general_recheck.md`
  passed with `35/35` checks.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg355_destroy_restricted_target_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg355_destroy_restricted_target_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg355_destroy_restricted_target_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg355_destroy_restricted_target_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg356_etb_graveyard_to_library_extended_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg356_etb_graveyard_to_library_extended_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg356_etb_graveyard_to_library_extended_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg356_etb_graveyard_to_library_extended_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg357_dies_recursion_keyword_fix_wave_docs_updated.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg357_dies_recursion_keyword_fix_wave_docs_updated.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg357_dies_recursion_keyword_fix_wave_docs_updated.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg357_dies_recursion_keyword_fix_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg358_returned_pastcaller_recursion_wave_docs_updated.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg358_returned_pastcaller_recursion_wave_docs_updated.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg358_returned_pastcaller_recursion_wave_docs_updated.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg358_returned_pastcaller_recursion_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg359_aphetto_shared_type_recursion_wave_docs_updated.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg359_aphetto_shared_type_recursion_wave_docs_updated.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg359_aphetto_shared_type_recursion_wave_docs_updated.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg359_aphetto_shared_type_recursion_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg360_static_graveyard_extended_filters_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg360_static_graveyard_extended_filters_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg360_static_graveyard_extended_filters_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg360_static_graveyard_extended_filters_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg361_recursion_battlefield_selection_constraints_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg362_recursion_x_spell_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg362_recursion_x_spell_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg362_recursion_x_spell_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg362_recursion_x_spell_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg363_recursion_x_exile_self_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg363_recursion_x_exile_self_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg363_recursion_x_exile_self_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg363_recursion_x_exile_self_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg364_multi_target_recursion_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg364_multi_target_recursion_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg364_multi_target_recursion_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg364_multi_target_recursion_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg365_battlefield_recursion_constraints_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg365_battlefield_recursion_constraints_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg365_battlefield_recursion_constraints_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg365_battlefield_recursion_constraints_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg366_activated_draw_costs_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg366_activated_draw_costs_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg366_activated_draw_costs_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg366_activated_draw_costs_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg367_return_all_graveyard_battlefield_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg367_return_all_graveyard_battlefield_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg367_return_all_graveyard_battlefield_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg367_return_all_graveyard_battlefield_wave.md`
  passed with `48` pass and `1` inherited warning.
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg368_graveyard_exile_spell_wave_docs_final.md`
  passed with `26/26` checks.
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg368_graveyard_exile_spell_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg368_graveyard_exile_spell_wave_docs_final.md`
  passed.
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg368_graveyard_exile_spell_wave.md`
  passed with `48` pass and `1` inherited warning.

The next executable work starts from
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg368_graveyard_exile_spell_wave_commander_legal.json`.
The first priority is still
`recursion::xmage_graveyard_return_variant_review_v1` with `1826` remaining
identities, but that broad work unit must be split by exact XMage
effect/ability/source signatures before any PostgreSQL promotion.

## Completion Criteria

Stop only when a freshly regenerated global queue and readiness report prove all
of these conditions:

1. `xmage_authoritative_adapter_required_count = 0`.
2. `xmage_authoritative_parser_gap_count = 0`.
3. `xmage_missing_source_exception_count = 0`, or every remaining exception is
   explicitly classified with evidence as official-source/manual-model,
   Forge-cross-check, unsupported/non-product, or no-runtime-needed.
4. No applicable all-card/Commander-legal identity remains in
   `battle_family_mapper_required` without a documented executable rule,
   generic/no-card-rule classification, or explicit exclusion.
5. PostgreSQL is the source of truth for every promoted executable rule, with
   matching `oracle_hash` for newly touched rows.
6. Hermes SQLite and `known_cards_canonical_snapshot.json` are synced from
   PostgreSQL after the final apply.
7. Focused runtime tests, E2E package validation, XMage strategy audit,
   operational surface audit, PG/Hermes/SQLite contract audit, and legacy
   contamination audit pass.
8. Final evidence is committed and pushed.

The goal is not complete just because a deck runs, a family looks broadly
mapped, or a generated `xmage_*_review_v1` scope exists. Broad review scopes are
planning lanes, not executable rules.

## Terminal Stop Definition

The final stop is reached only after the last cycle produces a fresh global
readiness report and authoritative XMage queue where every remaining card
identity is in exactly one closed state:

1. `battle_and_oracle_ready` through a reviewed PostgreSQL rule synced to
   Hermes/SQLite and visible in the canonical snapshot.
2. Generic/no-runtime-needed because the card has no Oracle rules text or no
   battle-executable behavior needed by ManaLoom.
3. Documented product exclusion or unsupported runtime lane with source
   evidence, owner-visible reason, and no silent fallback into deck/battle
   execution.
4. Manual/official/Forge exception lane for cards with no resolvable local
   XMage class, with the exception recorded separately from the XMage-resolved
   adapter backlog.

Any identity left as broad `xmage_*_review_v1`, parser gap, unresolved
missing-source exception, stale SQLite-only rule, or PostgreSQL/Hermes mismatch
means the global goal is still open.

## Work-Control Rule

Each working session must choose one of the following measurable outcomes before
it is considered useful progress:

1. Promote an exact runtime-backed PostgreSQL package and prove the refreshed
   queue decreased.
2. Add a reusable exact subpattern/runtime adapter with focused tests, then
   produce a package from it.
3. Exhaust a candidate family with blocker counts that change the next queue
   selection.
4. Classify a missing-source exception lane with source evidence and no
   executable ambiguity.

If a session does none of these, it is not allowed to claim progress. The next
action must be to rebuild the queue, inspect the largest remaining work units,
and select a different exact subpattern.

## Required Cycle

Repeat this cycle until the completion criteria are met:

1. Regenerate global all-card readiness and authoritative XMage adaptation
   queue.
2. Select the highest reusable work unit from the fresh queue.
3. Split it into a narrow `battle_model_scope` using XMage Java class/effect,
   Oracle text, target/cost constraints, and explicit blocker reasons.
4. Implement only exact runtime-backed behavior in the splitter and
   `battle_analyst_v9.py`.
5. Add focused positive and negative tests for the exact scope.
6. Generate PostgreSQL precheck/apply/rollback/postcheck package.
7. Apply PostgreSQL only through precheck -> apply -> postcheck.
8. Sync PostgreSQL -> Hermes/SQLite and refresh the canonical snapshot.
9. Run E2E validation and final alignment audits.
10. Rebuild readiness/queue and record the actual queue reduction.

The cycle is recursive: after each commit/push, immediately start again from
the newly generated queue instead of returning to deck-specific intuition or
historical artifacts.

If a selected family produces no safe package candidates, record blocker counts
and continue to the next highest reusable work unit in the same goal. Do not
fall back to per-card implementation unless all reusable subpatterns for that
family are exhausted and the residual card is explicitly classified as manual.

## Current Priority Order

Use the post-PG385 authoritative queue unless a newer queue exists:

1. `recursion::xmage_graveyard_return_variant_review_v1` - `1820`
2. `draw_engine::xmage_draw_card_variant_review_v1` - `1619`
3. `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` - `1114`
4. `direct_damage::targeted_damage_variant_v1` - `888`
5. `add_counters::source_add_counters_variant_v1` - `795`
6. `life_gain::xmage_life_gain_variant_review_v1` - `735`
7. `draw_cards::xmage_draw_card_variant_review_v1` - `615`
8. `removal_destroy::targeted_destroy_variant_v1` - `612`
9. `tutor::xmage_library_search_variant_review_v1` - `613`
10. `add_counters::targeted_add_counters_variant_v1` - `459`

Immediate checkpoint after PG361:

1. PG336 promoted the exact
   `xmage_permanent_simple_activated_graveyard_to_library_v1` subpattern for
   `Epitaph Golem`, `Haunted Crossroads`, and `Tomb Trawler`.
2. PG337 promoted the exact
   `xmage_creature_etb_put_graveyard_card_on_library_v1` subpattern for
   `Dukhara Scavenger` and `Meldweb Curator`.
3. PG338 promoted the exact
   `xmage_reveal_top_library_pick_to_hand_rest_graveyard_spell_v1` subpattern
   for `Commune with the Gods`, `Glacial Revelation`, `Grisly Salvage`,
   `Kruphix's Insight`, `Pieces of the Puzzle`, and `Scout the Borders`.
4. PG339 promoted the exact
   `xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1`
   subpattern for `Organ Hoarder`, `Sibsig Appraiser`, `Sultai Soothsayer`,
   and `Tower Geist`.
5. PG340 promoted the exact `xmage_spell_cast_draw_engine_v1` subpattern for
   `Beast Whisperer`, `Enchantress's Presence`,
   `Jhoira, Weatherlight Captain`, `Mesa Enchantress`, `Primordial Sage`,
   `Reki, the History of Kamigawa`, `Satyr Enchanter`, `Secrets of the Dead`,
   `Sram, Senior Edificer`, `Tanufel Rimespeaker`, `Thunderous Snapper`,
   `Vedalken Archmage`, `Verduran Enchantress`, and
   `Whirlwind of Thought`.
6. PG341 promoted the exact recursion auxiliary spell subpattern for
   `Morgue Theft`, `Mystic Retrieval`, `Unburial Rites`, `Unearth`, and
   `Wander in Death`, preserving flashback/cycling metadata and supported
   graveyard-to-hand/battlefield targets.
7. PG342 promoted exact self-exiling recursion spells for
   `Reconstruct History`, `Retrieve`, and `Vivid Revival`, including
   multi-component graveyard-to-hand selection and supported multicolored-card
   constraints.
8. PG343 promoted exact mill-then-return recursion spells/ETB creatures for
   `Acolyte of Affliction`, `Corpse Churn`, `Eccentric Farmer`,
   `Grapple with the Past`, and `Pothole Mole`.
9. PG344 promoted the exact
   `xmage_static_source_power_toughness_equal_graveyard_count_v1` subpattern
   for `Boneyard Wurm`, `Cantivore`, `Cognivore`, `Lord of Extinction`,
   `Magnivore`, `Revenant`, `Slag Fiend`, and `Terravore`.
10. PG345 promoted the exact
   `xmage_static_source_boost_if_graveyard_threshold_v1` subpattern for
   `Anurid Barkripper`, `Basking Capybara`, `Frilled Cave-Wurm`,
   `Krosan Beast`, `Metamorphic Wurm`, `Seton's Scout`, and
   `Springing Tiger`.
11. PG346 promoted the exact
    `xmage_static_source_boost_equal_graveyard_count_v1` subpattern for
    `Liliana's Elite`, `Salvage Slasher`, and `Wight of Precinct Six`.
12. PG347 promoted the exact any-graveyard/owner-library extension of
    `xmage_permanent_simple_activated_graveyard_to_library_v1` for
    `Cogwork Archivist`, `Jade-Cast Sentinel`, `Junktroller`,
    `Phyrexian Archivist`, and `Reito Lantern`.
13. PG348 promoted the exact
    `xmage_permanent_simple_activated_graveyard_to_battlefield_v1`
    subpattern for `Doomed Necromancer` and `Protomatter Powder`.
14. PG349 promoted the exact discard-cost extension of
    `xmage_graveyard_simple_activated_self_return_to_battlefield_v1` for
    `Advanced Stitchwing`, `Ghoulsteed`, and `Stitchwing Skaab`.
15. PG350 promoted the exact graveyard-exile-cost extension of
    `xmage_graveyard_simple_activated_self_return_to_battlefield_v1` for
    `Bone Dragon`, `Despoiler of Souls`, and `Scrapheap Scrounger`.
16. PG351 promoted the exact hand self-return discard/sorcery extension of
    `xmage_graveyard_simple_activated_self_return_to_hand_v1` for
    `Kraul Swarm` and `Summoned Dromedary`.
17. PG352 promoted the exact target-player graveyard shuffle-to-library spell
    subpattern for `Dwell on the Past`, `Krosan Reclamation`,
    `Memory's Journey`, and `Stream of Consciousness`.
18. PG353 promoted the exact permanent activated graveyard-to-hand subpattern
    with discard costs for `Tortured Existence` and `Undertaker`, including
    `{B}`, optional tap, and exact any-card or creature-card discard costs.
19. PG354 promoted the exact permanent activated damage restricted-target
    subpattern for `Centaur Archer`, `Chandra's Magmutt`,
    `Crossbow Infantry`, `D'Avenant Archer`, `Duergar Assailant`,
    `Elite Archers`, `Expendable Troops`, `Flamewave Invoker`,
    `Font of Ire`, `Goblin Fireslinger`, `Grapeshot Catapult`,
    `Heavy Ballista`, `Lady Caleria`, `Sacellum Archers`, `Scalding Devil`,
    `Soldier Replica`, `Telim'Tor's Darts`, `Tor Wauki`, `Viridian Scout`,
    `Volcanic Rambler`, `Vulshok Replica`, and `War-Torch Goblin`.
20. PG355 promoted exact destroy restricted-target extensions for
    `Bramblecrush`, `Crush`, `Dark Banishing`, `Dark Betrayal`, `Deathmark`,
    `Exorcist`, `Go for the Throat`, `Hero's Demise`, `Joven`, `Saltblast`,
    `Terror // Terror`, and `Ultimate Price`.
21. PG356 promoted exact ETB graveyard-to-library extensions for
    `Biblioplex Assistant`, `Monastery Messenger`, `Nantuko Tracer`, and
    `Swiftgear Drake`, including self-graveyard instant/sorcery and
    noncreature/nonland filters plus any-graveyard to owner's-library bottom
    movement.
22. PG357 promoted the exact creature dies recursion keyword-normalization
    extension for `Junk Diver`, allowing leading static combat keywords such as
    `Flying` before the `When this creature dies...` Oracle trigger.
23. PG358 promoted the exact creature ETB graveyard-to-hand recursion
    `spirit_instant_or_sorcery` target extension for `Returned Pastcaller`,
    preserving `Flying` metadata and constraining the graveyard target to a
    Spirit, instant, or sorcery card.
24. PG359 promoted the exact graveyard-to-hand shared creature type spell
    extension for `Aphetto Dredging`, preserving `up_to_count=true` so the
    runtime can return fewer than three matching creature cards when only a
    partial shared-type group is available.
25. PG360 promoted the exact static graveyard-count source boost filter
    extension for `Runaway Trash-Bot` and `Xande, Dark Mage`, preserving
    artifact-or-enchantment and noncreature/nonland graveyard filters inside
    `xmage_static_source_boost_equal_graveyard_count_v1`.
26. PG361 promoted the exact graveyard-to-battlefield spell selection
    constraint extension for `Behold the Sinister Six!`, `Brought Back`,
    `Continue?`, `Grim Return`, `March from the Tomb`, and `Patch Up`,
    preserving total mana value ceilings, different-name requirements,
    Ally-creature targeting, battlefield-to-graveyard-this-turn filters, and
    tapped entry where Oracle/XMage require it.
18. PG336 is applied, synced, and E2E validated. The package evidence is in
   `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_package.md`,
   `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_pg_apply_evidence.md`,
   and
   `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_e2e_validation.md`.
19. PG337 is applied, synced, and E2E validated. The package evidence is in
   `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_package.md`,
   `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_pg_apply_evidence.md`,
   and
   `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_e2e_validation.md`.
20. PG338 is applied, synced, and E2E validated. The package evidence is in
   `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_package.md`,
   `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_pg_apply_evidence.md`,
   and
   `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_e2e_validation.md`.
21. PG339 is applied, synced, and E2E validated. The package evidence is in
   `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_package.md`,
   `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_pg_apply_evidence.md`,
   and
   `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_e2e_validation.md`.
22. PG340 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_pg_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_e2e_validation.md`.
23. PG341 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_e2e_validation.md`.
24. PG342 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_e2e_validation.md`.
25. PG343 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_e2e_validation.md`.
26. PG344 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_e2e_validation.md`.
27. PG345 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_e2e_validation.md`.
28. PG346 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg346_xmage_static_graveyard_count_boost_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg346_xmage_static_graveyard_count_boost_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg346_xmage_static_graveyard_count_boost_wave_e2e_validation.md`.
29. PG347 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_e2e_validation.md`.
30. PG348 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_e2e_validation.md`.
31. PG349 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_e2e_validation.md`.
32. PG350 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg350_xmage_graveyard_self_return_exile_cost_battlefield_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg350_xmage_graveyard_self_return_exile_cost_battlefield_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg350_xmage_graveyard_self_return_exile_cost_battlefield_wave_e2e_validation.md`.
33. PG351 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_e2e_validation.md`.
34. PG352 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_e2e_validation.md`.
35. PG353 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_e2e_validation.md`.
36. PG354 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_e2e_validation.md`.
37. PG355 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_e2e_validation.md`.
38. PG356 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg356_xmage_etb_graveyard_to_library_extended_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg356_xmage_etb_graveyard_to_library_extended_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg356_xmage_etb_graveyard_to_library_extended_wave_e2e_validation.md`.
39. PG357 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg357_xmage_dies_recursion_keyword_fix_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg357_xmage_dies_recursion_keyword_fix_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg357_xmage_dies_recursion_keyword_fix_wave_e2e_validation.md`.
40. PG358 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg358_xmage_returned_pastcaller_recursion_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg358_xmage_returned_pastcaller_recursion_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg358_xmage_returned_pastcaller_recursion_wave_e2e_validation.md`.
41. PG359 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_e2e_validation.md`.
42. PG360 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg360_xmage_static_graveyard_extended_filters_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg360_xmage_static_graveyard_extended_filters_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg360_xmage_static_graveyard_extended_filters_wave_e2e_validation.md`.
43. PG361 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg361_xmage_recursion_battlefield_selection_constraints_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg361_xmage_recursion_battlefield_selection_constraints_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg361_xmage_recursion_battlefield_selection_constraints_wave_e2e_validation.md`.
44. PG362 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_e2e_validation.md`.
45. PG363 is applied, synced, and E2E validated. The package evidence is in
    `docs/hermes-analysis/master_optimizer_reports/pg363_recursion_x_exile_self_wave_package.md`,
    `docs/hermes-analysis/master_optimizer_reports/pg363_recursion_x_exile_self_wave_apply_evidence.md`,
    and
    `docs/hermes-analysis/master_optimizer_reports/pg363_recursion_x_exile_self_wave_e2e_validation.md`.
36. The post-PG344 supported splitter recheck returned `proposal_count=0` over
    `7952` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg344_supported_recheck.md`.
37. The post-PG345 supported splitter recheck returned `proposal_count=0` over
    `7945` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg345_supported_recheck.md`.
38. The post-PG346 supported splitter recheck returned `proposal_count=0` over
    `7942` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg346_supported_recheck.md`.
39. The post-PG347 supported splitter recheck returned `proposal_count=0` over
    `7937` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg347_supported_recheck.md`.
40. The post-PG348 supported splitter recheck returned `proposal_count=0` over
    `7935` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg348_supported_recheck.md`.
41. The post-PG349 supported splitter recheck returned `proposal_count=0` over
    `7932` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg349_supported_recheck.md`.
42. The post-PG350 supported splitter recheck returned `proposal_count=0` over
    `7929` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg350_supported_recheck.md`.
43. The post-PG351 supported splitter recheck returned `proposal_count=0` over
    `7927` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg351_supported_recheck.md`.
44. The post-PG352 supported splitter recheck returned `proposal_count=0` over
    `7923` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg352_supported_recheck.md`.
45. The post-PG353 supported splitter recheck returned `proposal_count=0` over
    `7921` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg353_supported_recheck.md`.
46. The post-PG354 supported splitter recheck returned `proposal_count=0` over
    `7899` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg354_supported_recheck.md`.
47. The post-PG355 supported splitter recheck returned `proposal_count=0` over
    `7887` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg355_supported_recheck.md`.
48. The post-PG356 supported splitter recheck returned `proposal_count=0` over
    `7883` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg356_supported_recheck.md`.
49. The post-PG357 supported splitter recheck returned `proposal_count=0` over
    `7882` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg357_supported_recheck.md`.
50. The post-PG358 supported splitter recheck returned `proposal_count=0` over
    `7881` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg358_supported_recheck.md`.
51. The post-PG359 supported splitter recheck returned `proposal_count=0` over
    `7880` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg359_supported_recheck.md`.
52. The post-PG360 supported splitter recheck returned `proposal_count=0` over
    `7878` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg360_supported_recheck.md`.
53. The post-PG361 supported splitter recheck returned `proposal_count=0` over
    `7872` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg361_supported_recheck.md`.
54. The post-PG362 supported splitter recheck returned `proposal_count=0` over
    `7869` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg362_supported_recheck.md`.
55. The post-PG363 supported splitter recheck returned `proposal_count=0` over
    `7867` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg363_supported_recheck.md`.
56. The post-PG364 supported splitter recheck returned `proposal_count=0` over
    `7865` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg364_supported_recheck.md`.
57. The post-PG365 supported splitter recheck returned `proposal_count=0` over
    `7861` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg365_supported_recheck.md`.
58. PG366 promoted `12` activated draw cost rules and reduced
    `draw_engine::xmage_draw_card_variant_review_v1` from `1646` to `1634`.
    Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_apply_evidence.md`.
59. The post-PG366 supported splitter recheck returned `proposal_count=0` over
    `7849` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg366_supported_recheck.md`.
60. At the post-PG366 checkpoint, the top reusable work unit remained
    `recursion::xmage_graveyard_return_variant_review_v1` at `1834`.
61. PG367 promoted `1` return-all graveyard-to-battlefield rule for
    `Raise the Past`, adding the exact
    `xmage_return_all_matching_graveyard_cards_to_battlefield_spell_v1`
    subpattern while explicitly leaving `Replenish` blocked for Aura attachment
    behavior and `Fix What's Broken` blocked for additional-cost/exact-X
    modeling. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_apply_evidence.md`.
62. The post-PG367 supported splitter recheck returned `proposal_count=0` over
    `7848` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg367_supported_recheck.md`.
63. PG368 promoted `7` graveyard-exile spell rules for `Coffin Purge`,
    `Decompose`, `Fade from Memory`, `Purify the Grave`, `Rapid Decay`,
    `Rats' Feast`, and `Scarab Feast`, adding the exact
    `xmage_exile_target_graveyard_card_spell_v1` subpattern while leaving
    `Shred Memory` blocked because its `TransmuteAbility` auxiliary behavior is
    not supported by the current runtime adapter. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_apply_evidence.md`.
64. The post-PG368 supported splitter recheck returned `proposal_count=0` over
    `7841` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg368_supported_recheck.md`.
65. PG369 promoted `4` activated recursion cost rules for `Ghen, Arcanum
    Weaver`, `Malevolent Awakening`, `Phyrexian Reclamation`, and `Strands of
    Night`, adding pay-life and single target-sacrifice activation costs to the
    existing simple graveyard-to-hand and graveyard-to-battlefield recursion
    scopes. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/pg369_activated_recursion_costs_wave_apply_evidence.md`.
66. The post-PG369 supported splitter recheck returned `proposal_count=0` over
    `7837` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg369_supported_recheck.md`.
67. PG370 promoted `8` static token keyword rules for `Advent of the Wurm`,
    `Call the Cavalry`, `Call to the Feast`, `Jungleborn Pioneer`,
    `Knight Watch`, `Paladin of the Bloodstained`, `Queen's Commission`, and
    `Sworn Companions`, extending simple token creation to runtime-supported
    static token keywords such as trample, vigilance, lifelink, and hexproof.
    Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/pg370_static_token_keywords_wave_apply_evidence.md`.
68. The post-PG370 supported splitter recheck returned `proposal_count=0` over
    `7829` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg370_supported_recheck.md`.
69. PG371 promoted `5` fixed controller life-gain plus draw-card spells:
    `Dosan's Oldest Chant`, `Resupply`, `Revitalize`, `Reviving Dose`, and
    `Ritual of Rejuvenation`, adding
    `xmage_fixed_controller_gain_life_draw_card_spell_v1` through
    `composite_resolution`.
70. PG372 promoted `10` fixed target-creature boost plus draw-card spells:
    `Afflict`, `Aggressive Urge`, `Befuddle`, `Bewilder`, `Defiant Strike`,
    `Fleeting Distraction`, `Rebellious Strike`, `Shocking Grasp`,
    `Sudden Strength`, and `Sugar Rush`, adding
    `xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1`.
71. The final post-PG372 supported splitter recheck returned
    `proposal_count=0` over `7814` considered supported rows. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg372_supported_recheck.md`.
72. PG373-PG376 subsequently promoted the destroy/draw, bounce/draw,
    counter/draw, scry/draw, and damage/draw composite spell waves. Those
    historical queues are no longer the execution baseline.
73. PG377 promoted `32` keyword-until-EOT rows after fixing the exact Oracle
    parser to ignore reminder text in parenthetical clauses for already
    runtime-backed keyword scopes. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/pg377_keyword_reminder_new_server_e2e.md`.
74. PG378 promoted `16` constrained activated target-keyword permanent rows on
    the new server after adding subtype/supertype target legality and full
    `target_constraints` comparison. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/pg378_target_keyword_constraints_new_server_e2e.md`.
75. PG379 promoted `5` fixed direct-damage spell rows on the new server after
    adding supported creature/land sacrifice additional costs to the exact
    mapper and battle runtime. Current evidence:
    `docs/hermes-analysis/master_optimizer_reports/pg379_fixed_damage_sacrifice_cost_new_server_e2e.md`.
76. Continue from the fresh post-PG379 queue. Since the exact splitter is now
    empty again, the next cycle must implement a new mapper/runtime subpattern
    before any PostgreSQL package can be generated.

## Non-Goals

- Do not prioritize only Lorehold, deck `607`, saved decks, or currently
  registered user decks. Those are QA seeds, not the global scope.
- Do not promote generic `xmage_*_review_v1` rows as executable PostgreSQL
  rules.
- Do not treat Hermes SQLite, old generated artifacts, or local JSON as source
  of truth over PostgreSQL.
- Do not count a cycle as successful unless it shrinks a queue dimension or
  leaves an explicit blocker report that changes the next selection.
