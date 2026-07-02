# XMage Global All-Card Completion Goal - 2026-07-01

Status: `active_operational_goal`.

This goal supersedes stale numeric baselines inside thread-level goal text. The
thread goal remains active, but execution must use the current post-PG366
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
- `docs/hermes-analysis/XMAGE_TO_MANALOOM_DEFINITIVE_FLOW_2026-06-29.md`

Post-PG366 counts:

- all known cards: `34331`
- all-card readiness `battle_and_oracle_ready`: `2532`
- all-card readiness `battle_family_mapper_required`: `30015`
- all-card readiness `snapshot_has_verified_rule`: `3680`
- target battle-gap identities in authoritative queue: `27092`
- XMage authoritative source resolved: `26778`
- XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26778`
- adapter work-unit keys: `11429`

## Latest Goal Recheck - 2026-07-02

Current thread goal text still mentions the older post-PG284 baseline. That is
historical only. The active execution baseline is the post-PG366 queue above.

## General Goal Contract - 2026-07-02

Treat this file as the active stop contract for the all-card work. The Codex
thread goal may contain older counts, but execution stops only when a freshly
generated queue proves the terminal stop definition below.

Current post-PG366 control numbers:

- target battle-gap identities: `27092`
- XMage-resolved authoritative source identities: `26778`
- local XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26778`
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
   `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg366_activated_draw_costs_wave_commander_legal.json`.
2. Re-split the top broad unit
   `recursion::xmage_graveyard_return_variant_review_v1` (`1834` identities)
   by exact XMage effect, ability, target, cost, zone movement, and Oracle text.
3. Promote only a narrow subpattern whose ManaLoom runtime behavior is already
   implemented or implemented in the same cycle.
4. If recursion produces no safe batch, record blocker counts and move to the
   next largest work units in order: draw engine, protection, direct damage,
   counters, life gain, draw cards, destroy removal, tutor, then targeted
   counters.

Fresh alignment evidence:

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

The next executable work starts from
`docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg366_activated_draw_costs_wave_commander_legal.json`.
The first priority is still
`recursion::xmage_graveyard_return_variant_review_v1` with `1834` remaining
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

Use the post-PG366 authoritative queue unless a newer queue exists:

1. `recursion::xmage_graveyard_return_variant_review_v1` - `1834`
2. `draw_engine::xmage_draw_card_variant_review_v1` - `1634`
3. `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` - `1162`
4. `direct_damage::targeted_damage_variant_v1` - `906`
5. `add_counters::source_add_counters_variant_v1` - `795`
6. `life_gain::xmage_life_gain_variant_review_v1` - `740`
7. `draw_cards::xmage_draw_card_variant_review_v1` - `676`
8. `removal_destroy::targeted_destroy_variant_v1` - `624`
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
60. Continue from the fresh post-PG366 queue. The top reusable work unit remains
    `recursion::xmage_graveyard_return_variant_review_v1`, now at `1834`, so
    the next cycle should split another exact recursion subpattern unless a
    fresher queue changes the ranking.

## Non-Goals

- Do not prioritize only Lorehold, deck `607`, saved decks, or currently
  registered user decks. Those are QA seeds, not the global scope.
- Do not promote generic `xmage_*_review_v1` rows as executable PostgreSQL
  rules.
- Do not treat Hermes SQLite, old generated artifacts, or local JSON as source
  of truth over PostgreSQL.
- Do not count a cycle as successful unless it shrinks a queue dimension or
  leaves an explicit blocker report that changes the next selection.
