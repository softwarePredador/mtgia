# XMage -> ManaLoom Definitive Flow - 2026-06-29

Status: `current_operating_standard`.

This document supersedes the operational parts of:

- `XMAGE_ABSORPTION_IMPLEMENTATION_PLAN_2026-06-23.md`
- `XMAGE_ABSORPTION_WORKFLOW_V2_2026-06-24.md`
- `XMAGE_ACCELERATION_STRATEGY_DECISION_2026-06-24.md`

Those files remain historical evidence. This file defines the current flow to
use for card-rule acceleration.

Execution contract:

- `BATTLE_RULES_FAMILY_PIPELINE_CONTRACT_2026-06-29.md` freezes how to follow
  this flow day to day.
- `XMAGE_GLOBAL_ALL_CARD_COMPLETION_GOAL_2026-07-01.md` freezes the global
  all-card completion goal, current baseline, and stop criteria.
- If the contract checkpoint passes, do not revalidate the full strategy again;
  rebuild the queue and continue family/subpattern work.

## Decision

Use a staged source-and-gate pipeline:

1. Scryfall/MTGJSON bulk for card identity, Oracle text, layout, legality,
   rulings, and hash inputs.
2. Local XMage as the authoritative open rules-engine behavior source for any
   card with a resolvable local XMage class.
3. Forge as a secondary implementation cross-check for ambiguous or high-risk
   scopes.
4. XMage signal extraction into source-authoritative adapter candidates and
   ManaLoom adapter work units.
5. Exact-scope adapter/runtime support per family/subpattern.
6. PostgreSQL executable package only after adapter support, tests, and
   precheck evidence.
7. PostgreSQL -> Hermes/SQLite sync and replay/audit validation after apply.

The definitive rule: resolved local XMage source is final behavior truth for
that card. Broad XMage extraction may create source-authoritative adapter
candidates in bulk, but a candidate becomes executable ManaLoom battle truth
only when the matching runtime adapter exists and the PostgreSQL package passes
precheck/apply/postcheck.

## Global All-Card Scope

As of 2026-07-01, card-rule acceleration is global over every PostgreSQL
`cards` row known by ManaLoom. Lorehold, saved decks, learned decks, and replay
usage are QA/validation seeds only; they are not the base scope and must not be
treated as market-demand proxies.

Use
`docs/hermes-analysis/manaloom-knowledge/scripts/global_card_oracle_battle_readiness.py`
to route the all-card inventory before creating a battle-family batch. The
current report is:

- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_all_cards_post_legalities_v5_demand_corrected.md`

Current routing rules:

- Start from `cards`. Left join current deck usage only for QA and smoke-test
  sampling; do not use it as launch/user-demand priority.
- Sync Oracle/legalities first. The 2026-07-01 global legalities apply upserted
  `56304` rows into `card_legalities`, reducing `missing_all_legalities` to
  `0` and `missing_commander_legality` to `3`.
- Treat blank Oracle text on vanilla/no-rules cards as a generic/no-card-rule
  lane, not as a battle mapper or Oracle backfill blocker.
- Count trusted battle coverage by `card_id` or by the existing
  `card_battle_rules.normalized_name + logical_rule_key` storage key. Do not
  create duplicate work for reprints already covered by normalized name.
- Use `oracle_id` rule propagation only for true alias/double-face gaps where
  neither `card_id` nor normalized name already has trusted coverage.

## All-Card Acceleration Model

Do not schedule all-card adaptation as 33k card-row tickets. Use
`docs/hermes-analysis/manaloom-knowledge/scripts/global_card_adaptation_acceleration_model.py`
to convert the backlog into product-priority identities, templates, and
residual families.

Current evidence:

- `docs/hermes-analysis/master_optimizer_reports/global_card_adaptation_acceleration_model_20260701_demand_corrected.md`

Current measured compression:

- all card rows: `34331`
- battle-gap rows: `31772`
- Commander-legal battle-gap identities: `28835`
- external-popularity battle-gap identities: `345`
- current registered-deck QA battle-gap identities: `1511`
- ready-product QA battle-gap identities: `232`
- template-first matched rows: `10285`
- template-first matched Commander-legal identities: `9386`
- template-first matched external-popularity identities: `218`
- template-first matched registered-deck QA identities: `644`
- template + residual family planning units: `28`

Interpretation:

- The immediate launch modeling queue is not the `1511` currently registered
  deck identities. Those cards are a QA seed because the current corpus was
  manually registered by the operator and is not representative of future user
  imports.
- The first implementation wave should target generic templates by global
  Commander-legal breadth, with external popularity/staple signals as secondary
  ordering: fixed token creation, fixed draw, fixed direct damage, mana
  production, targeted destroy/exile, counter target spell, scry/surveil, land
  tutor, graveyard return, and protection-until-end-of-turn.
- Residual high-volume families still require XMage split/scope review, but
  they should be scheduled as family/subpattern units, never as a card-by-card
  backlog.

## XMage Authoritative Adaptation Queue

As of 2026-07-01, the project no longer treats resolved local XMage classes as
mere review hints. For every target card where local XMage resolves a Java card
class, XMage is the final card-behavior source and ManaLoom's remaining work is
adapter/runtime translation.

Use
`docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_adaptation_queue.py`
to build this queue. Current evidence:

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg344_static_graveyard_count_pt_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg344_static_graveyard_count_pt_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg345_static_graveyard_threshold_boost_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg345_static_graveyard_threshold_boost_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg346_static_graveyard_count_boost_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg346_static_graveyard_count_boost_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg347_activated_graveyard_to_owner_library_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg347_activated_graveyard_to_owner_library_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg348_activated_graveyard_to_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg348_activated_graveyard_to_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg355_destroy_restricted_target_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg355_destroy_restricted_target_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg356_etb_graveyard_to_library_extended_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg356_etb_graveyard_to_library_extended_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg357_dies_recursion_keyword_fix_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg357_dies_recursion_keyword_fix_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg358_returned_pastcaller_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg358_returned_pastcaller_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg359_aphetto_shared_type_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg359_aphetto_shared_type_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg360_static_graveyard_extended_filters_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg360_static_graveyard_extended_filters_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg362_recursion_x_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg362_recursion_x_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg363_recursion_x_exile_self_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg363_recursion_x_exile_self_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg364_multi_target_recursion_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg364_multi_target_recursion_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg365_battlefield_recursion_constraints_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg365_battlefield_recursion_constraints_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg366_activated_draw_costs_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg366_activated_draw_costs_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg367_return_all_graveyard_battlefield_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg367_return_all_graveyard_battlefield_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg368_graveyard_exile_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg368_graveyard_exile_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg369_activated_recursion_costs_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg369_activated_recursion_costs_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg374_bounce_draw_spell_wave_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg374_bounce_draw_spell_wave_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg375_counter_draw_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg375_counter_draw_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg376_scry_damage_draw_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg376_scry_damage_draw_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg377_keyword_reminder_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg377_keyword_reminder_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg378_target_keyword_constraints_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg378_target_keyword_constraints_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg379_fixed_damage_sacrifice_cost_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg380_activated_draw_discard_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg380_activated_draw_discard_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg381_activate_as_sorcery_recursion_battlefield_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg381_activate_as_sorcery_recursion_battlefield_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg382_draw_additional_cost_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg382_draw_additional_cost_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg383_target_effect_scry_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg383_target_effect_scry_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg384_additional_cost_spell_runtime_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg384_additional_cost_spell_runtime_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg385_draw_discard_spell_runtime_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg385_draw_discard_spell_runtime_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg386_draw_lose_life_spell_runtime_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg386_draw_lose_life_spell_runtime_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg387_etb_draw_lose_life_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg387_etb_draw_lose_life_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg388_etb_tutor_battlefield_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg388_etb_tutor_battlefield_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg389_multi_zone_recursion_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg389_multi_zone_recursion_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg390_damage_exile_if_dies_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg390_damage_exile_if_dies_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg391_target_player_draw_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg391_target_player_draw_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg392_activated_draw_discard_cost_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg392_activated_draw_discard_cost_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg393_simple_mana_auxiliary_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg393_simple_mana_auxiliary_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg393_simple_mana_auxiliary_new_server_after_hash_cleanup_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg393_simple_mana_auxiliary_new_server_after_hash_cleanup.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg394_dies_create_tokens_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg394_dies_create_tokens_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg395_dies_life_gain_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg395_dies_life_gain_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg396_dies_damage_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg396_dies_damage_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg397_activated_damage_keywords_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg397_activated_damage_keywords_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg398_mana_source_activated_draw_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg398_mana_source_activated_draw_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg399c_hash_backfill_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg399c_hash_backfill_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg399c_hash_backfill_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg400_play_lands_from_graveyard_new_server_candidate.md`
- `docs/hermes-analysis/master_optimizer_reports/pg400_play_lands_from_graveyard_new_server_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg400_play_lands_from_graveyard_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg400_play_lands_from_graveyard_new_server_metadata_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg400_play_lands_from_graveyard_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg400_play_lands_from_graveyard_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg400_play_lands_from_graveyard_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg400_play_lands_from_graveyard_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg400_play_lands_from_graveyard_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg400_play_lands_from_graveyard_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg400_play_lands_from_graveyard_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg400_play_lands_from_graveyard_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg401_dynamic_graveyard_damage_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg401_dynamic_graveyard_damage_new_server_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg401_dynamic_graveyard_damage_new_server_apply_evidence.md`
- `docs/hermes-analysis/master_optimizer_reports/pg401_dynamic_graveyard_damage_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg401_dynamic_graveyard_damage_new_server_metadata_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg401_dynamic_graveyard_damage_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg401_dynamic_graveyard_damage_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg401_dynamic_graveyard_damage_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg401_dynamic_graveyard_damage_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg401_dynamic_graveyard_damage_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg401_dynamic_graveyard_damage_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg401_dynamic_graveyard_damage_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg401_dynamic_graveyard_damage_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg402_arcane_self_sacrifice_recursion_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg402_arcane_self_sacrifice_recursion_new_server_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg402_arcane_self_sacrifice_recursion_new_server_apply_evidence.md`
- `docs/hermes-analysis/master_optimizer_reports/pg402_arcane_self_sacrifice_recursion_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg402_arcane_self_sacrifice_recursion_new_server_metadata_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg402_oracle_hash_integrity_backfill_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg402_arcane_self_sacrifice_recursion_new_server_after_hash_backfill_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg402_arcane_self_sacrifice_recursion_new_server_after_hash_backfill_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg402_arcane_self_sacrifice_recursion_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg402_arcane_self_sacrifice_recursion_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg402_arcane_self_sacrifice_recursion_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg402_arcane_self_sacrifice_recursion_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg402_arcane_self_sacrifice_recursion_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg402_arcane_self_sacrifice_recursion_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg402_arcane_self_sacrifice_recursion_new_server_after_hash_backfill_final.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg403_dynamic_graveyard_count_boost_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_apply_evidence.md`
- `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_metadata_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg403_dynamic_graveyard_count_boost_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg403_dynamic_graveyard_count_boost_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg403_dynamic_graveyard_count_boost_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg403_dynamic_graveyard_count_boost_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg403_dynamic_graveyard_count_boost_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg403_dynamic_graveyard_count_boost_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg403_dynamic_graveyard_count_boost_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg403_dynamic_graveyard_count_boost_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg404_dynamic_count_boost_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg404_dynamic_count_boost_new_server_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg404_dynamic_count_boost_new_server_apply_evidence.md`
- `docs/hermes-analysis/master_optimizer_reports/pg404_dynamic_count_boost_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg404_dynamic_count_boost_new_server_metadata_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg404_dynamic_count_boost_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg404_dynamic_count_boost_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg404_dynamic_count_boost_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg404_dynamic_count_boost_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg404_dynamic_count_boost_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg404_dynamic_count_boost_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg404_dynamic_count_boost_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg404_dynamic_count_boost_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg405_dynamic_count_damage_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg405_dynamic_count_damage_new_server_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg405_dynamic_count_damage_new_server_apply_evidence.md`
- `docs/hermes-analysis/master_optimizer_reports/pg405_dynamic_count_damage_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg405_dynamic_count_damage_new_server_metadata_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg405_dynamic_count_damage_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg405_dynamic_count_damage_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260704_post_pg405_dynamic_count_damage_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg405_dynamic_count_damage_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/pg405_oracle_hash_integrity_backfill_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg405_oracle_hash_integrity_backfill_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg405_dynamic_count_damage_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg405_dynamic_count_damage_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg405_dynamic_count_damage_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg405_dynamic_count_damage_new_server_after_hash_backfill_final.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_pg408_mana_etb_draw_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_package_package.md`
- `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_apply_evidence.md`
- `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_pg_to_sqlite_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg408_mana_etb_draw_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260704_post_pg408_mana_etb_draw_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260704_post_pg408_mana_etb_draw_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260704_post_pg408_mana_etb_draw_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260704_post_pg408_mana_etb_draw_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260704_post_pg408_mana_etb_draw_new_server_after_docs_final.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260704_post_pg408_mana_etb_draw_new_server_after_docs_final.md`

Current measured queue:

- target all-card battle-gap identities: `26667`
- XMage authoritative source resolved: `26353`
- local XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `26353`
- ManaLoom adapter work-unit keys: `11427`
- authoritative source coverage ratio: `0.9882`

Interpretation:

- The old mental model, "review 28k cards manually", is wrong.
- For `26353` identities, card semantics are accepted from XMage; work is now
  adapter implementation and effect-family classification.
- `314` identities remain residual exceptions because the local XMage checkout
  did not resolve a source class in the all-card scope. These are a separate
  official/Forge/manual-model or product-exclusion lane, not a reason to slow
  the XMage-resolved adapter queue.
- Generic `xmage_*_review_v1` scopes and fallback manual-model hints are
  adapter work-unit names. Fallback hints must be split by real XMage Java
  class/effect/ability signatures; they are blocked only from executable PG
  promotion until ManaLoom has the matching runtime adapter.
- Card-specific `token_maker` scopes generated as
  `xmage_create_token_variant_<card>_v1` are planning artifacts, not real
  family boundaries. They must be grouped by XMage signature before scheduling
  a token wave.
- This goal stops only when the refreshed global queue has no remaining
  `xmage_authoritative_adapter_required`, no `xmage_authoritative_parser_gap`,
  and every `xmage_missing_source_exception` is classified into an explicit
  official/Forge/manual-model or product-exclusion lane with evidence.

## PG283-PG405 Exact Adapter And Integrity Waves

As of 2026-07-04, the PG283-PG405 all-card exact adapter waves are applied and
synced. PG375-PG405 and the PG399b/PG399c/PG402 integrity backfills were applied
against the new EasyPanel PostgreSQL target via the new-server tunnel and
validated with `database_target=127.0.0.1:15432/halder`.

Use
`docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
after building the authoritative queue. This splitter is the required bridge
between broad XMage work units and PostgreSQL package candidates. It only
selects narrow, runtime-backed signatures and blocks modes, variables,
additional costs, conditional costs, compound effects, and unsupported target
patterns:

- `draw_cards::xmage_draw_card_variant_review_v1` ->
  `xmage_fixed_source_controller_draw_spell_v1`
- `draw_cards::xmage_draw_card_variant_review_v1` with fixed
  `DrawCardTargetEffect`, exact "Target player draws N cards" Oracle/source
  text, and player target metadata ->
  `xmage_fixed_target_player_draw_spell_v1`.
- `draw_cards::xmage_draw_card_variant_review_v1` with fixed
  `DrawCardSourceControllerEffect + SpellCostReductionSourceEffect`, generic
  self-spell cost reduction only, and a runtime-measurable condition such as
  controlled subtype, controlled creature keyword, opponent graveyard count,
  opponent poison counters, delirium, or controlled Human plus non-Human
  creature ->
  `xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1`.
- `direct_damage::targeted_damage_variant_v1` ->
  `xmage_fixed_damage_target_spell_v1`
- `direct_damage::targeted_damage_variant_v1` with fixed `DamageTargetEffect`
  one-shot spells and exact supported XMage additional costs remains in
  `xmage_fixed_damage_target_spell_v1` with structured `additional_cost` and
  runtime payment before damage resolution. Supported spell costs currently
  include discard a card, sacrifice a creature, sacrifice a land, and sacrifice
  an artifact or creature.
- `direct_damage::targeted_damage_variant_v1` with one-shot
  `DamageTargetEffect` whose amount is an exact supported game-state count,
  no additional cost, Oracle/source agreement, and supported targets including
  any target, creature, creature-or-planeswalker, player-or-planeswalker,
  attacking creature, attacking-or-blocking creature, and tapped creature ->
  `xmage_dynamic_count_damage_spell_v1`. Supported amount sources are
  controller battlefield permanent counts by type/subtype, attacking-creature
  battlefield counts, controller hand count, and domain basic land type count,
  with optional fixed base amount.
- `direct_damage::targeted_damage_variant_v1` with one-shot
  `DamageTargetEffect(GetXValue.instance)` or
  `DamageTargetEffect(ManacostVariableValue.instance)`, exact "deals X damage"
  Oracle/source agreement, and no auxiliary ability class ->
  `xmage_x_damage_target_spell_v1`. This scope reads the chosen cast `x_value`
  at runtime. It deliberately blocks X-damage cards with buyback, alternative
  cast timing such as pay-more-as-flash, "where X is ..." game-state counts,
  divided damage, or additional costs until those families have their own
  adapters.
- `draw_cards::xmage_draw_card_variant_review_v1` with exact supported spell
  additional costs remains in `xmage_fixed_source_controller_draw_spell_v1`
  when the runtime pays that cost before drawing.
- `draw_cards::xmage_draw_card_variant_review_v1` with exact fixed
  `DrawDiscardControllerEffect` or fixed
  `DrawCardSourceControllerEffect + DiscardControllerEffect`, no extra ability
  class, and Oracle/source order agreement ->
  `xmage_fixed_draw_discard_spell_v1`.
- `removal_destroy::targeted_destroy_variant_v1` ->
  `xmage_destroy_target_spell_v1`
- `removal_destroy::targeted_destroy_variant_v1` with exact supported spell
  additional costs remains in `xmage_destroy_target_spell_v1` when the runtime
  pays that cost before target removal.
- `life_gain::xmage_life_gain_variant_review_v1` ->
  `xmage_fixed_controller_gain_life_spell_v1`
- `life_gain::xmage_life_gain_variant_review_v1` with
  `DamageTargetEffect + GainLifeEffect` and exact fixed damage/life-gain
  Oracle/source text ->
  `xmage_fixed_damage_target_and_controller_gain_life_spell_v1`
- `life_gain::xmage_life_gain_variant_review_v1` with
  `DestroyTargetEffect + GainLifeEffect`, one supported simple target, fixed
  controller life-gain amount, and exact destroy/gain-life Oracle text ->
  `xmage_destroy_target_and_controller_gain_life_spell_v1`
- `life_gain::xmage_life_gain_variant_review_v1` with
  `GainLifeEffect + DrawCardSourceControllerEffect`, exact fixed "You gain N
  life. Draw a card." Oracle/source text, and composite runtime resolution ->
  `xmage_fixed_controller_gain_life_draw_card_spell_v1`
- `draw_cards::xmage_draw_card_variant_review_v1` with
  `BoostTargetEffect + DrawCardSourceControllerEffect`, exact fixed "Target
  creature gets X/Y until end of turn. Draw a card." Oracle/source text, and
  composite runtime resolution without double-finishing the spell ->
  `xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1`
- `draw_cards::xmage_draw_card_variant_review_v1` with
  `DestroyTargetEffect + DrawCardSourceControllerEffect`, exact fixed
  "Destroy target ... Draw a card." Oracle/source text, a supported single
  battlefield target constraint, and composite runtime resolution without
  double-finishing the spell ->
  `xmage_destroy_target_and_draw_card_spell_v1`
- `draw_cards::xmage_draw_card_variant_review_v1` with
  `ReturnToHandTargetEffect + DrawCardSourceControllerEffect`, exact fixed
  "Return target ... to its owner's hand. Draw a card." Oracle/source text, a
  supported single battlefield target constraint, and composite runtime
  resolution using the removal destination helper so the target moves to hand
  rather than graveyard ->
  `xmage_return_target_to_hand_and_draw_card_spell_v1`
- `draw_cards::xmage_draw_card_variant_review_v1` with
  `CounterTargetEffect + DrawCardSourceControllerEffect`, exact supported
  "Counter target ... spell. Draw a card." Oracle/source text, stack-target
  constraints already supported by the counter runtime, and draw-on-counter
  metadata exercised by focused stack-response tests ->
  `xmage_counter_target_and_draw_card_spell_v1`
- `life_gain::xmage_life_gain_variant_review_v1` with
  `GainLifeEffect + EntersBattlefieldTriggeredAbility` on creatures and fixed
  Oracle/source amount ->
  `xmage_creature_etb_gain_life_v1`
- `life_gain::xmage_life_gain_variant_review_v1` with
  `GainLifeEffect + DiesSourceTriggeredAbility` on creatures, optional static
  self keywords only, exact fixed "when this creature/name dies, you gain N
  life" Oracle/source amount, and the battlefield-to-graveyard runtime hook ->
  `xmage_creature_dies_gain_life_v1`
- `life_gain::xmage_life_gain_variant_review_v1` with
  `GainLifeEffect + SimpleActivatedAbility` on battlefield permanents, exact
  fixed activated life-gain Oracle/source text, mana/tap/source self-sacrifice
  costs only, and no target sacrifice, discard, exile, graveyard, variable, or
  compound cost/effect text ->
  `xmage_permanent_simple_activated_life_gain_v1`
- `xmage_signature::BoostControlledEffect::SimpleStaticAbility::no_target_class::no_condition_class::static_ability`
  with exact permanent static controlled-creature power/toughness boosts,
  simple creature/artifact/subtype/legendary filters, exact Oracle/source
  agreement, and runtime refresh that avoids cumulative static deltas ->
  `xmage_static_controlled_power_toughness_boost_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` /
  `xmage_signature::SetBasePowerToughnessSourceEffect::SimpleStaticAbility::*`
  with direct XMage graveyard card-count dynamic values, exact Oracle text
  saying source power and toughness are each equal to matching controller or
  all-graveyard card counts, and only optional self combat keywords ->
  `xmage_static_source_power_toughness_equal_graveyard_count_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` /
  `xmage_signature::BoostSourceEffect,ConditionalContinuousEffect::SimpleStaticAbility::*`
  with exact Threshold/Descend 4 source power/toughness boosts gated by
  controller graveyard card count, exact Oracle/source agreement, supported
  `card` or `permanent` graveyard filters, and only optional self combat
  keywords ->
  `xmage_static_source_boost_if_graveyard_threshold_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` /
  `xmage_signature::BoostSourceEffect::SimpleStaticAbility::*` with exact
  static source power/toughness boost equal to controller or opponents'
  graveyard artifact/creature card count, controller graveyard
  artifact-or-enchantment count, or controller graveyard noncreature/nonland
  card count, exact Oracle/source agreement, and only optional self combat
  keywords ->
  `xmage_static_source_boost_equal_graveyard_count_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` /
  `xmage_signature::BoostTargetEffect::*::TargetCreaturePermanent::*` with
  exact one-shot target-creature power/toughness boost or reduction until end
  of turn where the dynamic value is the number of matching cards in the
  controller's graveyard, using `CardsInControllerGraveyardCount` with
  supported all-card or creature-card filters, no extra costs, and no
  composite fixed-plus-dynamic named-card formula ->
  `xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` /
  `xmage_signature::PutOnLibraryTargetEffect::SimpleActivatedAbility::*` with
  exact permanent activated abilities that put target card from any graveyard on
  the bottom of its owner's library, supported mana/tap costs, and optional
  self combat keywords ->
  `xmage_permanent_simple_activated_graveyard_to_library_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `PlayFromGraveyardControllerEffect + SimpleStaticAbility`, exact Oracle text
  "You may play lands from your graveyard.", and exact XMage
  `PlayFromGraveyardControllerEffect.playLands()` source ->
  `xmage_static_play_lands_from_graveyard_v1`. This scope deliberately blocks
  extra unmodeled ability classes such as `UnearthAbility` and the broader
  `playLandsAndCastSpells(...)` variants until their combined runtime contract
  exists.
- `draw_engine::xmage_draw_card_variant_review_v1` with
  `DrawCardSourceControllerEffect + EntersBattlefieldTriggeredAbility` on
  creatures and fixed Oracle/source draw count ->
  `xmage_creature_etb_draw_cards_v1`
- `draw_engine::xmage_draw_card_variant_review_v1` with
  `DrawCardSourceControllerEffect + DiesSourceTriggeredAbility` on creatures,
  optional static self keywords, and exact fixed "When/Whenever this creature
  dies, draw N cards" Oracle text ->
  `xmage_creature_dies_draw_cards_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToHandTargetEffect + DiesSourceTriggeredAbility` on
  creatures, optional static self combat keywords before the trigger, exact
  "When this creature dies, return another target artifact card from your
  graveyard to your hand" Oracle/source agreement, and focused runtime coverage
  that excludes the source card itself ->
  `xmage_creature_dies_return_graveyard_card_to_hand_v1`
- `draw_engine::xmage_draw_card_variant_review_v1` with
  `DrawCardSourceControllerEffect + SimpleActivatedAbility` on permanents,
  exact fixed Oracle activated draw text, mana/tap/source self-sacrifice costs,
  exact `PayLifeCost`, exact generic `DiscardCardCost` / `DiscardTargetCost`
  for "discard a card", or exact sacrifice-target costs for supported
  permanent filters where XMage and Oracle agree, and no filtered discard,
  target-tap, graveyard, or dynamic "for each" costs ->
  `xmage_permanent_simple_activated_draw_v1`
- `draw_engine::xmage_draw_card_variant_review_v1` with
  `DrawCardSourceControllerEffect + SpellCastControllerTriggeredAbility` on
  permanents, exact fixed draw count, and supported spell filters for
  creature/enchantment/artifact/noncreature spells, legendary or historic
  spells, aura/equipment/vehicle subtype OR filters, graveyard source-zone
  triggers, and mana-value thresholds ->
  `xmage_spell_cast_draw_engine_v1`
- `direct_damage::targeted_damage_variant_v1` with `DamageTargetEffect +
  EntersBattlefieldTriggeredAbility` on creatures and exact fixed ETB damage
  Oracle text ->
  `xmage_creature_etb_fixed_damage_target_v1`
- `removal_destroy::targeted_destroy_variant_v1` with
  `DestroyTargetEffect + EntersBattlefieldTriggeredAbility` on creatures and
  exact unrestricted ETB destroy Oracle text ->
  `xmage_creature_etb_destroy_target_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToHandTargetEffect + EntersBattlefieldTriggeredAbility`
  on creatures, optional static self combat keywords, and exact unrestricted
  ETB graveyard-to-hand Oracle text ->
  `xmage_creature_etb_return_graveyard_card_to_hand_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToHandTargetEffect + EntersBattlefieldTriggeredAbility`
  on creatures, optional static self combat keywords, exact Oracle/source
  agreement, and supported constrained ETB targets including subtype cards
  (`Knight`, `Mercenary`), artifact/permanent/creature cards with mana-value
  ceilings, instant and/or sorcery cards, and creature-or-Food cards ->
  `xmage_creature_etb_return_graveyard_card_to_hand_v1`
- `direct_damage::targeted_damage_variant_v1` with
  `DamageTargetEffect + SimpleActivatedAbility` on creatures, exact Oracle
  `{T}: ... deals N damage ...`, XMage `TapSourceCost` only, and no mana or
  sacrifice cost ->
  `xmage_creature_tap_fixed_damage_target_activated_v1` with nested
  `xmage_tap_fixed_damage_target_activated_ability_v1`
- `direct_damage::targeted_damage_variant_v1` with
  `DamageTargetEffect + SimpleActivatedAbility` on permanents, exact fixed
  activated damage Oracle text, mana/tap/self-sacrifice source costs only, and
  simple `any target`, `target creature`, `target player or planeswalker`, or
  exact source/Oracle-matched restricted battlefield targets for
  attacking/blocking creatures, blocking creatures, and creatures with flying ->
  `xmage_permanent_simple_activated_damage_v1`
- `removal_destroy::targeted_destroy_variant_v1` with
  `DestroyTargetEffect + SimpleActivatedAbility` on permanents, exact activated
  destroy-target Oracle text, mana/tap/source self-sacrifice costs only, no
  discard/exile/OrCost/CompositeCost/sacrifice-target costs, and supported
  battlefield target constraints ->
  `xmage_permanent_simple_activated_destroy_target_v1`
- `removal_destroy::targeted_destroy_variant_v1` with
  `DestroyTargetEffect` and exact source/Oracle-matched restricted battlefield
  targets for noncreature permanents/artifacts, color-restricted creatures or
  permanents, nonartifact creatures, legendary creatures, and monocolored
  creatures ->
  `xmage_destroy_target_spell_v1` or
  `xmage_permanent_simple_activated_destroy_target_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToHandTargetEffect + SimpleActivatedAbility` on
  permanents, exact Oracle activated graveyard-to-hand text, mana/tap/source
  self-sacrifice costs only, exact `DiscardCardCost` or creature-card discard
  cost only when source and Oracle agree, no exile/OrCost/CompositeCost, and
  supported graveyard targets including creature, artifact, enchantment,
  artifact creature, basic land, permanent, instant/sorcery, Arcane subtype
  cards, artifact or enchantment, and any card when source and Oracle agree ->
  `xmage_permanent_simple_activated_graveyard_to_hand_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToBattlefieldTargetEffect + SimpleActivatedAbility` on
  battlefield permanents, exact Oracle activated graveyard-to-battlefield text,
  mana/tap/source self-sacrifice costs only, self graveyard only, battlefield
  under the source controller only, and supported creature/artifact targets
  with exact Oracle/source agreement ->
  `xmage_permanent_simple_activated_graveyard_to_battlefield_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `PutOnLibraryTargetEffect + SimpleActivatedAbility` on battlefield
  permanents, exact Oracle activated graveyard-to-library text, mana/tap/source
  self-sacrifice costs only, self graveyard only, self library only, and
  supported targets `any card` or `creature card` with top/bottom destination
  agreement between Oracle and XMage source ->
  `xmage_permanent_simple_activated_graveyard_to_library_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `PutOnLibraryTargetEffect + EntersBattlefieldTriggeredAbility` on creatures,
  exact Oracle/source agreement, self graveyard only, self library only, and
  supported targets `artifact or creature` and `instant or sorcery` with
  top/bottom destination agreement between Oracle and XMage source ->
  `xmage_creature_etb_put_graveyard_card_on_library_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `TargetPlayerShufflesTargetCardsEffect` on instant/sorcery spells, exact
  Oracle/source agreement, `TargetPlayer`, and
  `TargetCardInTargetPlayersGraveyard(N)` for up to N target cards from that
  player's graveyard shuffled into that player's library. `FlashbackAbility`
  is allowed only when Oracle and XMage flashback costs match ->
  `xmage_put_target_graveyard_card_on_library_spell_v1` with
  `destination=library_shuffle`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnSourceFromGraveyardToHandEffect + SimpleActivatedAbility` in
  `Zone.GRAVEYARD`, mana-only activation cost, exact self-return Oracle/source
  text, and only optional static self keywords or enters-tapped text ->
  `xmage_graveyard_simple_activated_self_return_to_hand_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnSourceFromGraveyardToHandEffect + SimpleActivatedAbility` or
  `ActivateAsSorceryActivatedAbility` in `Zone.GRAVEYARD`, exact self-return
  Oracle/source text, simple mana activation cost, optional exact discard-one
  creature-card cost, optional sorcery-speed activation, and only optional
  static self keywords or enters-tapped text ->
  `xmage_graveyard_simple_activated_self_return_to_hand_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnSourceFromGraveyardToBattlefieldEffect + SimpleActivatedAbility` in
  `Zone.GRAVEYARD`, mana-only activation cost, exact self-return Oracle/source
  text, and tapped battlefield entry ->
  `xmage_graveyard_simple_activated_self_return_to_battlefield_v1`
- `xmage_signature::BoostSourceEffect::SimpleActivatedAbility::no_target_class::no_condition_class::activated_ability`
  with exact activated self power/toughness boost text, battlefield permanents,
  simple mana/tap source costs only, no life/discard/sacrifice-target/untap or
  target-tap costs, no hybrid/Phyrexian/untap-symbol costs, no dynamic X boost,
  and no modal/compound text ->
  `xmage_permanent_simple_activated_self_boost_until_eot_v1`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
  with `GainAbilityTargetEffect + SimpleActivatedAbility`, exact activated
  target-creature gains keyword until end of turn text, battlefield permanents,
  simple mana/tap source costs only, no source sacrifice, no subtype-filtered
  targets, and supported keywords `haste`, `flying`, `trample`, and
  `first_strike` ->
  `xmage_permanent_simple_activated_target_keyword_until_eot_v1`
- `xmage_signature::BoostTargetEffect::SimpleActivatedAbility::TargetCreaturePermanent::no_condition_class::targeting,activated_ability`
  with exact activated target-creature power/toughness modifier until end of
  turn text, battlefield permanents, simple mana/tap/source self-sacrifice costs
  only, no sacrifice-target costs, no filtered targets, no dynamic modifiers,
  no multi-target text, and no compound activated text ->
  `xmage_permanent_simple_activated_target_boost_until_eot_v1`
- `removal_exile::targeted_exile_variant_v1` ->
  `xmage_exile_target_spell_v1`
- fixed damage, destroy and exile target spells with XMage/Oracle-matched
  restricted battlefield target constraints for attacking/blocking,
  tapped/untapped, flying, color inclusion/exclusion, power minimum, and mana
  value minimum targets remain in those same exact scopes with structured
  `target_constraints`.
- `direct_damage::targeted_damage_variant_v1` with fixed `DamageTargetEffect +
  ScryEffect`, exact same-spell Oracle/source agreement, supported single target
  constraint, and fixed scry count ->
  `xmage_fixed_damage_target_and_scry_spell_v1`
- `removal_destroy::targeted_destroy_variant_v1` with fixed
  `DestroyTargetEffect + ScryEffect`, exact same-spell Oracle/source agreement,
  supported single target constraint including `power_min=3`, and fixed scry
  count ->
  `xmage_destroy_target_and_scry_spell_v1`
- `removal_exile::targeted_exile_variant_v1` with fixed `ExileTargetEffect +
  ScryEffect`, exact same-spell Oracle/source agreement, supported single target
  constraint, and fixed scry count ->
  `xmage_exile_target_and_scry_spell_v1`; this scope exists in the splitter,
  but PG383 had no safe PostgreSQL candidates because the current residual
  cards require unsupported target constraints.
- `bounce::targeted_return_to_hand_variant_v1` with fixed
  `ReturnToHandTargetEffect + ScryEffect`, exact same-spell Oracle/source
  agreement, supported single target constraint, and fixed scry count ->
  `xmage_return_target_to_hand_and_scry_spell_v1`
- `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` and
  `ramp_permanent::xmage_creature_mana_source_variant_review_v1` ->
  `xmage_simple_tap_mana_source_permanent_v1`
- `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` and
  `ramp_permanent::xmage_creature_mana_source_variant_review_v1` may also map
  to `xmage_simple_tap_mana_source_permanent_v1` when one simple tap mana line
  is embedded in multi-line Oracle text and all auxiliary abilities are safe
  static self keywords or `EntersBattlefieldTappedAbility`. Parenthetical mana
  reminders are stripped before matching. Crew, cycling, suspend, alternative
  costs, conditional mana, multiple complex mana abilities, unsafe activated
  abilities, and unsupported auxiliary ability classes remain blocked by
  `mana_source_auxiliary_ability_not_supported` or the narrower mana-source
  blockers.
- `counter_spell::counter_target_stack_object_variant_v1` ->
  `xmage_counter_target_spell_v1`
- `bounce::targeted_return_to_hand_variant_v1` ->
  `xmage_return_target_to_hand_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` ->
  `xmage_return_target_graveyard_card_to_hand_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToBattlefieldTargetEffect`, no ability class, no
  additional cost, and exact self-graveyard single-target Oracle text ->
  `xmage_return_target_graveyard_card_to_battlefield_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToBattlefieldTargetEffect`, no ability class, no
  additional cost, exact self-graveyard Oracle/source agreement, and supported
  battlefield selection constraints for total mana value ceilings,
  different-name requirements, Ally-creature targets, battlefield-to-graveyard
  this-turn filters, and tapped entry ->
  `xmage_return_target_graveyard_card_to_battlefield_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToHandTargetEffect` plus `XTargetsCountAdjuster`, no
  ability class, exact "Return X target creature cards" Oracle/source
  agreement, and `count_from_x` runtime support ->
  `xmage_return_target_graveyard_card_to_hand_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToBattlefieldTargetEffect`, no ability class, exact
  source agreement for either `XManaValueTargetAdjuster(ComparisonType.OR_LESS)`
  or `TargetsCountAdjuster(GetXValue.instance)`, and supported creature or
  outlaw-creature targets ->
  `xmage_return_target_graveyard_card_to_battlefield_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToBattlefieldTargetEffect`, no ability class, exact
  source/Oracle agreement for Fathomless Descent nonland-permanent targets
  whose mana value is limited by permanent cards in the controller's graveyard,
  or choose-one-or-both creature/Aura battlefield recursion components ->
  `xmage_return_target_graveyard_card_to_battlefield_spell_v1` or
  `xmage_return_one_or_both_graveyard_cards_to_battlefield_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with exact
  `ReturnFromGraveyardToBattlefieldTargetEffect +
  ReturnFromGraveyardToHandTargetEffect`, no ability class, no additional
  cost, exact two-component self-graveyard Oracle/source agreement, and
  supported `up to` targets for creature/permanent/nonland permanent/land
  cards moving to hand or battlefield, including tapped battlefield entry ->
  `xmage_return_multi_zone_graveyard_cards_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToBattlefieldTargetEffect + SimpleActivatedAbility` on
  battlefield permanents, exact Oracle/source agreement, mana/tap costs only,
  and supported constraints for creature cards put into the graveyard from the
  battlefield this turn or Rebel permanents with fixed mana-value ceilings ->
  `xmage_permanent_simple_activated_graveyard_to_battlefield_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToHandTargetEffect` or
  `ReturnFromGraveyardToBattlefieldTargetEffect`, safe auxiliary
  `FlashbackAbility` or `CyclingAbility`, exact supported graveyard target
  scope, mana-only flashback cost or fixed cycling cost, and exact primary
  recursion Oracle/source agreement ->
  `xmage_return_target_graveyard_card_to_hand_spell_v1` or
  `xmage_return_target_graveyard_card_to_battlefield_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ExileTargetEffect`, no unsupported auxiliary ability, exact graveyard-card
  Oracle/source agreement, supported `TargetCardInGraveyard` or
  `TargetCardInASingleGraveyard`, optional fixed cycling/flashback, up-to
  counts, and X target counts ->
  `xmage_exile_target_graveyard_card_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ExileSpellEffect + ReturnFromGraveyardToHandTargetEffect`, no ability class,
  no additional cost, exact self-exiling graveyard-to-hand Oracle/source
  agreement, and either supported simple targets such as multicolored cards or
  supported multi-component "up to one target" components ->
  `xmage_return_target_graveyard_card_to_hand_spell_v1` or
  `xmage_return_multiple_graveyard_cards_to_hand_exile_self_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToHandTargetEffect`, no ability class, no additional
  cost, exact self-graveyard Oracle/source agreement, `EachTargetPointer` or
  XMage color target support, and supported multi-component targets including
  one creature per color, Mount cards, Vehicle cards, and creature cards with
  no abilities ->
  `xmage_return_one_graveyard_creature_per_color_to_hand_spell_v1` or
  `xmage_return_multiple_graveyard_cards_to_hand_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToBattlefieldWithCounterTargetEffect`, no ability class,
  no additional cost, exact graveyard-to-battlefield Oracle/source agreement,
  and supported fixed counters (`+1/+1`, `-1/-1`, or keyword-granting
  `lifelink`) ->
  `xmage_return_target_graveyard_creature_to_battlefield_with_counter_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `PutOnLibraryTargetEffect`, no ability class, exact self-graveyard
  top/bottom library Oracle/source agreement, and no additional cost ->
  `xmage_put_target_graveyard_card_on_library_spell_v1`
- `tutor::xmage_library_search_variant_review_v1` with
  `SearchLibraryPutInPlayEffect` or `SearchLibraryPutOnLibraryEffect`, no
  ability class, no additional cost, exact Oracle/source target/count/destination
  matching, and simple land-to-battlefield or sorcery-to-library-top targets ->
  `xmage_library_search_to_battlefield_spell_v1` and
  `xmage_library_search_to_library_top_spell_v1`
- `tutor::xmage_library_search_variant_review_v1` with
  `SearchLibraryPutInPlayEffect + EntersBattlefieldTriggeredAbility` on
  creatures, optional static self keywords, exact one-card land tutor to
  battlefield Oracle/source agreement, supported targets `basic_land`, `plains`,
  `forest`, and `basic_forest_or_island`, and no condition/cost/modal or
  auxiliary non-static abilities ->
  `xmage_creature_etb_library_search_to_battlefield_v1`
- `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` ->
  `xmage_destroy_all_matching_permanents_spell_v1` and
  `xmage_fixed_damage_all_matching_permanents_spell_v1`
- `add_counters::targeted_add_counters_variant_v1` ->
  `xmage_fixed_add_counters_target_creature_spell_v1`
- `add_counters::targeted_add_counters_variant_v1` with
  `AddCountersTargetEffect + EntersBattlefieldTriggeredAbility` on creatures,
  exact one-target Oracle text, optional static self keywords, and simple
  `TargetCreaturePermanent()` source target ->
  `xmage_creature_etb_add_counters_target_creature_v1`
- `xmage_signature::BoostTargetEffect::no_ability_class::TargetCreaturePermanent::no_condition_class::targeting` ->
  `xmage_fixed_boost_target_creature_until_eot_spell_v1`
- `xmage_signature::BoostTargetEffect::no_ability_class::TargetCreaturePermanent::no_condition_class::targeting`
  with exact one-shot target-creature power/toughness boost or reduction until
  end of turn where the dynamic value is one of the supported game-state
  counts, including controller battlefield permanent counts by type/subtype,
  all-battlefield subtype counts, controller hand count, or domain basic land
  type count, with no additional costs, no X-spend costs, and no multi-target
  target-pointer fanout ->
  `xmage_dynamic_count_boost_target_creature_until_eot_spell_v1`
- `xmage_signature::BoostControlledEffect::no_ability_class::no_target_class::no_condition_class::no_signal`
  with exact one-shot "Creatures you control get +N/+N until end of turn"
  Oracle text, one fixed `BoostControlledEffect`, no color/modal/dynamic
  filter, and runtime until-end-of-turn cleanup ->
  `xmage_fixed_boost_controlled_creatures_until_eot_spell_v1`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
  with one `BoostTargetEffect`, one `GainAbilityTargetEffect`, one fixed target
  creature, and exact until-end-of-turn keyword Oracle text ->
  `xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1`
- `xmage_signature::no_effect_class::<combat keyword ability classes>::no_target_class::no_condition_class::no_signal` ->
  `xmage_static_self_combat_keyword_creature_v1`
- `token_maker::xmage_signature::CreateTokenEffect::no_ability_class::no_target_class::no_condition_class::token` with
  one fixed `CreateTokenEffect`, a literal token class constructor, no
  additional token fanout, no custom effect text, and token keywords limited to
  static runtime-supported keywords (`deathtouch`, `double_strike`,
  `first_strike`, `flying`, `haste`, `hexproof`, `indestructible`, `lifelink`,
  `menace`, `reach`, `trample`, `vigilance`) ->
  `xmage_fixed_create_creature_tokens_spell_v1`
- `token_maker::xmage_signature::CreateTokenEffect::EntersBattlefieldTriggeredAbility::no_target_class::no_condition_class::token,triggered_ability` with
  one fixed ETB `CreateTokenEffect`, a literal token class constructor, no
  additional token fanout, no custom effect text, and token keywords limited to
  static runtime-supported keywords (`deathtouch`, `double_strike`,
  `first_strike`, `flying`, `haste`, `hexproof`, `indestructible`, `lifelink`,
  `menace`, `reach`, `trample`, `vigilance`) ->
  `xmage_creature_etb_create_tokens_v1`
- `token_maker::xmage_signature::CreateTokenEffect::DiesSourceTriggeredAbility::*` with
  one fixed dies-triggered `CreateTokenEffect`, a literal safe creature token
  class, exact non-conditional "dies, create..." Oracle text, no dynamic count,
  no non-creature token, no additional token fanout, no custom effect text, and
  token keywords limited to static runtime-supported keywords ->
  `xmage_creature_dies_create_tokens_v1`

PG283 evidence:

- exact split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_fixed_spell_wave.md`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg283_xmage_fixed_spell_wave_package.md`
- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg283_xmage_fixed_spell_wave_e2e_validation.md`
- post-PG283 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg283_fixed_spell_wave_recheck.md`
- post-PG283 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg283_fixed_spell_wave.md`

Measured result:

- `312` exact spell rules promoted to PostgreSQL and synced to Hermes SQLite.
- PostgreSQL postcheck: `312/312` promoted rows, `312/312` verified/auto,
  `312/312` matching Oracle hash, with `50` stale shadow rows backed up and
  deprecated.
- SQLite post-sync direct validation: `312/312` present, verified, and auto.
- Global readiness moved from `battle_family_mapper_required=31772` to
  `31460`, and `battle_and_oracle_ready=788` to `1100`.
- Authoritative queue moved from `target_identity_count=28836` to `28524` and
  `xmage_authoritative_adapter_required_count=28522` to `28210`.
- Top affected work units moved:
  `direct_damage::targeted_damage_variant_v1` `1085 -> 979`,
  `removal_destroy::targeted_destroy_variant_v1` `839 -> 691`, and
  `draw_cards::xmage_draw_card_variant_review_v1` `734 -> 676`.

The blocked remainder is intentional, not refusal: it includes non-simple
permanents, triggers, activated abilities, variable/X effects, additional
costs, compound effects, and unsupported target patterns that require further
exact subpattern splits.

PG284 evidence:

- exact split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_utility_wave.md`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg284_xmage_utility_wave_package.md`
- PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg284_xmage_utility_wave_pg_apply_evidence.md`
- E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg284_xmage_utility_wave_e2e_validation.md`
- post-PG284 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg284_utility_wave_recheck.md`
- post-PG284 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg284_utility_wave.md`

PG284 measured result:

- `53` exact utility rules promoted to PostgreSQL and synced to Hermes SQLite:
  `29` simple tap mana-source permanents, `18` exile target spells, and `6`
  fixed controller life-gain spells.
- PostgreSQL precheck: `53/53` target rows found, `0` expected rows already
  present, `8` stale shadow rows scheduled for deprecation.
- PostgreSQL postcheck: `53/53` promoted rows, `53/53` verified/auto, and
  `53/53` matching Oracle hash, with `8` stale shadow rows backed up.
- E2E package validation: PostgreSQL `53/53`, SQLite `53/53`, canonical
  snapshot `53/53`, and runtime `get_card_effect` `53/53`.
- Authoritative queue moved from `target_identity_count=28524` to `28471` and
  `xmage_authoritative_adapter_required_count=28210` to `28157`.
- Top affected work units moved:
  `life_gain::xmage_life_gain_variant_review_v1` `823 -> 817`,
  `ramp_permanent::xmage_creature_mana_source_variant_review_v1` `390 -> 373`,
  `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` `327 -> 315`,
  and `removal_exile::targeted_exile_variant_v1` `174 -> 156`.

PG285-PG287 evidence:

- PG285 all-scope supported residual package:
  `docs/hermes-analysis/master_optimizer_reports/pg285_xmage_all_scope_supported_residual_package.md`
- PG285 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg285_xmage_all_scope_supported_residual_e2e_validation.md`
- PG286 counter spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg286_xmage_counter_spell_wave_package.md`
- PG286 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg286_xmage_counter_spell_wave_e2e_validation.md`
- PG287 bounce spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg287_xmage_bounce_spell_wave_package.md`
- PG287 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg287_xmage_bounce_spell_wave_e2e_validation.md`
- post-PG287 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg287_bounce_spell_wave_recheck.md`
- post-PG287 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg287_bounce_spell_wave.md`

PG285-PG287 measured result:

- PG285 promoted `8` all-card residual exact rules left outside the
  Commander-legal PG283/PG284 path: `5` simple Mox mana sources, `2` destroy
  target spells, and `1` fixed damage-to-player spell.
- PG286 promoted `12` pure `CounterTargetEffect` spells with exact stack target
  constraints for generic, creature, artifact, instant/sorcery, and blue spell
  targets. Runtime now preserves `target_constraints` from card-effect fallback
  data and validates stack target type/color before allowing a counterspell.
- PG287 promoted `7` pure `ReturnToHandTargetEffect` spells. Runtime now
  supports `destination=hand` for targeted removal/bounce by moving the
  permanent from battlefield to its controller's hand instead of falling through
  to graveyard removal.
- PG285 PostgreSQL postcheck: `8/8` promoted rows, `8/8` verified/auto,
  `8/8` matching Oracle hash; E2E: PostgreSQL, SQLite, canonical snapshot, and
  runtime all `8/8`.
- PG286 PostgreSQL postcheck: `12/12` promoted rows, `12/12` verified/auto,
  `12/12` matching Oracle hash, with `48` backup rows; E2E: PostgreSQL,
  SQLite, canonical snapshot, and runtime all `12/12`.
- PG287 PostgreSQL postcheck: `7/7` promoted rows, `7/7` verified/auto,
  `7/7` matching Oracle hash; E2E: PostgreSQL, SQLite, canonical snapshot, and
  runtime all `7/7`.
- Global all-card authoritative queue after PG287:
  `target_identity_count=31333`, `xmage_authoritative_source_count=28397`,
  `xmage_missing_source_exception_count=2936`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=28397`.
- Running the exact splitter after PG287 on the supported units returns
  `proposal_count=0`; all currently implemented exact adapters are exhausted
  against the current all-card gap. The next work must add a new exact
  subpattern/runtime adapter, not rerun the existing splitter.

PG288-PG290 evidence:

- PG288 recursion spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg288_xmage_recursion_spell_wave_package.md`
- PG288 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg288_xmage_recursion_spell_wave_pg_apply_evidence.md`
- PG288 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg288_xmage_recursion_spell_wave_e2e_validation.md`
- PG289 board wipe spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_package.md`
- PG289 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_pg_apply_evidence.md`
- PG289 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg289_xmage_board_wipe_spell_wave_e2e_validation.md`
- PG290 add counters spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg290_xmage_add_counters_spell_wave_package.md`
- PG290 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg290_xmage_add_counters_spell_wave_pg_apply_evidence.md`
- PG290 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg290_xmage_add_counters_spell_wave_e2e_validation.md`
- post-PG290 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg290_add_counters_spell_wave_recheck.md`
- post-PG290 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg290_add_counters_spell_wave.md`

PG288-PG290 measured result:

- PG288 promoted `22` exact graveyard-recursion spells that return target cards
  from graveyard to hand. Runtime now handles the matching `recursion` effect
  by moving a valid graveyard target to hand and leaving the resolved spell in
  graveyard.
- PG289 promoted `13` exact mass-removal spells: `9` simple
  `DestroyAllEffect` board wipes over supported permanent type scopes and `4`
  fixed `DamageAllEffect` wipes over supported creature/planeswalker scopes.
- PG290 promoted `3` exact `AddCountersTargetEffect` instant spells over
  target creatures: `Battlegrowth`, `Blight Rot`, and `Scar`. Runtime now
  handles fixed `+1/+1` and `-1/-1` counters on legal target creatures,
  including zero-toughness cleanup after negative counters.
- PG288 PostgreSQL postcheck: `22/22` promoted rows, `22/22` verified/auto,
  `22/22` matching Oracle hash, with `2` backup rows; E2E: PostgreSQL,
  SQLite, canonical snapshot, and runtime all `22/22`.
- PG289 PostgreSQL postcheck: `13/13` promoted rows, `13/13` verified/auto,
  `13/13` matching Oracle hash, with `8` backup rows; E2E: PostgreSQL,
  SQLite, canonical snapshot, and runtime all `13/13`.
- PG290 PostgreSQL postcheck: `3/3` promoted rows, `3/3` verified/auto,
  `3/3` matching Oracle hash, with `0` backup rows; E2E: PostgreSQL,
  SQLite, canonical snapshot, and runtime all `3/3`.
- Global all-card authoritative queue after PG290:
  `target_identity_count=31295`, `xmage_authoritative_source_count=28359`,
  `xmage_missing_source_exception_count=2936`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=28359`.
- Running the exact splitter after PG290 on supported units returned
  `proposal_count=0` over `7409` considered supported rows. The next work added
  the fixed target-creature boost/debuff until end of turn subpattern.

PG291 evidence:

- PG291 boost/debuff target spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg291_xmage_boost_target_spell_wave_package.md`
- PG291 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg291_xmage_boost_target_spell_wave_pg_apply_evidence.md`
- PG291 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg291_xmage_boost_target_spell_wave_e2e_validation.md`
- post-PG291 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg291_boost_target_spell_wave_recheck.md`
- post-PG291 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg291_boost_target_spell_wave.md`
- post-PG291 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg291_existing_supported_recheck.md`

PG291 measured result:

- PG291 promoted `42` exact `BoostTargetEffect` one-shot spells over target
  creatures, mapped to `stat_modifier_until_eot`. Runtime now chooses own
  creatures for pump effects, opponent creatures for harmful debuffs, records
  power/toughness until-end-of-turn cleanup, and handles zero-toughness death.
- PostgreSQL postcheck: `42/42` promoted rows, `42/42` verified/auto,
  `42/42` matching Oracle hash, with `0` backup rows.
- E2E package validation: PostgreSQL `42/42`, SQLite `42/42`, canonical
  snapshot `42/42`, and runtime `get_card_effect` `42/42`.
- Focused runtime tests cover both positive pump and negative debuff/zero
  toughness cleanup; `57` focused tests pass.
- Global all-card authoritative queue after PG291:
  `target_identity_count=31253`, `xmage_authoritative_source_count=28317`,
  `xmage_missing_source_exception_count=2936`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=28317`.
- Running the exact splitter after PG291 on supported units returns
  `proposal_count=0` over `7449` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with likely first
  candidates from the largest remaining XMage work units: `recursion`,
  `draw_engine`, `grant_protection_from_chosen_color`, residual
  `direct_damage`, `life_gain`, `source_add_counters`, `removal_destroy`, and
  `tutor`.

PG292 evidence:

- PG292 static keyword creature package:
  `docs/hermes-analysis/master_optimizer_reports/pg292_xmage_static_keyword_creature_wave_package.md`
- PG292 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg292_xmage_static_keyword_creature_wave_pg_apply_evidence.md`
- PG292 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg292_xmage_static_keyword_creature_wave_e2e_validation.md`
- post-PG292 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg292_static_keyword_creature_wave_recheck.md`
- post-PG292 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg292_static_keyword_creature_wave.md`
- post-PG292 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg292_existing_supported_recheck.md`

PG292 measured result:

- PG292 promoted `409` exact static self combat-keyword creatures with
  keyword-only Oracle first lines, excluding `ProtectionAbility` and any
  creature whose Oracle text did not exactly match the resolved XMage keyword
  set.
- Runtime now enriches cast creatures with the exact static keyword set,
  including haste clearing summoning sickness through the focused runtime test.
- PostgreSQL postcheck: `409/409` promoted rows, `409/409` verified/auto,
  `409/409` matching Oracle hash, with `2` backup rows.
- PG -> Hermes/SQLite sync loaded `409` PostgreSQL rows, inserted/updated
  `411` SQLite rows including deprecated shadow rows, and exported `4135`
  canonical snapshot rows.
- E2E package validation: PostgreSQL `409/409`, SQLite `409/409`, canonical
  snapshot `409/409`, and runtime `get_card_effect` `409/409`.
- Focused runtime tests cover static keyword enrichment on a permanent and
  haste clearing summoning sickness; `62` focused tests pass.
- Global all-card authoritative queue after PG292:
  `target_identity_count=30844`, `xmage_authoritative_source_count=27908`,
  `xmage_missing_source_exception_count=2936`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27908`.
- Running the exact splitter after PG292 on supported units returns
  `proposal_count=0` over `7495` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with likely first
  candidates from the largest remaining XMage work units: `recursion`,
  `draw_engine`, `grant_protection_from_chosen_color`, residual
  `direct_damage`, `life_gain`, `source_add_counters`, `removal_destroy`, and
  `tutor`.

PG293 evidence:

- PG293 static self keyword creature v2 package:
  `docs/hermes-analysis/master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_package.md`
- PG293 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_pg_apply_evidence.md`
- PG293 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg293_xmage_static_self_keyword_creature_v2_wave_e2e_validation.md`
- post-PG293 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg293_static_self_keyword_creature_v2_wave_recheck.md`
- post-PG293 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg293_static_self_keyword_creature_v2_wave.md`
- post-PG293 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg293_existing_supported_recheck.md`

PG293 measured result:

- PG293 promoted `85` additional exact static self-keyword creatures, covering
  multiline keyword Oracle text and safe self keywords routed through broad
  work units, including `hexproof`, `shroud`, and `indestructible`.
- Runtime now recognizes `hexproof` and `shroud` as self-owned keyword
  abilities during card enrichment; the existing targeting and removal paths
  enforce hexproof/shroud targeting legality and indestructible destruction
  prevention.
- `ProtectionAbility` and `WardAbility` remain deliberately excluded because
  they need parameterized color/scope or cost modeling before executable PG
  promotion.
- PostgreSQL postcheck: `85/85` promoted rows, `85/85` verified/auto,
  `85/85` matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `85` PostgreSQL rows, inserted/updated `85`
  SQLite rows, and exported `4220` canonical snapshot rows.
- E2E package validation: PostgreSQL `85/85`, SQLite `85/85`, canonical
  snapshot `85/85`, and runtime `get_card_effect` `85/85`.
- Focused runtime tests cover multiline static keywords and
  hexproof/shroud/indestructible enforcement; `66` focused tests pass.
- Global all-card authoritative queue after PG293:
  `target_identity_count=30759`, `xmage_authoritative_source_count=27823`,
  `xmage_missing_source_exception_count=2936`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27823`.
- Running the exact splitter after PG293 on supported units returns
  `proposal_count=0` over `7451` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with likely first
  candidates from the largest remaining XMage work units: `recursion`,
  `draw_engine`, `grant_protection_from_chosen_color`, residual
  `direct_damage`, `life_gain`, `source_add_counters`, `removal_destroy`, and
  `tutor`.

PG294 evidence:

- PG294 creature ETB life-gain package:
  `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_package.md`
- PG294 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_pg_apply_evidence.md`
- PG294 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg294_xmage_creature_etb_life_gain_wave_e2e_validation.md`
- post-PG294 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg294_creature_etb_life_gain_wave_recheck.md`
- post-PG294 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg294_creature_etb_life_gain_wave.md`
- post-PG294 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg294_existing_supported_recheck.md`

PG294 measured result:

- PG294 promoted `37` exact creatures whose local XMage source is
  `GainLifeEffect(N)` behind `EntersBattlefieldTriggeredAbility`, mapped to
  `xmage_creature_etb_gain_life_v1`.
- Runtime now resolves `etb_life_gain_amount` after the creature enters the
  battlefield and emits a `trigger_resolved` replay event with requested and
  actual life gained.
- The splitter explicitly blocks proportional ETB life-gain text such as
  "you gain N life for each ..." by requiring both fixed Oracle text and fixed
  `GainLifeEffect(N)` source amount.
- PostgreSQL postcheck: `37/37` promoted rows, `37/37` verified/auto,
  `37/37` matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `37` PostgreSQL rows, inserted/updated `37`
  SQLite rows, and exported `4257` canonical snapshot rows.
- E2E package validation: PostgreSQL `37/37`, SQLite `37/37`, canonical
  snapshot `37/37`, and runtime `get_card_effect` `37/37`.
- Focused runtime tests cover creature ETB life gain after battlefield entry;
  `71` focused exact-scope tests pass.
- Global all-card authoritative queue after PG294:
  `target_identity_count=30722`, `xmage_authoritative_source_count=27786`,
  `xmage_missing_source_exception_count=2936`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27786`.
- Running the exact splitter after PG294 on supported units returns
  `proposal_count=0` over `7414` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with likely first
  candidates from the largest remaining XMage work units: `recursion`,
  `draw_engine`, `grant_protection_from_chosen_color`, residual
  `direct_damage`, `source_add_counters`, `life_gain`, `removal_destroy`, and
  `tutor`.

PG295 evidence:

- PG295 creature ETB draw package:
  `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_package.md`
- PG295 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_pg_apply_evidence.md`
- PG295 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg295_xmage_creature_etb_draw_wave_e2e_validation.md`
- post-PG295 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg295_creature_etb_draw_wave_recheck.md`
- post-PG295 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg295_creature_etb_draw_wave.md`
- post-PG295 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg295_existing_supported_recheck.md`

PG295 measured result:

- PG295 promoted `28` exact creatures whose local XMage source is
  `DrawCardSourceControllerEffect` behind `EntersBattlefieldTriggeredAbility`,
  mapped to `xmage_creature_etb_draw_cards_v1`.
- Runtime now resolves `etb_draw_count` after the creature enters the
  battlefield and emits a `trigger_resolved` replay event with requested and
  actual cards drawn.
- The splitter blocks dynamic ETB draw amounts such as "draw a card for each"
  by requiring a fixed Oracle draw count and a fixed/no-argument XMage draw
  effect.
- PostgreSQL postcheck: `28/28` promoted rows, `28/28` verified/auto,
  `28/28` matching Oracle hash, with `10` stale shadow rows backed up.
- PG -> Hermes/SQLite sync loaded `28` PostgreSQL rows, inserted/updated `38`
  SQLite rows including deprecated shadow rows, and exported `4280` canonical
  snapshot rows.
- E2E package validation: PostgreSQL `28/28`, SQLite `28/28`, canonical
  snapshot `28/28`, and runtime `get_card_effect` `28/28`.
- Focused runtime tests cover creature ETB draw after battlefield entry and
  `trigger_resolved` evidence; `75` focused exact-scope tests pass.
- Global all-card authoritative queue after PG295:
  `target_identity_count=30694`, `xmage_authoritative_source_count=27758`,
  `xmage_missing_source_exception_count=2936`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27758`.
- Running the exact splitter after PG295 on supported units returns
  `proposal_count=0` over `7427` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with the highest
  reuse signal coming from `SimpleActivatedAbility` signatures across
  `direct_damage`, `removal_destroy`, `draw_engine`, `tutor`, `life_gain`, and
  boost effects.

PG296 evidence:

- PG296 creature tap-damage package:
  `docs/hermes-analysis/master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_package.md`
- PG296 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_pg_apply_evidence.md`
- PG296 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg296_xmage_creature_tap_damage_wave_e2e_validation.md`
- post-PG296 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg296_creature_tap_damage_wave_recheck.md`
- post-PG296 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg296_creature_tap_damage_wave.md`
- post-PG296 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg296_existing_supported_recheck.md`

PG296 measured result:

- PG296 promoted `6` exact creatures whose local XMage source is
  `DamageTargetEffect(N)` behind `SimpleActivatedAbility` with exactly
  `TapSourceCost`, mapped to
  `xmage_creature_tap_fixed_damage_target_activated_v1` with nested
  `xmage_tap_fixed_damage_target_activated_ability_v1`.
- Runtime now treats the card as a creature when cast, does not deal damage on
  entry, and can later tap a ready non-summoning-sick permanent to deal fixed
  damage to a legal target without moving the permanent out of battlefield.
- The splitter blocks activated damage with mana/sacrifice/additional costs,
  noncreature sources, and non-simple Oracle templates until those exact cost
  and target models exist.
- PostgreSQL postcheck: `6/6` promoted rows, `6/6` verified/auto,
  `6/6` matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `6` PostgreSQL rows, inserted/updated `6`
  SQLite rows, and exported `4286` canonical snapshot rows.
- E2E package validation: PostgreSQL `6/6`, SQLite `6/6`, canonical
  snapshot `6/6`, and runtime `get_card_effect` `6/6`.
- Focused runtime tests cover no damage on creature entry, later tap-damage
  activation, summoning-sickness blocking, priority-round activation, and tied
  activatable permanent ordering; `82` focused exact-scope tests pass.
- Global all-card authoritative queue after PG296:
  `target_identity_count=27812`, `xmage_authoritative_source_count=27498`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27498`.
- Running the exact splitter after PG296 on supported units returns
  `proposal_count=0` over `7370` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with the largest
  current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `removal_destroy`, `draw_cards`, and
  `tutor`.

PG297 evidence:

- PG297 creature ETB destroy package:
  `docs/hermes-analysis/master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_package.md`
- PG297 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_pg_apply_evidence.md`
- PG297 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg297_xmage_creature_etb_destroy_wave_e2e_validation.md`
- post-PG297 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg297_creature_etb_destroy_wave_recheck.md`
- post-PG297 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg297_creature_etb_destroy_wave.md`
- post-PG297 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg297_existing_supported_recheck.md`

PG297 measured result:

- PG297 promoted `19` exact creatures whose local XMage source is
  `DestroyTargetEffect` behind `EntersBattlefieldTriggeredAbility`, mapped to
  `xmage_creature_etb_destroy_target_v1`.
- Runtime already had the generic ETB removal executor; the focused runtime
  test now proves the creature remains on battlefield while the ETB trigger
  destroys a legal opponent permanent and moves it to graveyard.
- The splitter requires complete unrestricted ETB destroy Oracle text and
  blocks restricted clauses such as power/toughness limits, subtype filters,
  nonblack filters, Equipment/Aura-only filters, and dealt-damage-this-turn
  conditions.
- PostgreSQL postcheck: `19/19` promoted rows, `19/19` verified/auto,
  `19/19` matching Oracle hash, with `4` backup rows.
- PG -> Hermes/SQLite sync loaded `19` PostgreSQL rows, inserted/updated `23`
  SQLite rows including deprecated shadow rows, and exported `4303` canonical
  snapshot rows.
- E2E package validation: PostgreSQL `19/19`, SQLite `19/19`, canonical
  snapshot `19/19`, and runtime `get_card_effect` `19/19`.
- Focused exact-scope tests cover strict ETB destroy mapping, restricted-target
  blocking, and runtime ETB removal resolution; `85` focused exact-scope tests
  pass.
- Global all-card authoritative queue after PG297:
  `target_identity_count=27793`, `xmage_authoritative_source_count=27479`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27479`.
- Running the exact splitter after PG297 on supported units returns
  `proposal_count=0` over `7351` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with the largest
  current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG298 evidence:

- PG298 creature ETB recursion package:
  `docs/hermes-analysis/master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_package.md`
- PG298 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_pg_apply_evidence.md`
- PG298 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg298_xmage_creature_etb_recursion_wave_e2e_validation.md`
- post-PG298 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg298_creature_etb_recursion_wave_recheck.md`
- post-PG298 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg298_creature_etb_recursion_wave.md`
- post-PG298 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg298_existing_supported_recheck.md`

PG298 measured result:

- PG298 promoted `22` exact creatures whose local XMage source is
  `ReturnFromGraveyardToHandTargetEffect` behind
  `EntersBattlefieldTriggeredAbility`, mapped to
  `xmage_creature_etb_return_graveyard_card_to_hand_v1`.
- Runtime uses the generic ETB graveyard-recursion executor and now has focused
  tests for instant/sorcery recovery and land recovery from the controller's
  graveyard to hand.
- The splitter requires complete unrestricted ETB graveyard-to-hand Oracle text
  and blocks subtype-only targets, mana-value limits, conditional descend-style
  clauses, opponent-choice targets, multiple ETB triggers, and `and/or` target
  wording until a narrower adapter exists.
- PostgreSQL postcheck: `22/22` promoted rows, `22/22` verified/auto,
  `22/22` matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `6720` PostgreSQL rows, inserted/updated
  `6491` SQLite rows, and exported `4333` canonical snapshot rows.
- E2E package validation: PostgreSQL `22/22`, SQLite `22/22`, canonical
  snapshot `22/22`, and runtime `get_card_effect` `22/22`.
- Focused exact-scope tests cover strict ETB recursion mapping, dynamic/blocked
  ETB recursion text, land target recursion, and runtime ETB recursion
  resolution; `90` focused exact-scope tests pass.
- Global all-card readiness after PG298:
  `battle_and_oracle_ready=1853`, `battle_family_mapper_required=30694`, and
  `snapshot_has_verified_rule=3001`.
- Global all-card authoritative queue after PG298:
  `target_identity_count=27771`, `xmage_authoritative_source_count=27457`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27457`.
- Running the exact splitter after PG298 on supported units returns
  `proposal_count=0` over `7329` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with the largest
  current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG299 evidence:

- PG299 creature ETB recursion keyword package:
  `docs/hermes-analysis/master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_package.md`
- PG299 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_pg_apply_evidence.md`
- PG299 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg299_xmage_creature_etb_recursion_keyword_wave_e2e_validation.md`
- post-PG299 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg299_creature_etb_recursion_keyword_wave_recheck.md`
- post-PG299 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg299_creature_etb_recursion_keyword_wave.md`
- post-PG299 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg299_existing_supported_recheck.md`

PG299 measured result:

- PG299 promoted `4` additional exact creatures whose local XMage source is
  `ReturnFromGraveyardToHandTargetEffect` behind
  `EntersBattlefieldTriggeredAbility` plus a static self keyword such as
  `FlyingAbility` or `DefenderAbility`, mapped to
  `xmage_creature_etb_return_graveyard_card_to_hand_v1`.
- The splitter now strips only leading self-keyword Oracle lines before
  matching the ETB recursion text, preserving the keyword fields in
  `effect_json` and still blocking conditionals, mana-value limits, and
  subtype/and-or targets.
- PostgreSQL postcheck: `4/4` promoted rows, `4/4` verified/auto, `4/4`
  matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `6724` PostgreSQL rows, inserted/updated
  `6518` SQLite rows, and exported `4337` canonical snapshot rows.
- E2E package validation: PostgreSQL `4/4`, SQLite `4/4`, canonical snapshot
  `4/4`, and runtime `get_card_effect` `4/4`.
- Focused exact-scope tests cover ETB recursion with preserved self keywords;
  `91` focused exact-scope tests pass.
- Global all-card authoritative queue after PG299:
  `target_identity_count=27767`, `xmage_authoritative_source_count=27453`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27453`.
- Running the exact splitter after PG299 on supported units returns
  `proposal_count=0` over `7325` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with the largest
  current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG300 evidence:

- PG300 recursion battlefield spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_package.md`
- PG300 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_pg_apply_evidence.md`
- PG300 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg300_xmage_recursion_battlefield_spell_wave_e2e_validation.md`
- post-PG300 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg300_recursion_battlefield_spell_wave_recheck.md`
- post-PG300 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg300_recursion_battlefield_spell_wave.md`
- post-PG300 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg300_existing_supported_recheck.md`

PG300 measured result:

- PG300 promoted `8` exact self-graveyard recursion spells whose local XMage
  source is `ReturnFromGraveyardToBattlefieldTargetEffect` with no ability
  class and whose Oracle text is exactly a single target artifact, creature, or
  permanent card from your graveyard returned to the battlefield.
- The splitter maps them to
  `xmage_return_target_graveyard_card_to_battlefield_spell_v1` and still blocks
  opponent graveyards, X counts, name/type restrictions, total mana value,
  "this turn", tapped entry, modal text, and additional costs.
- PostgreSQL postcheck: `8/8` promoted rows, `8/8` verified/auto, `8/8`
  matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `6732` PostgreSQL rows, inserted/updated
  `6526` SQLite rows, and exported `4345` canonical snapshot rows.
- E2E package validation: PostgreSQL `8/8`, SQLite `8/8`, canonical snapshot
  `8/8`, and runtime `get_card_effect` `8/8`.
- Focused exact-scope tests cover graveyard-to-battlefield recursion returning
  the matching permanent to battlefield; `94` focused exact-scope tests pass.
- Global all-card authoritative queue after PG300:
  `target_identity_count=27759`, `xmage_authoritative_source_count=27445`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27445`.
- Running the exact splitter after PG300 on supported units returns
  `proposal_count=0` over `7317` considered supported rows. The next work must
  implement another exact runtime-backed family/subpattern, with the largest
  current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG301 evidence:

- PG301 creature dies draw package:
  `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_package.md`
- PG301 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_pg_apply_evidence.md`
- PG301 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg301_xmage_creature_dies_draw_wave_e2e_validation.md`
- post-PG301 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg301_creature_dies_draw_wave_recheck.md`
- post-PG301 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg301_creature_dies_draw_wave.md`
- post-PG301 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg301_existing_supported_recheck.md`

PG301 measured result:

- PG301 promoted `20` exact creatures whose local XMage source is
  `DrawCardSourceControllerEffect` behind `DiesSourceTriggeredAbility`, mapped
  to `xmage_creature_dies_draw_cards_v1`.
- Runtime now resolves `draw_cards_when_this_dies` only when the permanent
  moves from battlefield to graveyard and emits `dies_draw_resolved` replay
  evidence with the requested and actual drawn card count.
- The splitter blocks variable or conditional dies-draw amounts such as
  Zubera-style text, and allows only optional static self keywords plus exact
  fixed dies-draw Oracle text.
- PostgreSQL postcheck: `20/20` promoted rows, `20/20` verified/auto, `20/20`
  matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `6752` PostgreSQL rows, inserted/updated
  `6546` SQLite rows, and exported `4365` canonical snapshot rows.
- E2E package validation: PostgreSQL `20/20`, SQLite `20/20`, canonical
  snapshot `20/20`, and runtime `get_card_effect` `20/20`.
- Focused exact-scope tests cover strict dies-draw mapping, static keyword and
  optional draw preservation, dynamic/blocked dies-draw text, and runtime
  battlefield-to-graveyard draw resolution; `98` focused exact-scope tests
  pass.
- Global all-card authoritative queue after PG301:
  `target_identity_count=27739`, `xmage_authoritative_source_count=27425`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27425`.
- Running the exact splitter after PG301 on supported units returns
  `proposal_count=0` over `7319` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG302 evidence:

- PG302 creature ETB damage package:
  `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_package.md`
- PG302 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_pg_apply_evidence.md`
- PG302 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg302_xmage_creature_etb_damage_wave_e2e_validation.md`
- PG302 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg302_creature_etb_damage_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg302_creature_etb_damage_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg302_creature_etb_damage_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg302_creature_etb_damage_wave.md`
- post-PG302 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg302_creature_etb_damage_wave_recheck.md`
- post-PG302 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg302_creature_etb_damage_wave.md`
- post-PG302 token grouping replan:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg302_token_grouping_replan.md`
- post-PG302 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg302_token_grouping_replan_supported_recheck.md`

PG302 measured result:

- PG302 promoted `8` exact creatures whose local XMage source is
  `DamageTargetEffect` behind `EntersBattlefieldTriggeredAbility`, mapped to
  `xmage_creature_etb_fixed_damage_target_v1`.
- Runtime now resolves `etb_damage_amount` through the existing direct-damage
  executor after the creature enters the battlefield, with `finish_spell=false`
  so the source creature stays on battlefield.
- The splitter blocks variable/X, conditional/raid, target restrictions such
  as flying-only or damaged-this-turn, and target-player-or-planeswalker text
  until narrower target models exist.
- PostgreSQL postcheck: `8/8` promoted rows, `8/8` verified/auto, `8/8`
  matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `6760` PostgreSQL rows, inserted/updated
  `6554` SQLite rows, and exported `4373` canonical snapshot rows.
- E2E package validation: PostgreSQL `8/8`, SQLite `8/8`, canonical snapshot
  `8/8`, and runtime `get_card_effect` `8/8`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning; legacy
  contamination `pass`.
- Focused exact-scope tests cover fixed ETB damage mapping, variable and
  restricted-target blocking, and runtime ETB damage destroying a target
  creature while preserving the source creature; `102` focused exact-scope
  tests pass.
- Global all-card authoritative queue after PG302:
  `target_identity_count=27731`, `xmage_authoritative_source_count=27417`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27417`.
- Post-PG302 token grouping replan keeps the same card counts but reduces
  `adapter_work_unit_count` from `11905` to `11429` by grouping
  card-specific token variants by XMage signature. The top newly visible token
  groups are `CreateTokenEffect` with no ability class (`69` cards) and
  `CreateTokenEffect + EntersBattlefieldTriggeredAbility` (`60` cards).
- Running the exact splitter after PG302 on supported units returns
  `proposal_count=0` over `7311` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG303 evidence:

- PG303 fixed token spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_package.md`
- PG303 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_pg_apply_evidence.md`
- PG303 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg303_xmage_fixed_token_spell_wave_e2e_validation.md`
- PG303 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg303_fixed_token_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg303_fixed_token_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg303_fixed_token_spell_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg303_fixed_token_spell_wave.md`
- post-PG303 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg303_fixed_token_spell_wave_recheck.md`
- post-PG303 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg303_fixed_token_spell_wave.md`
- post-PG303 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg303_existing_supported_recheck.md`

PG303 measured result:

- PG303 promoted `27` exact one-shot token spells whose local XMage source is a
  single fixed `CreateTokenEffect` over a literal creature token class.
- The splitter now reads only the no-argument token constructor, extracts
  fixed token count, token name, colors, subtype, power/toughness, and safe
  `flying`/`haste` keywords, and blocks dynamic counts, unsupported token
  keywords, custom text, additional token fanout, and non-literal token
  descriptions.
- PostgreSQL postcheck: `27/27` promoted rows, `27/27` verified/auto, `27/27`
  matching Oracle hash, with `10` backup rows.
- PG -> Hermes/SQLite sync loaded `6787` PostgreSQL rows, inserted/updated
  `6581` SQLite rows, and exported `4395` canonical snapshot rows.
- E2E package validation: PostgreSQL `27/27`, SQLite `27/27`, canonical
  snapshot `27/27`, and runtime `get_card_effect` `27/27`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover fixed token spell mapping, dynamic count
  blocking, additional token blocking, unsupported keyword blocking, and
  runtime token creation; `107` focused exact-scope tests pass.
- Global all-card authoritative queue after PG303:
  `target_identity_count=27704`, `xmage_authoritative_source_count=27390`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27390`.
- Running the exact splitter after PG303 on supported units returns
  `proposal_count=0` over `7353` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG304 evidence:

- PG304 creature ETB token package:
  `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_package.md`
- PG304 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_pg_apply_evidence.md`
- PG304 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg304_xmage_creature_etb_token_wave_e2e_validation.md`
- PG304 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg304_creature_etb_token_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg304_creature_etb_token_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg304_creature_etb_token_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg304_creature_etb_token_wave.md`
- post-PG304 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg304_creature_etb_token_wave_recheck.md`
- post-PG304 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg304_creature_etb_token_wave.md`
- post-PG304 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg304_existing_supported_recheck.md`

PG304 measured result:

- PG304 promoted `27` exact creatures whose local XMage source is
  `CreateTokenEffect` behind `EntersBattlefieldTriggeredAbility`, mapped to
  `xmage_creature_etb_create_tokens_v1`.
- Runtime ETB token creation now preserves token subtype, colors, artifact
  status, and safe `flying`/`haste` token keywords instead of only creating a
  generic name/power/toughness token.
- The splitter blocks Treasure/non-creature tokens, dynamic token counts,
  multiple token fanout, custom text, non-literal token descriptions, and
  unsupported token keywords.
- PostgreSQL postcheck: `27/27` promoted rows, `27/27` verified/auto, `27/27`
  matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `6814` PostgreSQL rows, inserted/updated
  `6608` SQLite rows, and exported `4422` canonical snapshot rows.
- E2E package validation: PostgreSQL `27/27`, SQLite `27/27`, canonical
  snapshot `27/27`, and runtime `get_card_effect` `27/27`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover ETB token mapping, non-creature token
  blocking, and runtime token creation with artifact/flying/subtype
  preservation; `110` focused exact-scope tests pass.
- Global all-card authoritative queue after PG304:
  `target_identity_count=27677`, `xmage_authoritative_source_count=27363`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27363`.
- Running the exact splitter after PG304 on supported units returns
  `proposal_count=0` over `7386` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG305 evidence:

- PG305 boost plus keyword spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_package.md`
- PG305 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_pg_apply_evidence.md`
- PG305 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg305_xmage_boost_keyword_spell_wave_e2e_validation.md`
- PG305 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg305_boost_keyword_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg305_boost_keyword_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg305_boost_keyword_spell_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg305_boost_keyword_spell_wave.md`
- post-PG305 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg305_boost_keyword_spell_wave_recheck.md`
- post-PG305 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg305_boost_keyword_spell_wave.md`
- post-PG305 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg305_existing_supported_recheck.md`

PG305 measured result:

- PG305 promoted `27` exact one-shot spells whose local XMage source is one
  `BoostTargetEffect`, one `GainAbilityTargetEffect`, and one fixed target
  creature, mapped to
  `xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1`.
- Runtime now applies the temporary power/toughness modifier and also grants
  the temporary keyword through the existing until-end-of-turn cleanup path.
- The splitter blocks multi-target spells, unsupported or parameterized
  ability classes, non-exact Oracle text, source/Oracle boost mismatches, and
  source/Oracle target-controller mismatches.
- PostgreSQL postcheck: `27/27` promoted rows, `27/27` verified/auto,
  `27/27` matching Oracle hash, with `0` backup rows.
- PG -> Hermes/SQLite sync loaded `6841` PostgreSQL rows, inserted/updated
  `6635` SQLite rows, and exported `4449` canonical snapshot rows.
- E2E package validation: PostgreSQL `27/27`, SQLite `27/27`, canonical
  snapshot `27/27`, and runtime `get_card_effect` `27/27`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover strict boost-plus-keyword mapping,
  target-controller mismatch blocking, keyword application, replay evidence,
  and until-end-of-turn cleanup; `113` focused exact-scope tests pass.
- Global all-card authoritative queue after PG305:
  `target_identity_count=27650`, `xmage_authoritative_source_count=27336`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27336`.
- Running the exact splitter after PG305 on supported units returns
  `proposal_count=0` over `7429` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG306 evidence:

- PG306 damage plus controller life-gain package:
  `docs/hermes-analysis/master_optimizer_reports/pg306_xmage_damage_gain_life_spell_wave_package.md`
- PG306 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg306_xmage_damage_gain_life_spell_wave_pg_apply_evidence.md`
- PG306 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg306_xmage_damage_gain_life_spell_wave_e2e_validation.md`
- PG306 PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg306_xmage_damage_gain_life_spell_wave_pg_to_sqlite_sync.json`
- PG306 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg306_damage_gain_life_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg306_damage_gain_life_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg306_damage_gain_life_spell_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg306_damage_gain_life_spell_wave.md`
- post-PG306 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg306_damage_gain_life_spell_wave_recheck.md`
- post-PG306 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg306_damage_gain_life_spell_wave.md`
- PG306 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_damage_gain_life_spell_wave.md`
- post-PG306 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg306_existing_supported_recheck.md`

PG306 measured result:

- PG306 promoted `13` exact one-shot spells whose local XMage source is one
  fixed `DamageTargetEffect`, one fixed `GainLifeEffect`, and one supported
  target class, mapped to
  `xmage_fixed_damage_target_and_controller_gain_life_spell_v1`.
- PostgreSQL apply evidence reports `13/13` promoted rows, `13/13`
  verified/auto rows, and `13/13` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `6854` PostgreSQL rows, inserted/updated
  `6648` SQLite rows, and exported `4462` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover strict source/Oracle matching, period-separated
  life-gain Oracle text, variable-X blocking, runtime damage, creature death and
  controller life gain; `117` focused exact-scope tests pass.
- Global all-card readiness after PG306:
  `battle_and_oracle_ready=1987` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `ready_product_qa_unique_cards=818`.
- Global all-card authoritative queue after PG306:
  `target_identity_count=27637`, `xmage_authoritative_source_count=27323`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27323`.
- Running the exact splitter after PG306 on supported units returns
  `proposal_count=0` over `7416` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG307 evidence:

- PG307 destroy target plus controller life-gain package:
  `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_package.md`
- PG307 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_pg_apply_evidence.md`
- PG307 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_e2e_validation.md`
- PG307 PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg307_xmage_destroy_gain_life_spell_wave_pg_to_sqlite_sync.json`
- PG307 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg307_destroy_gain_life_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg307_destroy_gain_life_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg307_destroy_gain_life_spell_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg307_destroy_gain_life_spell_wave.md`
- post-PG307 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg307_destroy_gain_life_spell_wave_recheck.md`
- post-PG307 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg307_destroy_gain_life_spell_wave.md`
- PG307 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_destroy_gain_life_spell_wave.md`
- post-PG307 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg307_existing_supported_recheck.md`

PG307 measured result:

- PG307 promoted `13` exact one-shot spells whose local XMage source is one
  fixed `DestroyTargetEffect`, one fixed `GainLifeEffect`, and one supported
  target class, mapped to
  `xmage_destroy_target_and_controller_gain_life_spell_v1`.
- PostgreSQL apply evidence reports `13/13` promoted rows, `13/13`
  verified/auto rows, and `13/13` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `6867` PostgreSQL rows, inserted/updated
  `6661` SQLite rows, and exported `4475` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover strict destroy-plus-life-gain mapping,
  dynamic/unsupported target blocking, target destruction, and controller life
  gain; `121` focused exact-scope tests pass.
- Global all-card readiness after PG307:
  `battle_and_oracle_ready=2000` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `ready_product_qa_unique_cards=818`.
- Global all-card authoritative queue after PG307:
  `target_identity_count=27624`, `xmage_authoritative_source_count=27310`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27310`.
- Running the exact splitter after PG307 on supported units returns
  `proposal_count=0` over `7403` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG308 evidence:

- PG308 restricted target spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_package.md`
- PG308 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_pg_apply_evidence.md`
- PG308 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_e2e_validation.md`
- PG308 PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg308_xmage_restricted_target_spell_wave_pg_to_sqlite_sync.json`
- PG308 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg308_restricted_target_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg308_restricted_target_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg308_restricted_target_spell_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg308_restricted_target_spell_wave.md`
- post-PG308 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg308_restricted_target_spell_wave_recheck.md`
- post-PG308 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg308_restricted_target_spell_wave.md`
- PG308 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_restricted_target_spell_wave.md`
- post-PG308 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg308_existing_supported_recheck.md`

PG308 measured result:

- PG308 promoted `38` exact fixed damage, destroy and exile one-shot spells
  whose local XMage source and Oracle text agree on restricted battlefield
  target constraints.
- The target runtime now enforces structured constraints for
  attacking/blocking, tapped/untapped, flying, target colors, excluded colors,
  minimum power, and minimum mana value before selecting damage, destroy or
  exile targets.
- PostgreSQL apply evidence reports `38/38` promoted rows, `38/38`
  verified/auto rows, and `38/38` matching Oracle hash rows, with `2` stale
  shadow rows backed up.
- PG -> Hermes/SQLite sync loaded `6905` PostgreSQL rows, inserted/updated
  `6699` SQLite rows, and exported `4512` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover restricted target extraction, source/Oracle
  mismatch blocking, and runtime legality for attacking/blocking, untapped,
  power and color constraints; `130` focused exact-scope tests pass.
- Global all-card readiness after PG308:
  `battle_and_oracle_ready=2038` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `ready_product_qa_unique_cards=818`.
- Global all-card authoritative queue after PG308:
  `target_identity_count=27586`, `xmage_authoritative_source_count=27272`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27272`.
- Running the exact splitter after PG308 on supported units returns
  `proposal_count=0` over `7365` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG309 evidence:

- PG309 permanent activated draw package:
  `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_package.md`
- PG309 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_pg_apply_evidence.md`
- PG309 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_e2e_validation.md`
- PG309 PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg309_xmage_permanent_activated_draw_wave_pg_to_sqlite_sync.json`
- PG309 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg309_permanent_activated_draw_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg309_permanent_activated_draw_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg309_permanent_activated_draw_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg309_permanent_activated_draw_wave.md`
- post-PG309 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg309_permanent_activated_draw_wave_recheck.md`
- post-PG309 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg309_permanent_activated_draw_wave.md`
- PG309 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_draw_wave.md`
- post-PG309 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg309_existing_supported_recheck.md`

PG309 measured result:

- PG309 promoted `18` exact permanent activated draw rules whose local XMage
  source and Oracle text agree on fixed activated card draw.
- Runtime now supports simple permanent activated draw abilities in
  postcombat main, including mana costs, tap costs, colored activation costs,
  self-sacrifice draw costs, library exhaustion checks, hand-size throttling,
  and summoning-sickness blocking for tap-based creature activations.
- PostgreSQL apply evidence reports `18/18` promoted rows, `18/18`
  verified/auto rows, and `18/18` matching Oracle hash rows, with `0` stale
  shadow rows backed up.
- PG -> Hermes/SQLite sync loaded `18` PostgreSQL rows, inserted/updated `18`
  SQLite rows, and exported `4530` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover extraction and runtime execution for simple
  mana/tap activated draw, self-sacrifice draw, discard-cost blocking, and
  dynamic-count blocking; `136` focused exact-scope tests pass.
- Global all-card readiness after PG309:
  `battle_and_oracle_ready=2056` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `ready_product_qa_unique_cards=818`.
- Global all-card authoritative queue after PG309:
  `target_identity_count=27568`, `xmage_authoritative_source_count=27254`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27254`.
- Running the exact splitter after PG309 on supported units returns
  `proposal_count=0` over `7396` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG310 evidence:

- PG310 permanent activated damage package:
  `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_package.md`
- PG310 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_pg_apply_evidence.md`
- PG310 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_e2e_validation.md`
- PG310 PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg310_xmage_permanent_activated_damage_wave_pg_to_sqlite_sync.json`
- PG310 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg310_permanent_activated_damage_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg310_permanent_activated_damage_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg310_permanent_activated_damage_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg310_permanent_activated_damage_wave.md`
- post-PG310 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg310_permanent_activated_damage_wave_recheck.md`
- post-PG310 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg310_permanent_activated_damage_wave.md`
- PG310 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_damage_wave.md`
- post-PG310 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg310_existing_supported_recheck.md`

PG310 measured result:

- PG310 promoted `23` exact permanent activated damage rules whose local XMage
  source and Oracle text agree on fixed activated direct damage.
- Runtime now supports simple permanent activated damage abilities with mana
  costs, colored activation costs, optional tap cost, optional source sacrifice,
  summoning-sickness blocking only when tap is required, player/creature target
  resolution, and replay events that preserve the old `tap_damage` event kind
  for the PG296 scope while using `simple_activated_damage` for PG310.
- PostgreSQL apply evidence reports `23/23` promoted rows, `23/23`
  verified/auto rows, and `23/23` matching Oracle hash rows, with `0` stale
  shadow rows backed up.
- PG -> Hermes/SQLite sync loaded `6946` PostgreSQL rules, inserted/updated
  `6740` SQLite rows, and exported `4553` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover artifact mana/tap/self-sacrifice damage,
  creature colored-cost/self-sacrifice damage, missing-mana blocking,
  unsupported sacrifice-target cost blocking, dynamic amount blocking, and
  player-or-planeswalker target blocking; `143` focused exact-scope tests pass.
- Global all-card readiness after PG310:
  `battle_and_oracle_ready=2079` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `ready_product_qa_unique_cards=818`.
- Global all-card authoritative queue after PG310:
  `target_identity_count=27545`, `xmage_authoritative_source_count=27231`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27231`.
- Running the exact splitter after PG310 on supported units returns
  `proposal_count=0` over `7373` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern,
  with the largest current work units led by `recursion`, `draw_engine`,
  `grant_protection_from_chosen_color`, residual `direct_damage`,
  `source_add_counters`, `life_gain`, `draw_cards`, `removal_destroy`, and
  `tutor`.

PG311 evidence:

- PG311 permanent activated graveyard-to-hand recursion package:
  `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_package.md`
- PG311 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_pg_apply_evidence.md`
- PG311 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_e2e_validation.md`
- PG311 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_pg_to_sqlite_sync.json`
- PG311 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg311_xmage_permanent_activated_recursion_to_hand_wave_battle_rules_pg_to_sqlite_sync.json`
- PG311 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg311_permanent_activated_recursion_to_hand_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg311_permanent_activated_recursion_to_hand_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg311_permanent_activated_recursion_to_hand_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg311_permanent_activated_recursion_to_hand_wave.md`
- post-PG311 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg311_permanent_activated_recursion_to_hand_wave_recheck.md`
- post-PG311 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg311_permanent_activated_recursion_to_hand_wave.md`
- PG311 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_recursion_to_hand_wave.md`
- post-PG311 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg311_existing_supported_recheck.md`

PG311 measured result:

- PG311 promoted `11` exact permanent simple activated graveyard-to-hand
  recursion rules: Adun Oakenshield, Argivian Archaeologist, Corpse Hauler,
  Dowsing Shaman, Font of Return, Groundskeeper, Hanna, Ship's Navigator,
  Rootwater Diver, Salvage Scout, Skull of Orm, and Spellkeeper Weird.
- Runtime now supports colored, generic, and no-mana activation costs; optional
  tap; optional source self-sacrifice; summoning-sickness blocking for
  tap-creature activations; `basic_land` graveyard targets; and legacy Codex
  Shredder event-kind preservation.
- The splitter blocks unsafe neighbors such as discard/exile/OrCost/CompositeCost
  costs, graveyard-source activations, multi-target simple Oracle mismatches,
  watcher conditions, and unsupported subtype restrictions.
- PostgreSQL apply evidence reports `11/11` promoted rows, `11/11`
  verified/auto rows, and `11/11` matching Oracle hash rows, with `0` backup
  rows.
- PG battle-rules -> Hermes/SQLite sync loaded `6957` PostgreSQL rules,
  inserted/updated `6751` SQLite rows, and exported `4564` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover Adun Oakenshield, Font of Return, Rootwater
  Diver, Groundskeeper, discard-cost blocking, OrCost blocking, unsupported
  Restoration Specialist multi-target behavior, and runtime activation
  positives/negatives; `154` focused exact-scope tests pass. The legacy PG273
  Codex Shredder card-specific test also passes.
- Global all-card readiness after PG311:
  `battle_and_oracle_ready=2090` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `snapshot_has_verified_rule=3238`.
- Global all-card authoritative queue after PG311:
  `target_identity_count=27534`, `xmage_authoritative_source_count=27220`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27220`.
- Running the exact splitter after PG311 on supported units returns
  `proposal_count=0` over `7362` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG311 queue. The largest current work units are `recursion`
  `1984`, `draw_engine` `1660`, `grant_protection` `1179`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `754`, `draw_cards` `676`,
  `removal_destroy` `655`, and `tutor` `626`.

PG312 evidence:

- PG312 permanent activated destroy-target package:
  `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_package.md`
- PG312 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_pg_apply_evidence.md`
- PG312 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_e2e_validation.md`
- PG312 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_pg_to_sqlite_sync.json`
- PG312 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg312_xmage_permanent_activated_destroy_wave_battle_rules_pg_to_sqlite_sync.json`
- PG312 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg312_permanent_activated_destroy_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg312_permanent_activated_destroy_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg312_permanent_activated_destroy_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg312_permanent_activated_destroy_wave.md`
- post-PG312 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg312_permanent_activated_destroy_wave_recheck.md`
- post-PG312 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg312_permanent_activated_destroy_wave.md`
- PG312 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_destroy_wave.md`
- post-PG312 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg312_existing_supported_recheck.md`

PG312 measured result:

- PG312 promoted `19` exact permanent simple activated destroy-target rules:
  Ark of Blight, Barbarian Riftcutter, Druid Lyrist, Elf Replica, Elvish
  Lyrist, Elvish Scrapper, Executioner's Capsule, Felidar Cub, Kami of Ancient
  Law, Keening Apparition, Mine Bearer, Priest of Iroas, Reckless Reveler,
  Ronom Unicorn, Royal Assassin, Ruinous Gremlin, Scavenger Folk, Torch Fiend,
  and Universal Solvent.
- Runtime now supports simple activated destroy-target permanents with
  mana/tap/source self-sacrifice activation costs, summoning-sickness blocking
  for tap-creature activations, ward handling after activation cost payment,
  target-constraint legality, and main-phase activation selection.
- The splitter blocks unsafe neighbors such as sacrifice-target costs,
  discard/exile/OrCost/CompositeCost costs, non-simple destroy constructors,
  unsupported targets, and Oracle clauses with extra timing or other effects.
- PostgreSQL apply evidence reports `19/19` promoted rows, `19/19`
  verified/auto rows, and `19/19` matching Oracle hash rows, with `2` backup
  rows from old Royal Assassin rules.
- PG battle-rules -> Hermes/SQLite sync loaded `6976` PostgreSQL rules,
  inserted/updated `6770` SQLite rows, and exported `4582` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for
  legacy trusted SQLite rules without `oracle_hash`; legacy contamination
  `pass`.
- Focused exact-scope tests cover tapped-creature destroy, self-sacrifice
  artifact destroy, sacrifice-target blocking, extra Oracle-clause blocking,
  runtime destroy resolution, source self-sacrifice, and summoning-sickness
  blocking; `161` focused exact-scope tests pass.
- Global all-card readiness after PG312:
  `battle_and_oracle_ready=2109` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `snapshot_has_verified_rule=3257`.
- Global all-card authoritative queue after PG312:
  `target_identity_count=27515`, `xmage_authoritative_source_count=27201`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27201`.
- Running the exact splitter after PG312 on supported units returns
  `proposal_count=0` over `7343` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG312 queue. The largest current work units are `recursion`
  `1984`, `draw_engine` `1660`, `grant_protection` `1179`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `754`, `draw_cards` `676`,
  `removal_destroy` `636`, and `tutor` `626`.

PG313 evidence:

- PG313 permanent activated self-boost package:
  `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_package.md`
- PG313 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_pg_apply_evidence.md`
- PG313 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_e2e_validation.md`
- PG313 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_pg_to_sqlite_sync.json`
- PG313 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg313_xmage_permanent_activated_self_boost_wave_battle_rules_pg_to_sqlite_sync.json`
- PG313 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg313_permanent_activated_self_boost_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg313_permanent_activated_self_boost_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg313_permanent_activated_self_boost_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg313_permanent_activated_self_boost_wave.md`
- post-PG313 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg313_permanent_activated_self_boost_wave_recheck.md`
- post-PG313 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg313_permanent_activated_self_boost_wave.md`
- PG313 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_self_boost_wave.md`
- post-PG313 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg313_existing_supported_recheck.md`

PG313 measured result:

- PG313 promoted `63` exact permanent simple activated self-boost rules. The
  promoted runtime effect is `self_stat_modifier_until_eot`, with target `self`,
  explicit power/toughness deltas, activation cost metadata, tap handling, and
  cleanup at end of turn.
- Runtime now supports simple activated self-boost permanents with mana/tap
  payment, summoning-sickness blocking for tap-creature activations unless the
  source has haste, automatic profitable non-tap power-positive activation, and
  until-end-of-turn stat cleanup.
- The splitter blocks unsafe neighbors such as `PayLifeCost`, discard,
  sacrifice-target, `TapTargetCost`, `UntapSourceCost`, hybrid/Phyrexian/untap
  symbols, X or dynamic boosts, and modal or compound activated text.
- PostgreSQL apply evidence reports `63/63` promoted rows, `63/63`
  verified/auto rows, and `63/63` matching Oracle hash rows, with `1` backup
  row.
- PG battle-rules -> Hermes/SQLite sync loaded `7039` PostgreSQL rules,
  inserted/updated `6833` SQLite rows, and exported `4644` canonical snapshot
  rows.
- PG card metadata -> Hermes/SQLite sync matched `5653` PostgreSQL card rows,
  wrote `5579` SQLite cache alias rows, and backfilled `2699/2699` deck-card
  references.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning for legacy
  trusted SQLite rules without `oracle_hash`; legacy contamination `pass`.
- Focused exact-scope tests cover mapping, colored activation cost parsing,
  blocking target-tap costs, blocking variable boost text, runtime activation
  payment, until-end-of-turn cleanup, summoning-sickness blocking, and automatic
  profitable activation; `168` focused exact-scope tests pass.
- Global all-card readiness after PG313:
  `battle_and_oracle_ready=2172` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `snapshot_has_verified_rule=3320`.
- Global all-card authoritative queue after PG313:
  `target_identity_count=27452`, `xmage_authoritative_source_count=27138`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27138`.
- Running the exact splitter after PG313 on supported units returns
  `proposal_count=0` over `7366` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG313 queue. The largest current work units are `recursion`
  `1984`, `draw_engine` `1660`, `grant_protection` `1179`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `754`, `draw_cards` `676`,
  `removal_destroy` `636`, and `tutor` `626`.

PG314 evidence:

- PG314 permanent activated target-keyword package:
  `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_package.md`
- PG314 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_pg_apply_evidence.md`
- PG314 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_e2e_validation.md`
- PG314 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_pg_to_sqlite_sync.json`
- PG314 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg314_xmage_permanent_activated_target_keyword_wave_battle_rules_pg_to_sqlite_sync.json`
- PG314 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg314_permanent_activated_target_keyword_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg314_permanent_activated_target_keyword_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg314_permanent_activated_target_keyword_wave.md`
- post-PG314 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg314_permanent_activated_target_keyword_wave_recheck.md`
- post-PG314 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg314_permanent_activated_target_keyword_wave.md`
- PG314 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_target_keyword_wave.md`
- post-PG314 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg314_existing_supported_recheck.md`

PG314 measured result:

- PG314 promoted `12` exact permanent simple activated target-keyword rules.
  The promoted runtime effect is `target_keyword_until_eot`, with target
  creature selection, activation cost metadata, tap handling, supported
  keywords `haste`, `flying`, `trample`, and `first_strike`, and cleanup at end
  of turn.
- Runtime now supports simple activated keyword-grant permanents with mana/tap
  payment, summoning-sickness blocking for tap-creature activations, target
  legality through `target_constraints`, and temporary keyword cleanup.
- The splitter blocks unsafe neighbors such as source sacrifice, subtype-only
  target filters, unsupported Oracle text, hybrid/Phyrexian/untap symbols
  inherited from activation cost parsing, target-tap costs, discard, life costs,
  and compound activated text.
- PostgreSQL apply evidence reports `12/12` promoted rows, `12/12`
  verified/auto rows, and `12/12` matching Oracle hash rows, with `0` backup
  rows.
- PG battle-rules -> Hermes/SQLite sync loaded `3446` PostgreSQL rules,
  inserted/updated `4383` SQLite rows, and exported `4648` canonical snapshot
  rows.
- PG card metadata -> Hermes/SQLite sync matched `5653` PostgreSQL card rows,
  wrote `5579` SQLite cache alias rows, and backfilled `2699/2699` deck-card
  references.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning.
- Focused exact-scope tests cover mapping, controlled target selection,
  blocking subtype-filtered targets, blocking source sacrifice, runtime
  activation payment, until-end-of-turn keyword cleanup, and summoning-sickness
  blocking; `174` focused exact-scope tests pass.
- Global all-card readiness after PG314:
  `battle_and_oracle_ready=2184` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `snapshot_has_verified_rule=3332`.
- Global all-card authoritative queue after PG314:
  `target_identity_count=27440`, `xmage_authoritative_source_count=27126`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27126`.
- Running the exact splitter after PG314 on supported units returns
  `proposal_count=0` over `7406` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG314 queue. The largest current work units are `recursion`
  `1984`, `draw_engine` `1660`, `grant_protection` `1167`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `754`, `draw_cards` `676`,
  `removal_destroy` `636`, and `tutor` `626`.

PG315 evidence:

- PG315 permanent activated target-boost package:
  `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_package.md`
- PG315 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_pg_apply_evidence.md`
- PG315 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_e2e_validation.md`
- PG315 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_pg_to_sqlite_sync.json`
- PG315 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg315_xmage_permanent_activated_target_boost_wave_battle_rules_pg_to_sqlite_sync.json`
- PG315 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg315_permanent_activated_target_boost_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg315_permanent_activated_target_boost_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg315_permanent_activated_target_boost_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg315_permanent_activated_target_boost_wave.md`
- post-PG315 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg315_permanent_activated_target_boost_wave_recheck.md`
- post-PG315 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg315_permanent_activated_target_boost_wave.md`
- PG315 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_target_boost_wave.md`
- post-PG315 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg315_existing_supported_recheck.md`

PG315 measured result:

- PG315 promoted `19` exact permanent simple activated target-boost rules. The
  promoted runtime effect is `target_stat_modifier_until_eot`, with target
  creature selection, positive pump/debuff handling, activation cost metadata,
  tap handling, zero-toughness cleanup, and until-end-of-turn cleanup.
- Runtime now supports simple activated target-creature stat modifiers with
  mana/tap payment, summoning-sickness blocking for tap-creature activations,
  target legality through `target_constraints`, beneficial auto-targeting for
  own creatures, and harmful auto-targeting for opponent creatures.
- The splitter blocks unsafe neighbors such as sacrifice target/source costs,
  discard, life, exile, filtered target permanents, dynamic modifiers, target
  pointer variants, and compound activated text.
- PostgreSQL apply evidence reports `19/19` promoted rows, `19/19`
  verified/auto rows, and `19/19` matching Oracle hash rows, with `0` backup
  rows.
- PG battle-rules -> Hermes/SQLite sync loaded `3465` PostgreSQL rules,
  inserted/updated `3464` SQLite rows, and exported `4667` canonical snapshot
  rows.
- PG card metadata -> Hermes/SQLite sync matched `5683` PostgreSQL card rows,
  wrote `5608` SQLite cache alias rows, and backfilled `2699/2699` deck-card
  references after one transient SQLite lock retry.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning; legacy
  contamination `pass`.
- Focused exact-scope tests cover mapping, colored activation cost parsing,
  blocking sacrifice and filtered targets, runtime activation payment,
  beneficial target selection, harmful target selection with zero-toughness
  death, until-end-of-turn cleanup, and summoning-sickness blocking; `181`
  focused exact-scope tests pass.
- Global all-card readiness after PG315:
  `battle_and_oracle_ready=2203` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `snapshot_has_verified_rule=3351`.
- Global all-card authoritative queue after PG315:
  `target_identity_count=27421`, `xmage_authoritative_source_count=27107`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27107`.
- Running the exact splitter after PG315 on supported units returns
  `proposal_count=0` over `7433` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG315 queue. The largest current work units are `recursion`
  `1984`, `draw_engine` `1660`, `grant_protection` `1167`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `754`, `draw_cards` `676`,
  `removal_destroy` `636`, and `tutor` `626`.

PG316 evidence:

- PG316 permanent activated target-boost source-sacrifice package:
  `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_package.md`
- PG316 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_pg_apply_evidence.md`
- PG316 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_e2e_validation.md`
- PG316 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_pg_to_sqlite_sync.json`
- PG316 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg316_xmage_permanent_activated_target_boost_source_sacrifice_wave_battle_rules_pg_to_sqlite_sync.json`
- PG316 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg316_permanent_activated_target_boost_source_sacrifice_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg316_permanent_activated_target_boost_source_sacrifice_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg316_permanent_activated_target_boost_source_sacrifice_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg316_permanent_activated_target_boost_source_sacrifice_wave.md`
- post-PG316 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg316_permanent_activated_target_boost_source_sacrifice_wave_recheck.md`
- post-PG316 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg316_permanent_activated_target_boost_source_sacrifice_wave.md`
- PG316 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_target_boost_source_sacrifice_wave.md`
- post-PG316 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg316_existing_supported_recheck.md`

PG316 measured result:

- PG316 promoted `9` exact permanent simple activated target-boost rules whose
  activation cost sacrifices the source itself: Bloodtallow Candle, Cabal
  Trainee, Child of Thorns, Elven Lyre, Nim Replica, Phyrexian Defiler,
  Phyrexian Denouncer, Seal of Strength, and Shield Mate.
- Runtime now supports `activation_requires_sacrifice` for
  `target_stat_modifier_until_eot`, moves the source permanent to graveyard
  after cost payment, records sacrifice evidence, and uses
  `target_constraints.exclude_source` so a sacrificed creature source is not
  selected as its own target.
- The splitter now accepts Oracle/XMage source-sacrifice costs only for the
  exact "Sacrifice this artifact/creature/enchantment/permanent" source-cost
  pattern. It still blocks sacrifice-target costs, discard costs, multi-ability
  Oracle text, filtered targets, two-target text, and compound activated text.
- PostgreSQL apply evidence reports `9/9` promoted rows, `9/9`
  verified/auto rows, and `9/9` matching Oracle hash rows, with `0` backup
  rows.
- PG battle-rules -> Hermes/SQLite sync loaded `3474` PostgreSQL rules,
  inserted/updated `3473` SQLite rows, and exported `4676` canonical snapshot
  rows.
- PG card metadata -> Hermes/SQLite sync matched `5692` PostgreSQL card rows,
  wrote `5617` SQLite cache alias rows, and backfilled `2699/2699` deck-card
  references after one transient SQLite lock retry.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning; legacy
  contamination `pass`.
- Focused exact-scope tests cover source-sacrifice splitter mapping,
  sacrifice-target blocking, runtime source sacrifice, exclude-source target
  selection, replay evidence, and existing target-boost activation behavior;
  `183` focused exact-scope tests pass.
- Global all-card readiness after PG316:
  `battle_and_oracle_ready=2212` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `snapshot_has_verified_rule=3360`.
- Global all-card authoritative queue after PG316:
  `target_identity_count=27412`, `xmage_authoritative_source_count=27098`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27098`.
- Running the exact splitter after PG316 on supported units returns
  `proposal_count=0` over `7424` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG316 queue. The largest current work units are `recursion`
  `1984`, `draw_engine` `1660`, `grant_protection` `1167`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `754`, `draw_cards` `676`,
  `removal_destroy` `636`, and `tutor` `626`.

PG317 evidence:

- PG317 permanent activated target-keyword with static self-keyword package:
  `docs/hermes-analysis/master_optimizer_reports/pg317_xmage_permanent_activated_target_keyword_static_self_keyword_wave_package.md`
- PG317 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg317_xmage_permanent_activated_target_keyword_static_self_keyword_wave_pg_apply_evidence.md`
- PG317 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg317_xmage_permanent_activated_target_keyword_static_self_keyword_wave_e2e_validation.md`
- PG317 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg317_xmage_permanent_activated_target_keyword_static_self_keyword_wave_pg_to_sqlite_sync.json`
- PG317 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg317_xmage_permanent_activated_target_keyword_static_self_keyword_wave_battle_rules_pg_to_sqlite_sync.json`
- PG317 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg317_permanent_activated_target_keyword_static_self_keyword_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg317_permanent_activated_target_keyword_static_self_keyword_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg317_permanent_activated_target_keyword_static_self_keyword_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg317_permanent_activated_target_keyword_static_self_keyword_wave.md`
- post-PG317 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg317_permanent_activated_target_keyword_static_self_keyword_wave_recheck.md`
- post-PG317 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg317_permanent_activated_target_keyword_static_self_keyword_wave.md`
- PG317 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_target_keyword_static_self_keyword_wave.md`
- post-PG317 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg317_existing_supported_recheck.md`

PG317 measured result:

- PG317 promoted `5` exact permanent simple activated target-keyword rules on
  creatures that also have a leading static self keyword in Oracle/XMage:
  Advance Scout, Harmattan Efreet, Pixie Queen, Pseudodragon Familiar, and Wind
  Dancer.
- The splitter now strips leading static self-keyword Oracle lines before
  matching the activated target-keyword text, while preserving those self-owned
  keywords in `effect_json.keywords` with `_keywords_are_self=true`.
- The splitter still blocks filtered targets, "another target" variants,
  source-sacrifice target-keyword costs, exile/discard costs, and unsupported
  keyword text until narrower adapters exist.
- PostgreSQL apply evidence reports `5/5` promoted rows, `5/5`
  verified/auto rows, and `5/5` matching Oracle hash rows, with `0` backup
  rows.
- PG battle-rules -> Hermes/SQLite sync loaded `3479` PostgreSQL rules,
  inserted/updated `3478` SQLite rows, and exported `4681` canonical snapshot
  rows.
- PG card metadata -> Hermes/SQLite sync matched `5697` PostgreSQL card rows,
  wrote `5622` SQLite cache alias rows, and backfilled `2699/2699` deck-card
  references after one transient SQLite lock retry.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning; legacy
  contamination `pass`.
- Focused exact-scope tests cover leading static self-keyword parsing,
  preservation of source keyword state, target keyword activation and cleanup,
  and existing target-keyword activation behavior; `185` focused exact-scope
  tests pass.
- Global all-card readiness after PG317:
  `battle_and_oracle_ready=2217` all-known cards,
  `ready_product_qa_battle_and_oracle_ready=389`, and
  `snapshot_has_verified_rule=3365`.
- Global all-card authoritative queue after PG317:
  `target_identity_count=27407`, `xmage_authoritative_source_count=27093`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27093`.
- Running the exact splitter after PG317 on supported units returns
  `proposal_count=0` over `7419` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG317 queue. The largest current work units are `recursion`
  `1984`, `draw_engine` `1660`, `grant_protection` `1162`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `754`, `draw_cards` `676`,
  `removal_destroy` `636`, and `tutor` `626`.

PG318 evidence:

- PG318 library tutor spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_package.md`
- PG318 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_pg_apply_evidence.md`
- PG318 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_e2e_validation.md`
- PG318 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_pg_to_sqlite_sync.json`
- PG318 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg318_xmage_library_tutor_spell_wave_battle_rules_pg_to_sqlite_sync_canonical.json`
- PG318 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg318_library_tutor_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg318_library_tutor_spell_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg318_library_tutor_spell_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg318_library_tutor_spell_wave.md`
- post-PG318 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg318_library_tutor_spell_wave_recheck.md`
- post-PG318 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg318_library_tutor_spell_wave_commander_legal.md`
- PG318 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_library_tutor_spell_wave.md`
- post-PG318 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg318_existing_supported_recheck.md`

PG318 measured result:

- PG318 promoted `13` exact one-shot library tutor spells: `Circuitous Route`,
  `Farseek`, `Into the North`, `Natural Connection`, `Nature's Lore`,
  `Personal Tutor`, `Ranger's Path`, `Reshape the Earth`, `Shared Roots`,
  `Skyshroud Claim`, `Spoils of Victory`, `Three Visits`, and `Untamed Wilds`.
- Runtime now supports library-search tutor target families for `forest`,
  `snow_land`, `basic_land_type`, `plains_island_swamp_or_mountain`,
  `basic_land_or_gate`, `basic_land_or_town`, `instant`, and `sorcery`, and
  preserves `tutor_enters_tapped` for battlefield land tutors.
- The splitter blocks additional costs, distinct-name target selection,
  non-spell/ability-class/effect-class unsupported tutor cases, and any
  Oracle/source target/count/destination mismatch.
- PostgreSQL apply evidence reports `13/13` promoted rows, `13/13`
  verified/auto rows, `13/13` matching Oracle hash rows, and `14` stale shadow
  rows backed up.
- PG battle-rules -> Hermes/SQLite sync loaded `3492` PostgreSQL rules,
  inserted/updated `3491` SQLite rows, and exported `4687` canonical snapshot
  rows.
- PG card metadata -> Hermes/SQLite sync matched `5703` PostgreSQL card rows,
  wrote `5628` SQLite cache alias rows, and backfilled `2699/2699` deck-card
  references.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning; legacy
  contamination `pass`.
- Focused exact-scope tests cover strict library tutor splitting, additional
  cost blocking, battlefield tapped-entry preservation, and library-top tutor
  resolution; `190` focused exact-scope tests pass.
- Global all-card readiness after PG318:
  `battle_and_oracle_ready=2230`, `battle_family_mapper_required=30317`, and
  `snapshot_has_verified_rule=3378`.
- Global all-card authoritative queue after PG318:
  `target_identity_count=27394`, `xmage_authoritative_source_count=27080`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27080`.
- Running the exact splitter after PG318 on supported units returns
  `proposal_count=0` over `8032` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG318 queue. The largest current work units are `recursion`
  `1984`, `draw_engine` `1660`, `grant_protection` `1162`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `754`, `draw_cards` `676`,
  `removal_destroy` `636`, and `tutor` `613`.

PG319 evidence:

- PG319 graveyard self-return package:
  `docs/hermes-analysis/master_optimizer_reports/pg319_xmage_graveyard_self_return_wave_package.md`
- PG319 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg319_xmage_graveyard_self_return_wave_pg_apply_evidence.md`
- PG319 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg319_xmage_graveyard_self_return_wave_e2e_validation.md`
- PG319 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg319_xmage_graveyard_self_return_wave_pg_to_sqlite_sync.json`
- PG319 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg319_xmage_graveyard_self_return_wave_battle_rules_pg_to_sqlite_sync.json`
- PG319 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg319_graveyard_self_return_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg319_graveyard_self_return_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg319_graveyard_self_return_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg319_graveyard_self_return_wave.md`
- post-PG319 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg319_graveyard_self_return_wave_recheck.md`
- post-PG319 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg319_graveyard_self_return_wave_commander_legal.md`
- PG319 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_graveyard_self_return_wave.md`
- post-PG319 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg319_existing_supported_recheck.md`

PG319 measured result:

- PG319 promoted `6` exact graveyard self-return cards: `Clay Revenant`,
  `Durable Coilbug`, `Firewing Phoenix`, `Jungle Creeper`,
  `Merchant of Many Hats`, and `Sanitarium Skeleton`.
- Runtime now supports main-phase activation for cards in graveyard with
  `xmage_graveyard_simple_activated_self_return_to_hand_v1`, pays the mana
  activation cost, removes the source card from graveyard, appends it to hand,
  and emits `recursion_resolved` with the exact logical rule fields.
- The splitter blocks non-`SimpleActivatedAbility` variants, additional or
  non-mana costs, non-graveyard source zones, source/Oracle cost mismatch, and
  compound Oracle/source text.
- PostgreSQL apply evidence reports `6/6` promoted rows, `6/6`
  verified/auto rows, `6/6` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `3498` PostgreSQL rules,
  inserted/updated `3497` SQLite rows, and exported `4693` canonical snapshot
  rows.
- PG card metadata -> Hermes/SQLite sync matched `5709` PostgreSQL card rows,
  wrote `5634` SQLite cache alias rows, and backfilled `2699/2699` deck-card
  references.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning; legacy
  contamination `pass`.
- Focused exact-scope tests cover safe self-return splitting, static keyword
  preservation, enters-tapped preservation, additional-cost blocking, mana
  payment, and no-mana negative runtime behavior.
- Global all-card readiness after PG319:
  `battle_and_oracle_ready=2236`, `battle_family_mapper_required=30311`, and
  `snapshot_has_verified_rule=3384`.
- Global all-card authoritative queue after PG319:
  `target_identity_count=27388`, `xmage_authoritative_source_count=27074`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27074`.
- Running the exact splitter after PG319 on supported units returns
  `proposal_count=0` over `8026` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG319 queue. The largest current work units are `recursion`
  `1978`, `draw_engine` `1660`, `grant_protection` `1162`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `754`, `draw_cards` `676`,
  `removal_destroy` `636`, and `tutor` `613`.

PG320 evidence:

- PG320 permanent activated life-gain package:
  `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_package.md`
- PG320 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_pg_apply_evidence.md`
- PG320 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_e2e_validation.md`
- PG320 PG card metadata sync:
  `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_pg_to_sqlite_sync.json`
- PG320 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg320_xmage_permanent_activated_life_gain_wave_battle_rules_pg_to_sqlite_sync.json`
- PG320 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg320_permanent_activated_life_gain_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg320_permanent_activated_life_gain_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg320_permanent_activated_life_gain_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg320_permanent_activated_life_gain_wave.md`
- post-PG320 readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg320_permanent_activated_life_gain_wave_recheck.md`
- post-PG320 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg320_permanent_activated_life_gain_wave_commander_legal.md`
- PG320 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_permanent_activated_life_gain_wave.md`
- post-PG320 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg320_existing_supported_recheck.md`

PG320 measured result:

- PG320 promoted `14` exact battlefield permanents with simple activated fixed
  life-gain abilities: `Bottle Gnomes`, `Braidwood Cup`, `Brindle Boar`,
  `Dedicated Martyr`, `Font of Vigor`, `Fountain of Youth`, `Marble Chalice`,
  `Silent Attendant`, `Soulmender`, `Starlight Invoker`, `Stone Haven Medic`,
  `Tanglebloom`, `Tower of Eons`, and `Zarichi Tiger`.
- Runtime now supports main-phase activation for
  `xmage_permanent_simple_activated_life_gain_v1`, pays the activation cost,
  taps the source when required, sacrifices the source when required, applies
  fixed controller life gain, and emits `life_gain_activated` with exact
  logical rule fields.
- The splitter blocks variable life-gain amounts, target-sacrifice costs,
  discard/exile/graveyard costs, non-simple activated abilities, and
  source/Oracle amount or cost mismatches.
- PostgreSQL apply evidence reports `14/14` promoted rows, `14/14`
  verified/auto rows, `14/14` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `3512` PostgreSQL rules,
  inserted/updated `3511` SQLite rows, and exported `4707` canonical snapshot
  rows.
- PG card metadata -> Hermes/SQLite sync matched `5723` PostgreSQL card rows,
  wrote `5648` SQLite cache alias rows, and backfilled `2699/2699` deck-card
  references.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Final alignment audits: XMage strategy `26/26` pass; operational surface
  `pass`; PG/Hermes/SQLite contract `48` pass with `1` known warning; legacy
  contamination `pass`.
- Focused exact-scope tests cover safe activated life-gain splitting,
  source-sacrifice blocking/selection, dynamic amount blocking, mana payment,
  tapping, life total mutation, and self-sacrifice movement to graveyard.
- Global all-card readiness after PG320:
  `battle_and_oracle_ready=2250`, `battle_family_mapper_required=30297`, and
  `snapshot_has_verified_rule=3398`.
- Global all-card authoritative queue after PG320:
  `target_identity_count=27374`, `xmage_authoritative_source_count=27060`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27060`.
- Running the exact splitter after PG320 on supported units returns
  `proposal_count=0` over `8012` considered supported rows.
- The next work must implement another exact runtime-backed family/subpattern
  from the post-PG320 queue. The largest current work units are `recursion`
  `1978`, `draw_engine` `1660`, `grant_protection` `1162`, `direct_damage`
  `928`, `source_add_counters` `795`, `life_gain` `740`, `draw_cards` `676`,
  `removal_destroy` `636`, and `tutor` `613`.

PG321 evidence:

- PG321 static controlled power/toughness package:
  `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_package.md`
- PG321 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_pg_apply_evidence.md`
- PG321 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_pg_to_sqlite_sync.json`
- PG321 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg321_xmage_static_controlled_power_toughness_boost_wave_e2e_validation.md`
- PG321 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg321_static_controlled_power_toughness_boost_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg321_static_controlled_power_toughness_boost_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg321_static_controlled_power_toughness_boost_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg321_static_controlled_power_toughness_boost_wave.md`
- PG321 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg321_static_controlled_pt_wave.md`
- post-PG321 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg321_static_controlled_power_toughness_boost_wave_commander_legal.md`

PG321 measured result:

- PG321 promoted `32` exact static controlled-creature power/toughness boosts
  from `BoostControlledEffect + SimpleStaticAbility`, including anthem effects,
  Sliver/Warrior/Soldier/Vampire/Squirrel/Elf/Dinosaur filters, artifact
  creature filters, and legendary creature filters.
- Runtime now supports `xmage_static_controlled_power_toughness_boost_v1` via
  controller battlefield refresh, `excludeSource`, artifact/subtype/supertype
  constraints, source-leave recalculation, and non-accumulating static deltas
  that preserve other power/toughness mutations.
- The splitter blocks color/state/conditional filters such as white creatures,
  attacking creatures, untapped creatures, enchanted creatures, and multi-subtype
  predicate-or text until those layer/filter models are implemented.
- PostgreSQL apply evidence reports `32/32` promoted rows, `32/32`
  verified/auto rows, `32/32` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7149` PostgreSQL rules,
  inserted/updated `6920` SQLite rows, and exported `4747` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Post-PG321 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG321 rows themselves have `32/32` matching Oracle hashes.
- Global all-card authoritative queue after PG321:
  `target_identity_count=27342`, `xmage_authoritative_source_count=27028`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27028`.

PG322 evidence:

- PG322 controlled boost until EOT package:
  `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_package.md`
- PG322 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_pg_apply_evidence.md`
- PG322 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_pg_to_sqlite_sync.json`
- PG322 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg322_xmage_boost_controlled_until_eot_wave_e2e_validation.md`
- PG322 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg322_boost_controlled_until_eot_wave_docs_recheck.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg322_boost_controlled_until_eot_wave_docs_recheck.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg322_boost_controlled_until_eot_wave_docs_recheck.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg322_boost_controlled_until_eot_wave_docs_recheck.md`
- PG322 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg322_boost_controlled_until_eot_wave.md`
- post-PG322 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg322_boost_controlled_until_eot_wave_commander_legal.md`
- post-PG322 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg322_existing_supported_recheck.md`
- post-PG322 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg322_boost_controlled_until_eot_wave_recheck.md`

PG322 measured result:

- PG322 promoted `19` exact one-shot spells whose local XMage source is one
  fixed `BoostControlledEffect` and whose Oracle text is exactly "Creatures you
  control get +N/+N until end of turn."
- Runtime now supports `controlled_stat_modifier_until_eot`, applies the
  modifier only to the controller's current battlefield creatures, records
  until-end-of-turn power/toughness cleanup, and preserves opposing creatures.
- The splitter blocks unsafe neighbors such as white-creature filters,
  modal/two-effect spells, and dynamic/source-filtered variants until narrower
  filter and modal adapters exist.
- PostgreSQL apply evidence reports `19/19` promoted rows, `19/19`
  verified/auto rows, `19/19` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7168` PostgreSQL rules,
  inserted/updated `6962` SQLite rows, and exported `4766` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Post-PG322 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG322 rows themselves have `19/19` matching Oracle hashes.
- Global all-card readiness after PG322:
  `battle_and_oracle_ready=2301`, `battle_family_mapper_required=30246`, and
  `snapshot_has_verified_rule=3449`.
- Global all-card authoritative queue after PG322:
  `target_identity_count=27323`, `xmage_authoritative_source_count=27009`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=27009`.
- Running the exact splitter after PG322 on supported units returns
  `proposal_count=0` over `8030` considered supported rows.

PG323 evidence:

- PG323 creature ETB add-counters package:
  `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_package.md`
- PG323 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_pg_apply_evidence.md`
- PG323 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_pg_to_sqlite_sync.json`
- PG323 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg323_xmage_creature_etb_add_counters_wave_e2e_validation.md`
- PG323 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg323_creature_etb_add_counters_wave_docs_final.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg323_creature_etb_add_counters_wave_docs_final.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg323_creature_etb_add_counters_wave_docs_final.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg323_creature_etb_add_counters_wave_docs_final.md`
- PG323 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg323_creature_etb_add_counters_wave.md`
- post-PG323 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg323_creature_etb_add_counters_wave_commander_legal.md`
- post-PG323 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg323_existing_supported_recheck.md`
- post-PG323 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg323_creature_etb_add_counters_wave_recheck.md`

PG323 measured result:

- PG323 promoted `11` exact creatures whose local XMage source is
  `AddCountersTargetEffect` behind `EntersBattlefieldTriggeredAbility`, whose
  Oracle text is exactly one target creature receiving a fixed `+1/+1` or
  `-1/-1` counter, and whose source target is simple `TargetCreaturePermanent()`.
- Runtime now resolves `etb_add_counters_count` after the creature enters the
  battlefield, uses the same beneficial/harmful target selection as the spell
  counter adapter, keeps the source creature on the battlefield, and applies
  zero-toughness cleanup for `-1/-1` counters.
- The splitter intentionally blocks multi-target, "another target creature you
  control", subtype-filtered, conditional, and non-simple target variants until
  narrower adapters exist.
- PostgreSQL apply evidence reports `11/11` promoted rows, `11/11`
  verified/auto rows, `11/11` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7179` PostgreSQL rules,
  inserted/updated `6973` SQLite rows, and exported `4777` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Post-PG323 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG323 rows themselves have `11/11` matching Oracle hashes.
- Global all-card readiness after PG323:
  `battle_and_oracle_ready=2312`, `battle_family_mapper_required=30235`, and
  `snapshot_has_verified_rule=3460`.
- Global all-card authoritative queue after PG323:
  `target_identity_count=27312`, `xmage_authoritative_source_count=26998`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26998`.
- Running the exact splitter after PG323 on supported units returns
  `proposal_count=0` over `8019` considered supported rows.

PG324 evidence:

- PG324 permanent fixed tap-mana-source package:
  `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_package.md`
- PG324 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_pg_apply_evidence.md`
- PG324 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_pg_to_sqlite_sync.json`
- PG324 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg324_xmage_permanent_fixed_tap_mana_wave_e2e_validation.md`
- PG324 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg324_permanent_fixed_tap_mana_wave_docs_final_recheck.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg324_permanent_fixed_tap_mana_wave_docs_final.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg324_permanent_fixed_tap_mana_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg324_permanent_fixed_tap_mana_wave.md`
- PG324 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg324_permanent_fixed_tap_mana_wave.md`
- post-PG324 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg324_permanent_fixed_tap_mana_wave_commander_legal.md`
- post-PG324 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg324_existing_supported_recheck.md`
- post-PG324 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg324_permanent_fixed_tap_mana_wave_recheck.md`

PG324 measured result:

- PG324 promoted `16` exact permanent mana-source rules using
  `xmage_simple_tap_mana_source_permanent_v1` with fixed produced mana symbols
  and optional simple activation mana costs. The promoted cards are
  `Apprentice Wizard`, `Fyndhorn Elder`, `Golgari Signet`,
  `Greenweaver Druid`, `Gruul Signet`, `Gyre Engineer`, `Knotvine Mystic`,
  `Kozilek's Channeler`, `Llanowar Tribe`, `Nantuko Elder`, `Orzhov Signet`,
  `Palladium Myr`, `Rakdos Signet`, `Selesnya Signet`,
  `Sunastian Falconer`, and `Weaver of Currents`.
- Runtime now preserves fixed multi-symbol mana production through
  `produced_mana_symbols`, so `{G}{U}` becomes one green plus one blue and
  `{C}{C}{C}` becomes three colorless rather than flexible generic mana.
  Runtime also pays simple `activation_mana_cost` before adding the produced
  symbols, proven by the focused `Apprentice Wizard` positive and negative
  tests.
- The splitter now blocks unsafe neighbors with explicit reasons for source
  sacrifice, target sacrifice, discard, pay-life, conditional/restricted mana,
  missing tap cost, and non-simple Oracle text.
- Focused tests pass for the exact splitter (`146` tests) and runtime
  (`81` tests).
- PostgreSQL apply evidence reports `16/16` promoted rows, `16/16`
  verified/auto rows, `16/16` matching Oracle hash rows, and `14` stale shadow
  rows backed up/deprecated.
- PG battle-rules -> Hermes/SQLite sync loaded `7195` PostgreSQL rules,
  inserted/updated `6989` SQLite rows, and exported `4786` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Post-PG324 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG324 rows themselves have `16/16` matching Oracle hashes.
- Global all-card readiness after PG324:
  `battle_and_oracle_ready=2328`, `battle_family_mapper_required=30219`, and
  `snapshot_has_verified_rule=3476`.
- Global all-card authoritative queue after PG324:
  `target_identity_count=27296`, `xmage_authoritative_source_count=26982`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26982`.
- Running the exact splitter after PG324 on supported units returns
  `proposal_count=0` over `8003` considered supported rows.

PG325 evidence:

- PG325 recursion exile-self package:
  `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_package.md`
- PG325 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_pg_apply_evidence.md`
- PG325 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_pg_to_sqlite_sync.json`
- PG325 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg325_xmage_recursion_exile_self_wave_e2e_validation.md`
- PG325 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg325_recursion_exile_self_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg325_recursion_exile_self_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg325_recursion_exile_self_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg325_recursion_exile_self_wave.md`
- PG325 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg325_recursion_exile_self_wave.md`
- post-PG325 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg325_recursion_exile_self_wave_commander_legal.md`
- post-PG325 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg325_existing_supported_recheck.md`
- post-PG325 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg325_recursion_exile_self_wave_recheck.md`

PG325 measured result:

- PG325 promoted `3` exact recursion spells with
  `ReturnFromGraveyardToHandTargetEffect + ExileSpellEffect`, no additional
  ability class, fixed target/count Oracle text, and explicit self-exile on
  resolution. The promoted cards are `Flood of Recollection`, `Restock`, and
  `Treasured Find`.
- Runtime already supported `exiles_self` on recursion resolution; PG325
  strengthened the splitter and package manifest so `target`, `count`,
  `destination`, `target_controller`, `target_constraints`, and `exiles_self`
  are required by E2E checks.
- Focused tests pass for the exact splitter (`148` tests), runtime (`82`
  tests), and package builder (`4` tests).
- PostgreSQL precheck found `3/3` target rows, `0` existing expected rows, and
  `0` stale shadow rows.
- PostgreSQL apply evidence reports `3/3` promoted rows, `3/3` verified/auto
  rows, `3/3` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7198` PostgreSQL rules,
  inserted/updated `6992` SQLite rows, and exported `4789` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate under the stronger manifest checks.
- Post-PG325 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG325 rows themselves have `3/3` matching Oracle hashes.
- Global all-card readiness after PG325:
  `battle_and_oracle_ready=2331`, `battle_family_mapper_required=30216`, and
  `snapshot_has_verified_rule=3479`.
- Global all-card authoritative queue after PG325:
  `target_identity_count=27293`, `xmage_authoritative_source_count=26979`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26979`.
- Running the exact splitter after PG325 on supported units returns
  `proposal_count=0` over `8000` considered supported rows.

PG326 evidence:

- PG326 recursion fixed-target package:
  `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_package.md`
- PG326 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_pg_apply_evidence.md`
- PG326 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_pg_to_sqlite_sync.json`
- PG326 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg326_xmage_recursion_fixed_target_wave_e2e_validation.md`
- PG326 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg326_recursion_fixed_target_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg326_recursion_fixed_target_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg326_recursion_fixed_target_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg326_recursion_fixed_target_wave.md`
- PG326 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg326_recursion_fixed_target_wave.md`
- post-PG326 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg326_recursion_fixed_target_wave_commander_legal.md`
- post-PG326 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg326_existing_supported_recheck.md`
- post-PG326 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg326_recursion_fixed_target_wave_recheck.md`

PG326 measured result:

- PG326 promoted `4` exact recursion spells using
  `ReturnFromGraveyardToHandTargetEffect`, no additional ability class, and
  fixed graveyard target constraints. The promoted cards are `Boggart Birth
  Rite`, `Death's Duet`, `Reborn Hope`, and `Revive`.
- Runtime now recognizes `green_card`, `multicolored_card`, and `goblin_card`
  graveyard recursion targets, in addition to the existing fixed creature
  target count path.
- Focused tests pass for the exact splitter (`150` tests), runtime (`83`
  tests), and package builder (`4` tests).
- PostgreSQL precheck found `4/4` target rows, `0` existing expected rows, and
  `0` stale shadow rows.
- PostgreSQL apply evidence reports `4/4` promoted rows, `4/4` verified/auto
  rows, `4/4` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7202` PostgreSQL rules,
  inserted/updated `6996` SQLite rows, and exported `4793` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate.
- Post-PG326 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG326 rows themselves have `4/4` matching Oracle hashes.
- Global all-card readiness after PG326:
  `battle_and_oracle_ready=2335`, `battle_family_mapper_required=30212`, and
  `snapshot_has_verified_rule=3483`.
- Global all-card authoritative queue after PG326:
  `target_identity_count=27289`, `xmage_authoritative_source_count=26975`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26975`.
- Running the exact splitter after PG326 on supported units returns
  `proposal_count=0` over `7996` considered supported rows.

PG327 evidence:

- PG327 recursion choose-one-or-both package:
  `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_package.md`
- PG327 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_pg_apply_evidence.md`
- PG327 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_pg_to_sqlite_sync.json`
- PG327 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg327_xmage_recursion_choose_one_or_both_wave_e2e_validation.md`
- PG327 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg327_recursion_choose_one_or_both_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg327_recursion_choose_one_or_both_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg327_recursion_choose_one_or_both_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg327_recursion_choose_one_or_both_wave.md`
- PG327 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg327_recursion_choose_one_or_both_wave.md`
- post-PG327 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg327_recursion_choose_one_or_both_wave_commander_legal.md`
- post-PG327 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg327_existing_supported_recheck.md`
- post-PG327 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg327_recursion_choose_one_or_both_wave_recheck.md`

PG327 measured result:

- PG327 promoted `7` exact modal recursion spells with
  `ReturnFromGraveyardToHandTargetEffect`, no additional ability class,
  XMage `setMinModes(1)/setMaxModes(2)` source agreement, and exact
  choose-one-or-both Oracle text. The promoted cards are `Aid the Fallen`,
  `Fortuitous Find`, `Grim Discovery`, `Remember the Fallen`,
  `Reviving Melody`, `Season of Renewal`, and `Survivors' Bond`.
- Runtime now resolves `mode_selection=one_or_both` recursion components
  sequentially, preserving distinct graveyard targets across component
  resolution and supporting `human_creature`, `non_human_creature`, and
  `planeswalker` graveyard target filters.
- Focused tests pass for the exact splitter (`152` tests), runtime (`84`
  tests), and package builder (`4` tests).
- PostgreSQL precheck found `7/7` target rows, `0` existing expected rows, and
  `0` stale shadow rows.
- PostgreSQL apply evidence reports `7/7` promoted rows, `7/7` verified/auto
  rows, `7/7` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7209` PostgreSQL rules,
  inserted/updated `7003` SQLite rows, and exported `4800` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate.
- Post-PG327 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG327 rows themselves have `7/7` matching Oracle hashes.
- Global all-card readiness after PG327:
  `battle_and_oracle_ready=2342`, `battle_family_mapper_required=30205`, and
  `snapshot_has_verified_rule=3490`.
- Global all-card authoritative queue after PG327:
  `target_identity_count=27282`, `xmage_authoritative_source_count=26968`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26968`.
- Running the exact splitter after PG327 on supported units returns
  `proposal_count=0` over `7989` considered supported rows.

PG328 evidence:

- PG328 recursion choose-one package:
  `docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_package.md`
- PG328 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_pg_apply_evidence.md`
- PG328 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_pg_to_sqlite_sync.json`
- PG328 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg328_xmage_recursion_choose_one_wave_e2e_validation.md`
- PG328 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg328_recursion_choose_one_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg328_recursion_choose_one_wave.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg328_recursion_choose_one_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg328_recursion_choose_one_wave.md`
- PG328 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg328_recursion_choose_one_wave.md`
- post-PG328 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg328_recursion_choose_one_wave_commander_legal.md`
- post-PG328 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg328_existing_supported_recheck.md`
- post-PG328 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg328_recursion_choose_one_wave_recheck.md`

PG328 measured result:

- PG328 promoted `5` exact choose-one recursion spells with
  `ReturnFromGraveyardToHandTargetEffect`, no additional ability class, XMage
  `addMode` source agreement, and exact choose-one Oracle text. The promoted
  cards are `Ghoulcaller's Chant`, `March of the Drowned`, `Raise the Draugr`,
  `Return from Extinction`, and `Unbury`.
- Runtime now handles `mode_selection=choose_one` by scoring recursion
  components and resolving only the best mode. It supports subtype targets
  `zombie_card` and `pirate_card`, plus `shared_creature_type` selection for
  two creature cards sharing a subtype.
- Focused tests pass for the exact splitter (`154` tests), runtime (`86`
  tests), and package builder (`4` tests).
- PostgreSQL precheck found `5/5` target rows, `0` existing expected rows, and
  `0` stale shadow rows.
- PostgreSQL apply evidence reports `5/5` promoted rows, `5/5` verified/auto
  rows, `5/5` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7214` PostgreSQL rules,
  inserted/updated `7008` SQLite rows, and exported `4805` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate.
- Post-PG328 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG328 rows themselves have `5/5` matching Oracle hashes.
- Global all-card readiness after PG328:
  `battle_and_oracle_ready=2347`, `battle_family_mapper_required=30200`, and
  `snapshot_has_verified_rule=3495`.
- Global all-card authoritative queue after PG328:
  `target_identity_count=27277`, `xmage_authoritative_source_count=26963`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26963`.
- Running the exact splitter after PG328 on supported units returns
  `proposal_count=0` over `7984` considered supported rows.

PG329 evidence:

- PG329 recursion battlefield simple package:
  `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_package.md`
- PG329 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_pg_apply_evidence.md`
- PG329 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_pg_to_sqlite_sync.json`
- PG329 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg329_xmage_recursion_battlefield_simple_wave_e2e_validation.md`
- PG329 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg329_recursion_battlefield_simple_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg329_recursion_battlefield_simple_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg329_recursion_battlefield_simple_wave.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg329_recursion_battlefield_simple_wave.md`
- PG329 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg329_recursion_battlefield_simple_wave.md`
- post-PG329 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg329_recursion_battlefield_simple_wave_commander_legal.md`
- post-PG329 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg329_supported_recheck.md`
- post-PG329 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg329_recursion_battlefield_simple_wave_recheck.md`

PG329 measured result:

- PG329 promoted `3` exact graveyard-to-battlefield recursion spells:
  `Ashen Powder`, `Helping Hand`, and `Hymn of Rebirth`.
- Runtime now distinguishes the graveyard source controller from the
  battlefield controller for recursion effects. This supports opponent
  graveyard and any-player graveyard targets entering under the source
  controller's control, while preserving prior self-graveyard behavior.
- Runtime also preserves exact `enters_tapped` and mana-value limit semantics
  for the battlefield recursion scope.
- Focused tests pass for the exact splitter (`156` tests), runtime (`89`
  tests), and package builder (`4` tests).
- PostgreSQL precheck found `3/3` target rows, `0` existing expected rows, and
  `0` stale shadow rows.
- PostgreSQL apply evidence reports `3/3` promoted rows, `3/3` verified/auto
  rows, `3/3` matching Oracle hash rows, and `0` backup rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7217` PostgreSQL rules,
  inserted/updated `7011` SQLite rows, and exported `4808` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate.
- Post-PG329 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG329 rows themselves have `3/3` matching Oracle hashes.
- Global all-card readiness after PG329:
  `battle_and_oracle_ready=2350`, `battle_family_mapper_required=30197`, and
  `snapshot_has_verified_rule=3498`.
- Global all-card authoritative queue after PG329:
  `target_identity_count=27274`, `xmage_authoritative_source_count=26960`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26960`.
- Running the exact splitter after PG329 on supported units returns
  `proposal_count=0` over `7981` considered supported rows.

PG330 evidence:

- PG330 creature ETB recursion extended package:
  `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_package.md`
- PG330 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_pg_apply_evidence.md`
- PG330 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_pg_to_sqlite_sync.json`
- PG330 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg330_xmage_creature_etb_recursion_extended_wave_e2e_validation.md`
- PG330 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg330_creature_etb_recursion_extended_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg330_creature_etb_recursion_extended_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg330_creature_etb_recursion_extended_wave_final_docs.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg330_creature_etb_recursion_extended_wave_final_docs.md`
- PG330 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg330_creature_etb_recursion_extended_wave.md`
- post-PG330 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg330_creature_etb_recursion_extended_wave_commander_legal.md`
- post-PG330 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg330_supported_recheck.md`
- post-PG330 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg330_creature_etb_recursion_extended_wave_recheck.md`

PG330 measured result:

- PG330 promoted `7` exact creature ETB graveyard-to-hand recursion rules:
  `Barrow Witches`, `Disciple of the Sun`, `Leonin Squire`,
  `Pillardrop Rescuer`, `Ragamuffin Raptor`, `Scholar of the Ages`, and
  `Strongarm Thug`.
- The splitter now supports constrained ETB recursion targets for subtype cards
  (`Knight`, `Mercenary`), artifact/permanent/creature cards with mana-value
  ceilings, instant and/or sorcery cards, and creature-or-Food cards.
- Runtime now matches those recursion target constraints, including
  `creature_or_food`, subtype cards, and mana-value ceilings.
- Focused tests pass for the exact splitter (`160` tests), runtime (`92`
  tests), and package builder (`4` tests).
- PostgreSQL post-apply evidence reports `7/7` promoted rows, `7/7`
  verified/auto rows, and `7/7` matching Oracle hash rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7224` PostgreSQL rules,
  inserted/updated `7018` SQLite rows, and exported `4815` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate.
- Post-PG330 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG330 rows themselves have `7/7` matching Oracle hashes.
- Global all-card readiness after PG330:
  `battle_and_oracle_ready=2357`, `battle_family_mapper_required=30190`, and
  `snapshot_has_verified_rule=3505`.
- Global all-card authoritative queue after PG330:
  `target_identity_count=27267`, `xmage_authoritative_source_count=26953`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26953`.
- Running the exact splitter after PG330 on supported units returns
  `proposal_count=0` over `7974` considered supported rows.

PG331 evidence:

- PG331 creature dies recursion package:
  `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_package.md`
- PG331 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_pg_apply_evidence.md`
- PG331 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_pg_to_sqlite_sync.json`
- PG331 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg331_xmage_creature_dies_recursion_wave_e2e_validation.md`
- PG331 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg331_creature_dies_recursion_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg331_creature_dies_recursion_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg331_creature_dies_recursion_wave_final_docs.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg331_creature_dies_recursion_wave_final_docs.md`
- PG331 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg331_creature_dies_recursion_wave.md`
- post-PG331 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg331_creature_dies_recursion_wave_commander_legal.md`
- post-PG331 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg331_supported_recheck.md`
- post-PG331 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg331_creature_dies_recursion_wave_recheck.md`

PG331 measured result:

- PG331 promoted `5` exact creature dies graveyard-to-hand recursion rules:
  `Dutiful Attendant`, `Elderfang Ritualist`, `Living Lightning`,
  `Myr Retriever`, and `Workshop Assistant`.
- The splitter now supports exact `DiesSourceTriggeredAbility` +
  `ReturnFromGraveyardToHandTargetEffect` creatures with constrained
  controller-graveyard targets for creature, Elf, instant/sorcery, and artifact
  cards.
- Runtime now resolves `dies_recursion_target` only when the permanent moves
  from battlefield to graveyard, excludes the dying source when required, moves
  the selected matching graveyard card to hand, and emits
  `dies_recursion_resolved` replay evidence.
- Focused tests pass for the exact splitter (`162` tests), runtime (`93`
  tests), and package builder (`4` tests).
- PostgreSQL apply evidence reports `5/5` promoted rows, `5/5` verified/auto
  rows, `5/5` matching Oracle hash rows, and `2` stale shadow rows
  backed up/deprecated.
- PG battle-rules -> Hermes/SQLite sync loaded `7229` PostgreSQL rules,
  inserted/updated `7023` SQLite rows, and exported `4819` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate.
- Post-PG331 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG331 rows themselves have `5/5` matching Oracle hashes.
- Global all-card readiness after PG331:
  `battle_and_oracle_ready=2362`, `battle_family_mapper_required=30185`, and
  `snapshot_has_verified_rule=3510`.
- Global all-card authoritative queue after PG331:
  `target_identity_count=27262`, `xmage_authoritative_source_count=26948`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26948`.
- Running the exact splitter after PG331 on supported units returns
  `proposal_count=0` over `7969` considered supported rows.

PG332 evidence:

- PG332 graveyard exile package:
  `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_package.md`
- PG332 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_pg_apply_evidence.md`
- PG332 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_pg_to_sqlite_sync.json`
- PG332 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg332_xmage_graveyard_exile_wave_e2e_validation.md`
- PG332 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg332_graveyard_exile_wave_after_doc_update.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg332_graveyard_exile_wave_after_doc_update.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg332_graveyard_exile_wave_after_doc_update.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg332_graveyard_exile_wave_after_doc_update.md`
- PG332 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg332_graveyard_exile_wave.md`
- post-PG332 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg332_graveyard_exile_wave_commander_legal.md`
- post-PG332 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg332_supported_recheck.md`
- post-PG332 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg332_graveyard_exile_wave_recheck.md`

PG332 measured result:

- PG332 promoted `7` exact simple activated graveyard-exile permanent rules:
  `Carrion Beetles`, `Crypt Creeper`, `Famished Ghoul`, `Heap Doll`,
  `Rag Dealer`, `Thraben Heretic`, and `Withered Wretch`.
- The splitter now supports exact `SimpleActivatedAbility` +
  `ExileTargetEffect` permanents with graveyard targets, fixed target counts,
  single-graveyard targeting where present, and mana/tap/source
  self-sacrifice costs only.
- Runtime now evaluates graveyard-exile activations during main phases, pays
  the activation cost, enforces tap/summoning-sick restrictions, optionally
  sacrifices the source, selects the highest-value graveyard target cards, moves
  them to exile, and emits `graveyard_exile_activated` replay evidence.
- Focused tests pass for the exact splitter (`166` tests), runtime (`96`
  tests), and package builder (`4` tests).
- PostgreSQL apply evidence reports `7/7` promoted rows, `7/7` verified/auto
  rows, `7/7` matching Oracle hash rows, and `0` stale shadow rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7236` PostgreSQL rules,
  inserted/updated `7030` SQLite rows, and exported `4826` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate.
- Post-PG332 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG332 rows themselves have `7/7` matching Oracle hashes.
- Global all-card readiness after PG332:
  `battle_and_oracle_ready=2369`, `battle_family_mapper_required=30178`, and
  `snapshot_has_verified_rule=3517`.
- Global all-card authoritative queue after PG332:
  `target_identity_count=27255`, `xmage_authoritative_source_count=26941`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26941`.
- Running the exact splitter after PG332 on supported units returns
  `proposal_count=0` over `7962` considered supported rows.

PG333 evidence:

- PG333 graveyard self-return battlefield package:
  `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_package.md`
- PG333 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_pg_apply_evidence.md`
- PG333 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_pg_to_sqlite_sync.json`
- PG333 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg333_xmage_graveyard_self_return_battlefield_wave_e2e_validation.md`
- PG333 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg333_graveyard_self_return_battlefield_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg333_graveyard_self_return_battlefield_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg333_graveyard_self_return_battlefield_wave_final_docs.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg333_graveyard_self_return_battlefield_wave_final_docs.md`
- PG333 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg333_graveyard_self_return_battlefield_wave.md`
- post-PG333 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg333_graveyard_self_return_battlefield_wave_commander_legal.md`
- post-PG333 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg333_supported_recheck.md`
- post-PG333 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg333_graveyard_self_return_battlefield_wave_recheck.md`

PG333 measured result:

- PG333 promoted `3` exact simple activated graveyard self-return-to-battlefield
  rules: `Persistent Specimen`, `Reassembling Skeleton`, and `Tunnel Rats`.
- The splitter now supports exact `ReturnSourceFromGraveyardToBattlefieldEffect`
  cards with `SimpleActivatedAbility` in `Zone.GRAVEYARD`, mana-only activation
  costs, exact self-return Oracle/source agreement, and tapped battlefield
  entry.
- Runtime now evaluates graveyard self-return activations to either hand or
  battlefield depending on `graveyard_self_return_destination`, pays the
  activation cost, moves battlefield-returned cards from graveyard to battlefield
  tapped, applies summoning sickness, and emits destination-specific recursion
  replay evidence.
- Focused tests pass for the exact splitter (`168` tests), runtime (`98`
  tests), and package builder (`4` tests).
- PostgreSQL apply evidence reports `3/3` promoted rows, `3/3` verified/auto
  rows, `3/3` matching Oracle hash rows, and `2` stale shadow rows deprecated.
- PG battle-rules -> Hermes/SQLite sync loaded `7239` PostgreSQL rules,
  inserted/updated `7033` SQLite rows, and exported `4828` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate.
- Post-PG333 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The only residual
  warning is inherited SQLite cache coverage for old executable rules without
  `oracle_hash`; PG333 rows themselves have `3/3` matching Oracle hashes.
- Global all-card readiness after PG333:
  `battle_and_oracle_ready=2372`, `battle_family_mapper_required=30175`, and
  `snapshot_has_verified_rule=3520`.
- Global all-card authoritative queue after PG333:
  `target_identity_count=27252`, `xmage_authoritative_source_count=26938`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26938`.
- Running the exact splitter after PG333 on supported units returns
  `proposal_count=0` over `7959` considered supported rows.

PG334 evidence:

- PG334 graveyard-to-library spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_package.md`
- PG334 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_pg_apply_evidence.md`
- PG334 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_pg_to_sqlite_sync.json`
- PG334 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg334_xmage_graveyard_to_library_spell_wave_e2e_validation.md`
- PG334 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg334_graveyard_to_library_spell_wave.md`
- post-PG334 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg334_graveyard_to_library_spell_wave_commander_legal.md`
- post-PG334 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg334_supported_recheck.md`
- post-PG334 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg334_graveyard_to_library_spell_wave_recheck.md`

PG334 measured result:

- PG334 promoted `4` exact graveyard-to-library spell rules: `False Mourning`,
  `Reclaim`, `Reinforcements`, and `Salvage`.
- The splitter now supports exact spell-only `PutOnLibraryTargetEffect` rows
  with self-graveyard targets, top/bottom library destinations, and no
  additional cost or activation class.
- Runtime recursion now supports `destination=library_top` and
  `destination=library_bottom`, moving recovered cards from the matching
  graveyard to the owner's library instead of falling through to hand.
- Focused tests pass for the exact splitter (`171` tests), runtime (`100`
  tests), and package builder (`4` tests).
- PostgreSQL apply evidence reports `4/4` promoted rows, `4/4` verified/auto
  rows, `4/4` matching Oracle hash rows, and `0` stale shadow rows.
- PG battle-rules -> Hermes/SQLite sync loaded `7243` PostgreSQL rules,
  inserted/updated `7037` SQLite rows, and exported `4832` canonical snapshot
  rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  no-override battle package gate.
- Global all-card readiness after PG334:
  `battle_and_oracle_ready=2376`, `battle_family_mapper_required=30171`, and
  `snapshot_has_verified_rule=3524`.
- Global all-card authoritative queue after PG334:
  `target_identity_count=27248`, `xmage_authoritative_source_count=26934`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26934`.
- Running the exact splitter after PG334 on supported units returns
  `proposal_count=0` over `7955` considered supported rows.

PG335 evidence:

- PG335 battlefield-counter recursion package:
  `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_package.md`
- PG335 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_pg_to_sqlite_sync.json`
- PG335 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg335_xmage_battlefield_counter_recursion_wave_e2e_validation.md`
- PG335 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg335_battlefield_counter_recursion_wave.md`
- post-PG335 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg335_battlefield_counter_recursion_wave_commander_legal.md`
- post-PG335 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg335_supported_recheck.md`
- post-PG335 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg335_battlefield_counter_recursion_wave_recheck.md`
- PG335 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg335_battlefield_counter_recursion_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg335_battlefield_counter_recursion_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg335_battlefield_counter_recursion_wave_final_docs.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg335_battlefield_counter_recursion_wave_final_docs.md`

PG335 measured result:

- PG335 promoted `3` exact graveyard-to-battlefield-with-counter recursion
  spells: `Aberrant Return`, `Evil Reawakened`, and `Unbreakable Bond`.
- The splitter now supports exact spell-only
  `ReturnFromGraveyardToBattlefieldWithCounterTargetEffect` rows with
  supported fixed counters: `+1/+1`, `-1/-1`, and lifelink counters.
- Runtime recursion now applies counters to returned battlefield permanents,
  grants keyword counters where modeled, and performs zero-toughness cleanup
  after `-1/-1` counters.
- Focused tests pass for the exact splitter (`175` tests), runtime (`103`
  tests), and package builder (`4` tests).
- PostgreSQL postcheck reports `3/3` promoted rows, `3/3` verified/auto rows,
  and `3/3` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7246` PostgreSQL rows, inserted/updated
  `7040` SQLite rows, and exported `4835` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Post-PG335 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The PG/Hermes/SQLite
  audit has the inherited single warning for old trusted SQLite rules without
  `oracle_hash`; PG335 rows themselves have `3/3` matching Oracle hashes.
- Global all-card readiness after PG335:
  `battle_and_oracle_ready=2379`, `battle_family_mapper_required=30168`, and
  `snapshot_has_verified_rule=3527`.
- Global all-card authoritative queue after PG335:
  `target_identity_count=27245`, `xmage_authoritative_source_count=26931`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26931`.
- Running the exact splitter after PG335 on supported units returns
  `proposal_count=0` over `7952` considered supported rows.

PG336 evidence:

- PG336 activated graveyard-to-library package:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_package.md`
- PG336 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_pg_apply_evidence.md`
- PG336 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_pg_to_sqlite_sync.json`
- PG336 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg336_xmage_activated_graveyard_to_library_wave_e2e_validation.md`
- PG336 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg336_activated_graveyard_to_library_wave.md`
- post-PG336 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg336_activated_graveyard_to_library_wave_commander_legal.md`
- post-PG336 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg336_supported_recheck.md`
- post-PG336 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg336_activated_graveyard_to_library_wave_recheck.md`
- PG336 final alignment audits:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg336_activated_graveyard_to_library_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg336_activated_graveyard_to_library_wave_final_docs.md`,
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg336_activated_graveyard_to_library_wave_final_docs.md`, and
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg336_activated_graveyard_to_library_wave_final_docs.md`

PG336 measured result:

- PG336 promoted `3` exact permanent activated graveyard-to-library rules:
  `Epitaph Golem`, `Haunted Crossroads`, and `Tomb Trawler`.
- The splitter now supports exact
  `PutOnLibraryTargetEffect + SimpleActivatedAbility` rows on battlefield
  permanents when Oracle and XMage agree on self graveyard, self library,
  target type, count, destination, and simple mana/tap/source-sacrifice costs.
- The residual any-graveyard/owner-library variants remain blocked under
  `activated_graveyard_to_library_oracle_not_simple` until that separate
  owner-library runtime contract exists.
- Runtime now activates those permanents in main phases, pays the modeled cost,
  respects tap/summoning-sickness/source-sacrifice gates, and moves the chosen
  self-graveyard cards to library top or bottom.
- Focused tests pass for the exact splitter (`178` tests), runtime (`107`
  tests), and package builder (`4` tests).
- PostgreSQL postcheck reports `3/3` promoted rows, `3/3` verified/auto rows,
  and `3/3` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7249` PostgreSQL rows, inserted/updated
  `7043` SQLite rows, and exported `4838` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Post-PG336 alignment audits pass for XMage strategy, operational surface,
  PG/Hermes/SQLite contract, and legacy contamination. The PG/Hermes/SQLite
  audit has the inherited single warning for old trusted SQLite rules without
  `oracle_hash`; PG336 rows themselves have `3/3` matching Oracle hashes.
- Global all-card readiness after PG336:
  `battle_and_oracle_ready=2382`, `battle_family_mapper_required=30165`, and
  `snapshot_has_verified_rule=3530`.
- Global all-card authoritative queue after PG336:
  `target_identity_count=27242`, `xmage_authoritative_source_count=26928`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26928`.
- Running the exact splitter after PG336 on supported units returns
  `proposal_count=0` over `7949` considered supported rows.

PG337 evidence:

- PG337 ETB graveyard-to-library package:
  `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_package.md`
- PG337 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_pg_apply_evidence.md`
- PG337 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_pg_to_sqlite_sync.json`
- PG337 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg337_xmage_etb_graveyard_to_library_wave_e2e_validation.md`
- PG337 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg337_etb_graveyard_to_library_wave.md`
- post-PG337 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg337_etb_graveyard_to_library_wave_commander_legal.md`
- post-PG337 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg337_supported_recheck.md`
- post-PG337 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg337_etb_graveyard_to_library_wave_recheck.md`

PG337 measured result:

- PG337 promoted `2` exact creature ETB graveyard-to-library rules:
  `Dukhara Scavenger` and `Meldweb Curator`.
- The splitter now supports exact
  `PutOnLibraryTargetEffect + EntersBattlefieldTriggeredAbility` rows on
  creatures when Oracle and XMage agree on self graveyard, self library, target
  type, count, up-to count, and top/bottom destination.
- The residual any-graveyard/owner-library variants remain blocked under
  `etb_graveyard_to_library_oracle_not_simple`; unsupported source target
  shapes remain blocked under `etb_graveyard_to_library_source_target_not_supported`.
- Runtime now lets ETB recursion move selected self-graveyard cards to
  `library_top` or `library_bottom`, in addition to the existing hand and
  battlefield destinations.
- Focused tests pass for the exact splitter (`181` tests), runtime (`109`
  tests), and package builder (`4` tests).
- PostgreSQL postcheck reports `2/2` promoted rows, `2/2` verified/auto rows,
  and `2/2` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7251` PostgreSQL rows, inserted/updated
  `7045` SQLite rows, and exported `4840` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Global all-card readiness after PG337:
  `battle_and_oracle_ready=2384`, `battle_family_mapper_required=30163`, and
  `snapshot_has_verified_rule=3532`.
- Global all-card authoritative queue after PG337:
  `target_identity_count=27240`, `xmage_authoritative_source_count=26926`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26926`.
- Running the exact splitter after PG337 on supported units returns
  `proposal_count=0` over `7947` considered supported rows.

PG338 evidence:

- PG338 reveal-library-pick package:
  `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_package.md`
- PG338 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_pg_apply_evidence.md`
- PG338 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_pg_to_sqlite_sync.json`
- PG338 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg338_xmage_reveal_library_pick_wave_e2e_validation.md`
- PG338 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg338_reveal_library_pick_wave.md`
- post-PG338 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg338_reveal_library_pick_wave_commander_legal.md`
- post-PG338 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg338_supported_recheck.md`
- post-PG338 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg338_reveal_library_pick_wave_recheck.md`
- post-PG338 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg338_reveal_library_pick_wave.md`
- post-PG338 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg338_reveal_library_pick_wave.md`

PG338 measured result:

- PG338 promoted `6` exact reveal-top-library pick-to-hand rules:
  `Commune with the Gods`, `Glacial Revelation`, `Grisly Salvage`,
  `Kruphix's Insight`, `Pieces of the Puzzle`, and `Scout the Borders`.
- The splitter now supports exact
  `RevealLibraryPickControllerEffect` one-shot spell rows when Oracle and
  XMage agree on `look_count`, `pick_count` or all-matching mode, pick target,
  hand destination, and graveyard rest destination.
- Runtime `dig_to_hand` now respects `pick_target` filters including
  `creature_or_enchantment`, `creature_or_land`, `instant_or_sorcery`,
  `enchantment`, and `snow_permanent`; nonmatching revealed cards go to the
  graveyard even when the ranking heuristic would otherwise prefer them.
- Similar rows with flashback, ETB, activated, or other ability classes remain
  blocked from this exact scope under reasons such as
  `library_pick_ability_class_not_simple`.
- Focused tests pass for the exact splitter (`184` tests), runtime (`111`
  tests), and package builder (`4` tests).
- PostgreSQL postcheck reports `6/6` promoted rows, `6/6` verified/auto rows,
  and `6/6` matching Oracle hash rows, with `2` stale `Grisly Salvage` shadow
  rows backed up and deprecated.
- PG -> Hermes/SQLite sync loaded `7257` PostgreSQL rows, inserted/updated
  `7051` SQLite rows, and exported `4845` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- XMage strategy consistency audit reports `26/26` pass.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual `trusted_executable_rules_missing_oracle_hash=1418`;
  PG338 rows all carry matching Oracle hashes.
- Global all-card readiness after PG338:
  `battle_and_oracle_ready=2390`, `battle_family_mapper_required=30157`, and
  `snapshot_has_verified_rule=3538`.
- Global all-card authoritative queue after PG338:
  `target_identity_count=27234`, `xmage_authoritative_source_count=26920`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26920`.
- Running the exact splitter after PG338 on supported units returns
  `proposal_count=0` over `7941` considered supported rows.

PG339 evidence:

- PG339 ETB library-pick package:
  `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_package.md`
- PG339 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_pg_apply_evidence.md`
- PG339 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_pg_to_sqlite_sync.json`
- PG339 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg339_xmage_etb_library_pick_wave_e2e_validation.md`
- PG339 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg339_etb_library_pick_wave.md`
- post-PG339 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg339_etb_library_pick_wave_commander_legal.md`
- post-PG339 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg339_supported_recheck.md`
- post-PG339 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg339_etb_library_pick_wave_recheck.md`
- post-PG339 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg339_etb_library_pick_wave.md`
- post-PG339 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg339_etb_library_pick_wave.md`

PG339 measured result:

- PG339 promoted `4` exact creature ETB look-library pick-to-hand rules:
  `Organ Hoarder`, `Sibsig Appraiser`, `Sultai Soothsayer`, and `Tower Geist`.
- The splitter now supports exact
  `LookLibraryAndPickControllerEffect + EntersBattlefieldTriggeredAbility`
  creature rows when Oracle and XMage agree on fixed look count, one-card hand
  pick, and graveyard rest destination. Static self keywords such as flying are
  preserved.
- Runtime now resolves `etb_library_look_count` through the same filtered
  `dig_to_hand` executor used by PG338, so ETB permanents move one selected
  card to hand and the rest of the looked cards to graveyard.
- Similar ETB rows with `TOP_ANY`, dynamic X look count, warp/craft/condition,
  exploit, or non-ETB triggers remain blocked under exact blocker reasons such
  as `etb_library_pick_oracle_not_simple`.
- Focused tests pass for the exact splitter (`187` tests), runtime (`112`
  tests), and package builder (`4` tests).
- PostgreSQL postcheck reports `4/4` promoted rows, `4/4` verified/auto rows,
  and `4/4` matching Oracle hash rows, with no stale shadow rows.
- PG -> Hermes/SQLite sync loaded `7261` PostgreSQL rows, inserted/updated
  `7055` SQLite rows, and exported `4849` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- XMage strategy consistency audit reports `26/26` pass.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual `trusted_executable_rules_missing_oracle_hash=1418`;
  PG339 rows all carry matching Oracle hashes.
- Global all-card readiness after PG339:
  `battle_and_oracle_ready=2394`, `battle_family_mapper_required=30153`, and
  `snapshot_has_verified_rule=3542`.
- Global all-card authoritative queue after PG339:
  `target_identity_count=27230`, `xmage_authoritative_source_count=26916`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26916`.
- Running the exact splitter after PG339 on supported units returns
  `proposal_count=0` over `7937` considered supported rows.

PG340 evidence:

- PG340 spell-cast draw-engine package:
  `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_package.md`
- PG340 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_pg_apply_evidence.md`
- PG340 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_pg_to_sqlite_sync.json`
- PG340 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg340_xmage_spell_cast_draw_engine_wave_e2e_validation.md`
- post-PG340 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260701_post_pg340_spell_cast_draw_engine_wave.md`
- post-PG340 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260701_post_pg340_spell_cast_draw_engine_wave.md`
- post-PG340 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260701_post_pg340_spell_cast_draw_engine_wave.md`
- post-PG340 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260701_post_pg340_spell_cast_draw_engine_wave.md`
- PG340 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg340_spell_cast_draw_engine_wave.md`
- post-PG340 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg340_spell_cast_draw_engine_wave_commander_legal.md`
- post-PG340 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_post_pg340_supported_recheck.md`
- post-PG340 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260701_post_pg340_spell_cast_draw_engine_wave_recheck.md`

PG340 measured result:

- PG340 promoted `14` exact spell-cast draw-engine rules:
  `Beast Whisperer`, `Enchantress's Presence`,
  `Jhoira, Weatherlight Captain`, `Mesa Enchantress`, `Primordial Sage`,
  `Reki, the History of Kamigawa`, `Satyr Enchanter`, `Secrets of the Dead`,
  `Sram, Senior Edificer`, `Tanufel Rimespeaker`, `Thunderous Snapper`,
  `Vedalken Archmage`, `Verduran Enchantress`, and
  `Whirlwind of Thought`.
- The splitter now supports exact
  `DrawCardSourceControllerEffect + SpellCastControllerTriggeredAbility`
  permanent rows when Oracle and XMage agree on fixed draw count and one of the
  supported spell filters.
- Runtime now checks the cast spell against card type, subtype, supertype,
  historic, source-zone, and mana-value constraints before drawing cards and
  resolving downstream draw triggers.
- Unsupported or ambiguous rows such as `Dreamcatcher`, `Edgewall Innkeeper`,
  `Lunar Mystic`, and `Emrakul's Influence` remain blocked under exact blocker
  reasons instead of being promoted.
- Focused tests pass for the exact splitter (`191` tests) and runtime (`114`
  tests).
- PostgreSQL postcheck reports `14/14` promoted rows, `14/14` verified/auto
  rows, and `14/14` matching Oracle hash rows, with `16` stale shadow rows
  backed up and deprecated.
- PG -> Hermes/SQLite sync loaded `7275` PostgreSQL rows, inserted/updated
  `7069` SQLite rows, and exported `4855` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual `trusted_executable_rules_missing_oracle_hash=1418`;
  PG340 rows all carry matching Oracle hashes.
- Global all-card readiness after PG340:
  `battle_and_oracle_ready=2408`, `battle_family_mapper_required=30139`, and
  `snapshot_has_verified_rule=3556`.
- Global all-card authoritative queue after PG340:
  `target_identity_count=27216`, `xmage_authoritative_source_count=26902`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26902`.
- Running the exact splitter after PG340 on supported units returns
  `proposal_count=0` over `7941` considered supported rows.

PG341 evidence:

- PG341 recursion auxiliary spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_package.md`
- PG341 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_apply_evidence.md`
- PG341 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_pg_to_sqlite_sync.json`
- PG341 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg341_xmage_recursion_auxiliary_spell_wave_e2e_validation.md`
- post-PG341 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg341_recursion_auxiliary_spell_wave.md`
- post-PG341 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg341_recursion_auxiliary_spell_wave.md`
- post-PG341 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg341_recursion_auxiliary_spell_wave.md`
- post-PG341 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg341_recursion_auxiliary_spell_wave.md`
- PG341 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260701_pg341_recursion_auxiliary_spell_wave.md`
- post-PG341 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg341_recursion_auxiliary_spell_wave_commander_legal.md`
- post-PG341 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg341_supported_recheck.md`
- post-PG341 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg341_recursion_auxiliary_spell_wave_recheck.md`

PG341 measured result:

- PG341 promoted `5` exact graveyard-recursion spell rules with safe
  flashback/cycling auxiliary abilities: `Morgue Theft`, `Mystic Retrieval`,
  `Unburial Rites`, `Unearth`, and `Wander in Death`.
- The splitter now accepts primary graveyard-to-hand or
  graveyard-to-battlefield recursion spells whose auxiliary ability is limited
  to fixed cycling cost or mana-only flashback cost; non-mana flashback such as
  `Dread Return` and non-simple primary recursion such as `Sacred Excavation`
  remain blocked with explicit reasons.
- Runtime coverage is validated through focused flashback-from-graveyard and
  cycling tests. The splitter suite reports `195` tests passing; the runtime
  suite reports `116` tests passing; the PostgreSQL package builder test
  passes.
- PostgreSQL postcheck reports `5/5` promoted rows, `5/5` verified/auto rows,
  and `5/5` matching Oracle hash rows, with `2` stale shadow rows backed up
  and deprecated.
- PG -> Hermes/SQLite sync loaded `7280` PostgreSQL rows, inserted/updated
  `7074` SQLite rows, and exported `4859` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual `trusted_executable_rules_missing_oracle_hash=1418`;
  PG341 rows all carry matching Oracle hashes.
- Global all-card readiness after PG341:
  `battle_and_oracle_ready=2413`, `battle_family_mapper_required=30134`, and
  `snapshot_has_verified_rule=3561`.
- Global all-card authoritative queue after PG341:
  `target_identity_count=27211`, `xmage_authoritative_source_count=26897`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26897`.
- Running the exact splitter after PG341 on supported units returns
  `proposal_count=0` over `7936` considered supported rows. The next cycle
  must add another exact runtime-backed subpattern, not rerun an old package.

PG342 evidence:

- PG342 recursion self-exile spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_package.md`
- PG342 PostgreSQL precheck evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_precheck_evidence.md`
- PG342 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_apply_evidence.md`
- PG342 PostgreSQL postcheck evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_postcheck_evidence.md`
- PG342 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_pg_to_sqlite_sync.json`
- PG342 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg342_xmage_recursion_exile_self_spell_wave_e2e_validation.md`
- post-PG342 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg342_recursion_exile_self_spell_wave.md`
- post-PG342 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg342_recursion_exile_self_spell_wave.md`
- post-PG342 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg342_recursion_exile_self_spell_wave.md`
- post-PG342 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg342_recursion_exile_self_spell_wave.md`
- PG342 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg342_recursion_exile_self_spell_wave.md`
- post-PG342 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg342_recursion_exile_self_spell_wave_commander_legal.md`
- post-PG342 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg342_supported_recheck.md`
- post-PG342 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg342_recursion_exile_self_spell_wave_recheck.md`

PG342 measured result:

- PG342 promoted `3` exact self-exiling graveyard-recursion spell rules:
  `Reconstruct History`, `Retrieve`, and `Vivid Revival`.
- The splitter now accepts exact
  `ExileSpellEffect + ReturnFromGraveyardToHandTargetEffect` spells when
  Oracle and XMage agree on self-exile plus either supported simple
  graveyard-to-hand targets or supported multi-component "up to one target"
  lists. Variable/X self-exile recursion such as `Divergent Equation`,
  `Uncle's Musings`, and `Wildest Dreams` remains blocked.
- Runtime now supports `noncreature_permanent` graveyard target matching and
  existing recursion execution handles `recursion_components`, `mode_selection`
  and `exiles_self` from PostgreSQL-backed `effect_json`.
- Focused splitter/runtime suites report `316` tests passing, and the
  PostgreSQL package builder test passes.
- PostgreSQL precheck found `3/3` target rows, `0/3` expected rules already
  present, and `2` nonmatching shadow rows to deprecate.
- PostgreSQL apply inserted/updated `3` rules and deprecated `2` shadow rows.
- PostgreSQL postcheck reports `3/3` promoted rows, `3/3` verified/auto rows,
  and `3/3` matching Oracle hash rows, with `2` stale shadow rows backed up
  and deprecated.
- PG -> Hermes/SQLite sync loaded `7283` PostgreSQL rows, inserted/updated
  `7077` SQLite rows, and exported `4861` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual `trusted_executable_rules_missing_oracle_hash=1418`;
  PG342 rows all carry matching Oracle hashes.
- Global all-card readiness after PG342:
  `battle_and_oracle_ready=2416`, `battle_family_mapper_required=30131`, and
  `snapshot_has_verified_rule=3564`.
- Global all-card authoritative queue after PG342:
  `target_identity_count=27208`, `xmage_authoritative_source_count=26894`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26894`.
- Running the exact splitter after PG342 on supported units returns
  `proposal_count=0` over `7933` considered supported rows. The next cycle
  must split another exact recursion subpattern or move to the next largest
  reusable work unit if recursion no longer yields a safe package.

PG343 evidence:

- PG343 recursion mill-return package:
  `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_package.md`
- PG343 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_apply_evidence.md`
- PG343 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_pg_to_sqlite_sync.json`
- PG343 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg343_xmage_recursion_mill_return_wave_e2e_validation.md`
- post-PG343 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg343_recursion_mill_return_wave.md`
- post-PG343 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg343_recursion_mill_return_wave.md`
- post-PG343 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg343_recursion_mill_return_wave.md`
- post-PG343 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg343_recursion_mill_return_wave.md`
- PG343 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg343_recursion_mill_return_wave.md`
- post-PG343 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg343_recursion_mill_return_wave_commander_legal.md`
- post-PG343 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg343_supported_recheck.md`
- post-PG343 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg343_recursion_mill_return_wave_recheck.md`

PG343 measured result:

- PG343 promoted `5` exact mill-then-return recursion rules:
  `Acolyte of Affliction`, `Corpse Churn`, `Eccentric Farmer`,
  `Grapple with the Past`, and `Pothole Mole`.
- The splitter now accepts exact
  `MillCardsControllerEffect + ReturnCardChosenFromGraveyardEffect` rows when
  Oracle and XMage agree on mill count, graveyard target filter, effect order,
  and hand destination. Supported targets in this wave are `creature`,
  `creature_or_land`, `land`, and `permanent`.
- Runtime now mills the controller before resolving graveyard recursion for
  both instant/sorcery spells and ETB creatures, so a freshly milled matching
  card can be returned in the same effect.
- Focused splitter/runtime suites report `325` tests passing, and the package
  builder/E2E validator pytest suite reports `6` tests passing.
- PostgreSQL precheck found `5/5` target rows, `0/5` expected rules already
  present, and `2` nonmatching shadow rows to deprecate.
- PostgreSQL apply inserted/updated `5` rules and deprecated `2` shadow rows.
- PostgreSQL postcheck reports `5/5` promoted rows, `5/5` verified/auto rows,
  and `5/5` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7288` PostgreSQL rows, inserted/updated
  `7082` SQLite rows, and exported `4865` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual `trusted_executable_rules_missing_oracle_hash=1418`;
  PG343 rows all carry matching Oracle hashes.
- Global all-card readiness after PG343:
  `battle_and_oracle_ready=2421`, `battle_family_mapper_required=30126`, and
  `snapshot_has_verified_rule=3569`.
- Global all-card authoritative queue after PG343:
  `target_identity_count=27203`, `xmage_authoritative_source_count=26889`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26889`.
- Running the exact splitter after PG343 on supported units returns
  `proposal_count=0` over `7928` considered supported rows. That checkpoint is
  superseded by later package checkpoints below; use only the latest queue in
  the Current Priority Order section for new work.

PG344 evidence:

- PG344 static graveyard-count P/T package:
  `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_package.md`
- PG344 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_apply_evidence.md`
- PG344 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_pg_to_sqlite_sync.json`
- PG344 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg344_xmage_static_graveyard_count_pt_wave_e2e_validation.md`
- post-PG344 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg344_static_graveyard_count_pt_wave.md`
- post-PG344 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg344_static_graveyard_count_pt_wave.md`
- post-PG344 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg344_static_graveyard_count_pt_wave.md`
- post-PG344 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg344_static_graveyard_count_pt_wave.md`
- PG344 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_static_graveyard_count_pt_wave.md`
- post-PG344 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg344_static_graveyard_count_pt_wave_commander_legal.md`
- post-PG344 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg344_supported_recheck.md`
- post-PG344 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg344_static_graveyard_count_pt_wave_recheck.md`

PG344 measured result:

- PG344 promoted `8` exact static graveyard-count power/toughness rules:
  `Boneyard Wurm`, `Cantivore`, `Cognivore`, `Lord of Extinction`,
  `Magnivore`, `Revenant`, `Slag Fiend`, and `Terravore`.
- The splitter now accepts `SetBasePowerToughnessSourceEffect` static rows only
  when XMage uses a direct controller/all-graveyard card-count dynamic value,
  Oracle text says source power and toughness are each equal to that same
  count, and the only extra rules are optional self combat keywords.
- Runtime now refreshes dynamic source power/toughness from graveyard counts,
  preserves simple +/- counters on top of the dynamic base, and applies the
  zero-toughness state-based graveyard move after refresh.
- Focused splitter and runtime suites report `330` tests passing.
- PostgreSQL precheck found `8/8` target rows, `0/8` expected rules already
  present, and `0` nonmatching shadow rows to deprecate.
- PostgreSQL apply inserted/updated `8` rules and deprecated `0` shadow rows.
- PostgreSQL postcheck reports `8/8` promoted rows, `8/8` verified/auto rows,
  and `8/8` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7296` PostgreSQL rows, inserted/updated
  `7090` SQLite rows, and exported `4873` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual trusted SQLite rules without Oracle hash; PG344 rows
  all carry matching Oracle hashes.
- Global all-card readiness after PG344:
  `battle_and_oracle_ready=2429`, `battle_family_mapper_required=30118`, and
  `snapshot_has_verified_rule=3577`.
- Global all-card authoritative queue after PG344:
  `target_identity_count=27195`, `xmage_authoritative_source_count=26881`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26881`.
- Running the exact splitter after PG344 on supported units returns
  `proposal_count=0` over `7952` considered supported rows. The next cycle
  is superseded by PG345 below.

PG345 evidence:

- PG345 static graveyard-threshold source boost package:
  `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_package.md`
- PG345 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_apply_evidence.md`
- PG345 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_pg_to_sqlite_sync.json`
- PG345 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg345_xmage_static_graveyard_threshold_boost_wave_e2e_validation.md`
- post-PG345 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg345_static_graveyard_threshold_boost_wave.md`
- post-PG345 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg345_static_graveyard_threshold_boost_wave.md`
- post-PG345 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg345_static_graveyard_threshold_boost_wave.md`
- post-PG345 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg345_static_graveyard_threshold_boost_wave.md`
- PG345 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_static_graveyard_threshold_boost_wave.md`
- post-PG345 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg345_static_graveyard_threshold_boost_wave_commander_legal.md`
- post-PG345 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg345_supported_recheck.md`
- post-PG345 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg345_static_graveyard_threshold_boost_wave_recheck.md`

PG345 measured result:

- PG345 promoted `7` exact static graveyard-threshold source boost rules:
  `Anurid Barkripper`, `Basking Capybara`, `Frilled Cave-Wurm`,
  `Krosan Beast`, `Metamorphic Wurm`, `Seton's Scout`, and
  `Springing Tiger`.
- The splitter now accepts `BoostSourceEffect + ConditionalContinuousEffect`
  static rows only when XMage uses `ThresholdCondition.instance` or
  `DescendCondition.FOUR`, Oracle text says the source gets a fixed
  power/toughness boost while the controller has the same threshold of cards
  or permanent cards in graveyard, and the only extra rules are optional self
  combat keywords.
- Runtime now refreshes the conditional source boost from graveyard counts,
  counts `permanent` graveyard cards through ManaLoom permanent card types,
  and removes the old boost without cumulative drift when the threshold stops
  being true.
- Focused splitter and runtime suites report `335` tests passing.
- PostgreSQL precheck found `7/7` target rows, `0/7` expected rules already
  present, and `0` nonmatching shadow rows to deprecate.
- PostgreSQL apply inserted/updated `7` rules and deprecated `0` shadow rows.
- PostgreSQL postcheck reports `7/7` promoted rows, `7/7` verified/auto rows,
  and `7/7` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7303` PostgreSQL rows, inserted/updated
  `7097` SQLite rows, and exported `4880` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual trusted SQLite rules without Oracle hash; PG345 rows
  all carry matching Oracle hashes.
- Global all-card readiness after PG345:
  `battle_and_oracle_ready=2436`, `battle_family_mapper_required=30111`, and
  `snapshot_has_verified_rule=3584`.
- Global all-card authoritative queue after PG345:
  `target_identity_count=27188`, `xmage_authoritative_source_count=26874`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26874`.
- Running the exact splitter after PG345 on supported units returns
  `proposal_count=0` over `7945` considered supported rows. The next cycle
  is superseded by PG346 below.

PG346 evidence:

- PG346 static graveyard-count source boost package:
  `docs/hermes-analysis/master_optimizer_reports/pg346_xmage_static_graveyard_count_boost_wave_package.md`
- PG346 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg346_xmage_static_graveyard_count_boost_wave_apply_evidence.md`
- PG346 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg346_xmage_static_graveyard_count_boost_wave_pg_to_sqlite_sync.json`
- PG346 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg346_xmage_static_graveyard_count_boost_wave_e2e_validation.md`
- post-PG346 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg346_static_graveyard_count_boost_wave_docs_final.md`
- post-PG346 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg346_static_graveyard_count_boost_wave_docs_final.md`
- post-PG346 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg346_static_graveyard_count_boost_wave_docs_final.md`
- post-PG346 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg346_static_graveyard_count_boost_wave_docs_final.md`
- PG346 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_static_graveyard_count_boost_wave.md`
- post-PG346 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg346_static_graveyard_count_boost_wave_commander_legal.md`
- post-PG346 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg346_supported_recheck.md`
- post-PG346 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg346_static_graveyard_count_boost_wave_recheck.md`

PG346 measured result:

- PG346 promoted `3` exact static graveyard-count source boost rules:
  `Liliana's Elite`, `Salvage Slasher`, and `Wight of Precinct Six`.
- The splitter now accepts `BoostSourceEffect + SimpleStaticAbility` static
  rows only when XMage and Oracle agree that the source gets a per-card
  power/toughness boost from a controller or opponents' graveyard artifact or
  creature card count.
- Runtime now refreshes this source boost from current graveyard state, supports
  controller and opponents' graveyard scopes, supports artifact/creature card
  filters, and removes the old boost before recalculation so repeated refreshes
  do not accumulate deltas.
- Focused splitter and runtime suites report `342` tests passing.
- PostgreSQL postcheck reports `3/3` promoted rows, `3/3` verified/auto rows,
  and `3/3` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7306` PostgreSQL rows, inserted/updated
  `7100` SQLite rows, and exported `4883` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual trusted SQLite rules without Oracle hash; PG346 rows
  all carry matching Oracle hashes.
- Global all-card readiness after PG346:
  `battle_and_oracle_ready=2439`, `battle_family_mapper_required=30108`, and
  `snapshot_has_verified_rule=3587`.
- Global all-card authoritative queue after PG346:
  `target_identity_count=27185`, `xmage_authoritative_source_count=26871`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26871`.
- Running the exact splitter after PG346 on supported units returns
  `proposal_count=0` over `7942` considered supported rows. That checkpoint is
  superseded by PG347 below; use only the latest queue in the Current Priority
  Order section for new work.

PG347 evidence:

- PG347 activated graveyard-to-owner-library package:
  `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_package.md`
- PG347 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_apply_evidence.md`
- PG347 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_pg_to_sqlite_sync.json`
- PG347 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg347_xmage_activated_graveyard_to_owner_library_wave_e2e_validation.md`
- post-PG347 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg347_activated_graveyard_to_owner_library_wave_docs_final.md`
- post-PG347 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg347_activated_graveyard_to_owner_library_wave_docs_final.md`
- post-PG347 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg347_activated_graveyard_to_owner_library_wave_docs_final.md`
- post-PG347 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg347_activated_graveyard_to_owner_library_wave_docs_final.md`
- PG347 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg347_activated_graveyard_to_owner_library_wave.md`
- post-PG347 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg347_activated_graveyard_to_owner_library_wave_commander_legal.md`
- post-PG347 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg347_supported_recheck.md`
- post-PG347 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg347_activated_graveyard_to_owner_library_wave_recheck.md`

PG347 measured result:

- PG347 promoted `5` exact any-graveyard/owner-library activated rules:
  `Cogwork Archivist`, `Jade-Cast Sentinel`, `Junktroller`,
  `Phyrexian Archivist`, and `Reito Lantern`.
- The splitter now accepts `PutOnLibraryTargetEffect + SimpleActivatedAbility`
  permanents with `TargetCardInGraveyard()` when XMage and Oracle agree that
  the target may come from any graveyard and the destination is the owner's
  library.
- Runtime now selects target cards with their graveyard owner, removes them
  from the correct graveyard, and moves them to the library selected by
  `library_controller=owner`, while preserving the prior self/self behavior.
- Focused splitter and runtime suites report `345` tests passing.
- PostgreSQL postcheck reports `5/5` promoted rows, `5/5` verified/auto rows,
  and `5/5` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7311` PostgreSQL rows, inserted/updated
  `7105` SQLite rows, and exported `4888` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` warning for the
  pre-existing residual trusted SQLite rules without Oracle hash; PG347 rows
  all carry matching Oracle hashes.
- Global all-card readiness after PG347:
  `battle_and_oracle_ready=2444`, `battle_family_mapper_required=30103`, and
  `snapshot_has_verified_rule=3592`.
- Global all-card authoritative queue after PG347:
  `target_identity_count=27180`, `xmage_authoritative_source_count=26866`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26866`.
- Running the exact splitter after PG347 on supported units returns
  `proposal_count=0` over `7937` considered supported rows. The next cycle
  should continue from the fresh post-PG347 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1876`.

PG348 evidence:

- PG348 activated graveyard-to-battlefield package:
  `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_package.md`
- PG348 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_apply_evidence.md`
- PG348 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_pg_to_sqlite_sync.json`
- PG348 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg348_xmage_activated_graveyard_to_battlefield_wave_e2e_validation.md`
- post-PG348 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg348_activated_graveyard_to_battlefield_wave_docs_final.md`
- post-PG348 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg348_activated_graveyard_to_battlefield_wave_docs_final.md`
- post-PG348 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg348_activated_graveyard_to_battlefield_wave_docs_final.md`
- post-PG348 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg348_activated_graveyard_to_battlefield_wave_docs_final.md`
- PG348 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg348_activated_graveyard_to_battlefield_wave.md`
- post-PG348 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg348_activated_graveyard_to_battlefield_wave_commander_legal.md`
- post-PG348 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg348_supported_recheck.md`
- post-PG348 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg348_activated_graveyard_to_battlefield_wave_recheck.md`

PG348 measured result:

- PG348 promoted `2` exact self-graveyard/source-controller battlefield
  activated rules: `Doomed Necromancer` and `Protomatter Powder`.
- The splitter now accepts
  `ReturnFromGraveyardToBattlefieldTargetEffect + SimpleActivatedAbility`
  permanents only when Oracle and XMage agree on a single self-graveyard target,
  battlefield destination, supported target type, and mana/tap/source
  self-sacrifice costs.
- Unsafe neighbors remain blocked explicitly, including `Ghen, Arcanum Weaver`
  for sacrifice-target costs and `Othelm, Sigardian Outcast` for the this-turn
  graveyard watcher target window.
- Runtime now resolves the matching activated permanent recursion by paying
  mana, tapping when required, sacrificing the source when required, removing
  the selected target from graveyard, and putting it onto the battlefield under
  the activating player.
- Focused splitter/runtime suites report `350` tests passing.
- PostgreSQL precheck found `2/2` target card rows, `0` existing expected
  rows, and `0` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `2` upserted rows, `2/2` promoted rows,
  `2/2` verified/auto rows, and `2/2` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7313` PostgreSQL rows, inserted/updated
  `7107` SQLite rows, and exported `4890` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG348 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG348:
  `battle_and_oracle_ready=2446`, `battle_family_mapper_required=30101`, and
  `snapshot_has_verified_rule=3594`.
- Global all-card authoritative queue after PG348:
  `target_identity_count=27178`, `xmage_authoritative_source_count=26864`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26864`.
- Running the exact splitter after PG348 on supported units returns
  `proposal_count=0` over `7935` considered supported rows. The next cycle
  should continue from the fresh post-PG348 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1874`.

PG349 evidence:

- PG349 graveyard self-return discard battlefield package:
  `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_package.md`
- PG349 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_apply_evidence.md`
- PG349 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_pg_to_sqlite_sync.json`
- PG349 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg349_xmage_graveyard_self_return_discard_battlefield_wave_e2e_validation.md`
- post-PG349 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_docs_final.md`
- post-PG349 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_docs_final.md`
- post-PG349 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_docs_final.md`
- post-PG349 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_docs_final.md`
- PG349 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg349_graveyard_self_return_discard_battlefield_wave.md`
- post-PG349 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_commander_legal.md`
- post-PG349 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg349_supported_recheck.md`
- post-PG349 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg349_graveyard_self_return_discard_battlefield_wave_recheck.md`

PG349 measured result:

- PG349 promoted `3` exact self-graveyard battlefield activated rules with a
  real two-card discard cost: `Advanced Stitchwing`, `Ghoulsteed`, and
  `Stitchwing Skaab`.
- The splitter now accepts exact
  `ReturnSourceFromGraveyardToBattlefieldEffect + SimpleActivatedAbility`
  self-return creatures only when Oracle and XMage agree on the mana cost,
  battlefield tapped destination, and
  `DiscardTargetCost(new TargetCardInHand(2, StaticFilters.FILTER_CARD_CARDS))`.
- Exile-from-graveyard cost neighbors remained blocked in PG349 and were split
  into the next exact subpattern in PG350.
- Runtime now checks for enough hand cards, pays mana, discards exactly two
  cards through the existing discard replacement/trigger pipeline, removes the
  source from graveyard, and puts it onto the battlefield tapped.
- Focused splitter/runtime suites report `221` and `133` tests passing,
  respectively; the package-builder focused test also passes.
- PostgreSQL precheck found `3/3` target card rows, `0` existing expected
  rows, and `0` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `3` upserted rows, `3/3` promoted rows,
  `3/3` verified/auto rows, and `3/3` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7316` PostgreSQL rows, inserted/updated
  `7110` SQLite rows, and exported `4893` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG349 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG349:
  `battle_and_oracle_ready=2449`, `battle_family_mapper_required=30098`, and
  `snapshot_has_verified_rule=3597`.
- Global all-card authoritative queue after PG349:
  `target_identity_count=27175`, `xmage_authoritative_source_count=26861`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26861`.
- Running the exact splitter after PG349 on supported units returns
  `proposal_count=0` over `7932` considered supported rows. At that checkpoint,
  the top reusable work unit remained
  `recursion::xmage_graveyard_return_variant_review_v1` at `1871`; the current
  continuation point is the newer post-PG350 queue below.

PG350 evidence:

- PG350 graveyard self-return exile-cost battlefield package:
  `docs/hermes-analysis/master_optimizer_reports/pg350_xmage_graveyard_self_return_exile_cost_battlefield_wave_package.md`
- PG350 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg350_xmage_graveyard_self_return_exile_cost_battlefield_wave_apply_evidence.md`
- PG350 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg350_xmage_graveyard_self_return_exile_cost_battlefield_wave_pg_to_sqlite_sync.json`
- PG350 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg350_xmage_graveyard_self_return_exile_cost_battlefield_wave_e2e_validation.md`
- post-PG350 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_docs_final.md`
- post-PG350 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_docs_final.md`
- post-PG350 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_docs_final.md`
- post-PG350 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_docs_final.md`
- PG350 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg350_graveyard_self_return_exile_cost_battlefield_wave.md`
- post-PG350 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_commander_legal.md`
- post-PG350 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg350_supported_recheck.md`
- post-PG350 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg350_graveyard_self_return_exile_cost_battlefield_wave_recheck.md`

PG350 measured result:

- PG350 promoted `3` exact self-graveyard battlefield activated rules with a
  real graveyard-exile cost: `Bone Dragon`, `Despoiler of Souls`, and
  `Scrapheap Scrounger`.
- The splitter now accepts exact
  `ReturnSourceFromGraveyardToBattlefieldEffect + SimpleActivatedAbility`
  self-return permanents when Oracle and XMage agree on mana cost, tapped
  destination, optional static `CantBlockAbility`, and exact
  `ExileFromGraveCost(new TargetCardInYourGraveyard(..., filter))` using
  `AnotherPredicate.instance`.
- The supported exile-cost variants are count/target constrained: seven other
  cards, two other creature cards, or another creature card from your
  graveyard. Generic graveyard exiling remains blocked.
- Runtime now checks for enough valid other graveyard cards, pays mana, exiles
  those cost cards through the graveyard leave/exile path, then removes the
  source from graveyard and returns it to battlefield tapped or untapped as the
  Oracle/XMage source says.
- Focused splitter/runtime suites report `223` and `135` tests passing,
  respectively; the package-builder focused command also exits `0`.
- PostgreSQL precheck found `3/3` target card rows, `0` existing expected
  rows, and `0` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `3` upserted rows, `3/3` promoted rows,
  `3/3` verified/auto rows, and `3/3` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7319` PostgreSQL rows, inserted/updated
  `7113` SQLite rows, and exported `4896` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG350 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG350:
  `battle_and_oracle_ready=2452`, `battle_family_mapper_required=30095`, and
  `snapshot_has_verified_rule=3600`.
- Global all-card authoritative queue after PG350:
  `target_identity_count=27172`, `xmage_authoritative_source_count=26858`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26858`.
- Running the exact splitter after PG350 on supported units returns
  `proposal_count=0` over `7929` considered supported rows. The next cycle
  should continue from the fresh post-PG350 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1868`.

PG351 evidence:

- PG351 graveyard self-return hand discard/sorcery package:
  `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_package.md`
- PG351 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_apply_evidence.md`
- PG351 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_pg_to_sqlite_sync.json`
- PG351 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg351_xmage_graveyard_self_return_hand_discard_creature_sorcery_wave_e2e_validation.md`
- post-PG351 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_docs_final.md`
- post-PG351 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_docs_final.md`
- post-PG351 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_docs_final.md`
- post-PG351 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_docs_final.md`
- PG351 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave.md`
- post-PG351 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_commander_legal.md`
- post-PG351 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg351_supported_recheck.md`
- post-PG351 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg351_graveyard_self_return_hand_discard_creature_sorcery_wave_recheck.md`

PG351 measured result:

- PG351 promoted `2` exact self-graveyard hand activated rules:
  `Kraul Swarm` and `Summoned Dromedary`.
- The splitter/runtime now support exact
  `ReturnSourceFromGraveyardToHandEffect` variants with a single creature-card
  discard cost and exact sorcery-speed activation via
  `ActivateAsSorceryActivatedAbility`.
- Runtime now filters discard-cost payment by the required card type, so
  `creature_card` discard costs cannot be paid with noncreature cards.
- Focused splitter/runtime suites report `226` and `137` tests passing,
  respectively.
- PostgreSQL postcheck reports `2/2` promoted rows, `2/2` verified/auto rows,
  and `2/2` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7321` PostgreSQL rows, inserted/updated
  `7115` SQLite rows, and exported `4898` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG351 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG351:
  `battle_and_oracle_ready=2454`, `battle_family_mapper_required=30093`, and
  `snapshot_has_verified_rule=3602`.
- Global all-card authoritative queue after PG351:
  `target_identity_count=27170`, `xmage_authoritative_source_count=26856`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26856`.
- Running the exact splitter after PG351 on supported units returns
  `proposal_count=0` over `7927` considered supported rows. The next cycle
  should continue from the fresh post-PG351 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1866`.

PG352 evidence:

- PG352 graveyard shuffle-to-library spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_package.md`
- PG352 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_apply_evidence.md`
- PG352 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_pg_to_sqlite_sync.json`
- PG352 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg352_xmage_graveyard_shuffle_to_library_spell_wave_e2e_validation.md`
- post-PG352 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_docs_final.md`
- post-PG352 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_docs_final.md`
- post-PG352 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_docs_final.md`
- post-PG352 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_docs_final.md`
- PG352 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg352_graveyard_shuffle_to_library_spell_wave.md`
- post-PG352 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_commander_legal.md`
- post-PG352 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg352_supported_recheck.md`
- post-PG352 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg352_graveyard_shuffle_to_library_spell_wave_recheck.md`

PG352 measured result:

- PG352 promoted `4` exact target-player graveyard shuffle-to-library spells:
  `Dwell on the Past`, `Krosan Reclamation`, `Memory's Journey`, and
  `Stream of Consciousness`.
- The splitter/runtime now support exact
  `TargetPlayerShufflesTargetCardsEffect` spells with
  `TargetCardInTargetPlayersGraveyard(N)`, `destination=library_shuffle`, and
  optional Flashback only when source/Oracle costs match.
- Runtime now chooses a single target player with valid graveyard targets, moves
  up to the modeled count into that player's library, and shuffles that
  library once after the move.
- Focused splitter/runtime suites report `229` and `138` tests passing,
  respectively.
- PostgreSQL precheck found `4/4` target card rows, `0` existing expected rows,
  and `0` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `4` upserted rows, `4/4` promoted rows,
  `4/4` verified/auto rows, and `4/4` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7325` PostgreSQL rows, inserted/updated
  `7119` SQLite rows, and exported `4902` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG352 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG352:
  `battle_and_oracle_ready=2458`, `battle_family_mapper_required=30089`, and
  `snapshot_has_verified_rule=3606`.
- Global all-card authoritative queue after PG352:
  `target_identity_count=27166`, `xmage_authoritative_source_count=26852`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26852`.
- Running the exact splitter after PG352 on supported units returns
  `proposal_count=0` over `7923` considered supported rows. The next cycle
  should continue from the fresh post-PG352 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1862`.

PG353 evidence:

- PG353 permanent activated graveyard-to-hand discard-cost package:
  `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_package.md`
- PG353 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_apply_evidence.md`
- PG353 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_pg_to_sqlite_sync.json`
- PG353 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg353_xmage_permanent_activated_graveyard_to_hand_discard_cost_wave_e2e_validation.md`
- post-PG353 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_docs_final.md`
- post-PG353 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_docs_final.md`
- post-PG353 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_docs_final.md`
- post-PG353 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_docs_final.md`
- PG353 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave.md`
- post-PG353 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_commander_legal.md`
- post-PG353 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg353_supported_recheck.md`
- post-PG353 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg353_permanent_activated_graveyard_to_hand_discard_cost_wave_recheck.md`

PG353 measured result:

- PG353 promoted `2` exact permanent activated graveyard-to-hand rules with
  discard costs: `Tortured Existence` and `Undertaker`.
- The splitter/runtime now support exact
  `ReturnFromGraveyardToHandTargetEffect + SimpleActivatedAbility` permanents
  where source and Oracle agree on `{B}` mana, optional tap, and a single
  `DiscardCardCost` for any card or creature card.
- Runtime pays the discard cost before resolving the graveyard-to-hand
  activation, records discard replacement metadata, and skips activation when
  no valid discard card exists.
- Focused splitter/runtime suites report `230` and `140` tests passing,
  respectively; package/E2E pytest checks report `6` passing tests.
- PostgreSQL precheck found `2/2` target card rows, `0` existing expected rows,
  and `2` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `2` upserted rows, `2` deprecated shadow
  rows, `2/2` promoted rows, `2/2` verified/auto rows, and `2/2` matching
  Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7327` PostgreSQL rows, inserted/updated
  `7121` SQLite rows, and exported `4903` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG353 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG353:
  `battle_and_oracle_ready=2460`, `battle_family_mapper_required=30087`, and
  `snapshot_has_verified_rule=3608`.
- Global all-card authoritative queue after PG353:
  `target_identity_count=27164`, `xmage_authoritative_source_count=26850`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26850`.
- Running the exact splitter after PG353 on supported units returns
  `proposal_count=0` over `7921` considered supported rows. This checkpoint
  was superseded by PG354 below; at the PG353 checkpoint the top reusable work
  unit remained `recursion::xmage_graveyard_return_variant_review_v1` at
  `1860`.

PG354 evidence:

- PG354 permanent activated damage restricted-target package:
  `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_package.md`
- PG354 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_apply_evidence.md`
- PG354 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_pg_to_sqlite_sync.json`
- PG354 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg354_xmage_permanent_activated_damage_restricted_target_wave_e2e_validation.md`
- post-PG354 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_docs_final.md`
- post-PG354 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave.md`
- post-PG354 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_docs_final.md`
- post-PG354 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_docs_final.md`
- PG354 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg354_permanent_activated_damage_restricted_target_wave.md`
- post-PG354 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_commander_legal.md`
- post-PG354 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg354_supported_recheck.md`
- post-PG354 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg354_permanent_activated_damage_restricted_target_wave_recheck.md`

PG354 measured result:

- PG354 promoted `22` exact permanent activated damage rules with
  source/Oracle-matched restricted targets: `8` player-or-planeswalker,
  `10` attacking-or-blocking creature, `3` flying creature, and `1` blocking
  creature target.
- The splitter/runtime now support `TargetPlayerOrPlaneswalker`,
  `TargetPermanent(StaticFilters.FILTER_CREATURE_FLYING)`,
  `TargetAttackingOrBlockingCreature`, and `TargetBlockingCreature` for exact
  permanent activated damage rules in
  `xmage_permanent_simple_activated_damage_v1`.
- Focused splitter/runtime suites report `233` and `142` tests passing,
  respectively; package/E2E pytest checks report `6` passing tests.
- PostgreSQL precheck found `22/22` target card rows, `0` existing expected
  rows, and `0` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `22` upserted rows, `22/22` promoted
  rows, `22/22` verified/auto rows, and `22/22` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7349` PostgreSQL rows, inserted/updated
  `7143` SQLite rows, and exported `4925` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG354 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG354:
  `battle_and_oracle_ready=2482`, `battle_family_mapper_required=30065`, and
  `snapshot_has_verified_rule=3630`.
- Global all-card authoritative queue after PG354:
  `target_identity_count=27142`, `xmage_authoritative_source_count=26828`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26828`.
- Running the exact splitter after PG354 on supported units returns
  `proposal_count=0` over `7899` considered supported rows. This checkpoint
  was superseded by PG355 below; at the PG354 checkpoint the top reusable work
  unit remained `recursion::xmage_graveyard_return_variant_review_v1` at
  `1860`.

PG355 evidence:

- PG355 destroy restricted-target package:
  `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_package.md`
- PG355 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_apply_evidence.md`
- PG355 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_pg_to_sqlite_sync.json`
- PG355 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg355_xmage_destroy_restricted_target_wave_e2e_validation.md`
- post-PG355 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg355_destroy_restricted_target_wave_docs_final.md`
- post-PG355 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg355_destroy_restricted_target_wave.md`
- post-PG355 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg355_destroy_restricted_target_wave_docs_final.md`
- post-PG355 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg355_destroy_restricted_target_wave_docs_final.md`
- PG355 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg355_destroy_restricted_target_wave.md`
- post-PG355 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg355_destroy_restricted_target_wave_commander_legal.md`
- post-PG355 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg355_supported_recheck.md`
- post-PG355 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg355_destroy_restricted_target_wave_recheck.md`

PG355 measured result:

- PG355 promoted `12` exact destroy restricted-target rules for `Bramblecrush`,
  `Crush`, `Dark Banishing`, `Dark Betrayal`, `Deathmark`, `Exorcist`,
  `Go for the Throat`, `Hero's Demise`, `Joven`, `Saltblast`,
  `Terror // Terror`, and `Ultimate Price`.
- The splitter/runtime now support exact source/Oracle-matched destroy targets
  for noncreature permanents/artifacts, black/green/white/color-excluded
  creatures and permanents, nonartifact creatures, legendary creatures, and
  monocolored creatures in `xmage_destroy_target_spell_v1` and
  `xmage_permanent_simple_activated_destroy_target_v1`.
- Focused splitter/runtime suites report `235` and `144` tests passing,
  respectively; package/E2E pytest checks report `6` passing tests.
- PostgreSQL precheck found `12/12` target card rows, `0` expected rule rows
  before apply, and `2` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `12/12` promoted rows, `12/12`
  verified/auto rows, and `12/12` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7361` PostgreSQL rows, inserted/updated
  `7155` SQLite rows, and exported `4936` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG355 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG355:
  `battle_and_oracle_ready=2494`, `battle_family_mapper_required=30053`, and
  `snapshot_has_verified_rule=3642`.
- Global all-card authoritative queue after PG355:
  `target_identity_count=27130`, `xmage_authoritative_source_count=26816`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26816`.
- Running the exact splitter after PG355 on supported units returns
  `proposal_count=0` over `7887` considered supported rows. At that
  checkpoint, the next cycle was the fresh post-PG355 queue and the top
  reusable work unit remained
  `recursion::xmage_graveyard_return_variant_review_v1` at `1860`.

PG356 evidence:

- PG356 ETB graveyard-to-library extended package:
  `docs/hermes-analysis/master_optimizer_reports/pg356_xmage_etb_graveyard_to_library_extended_wave_package.md`
- PG356 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg356_xmage_etb_graveyard_to_library_extended_wave_apply_evidence.md`
- PG356 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg356_xmage_etb_graveyard_to_library_extended_wave_pg_to_sqlite_sync.json`
- PG356 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg356_xmage_etb_graveyard_to_library_extended_wave_e2e_validation.md`
- post-PG356 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg356_etb_graveyard_to_library_extended_wave_docs_final.md`
- post-PG356 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg356_etb_graveyard_to_library_extended_wave.md`
- post-PG356 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg356_etb_graveyard_to_library_extended_wave_docs_final.md`
- post-PG356 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg356_etb_graveyard_to_library_extended_wave_docs_final.md`
- PG356 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg356_etb_graveyard_to_library_extended_wave.md`
- post-PG356 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg356_etb_graveyard_to_library_extended_wave_commander_legal.md`
- post-PG356 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg356_supported_recheck.md`
- post-PG356 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg356_etb_graveyard_to_library_extended_wave_recheck.md`

PG356 measured result:

- PG356 promoted `4` exact ETB graveyard-to-library rules for
  `Biblioplex Assistant`, `Monastery Messenger`, `Nantuko Tracer`, and
  `Swiftgear Drake`.
- The splitter/runtime now support exact XMage `PutOnLibraryTargetEffect`
  ETB creatures with real source filters for `FilterInstantOrSorceryCard`,
  `FilterNonlandCard` plus noncreature predicate, and `TargetCardInGraveyard`
  any-graveyard targets that move cards to the bottom of their owner's library.
- Focused splitter/runtime suites report `237` and `145` tests passing before
  package generation; combined focused unittest suites report `382` passing
  tests after apply. Package/E2E pytest checks report `6` passing tests.
- PostgreSQL precheck found `4/4` target card rows, `0` expected rule rows
  before apply, and `0` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `4/4` promoted rows, `4/4` verified/auto
  rows, and `4/4` matching Oracle hash rows.
- PG -> Hermes/SQLite sync loaded `7365` PostgreSQL rows, inserted/updated
  `7160` SQLite rows, and exported `4940` canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG356 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG356:
  `battle_and_oracle_ready=2498`, `battle_family_mapper_required=30049`, and
  `snapshot_has_verified_rule=3646`.
- Global all-card authoritative queue after PG356:
  `target_identity_count=27126`, `xmage_authoritative_source_count=26812`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26812`.
- Running the exact splitter after PG356 on supported units returns
  `proposal_count=0` over `7883` considered supported rows. The next cycle
  should continue from the fresh post-PG356 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1856`.

PG357 evidence:

- PG357 dies-recursion keyword-fix package:
  `docs/hermes-analysis/master_optimizer_reports/pg357_xmage_dies_recursion_keyword_fix_wave_package.md`
- PG357 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg357_xmage_dies_recursion_keyword_fix_wave_apply_evidence.md`
- PG357 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg357_xmage_dies_recursion_keyword_fix_wave_pg_to_sqlite_sync.json`
- PG357 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg357_xmage_dies_recursion_keyword_fix_wave_e2e_validation.md`
- post-PG357 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg357_dies_recursion_keyword_fix_wave_docs_updated.md`
- post-PG357 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg357_dies_recursion_keyword_fix_wave.md`
- post-PG357 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg357_dies_recursion_keyword_fix_wave_docs_updated.md`
- post-PG357 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg357_dies_recursion_keyword_fix_wave_docs_updated.md`
- PG357 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg356_dies_recursion_keyword_fix.md`
- post-PG357 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg357_dies_recursion_keyword_fix_wave_commander_legal.md`
- post-PG357 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg357_supported_recheck.md`
- post-PG357 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg357_dies_recursion_keyword_fix_wave_recheck.md`

PG357 measured result:

- PG357 promoted `1` exact creature dies graveyard-to-hand recursion rule for
  `Junk Diver`.
- The splitter now parses dies-recursion Oracle text after leading static combat
  keywords such as `Flying`, matching the PostgreSQL Oracle template
  `Flying\nWhen this creature dies...`.
- Focused splitter/runtime/package suites report `382` passing unittest tests.
- PostgreSQL precheck found `1/1` target card row, `0` expected rule rows before
  apply, and `2` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `1/1` promoted row, `1/1` verified/auto row,
  `1/1` matching Oracle hash row, and `2` backup shadow rows.
- PG -> Hermes/SQLite metadata sync matched `5948` PostgreSQL card rows and
  refreshed `5875` SQLite cache alias rows. Battle-rules sync loaded `7366`
  PostgreSQL rows, inserted/updated `7161` SQLite rows, and exported `4940`
  canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG357 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG357:
  `battle_and_oracle_ready=2499`, `battle_family_mapper_required=30048`, and
  `snapshot_has_verified_rule=3647`.
- Global all-card authoritative queue after PG357:
  `target_identity_count=27125`, `xmage_authoritative_source_count=26811`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26811`.
- Running the exact splitter after PG357 on supported units returns
  `proposal_count=0` over `7882` considered supported rows. The next cycle
  should continue from the fresh post-PG357 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1855`.

PG358 evidence:

- PG358 Returned Pastcaller recursion package:
  `docs/hermes-analysis/master_optimizer_reports/pg358_xmage_returned_pastcaller_recursion_wave_package.md`
- PG358 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg358_xmage_returned_pastcaller_recursion_wave_apply_evidence.md`
- PG358 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg358_xmage_returned_pastcaller_recursion_wave_pg_to_sqlite_sync.json`
- PG358 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg358_xmage_returned_pastcaller_recursion_wave_pg_metadata_sync.json`
- PG358 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg358_xmage_returned_pastcaller_recursion_wave_e2e_validation.md`
- post-PG358 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg358_returned_pastcaller_recursion_wave_docs_updated.md`
- post-PG358 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg358_returned_pastcaller_recursion_wave.md`
- post-PG358 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg358_returned_pastcaller_recursion_wave_docs_updated.md`
- post-PG358 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg358_returned_pastcaller_recursion_wave_docs_updated.md`
- PG358 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg357_returned_pastcaller_wave.md`
- post-PG358 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg358_returned_pastcaller_recursion_wave_commander_legal.md`
- post-PG358 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg358_supported_recheck.md`
- post-PG358 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg358_returned_pastcaller_recursion_wave_recheck.md`

PG358 measured result:

- PG358 promoted `1` exact creature ETB graveyard-to-hand recursion rule for
  `Returned Pastcaller`.
- The exact scope extends
  `xmage_creature_etb_return_graveyard_card_to_hand_v1` with the
  `spirit_instant_or_sorcery` target constraint, preserving `Flying` metadata.
- Focused splitter/runtime/package suites report `384` passing unittest tests.
- PostgreSQL precheck found `1/1` target card row, `0` expected rule rows before
  apply, and `0` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `1/1` promoted row, `1/1` verified/auto row,
  `1/1` matching Oracle hash row, and `0` backup shadow rows.
- PG -> Hermes/SQLite metadata sync matched `5949` PostgreSQL card rows and
  refreshed `5876` SQLite cache alias rows. Battle-rules sync loaded `7367`
  PostgreSQL rows, inserted/updated `7162` SQLite rows, and exported `4941`
  canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG358 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG358:
  `battle_and_oracle_ready=2500`, `battle_family_mapper_required=30047`, and
  `snapshot_has_verified_rule=3648`.
- Global all-card authoritative queue after PG358:
  `target_identity_count=27124`, `xmage_authoritative_source_count=26810`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26810`.
- Running the exact splitter after PG358 on supported units returns
  `proposal_count=0` over `7881` considered supported rows. The next cycle
  should continue from the fresh post-PG358 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1854`.

PG359 evidence:

- PG359 Aphetto shared-type recursion package:
  `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_package.md`
- PG359 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_apply_evidence.md`
- PG359 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_pg_to_sqlite_sync.json`
- PG359 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_pg_metadata_sync.json`
- PG359 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg359_xmage_aphetto_shared_type_recursion_wave_e2e_validation.md`
- post-PG359 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg359_aphetto_shared_type_recursion_wave_docs_updated.md`
- post-PG359 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg359_aphetto_shared_type_recursion_wave.md`
- post-PG359 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg359_aphetto_shared_type_recursion_wave_docs_updated.md`
- post-PG359 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg359_aphetto_shared_type_recursion_wave_docs_updated.md`
- PG359 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg359_aphetto_shared_type_recursion_wave.md`
- post-PG359 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg359_aphetto_shared_type_recursion_wave_commander_legal.md`
- post-PG359 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg359_supported_recheck.md`
- post-PG359 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg359_aphetto_shared_type_recursion_wave_recheck.md`

PG359 measured result:

- PG359 promoted `1` exact graveyard-to-hand recursion spell rule for
  `Aphetto Dredging`.
- The exact scope extends
  `xmage_return_target_graveyard_card_to_hand_spell_v1` with
  `shared_creature_type`, `count=3`, and `up_to_count=true`, matching the XMage
  `ChoiceCreatureType` + `TargetCardInYourGraveyard(0, 3, ...)` source
  signature.
- Runtime now preserves exact-count shared-type behavior while allowing
  partial groups for `up_to_count` shared creature type recursion.
- Focused splitter/runtime/package suites report `387` passing unittest tests.
- PostgreSQL precheck found `1/1` target card row, `0` expected rule rows before
  apply, and `0` shadow rows to deprecate.
- PostgreSQL apply/postcheck reports `1/1` promoted row, `1/1` verified/auto row,
  `1/1` matching Oracle hash row, and `0` backup shadow rows.
- PG -> Hermes/SQLite metadata sync matched `5949` PostgreSQL card rows and
  refreshed `5876` SQLite cache alias rows. Battle-rules sync loaded `7368`
  PostgreSQL rows, inserted/updated `7163` SQLite rows, and exported `4942`
  canonical snapshot rows.
- E2E package validation reports pass for PostgreSQL source of truth, SQLite
  Hermes cache, canonical snapshot fallback, runtime `get_card_effect`, and
  battle execution no-override.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG359 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG359:
  `battle_and_oracle_ready=2501`, `battle_family_mapper_required=30046`, and
  `snapshot_has_verified_rule=3649`.
- Global all-card authoritative queue after PG359:
  `target_identity_count=27123`, `xmage_authoritative_source_count=26809`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26809`.
- Running the exact splitter after PG359 on supported units returns
  `proposal_count=0` over `7880` considered supported rows. The next cycle
  should continue from the fresh post-PG359 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1853`.

PG360 evidence:

- PG360 static graveyard extended filters package:
  `docs/hermes-analysis/master_optimizer_reports/pg360_xmage_static_graveyard_extended_filters_wave_package.md`
- PG360 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg360_xmage_static_graveyard_extended_filters_wave_apply_evidence.md`
- PG360 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg360_xmage_static_graveyard_extended_filters_wave_pg_to_sqlite_sync.json`
- PG360 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg360_xmage_static_graveyard_extended_filters_wave_pg_metadata_sync.json`
- PG360 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg360_xmage_static_graveyard_extended_filters_wave_e2e_validation.md`
- post-PG360 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg360_static_graveyard_extended_filters_wave_docs_final.md`
- post-PG360 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg360_static_graveyard_extended_filters_wave.md`
- post-PG360 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg360_static_graveyard_extended_filters_wave_docs_final.md`
- post-PG360 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg360_static_graveyard_extended_filters_wave_docs_final.md`
- PG360 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg360_static_graveyard_extended_filters_wave.md`
- post-PG360 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg360_static_graveyard_extended_filters_wave_commander_legal.md`
- post-PG360 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg360_supported_recheck.md`
- post-PG360 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg360_static_graveyard_extended_filters_wave_recheck.md`

PG360 measured result:

- PG360 promoted `2` exact static graveyard-count source boost rules for
  `Runaway Trash-Bot` and `Xande, Dark Mage`.
- The splitter now supports XMage/Oracle-matched controller graveyard
  `artifact and/or enchantment` filters and `noncreature, nonland` filters for
  the existing `xmage_static_source_boost_equal_graveyard_count_v1` runtime
  family.
- Focused tests cover the exact split/parser cases and runtime count behavior
  for artifact-or-enchantment and noncreature/nonland cards.
- PostgreSQL precheck found `2/2` target card rows, `0` existing expected
  rows, and `0` shadow rows.
- PostgreSQL apply upserted `2` rows and deprecated `0` shadow rows.
- PostgreSQL postcheck verified `2/2` promoted rows, `2/2` verified/auto rows,
  and `2/2` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7370` PG rows, updated `7165` SQLite rows,
  and exported `4944` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `2/2` cards.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning
  for trusted executable SQLite rows without Oracle hash; PG360 rows all carry
  matching Oracle hashes.
- Global all-card readiness after PG360:
  `battle_and_oracle_ready=2503`, `battle_family_mapper_required=30044`, and
  `snapshot_has_verified_rule=3651`.
- Global all-card authoritative queue after PG360:
  `target_identity_count=27121`, `xmage_authoritative_source_count=26807`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26807`.
- Running the exact splitter after PG360 on supported units returns
  `proposal_count=0` over `7878` considered supported rows. The next cycle
  should continue from the fresh post-PG360 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1851`.

PG361 evidence:

- PG361 recursion battlefield selection constraints package:
  `docs/hermes-analysis/master_optimizer_reports/pg361_xmage_recursion_battlefield_selection_constraints_wave_package.md`
- PG361 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg361_xmage_recursion_battlefield_selection_constraints_wave_apply_evidence.md`
- PG361 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg361_xmage_recursion_battlefield_selection_constraints_wave_pg_to_sqlite_sync.json`
- PG361 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg361_xmage_recursion_battlefield_selection_constraints_wave_pg_metadata_sync.json`
- PG361 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg361_xmage_recursion_battlefield_selection_constraints_wave_e2e_validation.md`
- post-PG361 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_docs_final.md`
- post-PG361 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg361_recursion_battlefield_selection_constraints_wave.md`
- post-PG361 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_docs_final.md`
- post-PG361 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_docs_final.md`
- PG361 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg361_recursion_battlefield_selection_constraints_wave.md`
- post-PG361 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_commander_legal.md`
- post-PG361 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg361_supported_recheck.md`
- post-PG361 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg361_recursion_battlefield_selection_constraints_wave_recheck.md`

PG361 measured result:

- PG361 promoted `6` exact graveyard-to-battlefield spell rules for
  `Behold the Sinister Six!`, `Brought Back`, `Continue?`, `Grim Return`,
  `March from the Tomb`, and `Patch Up`.
- The splitter/runtime now support battlefield-recursion selection constraints:
  total mana value ceilings, different-name requirements, Ally-creature
  targeting, graveyard cards put there from the battlefield this turn, and
  tapped entry for returned permanents where applicable.
- Focused tests cover exact split/parser cases and runtime selection behavior
  for total mana value limits, different names, and this-turn graveyard filters.
- PostgreSQL precheck found `6/6` target card rows, `0` existing expected
  rows, and `0` shadow rows.
- PostgreSQL apply upserted `6` rows and deprecated `0` shadow rows.
- PostgreSQL postcheck verified `6/6` promoted rows, `6/6` verified/auto rows,
  and `6/6` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7376` PG rows, updated `7171` SQLite rows,
  and exported `4950` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `6/6` cards.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning;
  PG361 rows all carry matching Oracle hashes.
- Global all-card readiness after PG361:
  `battle_and_oracle_ready=2509`, `battle_family_mapper_required=30038`, and
  `snapshot_has_verified_rule=3657`.
- Global all-card authoritative queue after PG361:
  `target_identity_count=27115`, `xmage_authoritative_source_count=26801`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26801`.
- Running the exact splitter after PG361 on supported units returns
  `proposal_count=0` over `7872` considered supported rows. At that point the
  next cycle continued from the fresh post-PG361 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1845`.

PG362 evidence:

- PG362 recursion X spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_package.md`
- PG362 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_apply_evidence.md`
- PG362 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_pg_to_sqlite_sync.json`
- PG362 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_pg_metadata_sync.json`
- PG362 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg362_xmage_recursion_x_spell_wave_e2e_validation.md`
- post-PG362 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg362_recursion_x_spell_wave_docs_final.md`
- post-PG362 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg362_recursion_x_spell_wave.md`
- post-PG362 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg362_recursion_x_spell_wave_docs_final.md`
- post-PG362 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg362_recursion_x_spell_wave_docs_final.md`
- PG362 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg362_recursion_x_spell_wave.md`
- post-PG362 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg362_recursion_x_spell_wave_commander_legal.md`
- post-PG362 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg362_supported_recheck.md`
- post-PG362 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg362_recursion_x_spell_wave_recheck.md`

PG362 measured result:

- PG362 promoted `3` exact recursion X spell rules for `Back in Town`,
  `Death Denied`, and `Stir the Grave`.
- The splitter/runtime now support `count_from_x` for graveyard recursion,
  `target_mana_value_max_from_x` for battlefield recursion, and the XMage
  `OutlawPredicate` target as `outlaw_creature`.
- Focused tests cover exact split/parser cases, missing-adjuster blocking, and
  runtime resolution for X count, X mana value ceiling, and outlaw filtering.
- PostgreSQL precheck found `3/3` target card rows, `0` existing expected
  rows, and `0` shadow rows.
- PostgreSQL apply upserted `3` rows and deprecated `0` shadow rows.
- PostgreSQL postcheck verified `3/3` promoted rows, `3/3` verified/auto rows,
  and `3/3` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7379` PG rows, updated `7174` SQLite rows,
  and exported `4953` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `3/3` cards.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning;
  PG362 rows all carry matching Oracle hashes.
- Global all-card readiness after PG362:
  `battle_and_oracle_ready=2512`, `battle_family_mapper_required=30035`, and
  `snapshot_has_verified_rule=3660`.
- Global all-card authoritative queue after PG362:
  `target_identity_count=27112`, `xmage_authoritative_source_count=26798`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26798`.
- Running the exact splitter after PG362 on supported units returns
  `proposal_count=0` over `7869` considered supported rows. The next cycle
  should continue from the fresh post-PG362 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1842`.

PG363 evidence:

- PG363 recursion X exile-self package:
  `docs/hermes-analysis/master_optimizer_reports/pg363_recursion_x_exile_self_wave_package.md`
- PG363 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg363_recursion_x_exile_self_wave_apply_evidence.md`
- PG363 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg363_recursion_x_exile_self_wave_pg_to_sqlite_sync.json`
- PG363 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg363_recursion_x_exile_self_wave_pg_metadata_sync.json`
- PG363 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg363_recursion_x_exile_self_wave_e2e_validation.md`
- post-PG363 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg363_recursion_x_exile_self_wave_docs_final.md`
- post-PG363 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg363_recursion_x_exile_self_wave.md`
- post-PG363 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg363_recursion_x_exile_self_wave_docs_final.md`
- post-PG363 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg363_recursion_x_exile_self_wave_docs_final.md`
- PG363 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg363_recursion_x_exile_self_wave.md`
- post-PG363 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg363_recursion_x_exile_self_wave_commander_legal.md`
- post-PG363 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg363_supported_recheck.md`
- post-PG363 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg363_recursion_x_exile_self_wave_recheck.md`

PG363 measured result:

- PG363 promoted `2` exact recursion X exile-self spell rules for
  `Divergent Equation` and `Wildest Dreams`.
- The splitter now supports `XTargetsCountAdjuster` for graveyard-to-hand
  recursion spells that exile themselves after resolution, with exact
  any-card and instant/sorcery target filters.
- Focused tests cover exact split/parser cases, missing-adjuster blocking, and
  runtime resolution for `count_from_x`, target filtering, and `exiles_self`.
- PostgreSQL precheck found `2/2` target card rows, `0` existing expected
  rows, and `0` shadow rows.
- PostgreSQL apply upserted `2` rows and deprecated `0` shadow rows.
- PostgreSQL postcheck verified `2/2` promoted rows, `2/2` verified/auto rows,
  and `2/2` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7381` PG rows, updated `7176` SQLite rows,
  and exported `4955` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `2/2` cards.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning;
  PG363 rows all carry matching Oracle hashes.
- Global all-card readiness after PG363:
  `battle_and_oracle_ready=2514`, `battle_family_mapper_required=30033`, and
  `snapshot_has_verified_rule=3662`.
- Global all-card authoritative queue after PG363:
  `target_identity_count=27110`, `xmage_authoritative_source_count=26796`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26796`.
- Running the exact splitter after PG363 on supported units returns
  `proposal_count=0` over `7867` considered supported rows. At that checkpoint,
  the next cycle was expected to continue from the fresh post-PG363 queue; the
  top reusable work unit remained
  `recursion::xmage_graveyard_return_variant_review_v1` at `1840`.

PG364 evidence:

- PG364 multi-target recursion package:
  `docs/hermes-analysis/master_optimizer_reports/pg364_multi_target_recursion_wave_package.md`
- PG364 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg364_multi_target_recursion_wave_apply_evidence.md`
- PG364 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg364_multi_target_recursion_wave_pg_to_sqlite_sync.json`
- PG364 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg364_multi_target_recursion_wave_pg_metadata_sync.json`
- PG364 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg364_multi_target_recursion_wave_e2e_validation.md`
- post-PG364 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg364_multi_target_recursion_wave_docs_final.md`
- post-PG364 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg364_multi_target_recursion_wave.md`
- post-PG364 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg364_multi_target_recursion_wave_docs_final.md`
- post-PG364 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg364_multi_target_recursion_wave_docs_final.md`
- PG364 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg364_multi_target_recursion_wave.md`
- post-PG364 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg364_multi_target_recursion_wave_commander_legal.md`
- post-PG364 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg364_supported_recheck.md`
- post-PG364 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg364_multi_target_recursion_wave_recheck.md`

PG364 measured result:

- PG364 promoted `2` exact multi-target recursion spell rules for
  `Rise from the Wreck` and `Rogues' Gallery`.
- The splitter now supports graveyard-to-hand recursion components for one
  creature per color and for multi-target "up to one" Mount, Vehicle, and
  creature-with-no-abilities targets when XMage source confirms the exact
  target machinery.
- Runtime now filters recursion targets for color-specific creatures, Mount
  cards, Vehicle cards, and conservatively identified creatures with no
  abilities.
- Focused tests cover exact split/parser cases, missing-source-filter
  blocking, and runtime resolution for the new component targets.
- PostgreSQL precheck found `2/2` target card rows, `0` existing expected
  rows, and `0` shadow rows.
- PostgreSQL apply upserted `2` rows and deprecated `0` shadow rows.
- PostgreSQL postcheck verified `2/2` promoted rows, `2/2` verified/auto rows,
  and `2/2` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7383` PG rows, updated `7178` SQLite rows,
  and exported `4957` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `2/2` cards.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning;
  PG364 rows all carry matching Oracle hashes.
- Global all-card readiness after PG364:
  `battle_and_oracle_ready=2516`, `battle_family_mapper_required=30031`, and
  `snapshot_has_verified_rule=3664`.
- Global all-card authoritative queue after PG364:
  `target_identity_count=27108`, `xmage_authoritative_source_count=26794`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26794`.
- Running the exact splitter after PG364 on supported units returns
  `proposal_count=0` over `7865` considered supported rows. The next cycle
  should continue from the fresh post-PG364 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1838`.

PG365 evidence:

- PG365 battlefield recursion constraints package:
  `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_package.md`
- PG365 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_apply_evidence.md`
- PG365 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_pg_to_sqlite_sync.json`
- PG365 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_pg_metadata_sync.json`
- PG365 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg365_battlefield_recursion_constraints_wave_e2e_validation.md`
- post-PG365 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg365_battlefield_recursion_constraints_wave_docs_final.md`
- post-PG365 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg365_battlefield_recursion_constraints_wave.md`
- post-PG365 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg365_battlefield_recursion_constraints_wave_docs_final.md`
- post-PG365 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg365_battlefield_recursion_constraints_wave_docs_final.md`
- PG365 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg365_battlefield_recursion_constraints_wave.md`
- post-PG365 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg365_battlefield_recursion_constraints_wave_commander_legal.md`
- post-PG365 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg365_supported_recheck.md`
- post-PG365 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg365_battlefield_recursion_constraints_wave_recheck.md`

PG365 measured result:

- PG365 promoted `4` exact battlefield-recursion rules for
  `Othelm, Sigardian Outcast`, `Ramosian Revivalist`, `Rise to Glory`, and
  `Squirming Emergence`.
- The splitter now supports nonland-permanent graveyard-to-battlefield
  recursion constrained by the number of permanent cards in the controller's
  graveyard, one-or-both creature/Aura battlefield recursion components, and
  activated battlefield recursion constrained to this-turn creature cards or
  fixed mana-value Rebel permanents.
- Runtime now filters graveyard recursion targets for Aura cards, Rebel
  permanents, nonland permanents, dynamic graveyard-permanent-count mana-value
  ceilings, this-turn-from-battlefield constraints, and tapped battlefield
  entry where required.
- Focused splitter/runtime tests cover the new exact split/parser cases and
  runtime resolution for all promoted target constraints.
- PostgreSQL precheck found `4/4` target card rows, `0` existing expected rows,
  and `0` shadow rows.
- PostgreSQL apply upserted `4` rows and deprecated `0` shadow rows.
- PostgreSQL postcheck verified `4/4` promoted rows, `4/4` verified/auto rows,
  and `4/4` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7387` PG rows, updated `7182` SQLite rows,
  and exported `4961` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `4/4` cards.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning;
  PG365 rows all carry matching Oracle hashes.
- Global all-card readiness after PG365:
  `battle_and_oracle_ready=2520`, `battle_family_mapper_required=30027`, and
  `snapshot_has_verified_rule=3668`.
- Global all-card authoritative queue after PG365:
  `target_identity_count=27104`, `xmage_authoritative_source_count=26790`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26790`.
- Running the exact splitter after PG365 on supported units returns
  `proposal_count=0` over `7861` considered supported rows. At that point, the
  top reusable work unit remained
  `recursion::xmage_graveyard_return_variant_review_v1` at `1834`.

PG366 evidence:

- PG366 activated draw costs package:
  `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_package.md`
- PG366 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_apply_evidence.md`
- PG366 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_pg_to_sqlite_sync.json`
- PG366 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_pg_metadata_sync.json`
- PG366 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg366_activated_draw_costs_wave_e2e_validation.md`
- post-PG366 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg366_activated_draw_costs_wave_docs_final.md`
- post-PG366 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg366_activated_draw_costs_wave.md`
- post-PG366 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg366_activated_draw_costs_wave_docs_final.md`
- post-PG366 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg366_activated_draw_costs_wave_docs_final.md`
- PG366 authoritative split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_pg366_activated_draw_costs_wave.md`
- post-PG366 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg366_activated_draw_costs_wave_commander_legal.md`
- post-PG366 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg366_supported_recheck.md`
- post-PG366 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg366_activated_draw_costs_wave_recheck.md`
- PG367 return-all graveyard battlefield package:
  `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_package.md`
- PG367 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_apply_evidence.md`
- PG367 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_pg_to_sqlite_sync.json`
- PG367 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_pg_metadata_sync.json`
- PG367 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg367_return_all_graveyard_battlefield_wave_e2e_validation.md`
- post-PG367 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg367_return_all_graveyard_battlefield_wave_commander_legal.md`
- post-PG367 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg367_supported_recheck.md`
- post-PG367 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg367_return_all_graveyard_battlefield_wave_recheck.md`
- PG368 graveyard-exile spell package:
  `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_package.md`
- PG368 PostgreSQL apply evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_apply_evidence.md`
- PG368 PG battle-rules -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_pg_to_sqlite_sync.json`
- PG368 PG card metadata -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_pg_metadata_sync.json`
- PG368 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg368_graveyard_exile_spell_wave_e2e_validation.md`
- post-PG368 XMage strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260702_post_pg368_graveyard_exile_spell_wave_docs_final.md`
- post-PG368 PG/Hermes/SQLite contract audit:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260702_post_pg368_graveyard_exile_spell_wave.md`
- post-PG368 operational surface audit:
  `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260702_post_pg368_graveyard_exile_spell_wave_docs_final.md`
- post-PG368 legacy contamination audit:
  `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260702_post_pg368_graveyard_exile_spell_wave_docs_final.md`
- post-PG368 authoritative queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260702_post_pg368_graveyard_exile_spell_wave_commander_legal.md`
- post-PG368 supported splitter recheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260702_post_pg368_supported_recheck.md`
- post-PG368 all-card readiness:
  `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260702_post_pg368_graveyard_exile_spell_wave_recheck.md`

PG366 measured result:

- PG366 promoted `12` exact permanent activated draw rules with life payment or
  sacrifice-target costs for `Akki Scrapchomper`, `Book of Rass`,
  `Carnage Altar`, `Destructive Digger`, `Dockside Chef`, `Greed`,
  `Hardened Tactician`, `Infernal Tribute`, `Phyrexian Vault`,
  `Slagdrill Scrapper`, `Soulreaper of Mogis`, and `Thallid Soothsayer`.
- The splitter now supports `PayLifeCost` and exact `SacrificeTargetCost`
  variants for artifact, creature, land, token, nontoken permanent, and
  supported OR-filter sacrifices when XMage source and Oracle cost text agree.
- Runtime now pays activated draw life costs, selects a legal low-impact
  sacrifice target other than the source, removes tokens without moving them to
  graveyard, moves non-token sacrifices to graveyard, and records replay/trace
  evidence for life paid and sacrificed permanents.
- Focused splitter/runtime tests cover life payment and target-sacrifice draw
  activation, plus the existing mana/tap and source-self-sacrifice cases.
- PostgreSQL precheck found `12/12` target card rows, `0` existing expected
  rows, and `2` nonmatching shadow rows for `Greed`.
- PostgreSQL apply upserted `12` rows and deprecated `2` shadow rows.
- PostgreSQL postcheck verified `12/12` promoted rows, `12/12` verified/auto
  rows, and `12/12` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7399` PG rows, updated `7194` SQLite rows,
  and exported `4972` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `12/12` cards.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning;
  PG366 rows all carry matching Oracle hashes.
- Global all-card readiness after PG366:
  `battle_and_oracle_ready=2532`, `battle_family_mapper_required=30015`, and
  `snapshot_has_verified_rule=3680`.
- Global all-card authoritative queue after PG366:
  `target_identity_count=27092`, `xmage_authoritative_source_count=26778`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26778`.
- Running the exact splitter after PG366 on supported units returns
  `proposal_count=0` over `7849` considered supported rows. The next cycle
  should continue from the fresh post-PG366 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1834`.

PG367 measured result:

- PG367 promoted `1` exact return-all graveyard-to-battlefield spell rule for
  `Raise the Past`.
- The splitter now supports the exact
  `ReturnFromYourGraveyardToBattlefieldAllEffect` one-shot spell subpattern
  only when XMage source and Oracle agree on self graveyard, battlefield under
  self, fixed target filter, optional tapped entry, and optional fixed mana
  value ceiling.
- Runtime support reuses the existing `recursion` executor with
  `return_all_matching=true`, destination `battlefield`, target filters, and
  focused replay evidence.
- Focused splitter/runtime tests cover return-all enchantment parsing,
  return-all creature mana-value ceilings, exact-X blocking, and battlefield
  resolution for all matching cards.
- PostgreSQL precheck found `1/1` target card row, `0` existing expected rows,
  and `0` nonmatching shadow rows.
- PostgreSQL apply upserted `1` row and deprecated `0` shadow rows.
- PostgreSQL postcheck verified `1/1` promoted rows, `1/1` verified/auto rows,
  and `1/1` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7400` PG rows, updated `7195` SQLite rows,
  and exported `4973` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `Raise the Past`.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning.
- `Replenish` remains blocked because current Oracle text includes Aura
  attachment behavior that the simple return-all battlefield runtime does not
  model. `Fix What's Broken` remains blocked by additional cost plus exact
  `mana value X` matching, which is not equivalent to X-or-less support.
- Global all-card readiness after PG367:
  `battle_and_oracle_ready=2533`, `battle_family_mapper_required=30014`, and
  `snapshot_has_verified_rule=3681`.
- Global all-card authoritative queue after PG367:
  `target_identity_count=27091`, `xmage_authoritative_source_count=26777`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26777`.
- Running the exact splitter after PG367 on supported units returns
  `proposal_count=0` over `7848` considered supported rows. The next cycle
  should continue from the fresh post-PG367 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1833`.

PG368 measured result:

- PG368 promoted `7` exact graveyard-exile spell rules for `Coffin Purge`,
  `Decompose`, `Fade from Memory`, `Purify the Grave`, `Rapid Decay`,
  `Rats' Feast`, and `Scarab Feast`.
- The splitter now supports exact `ExileTargetEffect` graveyard-card spells
  with supported `TargetCardInGraveyard` or `TargetCardInASingleGraveyard`,
  fixed/up-to target counts, X target counts, and safe flashback/cycling
  auxiliaries when XMage source and Oracle text agree.
- Runtime now resolves `graveyard_exile` spells by selecting legal graveyard
  targets, moving selected cards to exile, and emitting
  `graveyard_exile_resolved` replay and decision-trace evidence.
- Focused splitter/runtime tests pass for fixed target, up-to single-graveyard,
  X-count, unsupported auxiliary blocking, and multi-card exile resolution.
- PostgreSQL precheck found `7/7` target card rows, `0` existing expected rows,
  and `0` nonmatching shadow rows.
- PostgreSQL apply upserted `7` rows and deprecated `0` shadow rows.
- PostgreSQL postcheck verified `7/7` promoted rows, `7/7` verified/auto rows,
  and `7/7` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7407` PG rows, updated `7202` SQLite rows,
  and exported `4980` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `7/7` cards.
- XMage strategy consistency audit reports `26/26` pass.
- Operational surface alignment and legacy contamination audits report `pass`.
- PG/Hermes/SQLite contract audit reports `48` pass and `1` inherited warning.
- `Shred Memory` remains blocked because its `TransmuteAbility` auxiliary
  behavior is not supported by the exact graveyard-exile spell runtime.
- Global all-card readiness after PG368:
  `battle_and_oracle_ready=2540`, `battle_family_mapper_required=30007`, and
  `snapshot_has_verified_rule=3688`.
- Global all-card authoritative queue after PG368:
  `target_identity_count=27084`, `xmage_authoritative_source_count=26770`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26770`.
- Running the exact splitter after PG368 on supported units returns
  `proposal_count=0` over `7841` considered supported rows. The next cycle
  should continue from the fresh post-PG368 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1826`.

PG369 measured result:

- PG369 promoted `4` activated recursion cost rules for `Ghen, Arcanum Weaver`,
  `Malevolent Awakening`, `Phyrexian Reclamation`, and `Strands of Night`.
- The splitter/runtime now supports pay-life and single target-sacrifice
  activation costs for the existing simple graveyard-to-hand and
  graveyard-to-battlefield recursion scopes.
- PostgreSQL precheck found `4/4` target card rows and `0` expected rows
  before apply, with `2` nonmatching shadow rows only on `Phyrexian Reclamation`.
- PostgreSQL apply upserted `4` rows and deprecated `2` shadow rows.
- PostgreSQL postcheck verified `4/4` promoted rows, `4/4` verified/auto rows,
  and `4/4` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7411` PG rows, updated `7206` SQLite rows,
  and exported `4983` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `4/4` cards.
- Global all-card readiness after PG369:
  `battle_and_oracle_ready=2544`, `battle_family_mapper_required=30003`, and
  `snapshot_has_verified_rule=3692`.
- Global all-card authoritative queue after PG369:
  `target_identity_count=27080`, `xmage_authoritative_source_count=26766`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26766`.
- Running the exact splitter after PG369 on supported units returns
  `proposal_count=0` over `7837` considered supported rows. The next cycle
  should continue from the fresh post-PG369 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1822`.

PG370 measured result:

- PG370 promoted `8` exact static token keyword rules for `Advent of the Wurm`,
  `Call the Cavalry`, `Call to the Feast`, `Jungleborn Pioneer`, `Knight Watch`,
  `Paladin of the Bloodstained`, `Queen's Commission`, and `Sworn Companions`.
- The splitter now accepts only safe static token keywords in simple fixed token
  creation and creature ETB token creation; unsupported token text such as
  infect, prowess, toxic, triggered token text, sacrifice text, banding, and
  landwalk remains blocked.
- Runtime token creation now copies safe `token_keywords` into the token's
  boolean keyword fields, so `card_has_keyword` can read generated tokens even
  when they have no Oracle text.
- Focused splitter/runtime tests passed with `441` tests, `OK`.
- PostgreSQL precheck found `8/8` target card rows, `0` expected rows before
  apply, and `0` nonmatching shadow rows.
- PostgreSQL apply upserted `8` rows and deprecated `0` shadow rows.
- PostgreSQL postcheck verified `8/8` promoted rows, `8/8` verified/auto rows,
  and `8/8` matching Oracle hashes.
- PG -> Hermes/SQLite sync loaded `7419` PG rows, updated `7214` SQLite rows,
  and exported `4991` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `8/8` cards.
- Global all-card readiness after PG370:
  `battle_and_oracle_ready=2552`, `battle_family_mapper_required=29995`, and
  `snapshot_has_verified_rule=3700`.
- Global all-card authoritative queue after PG370:
  `target_identity_count=27072`, `xmage_authoritative_source_count=26758`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26758`.
- Running the exact splitter after PG370 on supported units returns
  `proposal_count=0` over `7829` considered supported rows. The next cycle
  should continue from the fresh post-PG370 queue; the top reusable work unit
  remains `recursion::xmage_graveyard_return_variant_review_v1` at `1822`.

PG371-PG372 measured result:

- PG371 promoted `5` fixed life-gain plus draw-card spells into
  `xmage_fixed_controller_gain_life_draw_card_spell_v1`.
- PG372 promoted `10` fixed target-creature boost plus draw-card spells into
  `xmage_fixed_boost_target_creature_until_eot_draw_card_spell_v1`.
- The runtime now supports `stat_modifier_until_eot` inside
  `composite_resolution` without double-finishing the source spell.
- Focused splitter/runtime tests passed with `447` tests, `OK`.
- PostgreSQL postchecks verified `5/5` PG371 rows and `10/10` PG372 rows as
  promoted, `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite final sync exported `5005` canonical snapshot rows and
  updated `7229` SQLite rows.
- Trusted executable curated/manual PostgreSQL rules missing `oracle_hash` were
  backfilled from `md5(cards.oracle_text)`: `1419` general rows plus `3`
  basic-land aliases; postcheck left `0` trusted executable rules without hash.
- Final PG-Hermes-SQLite contract audit passed with `49/49` checks.
- Global all-card authoritative queue after PG372:
  `target_identity_count=27057`, `xmage_authoritative_source_count=26743`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26743`.
- Running the exact splitter after PG372 on supported units returns
  `proposal_count=0` over `7814` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG373-PG374 measured result:

- PG373 promoted `7` fixed destroy-target plus draw-card spells into
  `xmage_destroy_target_and_draw_card_spell_v1`.
- PG374 promoted `5` fixed return-target-to-hand plus draw-card spells into
  `xmage_return_target_to_hand_and_draw_card_spell_v1`: `Drag Under`,
  `Galestrike`, `Leave in the Dust`, `Repulse`, and
  `Symbol of Unsummoning`.
- The runtime now routes composite removal components through the shared
  removal destination helper, so `destination=hand` bounce components move the
  target to hand rather than falling through to graveyard.
- Focused splitter/runtime tests passed with `458` tests, `OK`.
- PostgreSQL postcheck verified `5/5` PG374 rows as promoted, `verified`,
  `auto`, and hash-backed.
- PG -> Hermes/SQLite final sync exported `5017` canonical snapshot rows and
  updated `7241` SQLite rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `5/5` cards.
- Final PG-Hermes-SQLite contract audit passed with `49/49` checks.
- Global all-card authoritative queue after PG374:
  `target_identity_count=27045`, `xmage_authoritative_source_count=26731`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26731`.
- Running the exact splitter after PG374 on supported units returns
  `proposal_count=0` over `7802` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG375 measured result:

- PG375 promoted `6` fixed counter-target plus draw-card spells into
  `xmage_counter_target_and_draw_card_spell_v1`: `Bone to Ash`, `Contradict`,
  `Dismiss`, `Exclude`, `Halt Order`, and `Scatter Arc`.
- Unsupported neighbors remain deliberately blocked: activated-ability
  counters (`Bind`, `Squelch`), spell-targeting restriction variants
  (`Confound`, `Hindering Light`, `Keep Safe`), graveyard-cast restriction
  (`Laquatus's Disdain`), and modal text (`School Daze`).
- Focused splitter tests passed with `288` tests; focused exact runtime tests
  passed with `173` tests; the runtime stack-response test proves
  `draw_on_counter=1` draws a card while countering a legal creature spell.
- PostgreSQL precheck matched `6/6` target card rows on the new server; apply
  upserted `6` rows and deprecated `0` shadows; postcheck verified `6/6`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `6` PostgreSQL rows from the new target,
  updated `6` SQLite rows, and exported `5023` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `6/6` cards.
- Global all-card authoritative queue after PG375:
  `target_identity_count=27039`, `xmage_authoritative_source_count=26725`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26725`.
- Running the exact splitter after PG375 on supported units returns
  `proposal_count=0` over `7796` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.
- `db_helper.py` now prefers explicit process `DATABASE_URL` or complete
  `DB_*`/`PG*` variables over any convenience `.env` loaded from the workspace,
  preventing ignored old-server env files from overriding new-server commands.

PG376 measured result:

- PG376 promoted `12` composite draw spells on the new server:
  `9` fixed scry/draw spells and `3` fixed damage/draw spells.
- Runtime support was extended for `scry` and `direct_damage` components inside
  `composite_resolution`, with focused tests proving ordered component
  resolution without double-moving the source spell.
- Focused splitter tests passed with `294` tests; focused exact runtime tests
  passed with `175` tests.
- PostgreSQL precheck matched `12/12` target card rows on the new server; apply
  upserted `12` rows and deprecated `8` shadows; postcheck verified `12/12`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `12` PostgreSQL rows from the new target,
  inserted/updated `20` SQLite rows including deprecated shadows, and exported
  `5031` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `12/12` cards.
- Global all-card authoritative queue after PG376:
  `target_identity_count=27027`, `xmage_authoritative_source_count=26713`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26713`.
- Running the exact splitter after PG376 on supported units returned
  `proposal_count=0` over `7784` considered supported rows.

PG377 measured result:

- PG377 promoted `32` keyword-until-EOT rules on the new server:
  `25` fixed target-creature boost plus keyword spells and `7` simple
  activated target-creature keyword permanents.
- The splitter now strips Oracle reminder text in parenthetical clauses for
  the keyword-until-EOT exact mapper path, fixing false blockers such as
  `Bloodlust Inciter`, `Axgard Cavalry`, `Brute Strength`, and
  `Beaming Defiance` without promoting broad generic protection behavior.
- Focused splitter tests passed with `296` tests; focused exact runtime tests
  passed with `175` tests. No new runtime executor was needed because both
  scopes already had focused runtime coverage.
- PostgreSQL precheck matched `32/32` target card rows on the new server; apply
  upserted `32` rows and deprecated `0` shadows; postcheck verified `32/32`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `32` PostgreSQL rows from the new target,
  updated `32` SQLite rows, and exported `5063` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `32/32` cards.
- Global all-card authoritative queue after PG377:
  `target_identity_count=26995`, `xmage_authoritative_source_count=26681`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26681`.
- Running the exact splitter after PG377 on supported units returned
  `proposal_count=0` over `7752` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG378 measured result:

- PG378 promoted `16` constrained activated target-keyword permanent rules on
  the new server:
  `Accursed Horde`, `Air Marshal`, `Beacon Behemoth`, `Bloodthorn Taunter`,
  `Hotfoot Gnome`, `Jawbone Skulkin`, `Kelsinko Ranger`,
  `Krosan Groundshaker`, `Might Weaver`, `Mosstodon`, `Rage Weaver`,
  `Rakeclaw Gargantuan`, `Sky Weaver`, `Sootstoke Kindler`,
  `Spearbreaker Behemoth`, and `Whalebone Glider`.
- The runtime now validates subtype/supertype target constraints and lets
  activated target-keyword abilities consider `permanent` targets when XMage
  uses `TargetPermanent`. The splitter now requires full Oracle/source
  agreement on `target_constraints` before packaging.
- Focused splitter tests passed with `302` tests; focused exact runtime tests
  passed with `178` tests; py_compile passed.
- PostgreSQL precheck matched `16/16` target card rows on the new server; apply
  upserted `16` rows and deprecated `0` shadows; postcheck verified `16/16`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `16` PostgreSQL rows from the new target,
  updated `16` SQLite rows, and exported `5079` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `16/16` cards.
- Global all-card authoritative queue after PG378:
  `target_identity_count=26979`, `xmage_authoritative_source_count=26665`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26665`.
- Running the exact splitter after PG378 on supported units returned
  `proposal_count=0` over `7736` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG379 measured result:

- PG379 promoted `5` fixed direct-damage spells with exact XMage
  `SacrificeTargetCost` support on the new server: `Collateral Damage`,
  `Fiery Conclusion`, `Magma Rift`, `Reckless Abandon`, and `Shard Volley`.
- The splitter now admits only pure fixed `DamageTargetEffect` one-shot spells
  whose additional cost is an exact supported target sacrifice of a creature or
  land. Mixed sacrifice filters such as creature-or-enchantment,
  creature-or-planeswalker, artifact-or-creature, permanent, subtype-only, and
  discard/random costs remain blocked.
- The runtime now pays `requires_sacrifice_land` in the generic card additional
  cost path and marks additional costs as paid so stack resolution cannot charge
  the same spell twice.
- Focused splitter tests passed with `305` tests; focused exact runtime tests
  passed with `180` tests; py_compile passed.
- PostgreSQL precheck matched `5/5` target card rows on the new server; apply
  upserted `5` rows and deprecated `0` shadows; postcheck verified `5/5`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `5` PostgreSQL rows from the new target,
  updated `5` SQLite rows, and exported `5084` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `5/5` cards.
- Global all-card authoritative queue after PG379:
  `target_identity_count=26974`, `xmage_authoritative_source_count=26660`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26660`.
- Running the exact splitter after PG379 on supported units returned
  `proposal_count=0` over `7731` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG380 measured result:

- PG380 promoted `15` permanent activated draw-then-discard rules with exact
  local XMage `DrawDiscardControllerEffect + SimpleActivatedAbility` support on
  the new server: `Bloodfire Mentor`, `Captain of Umbar`, `Dragonborn Looter`,
  `Emmessi Tome`, `Erratic Visionary`, `Facet Reader`, `Hapless Researcher`,
  `Jalum Tome`, `Magus of the Bazaar`, `Merfolk Looter`,
  `Research Assistant`, `Soothsayer Adept`, `Teferi's Protege`,
  `Thought Courier`, and `Unfulfilled Desires`.
- The splitter now admits only exact permanent activated draw-discard rows with
  fixed draw/discard counts and supported mana, tap, life, or source
  self-sacrifice costs. `Maestros Initiate` remains blocked as
  `activated_draw_discard_oracle_cost_not_supported`.
- The runtime now executes generic `activated_draw_discard` permanents by
  paying costs, drawing, discarding, resolving discard triggers, and emitting
  `simple_activated_draw_discard`.
- Focused splitter tests passed with `309` tests; focused exact runtime tests
  passed with `183` tests; package-builder tests and py_compile passed.
- PostgreSQL precheck matched `15/15` target card rows on the new server; apply
  upserted `15` rows and deprecated `0` shadows; postcheck verified `15/15`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `3932` PostgreSQL rows from the new target,
  updated `4933` SQLite rows, and exported `5091` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `15/15` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Contract cleanup in the same closeout backfilled missing `oracle_hash` for
  the trusted executable curated rules of `Angel's Grace` and `Seething Song`
  from `cards.oracle_text`, synced those rows back to Hermes/SQLite, and linked
  SQLite deck `607` to PostgreSQL deck
  `8938b746-1a9e-46ce-b0d9-c2ec932ddddd` after exact 94-row/100-card parity
  comparison.
- Global all-card authoritative queue after PG380:
  `target_identity_count=26959`, `xmage_authoritative_source_count=26645`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26645`.
- Running the exact splitter after PG380 on supported units returned
  `proposal_count=0` over `7732` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG381 measured result:

- PG381 promoted `2` permanent activated graveyard-to-battlefield rules with
  exact local XMage `ReturnFromGraveyardToBattlefieldTargetEffect` plus
  `ActivateAsSorceryActivatedAbility` support on the new server:
  `Bonecaller Cleric` and `Valgavoth's Faithful`.
- The splitter now admits sorcery-speed activated recursion only when Oracle
  text and source agree on `Activate only as a sorcery.`, a fixed supported
  activation cost, source self-sacrifice, and a target creature card in your
  graveyard. Variable-X and mana-value-constrained neighbors remain blocked.
- Effect JSON records `activation_timing = sorcery`, so package/runtime checks
  distinguish this from ordinary `SimpleActivatedAbility` recursion.
- Focused splitter tests passed with `310` tests; focused exact runtime tests
  passed with `184` tests; package-builder tests and py_compile passed.
- PostgreSQL precheck matched `2/2` target card rows on the new server; apply
  upserted `2` rows and deprecated `0` shadows; postcheck verified `2/2`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `2` PostgreSQL rows from the new target,
  updated `2` SQLite rows, and exported `5093` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `2/2` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG381:
  `target_identity_count=26957`, `xmage_authoritative_source_count=26643`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26643`.
- Running the exact splitter after PG381 on supported units returned
  `proposal_count=0` over `7730` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG382 measured result:

- PG382 promoted `9` fixed source-controller draw spells with exact local XMage
  `DrawCardSourceControllerEffect` support and runtime-supported additional
  costs on the new server: `Altar's Reap`, `Blood Divination`,
  `Corrupted Conviction`, `Magmatic Insight`, `Skulltap`,
  `Tormenting Voice`, `Village Rites`, `Vivisection`, and `Wild Guess`.
- The splitter now accepts only fixed draw spells whose additional cost is one
  of: sacrifice one creature, discard one card, or discard one land card.
  Unsupported neighbors remain blocked as `draw_additional_cost_not_supported`.
- Runtime coverage reuses `pay_additional_card_costs`; focused runtime tests
  prove sacrifice/discard is paid before draw resolution.
- Focused splitter tests passed with `314` tests; focused exact runtime tests
  passed with `186` tests; package-builder tests and py_compile passed.
- PostgreSQL precheck matched `9/9` target card rows on the new server; apply
  upserted `9` rows; postcheck verified `9/9` promoted rows as `verified`,
  `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `9` PostgreSQL rows from the new target,
  updated `17` SQLite rows, and exported `5098` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `9/9` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG382:
  `target_identity_count=26948`, `xmage_authoritative_source_count=26634`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26634`.
- Running the exact splitter after PG382 on supported units returned
  `proposal_count=0` over `7721` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG383 measured result:

- PG383 promoted `18` same-spell target-effect plus fixed-scry cards on the
  new server: `8` damage+scry, `8` destroy+scry, and `2` bounce+scry.
- Promoted cards were `Artisan's Sorrow`, `Bolt of Keranos`,
  `Expose to Daylight`, `Fateful End`, `Get the Point`, `Guiding Bolt`,
  `Jaya's Firenado`, `Jaya's Greeting`, `Lightning Javelin`, `Magma Jet`,
  `Piercing Light`, `Rubble Reading`, `Select for Inspection`,
  `Skywhaler's Shot`, `Spark Jolt`, `Tel-Jilad Justice`,
  `Vanquish the Foul`, and `Voyage's End`.
- The splitter now maps fixed `DamageTargetEffect + ScryEffect`,
  `DestroyTargetEffect + ScryEffect`, `ExileTargetEffect + ScryEffect`, and
  `ReturnToHandTargetEffect + ScryEffect` spells into composite runtime scopes
  when Oracle and local XMage source agree exactly. The exile+scry parser exists
  but did not produce safe PG383 candidates because current residual cards need
  unsupported target constraints.
- Runtime coverage uses existing composite resolution for damage, destroy,
  return-to-hand, and scry; focused runtime tests prove destroy+scry removes
  the target and then scries.
- Focused splitter tests passed with `320` tests; focused exact runtime tests
  passed with `187` tests; package-builder tests and py_compile passed.
- PostgreSQL precheck matched `18/18` target card rows on the new server; apply
  upserted `18` rows; postcheck verified `18/18` promoted rows as `verified`,
  `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `18` PostgreSQL rows from the new target,
  updated `18` SQLite rows, and exported `5116` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `18/18` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG383:
  `target_identity_count=26930`, `xmage_authoritative_source_count=26616`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26616`.
- Running the exact splitter after PG383 on supported units returned
  `proposal_count=0` over `7703` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG384 measured result:

- PG384 promoted `12` supported additional-cost spells on the new server:
  `5` fixed damage spells, `4` destroy-target spells, and `3` fixed draw
  spells.
- Promoted cards were `Acceptable Losses`, `Artillerize`, `Bone Splinters`,
  `Costly Plunder`, `Embrace Oblivion`, `Eviscerator's Insight`,
  `Improvised Club`, `Morbid Curiosity`, `Powerstone Fracture`, `Raze`,
  `Sonic Burst`, and `Sonic Seizure`.
- The splitter now uses one shared spell-additional-cost mapper for supported
  discard, sacrifice-creature, sacrifice-land, and sacrifice-artifact-or-creature
  costs across damage, draw, and destroy exact spell scopes.
- Runtime coverage now pays `requires_sacrifice_artifact_or_creature` and pays
  additional costs before resolving destroy/remove effects, matching the earlier
  damage/draw behavior.
- Focused splitter tests passed with `323` tests; focused exact runtime tests
  passed with `189` tests; package-builder tests and py_compile passed.
- PostgreSQL precheck matched `12/12` target card rows on the new server; apply
  upserted `12` rows; postcheck verified `12/12` promoted rows as `verified`,
  `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `12` PostgreSQL rows from the new target,
  updated `12` SQLite rows, and exported `5128` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `12/12` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG384:
  `target_identity_count=26918`, `xmage_authoritative_source_count=26604`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26604`.
- Running the exact splitter after PG384 on supported units returned
  `proposal_count=0` over `7691` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG385 measured result:

- PG385 promoted `9` fixed draw/discard spells on the new server:
  `Ancestral Reminiscence`, `Careful Study`, `Catalog`, `Enhanced Awareness`,
  `Prying Eyes`, `Rain of Revelation`, `Romantic Rendezvous`, `Sift`, and
  `Thoughtflare`.
- The splitter now maps exact fixed `DrawDiscardControllerEffect` and exact
  fixed `DrawCardSourceControllerEffect + DiscardControllerEffect` spell pairs
  into `xmage_fixed_draw_discard_spell_v1` only when Oracle and XMage agree on
  draw count, discard count, and order. Dynamic counts, additional abilities,
  optional costs, and non-exact Oracle text remain blocked.
- Runtime coverage resolves `draw_then_discard` and `discard_then_draw`, emits
  `draw_discard_spell_resolved`, uses seeded random discard when XMage marks
  `DiscardControllerEffect(..., true)`, and otherwise reuses the existing
  discard-selection heuristic plus discard triggers.
- Focused splitter tests passed with `327` tests; focused exact runtime tests
  passed with `191` tests; sync selection tests passed with `19` tests; and
  `py_compile` passed.
- PostgreSQL precheck matched `9/9` target card rows on the new server; apply
  upserted `9` rows with `0` shadow rows deprecated; postcheck verified `9/9`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `9` PostgreSQL rows from the new target,
  updated `9` SQLite rows, and exported `5137` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `9/9` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, and PG-Hermes-SQLite contract `50/50`
  pass.
- Global all-card authoritative queue after PG385:
  `target_identity_count=26909`, `xmage_authoritative_source_count=26595`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26595`.
- Running the exact splitter after PG385 on supported units returned
  `proposal_count=0` over `7682` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG386 measured result:

- PG386 promoted `8` fixed draw plus life-loss spells on the new server:
  `Ambition's Cost`, `Ancient Craving`, `Blood Pact`, `Harrowing Journey`,
  `Night's Whisper`, `Painful Lesson`, `Sign in Blood`, and
  `Succumb to Temptation`.
- The splitter now maps exact fixed
  `DrawCardSourceControllerEffect + LoseLifeSourceControllerEffect` into
  `xmage_fixed_controller_draw_lose_life_spell_v1` and exact fixed
  `DrawCardTargetEffect + LoseLifeTargetEffect` with `TargetPlayer` into
  `xmage_fixed_target_player_draw_lose_life_spell_v1`, only when Oracle and
  XMage agree on draw count, life loss, and target model. Dynamic `X`,
  devotion/converge, additional ability classes, and non-exact Oracle text
  remain blocked.
- Runtime coverage resolves draw plus life loss with
  `draw_lose_life_spell_resolved`; target-player variants choose self for
  normal card draw and only target an opponent when the life loss is lethal,
  unless a replay declares a target.
- Focused splitter tests passed with `330` tests; focused exact runtime tests
  passed with `193` tests; sync selection tests passed with `19` tests; and
  `py_compile` passed.
- PostgreSQL precheck matched `8/8` target card rows on the new server; apply
  upserted `8` rows and deprecated `4` stale shadow rows; postcheck verified
  `8/8` promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `12` PostgreSQL rows from the new target
  because the four deprecated shadows are mirrored as disabled history,
  updated `12` SQLite rows, and exported `5143` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `8/8` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG386:
  `target_identity_count=26901`, `xmage_authoritative_source_count=26587`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26587`.
- Running the exact splitter after PG386 on supported units returned
  `proposal_count=0` over `7674` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG387 measured result:

- PG387 promoted `4` fixed creature ETB draw plus life-loss rules on the new
  server: `Dusk Legion Zealot`, `Phyrexian Gargantua`, `Phyrexian Rager`, and
  `Tithebearer Giant`.
- The splitter now maps exact fixed
  `DrawCardSourceControllerEffect + LoseLifeSourceControllerEffect` with
  `EntersBattlefieldTriggeredAbility` into
  `xmage_creature_etb_draw_lose_life_v1`, only when Oracle and XMage agree on
  fixed draw count and fixed life loss. Conditional ETB, `X`/dynamic counts,
  alternative triggers, and non-static auxiliary abilities remain blocked.
- Runtime coverage resolves the ETB draw, processes draw triggers, then applies
  controller life loss through `etb_life_loss` in the same triggered event.
- Focused splitter/runtime tests passed; full exact splitter tests passed
  `333/333`, full exact runtime tests passed `194/194`, and package
  builder/sync tests passed `23/23`.
- PostgreSQL precheck matched `4/4` target card rows on the new server; apply
  upserted `4` rows and deprecated `0` stale shadows; postcheck verified `4/4`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `4` PostgreSQL rows, updated `4` SQLite
  rows, and exported `5147` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `4/4` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG387:
  `target_identity_count=26897`, `xmage_authoritative_source_count=26583`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26583`.
- Running the exact splitter after PG387 on supported units returned
  `proposal_count=0` over `7675` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG388 measured result:

- PG388 promoted `8` exact creature ETB library tutor-to-battlefield rules on
  the new server: `Farhaven Elf`, `Kor Cartographer`, `Ondu Giant`,
  `Quandrix Cultivator`, `Quirion Trailblazer`, `Silverglade Elemental`,
  `Wild Wanderer`, and `Wood Elves`.
- The splitter now maps exact
  `SearchLibraryPutInPlayEffect + EntersBattlefieldTriggeredAbility` with
  optional static self keywords into
  `xmage_creature_etb_library_search_to_battlefield_v1`, only when Oracle and
  XMage agree on a one-card land tutor destination. Supported targets are
  `basic_land`, `plains`, `forest`, and `basic_forest_or_island`; unsupported
  conditions, optional costs, modal clauses, dynamic counts, and unsupported
  target classes stay blocked.
- Runtime coverage reuses the ETB tutor execution path through
  `etb_tutor_target` and `move_library_tutor_selection`, with added
  `basic_forest_or_island` selection support. Tapped-entry state is carried by
  `tutor_enters_tapped`.
- Focused splitter/runtime tests passed; full exact splitter tests passed
  `336/336`, full exact runtime tests passed `195/195`, package builder/sync
  tests passed `23/23`, and `py_compile` passed for the changed scripts.
- PostgreSQL precheck matched `8/8` target card rows on the new server; apply
  upserted `8` rows and deprecated `2` stale Farhaven Elf review-only shadows;
  postcheck verified `8/8` promoted rows as `verified`, `auto`, and
  hash-backed.
- PG -> Hermes/SQLite sync loaded `8` PostgreSQL rows, updated `10` SQLite rows
  including the two disabled stale shadows, and exported `5154` canonical
  snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `8/8` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global readiness after PG388: `battle_and_oracle_ready=4018`,
  `battle_family_mapper_required=29812`, and `snapshot_has_verified_rule=3883`.
- Global all-card authoritative queue after PG388:
  `target_identity_count=26889`, `xmage_authoritative_source_count=26575`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26575`.
- Running the exact splitter after PG388 on supported units returned
  `proposal_count=0` over `7667` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG389 measured result:

- PG389 promoted `2` exact multi-zone graveyard recursion spells on the new
  server: `Badlands Revival` and `Pull Through the Weft`.
- The splitter now maps exact
  `ReturnFromGraveyardToBattlefieldTargetEffect +
  ReturnFromGraveyardToHandTargetEffect` spells into
  `xmage_return_multi_zone_graveyard_cards_spell_v1`, only when Oracle and
  XMage agree on exactly two self-graveyard components, destination order,
  target count, `up to` semantics, and tapped battlefield entry. Supported
  targets are `creature`, `permanent`, `nonland_permanent`, and `land`.
- Conditional effects, threshold-style wrappers, additional costs, auxiliary
  ability classes, unsupported target classes, and non-two-component recursion
  remain blocked by the splitter instead of being promoted.
- Runtime coverage reuses the existing recursion-component executor, including
  mixed hand/battlefield destinations and tapped battlefield entry.
- Full exact splitter tests passed `339/339`, full exact runtime tests passed
  `196/196`, package builder/sync tests passed `23/23`, and `py_compile`
  passed for the changed scripts.
- PostgreSQL precheck matched `2/2` target card rows on the new server; apply
  upserted `2` rows and deprecated `0` shadows; postcheck verified `2/2`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `2` PostgreSQL rows, updated `2` SQLite rows,
  and exported `5156` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `2/2` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global readiness after PG389: `battle_and_oracle_ready=4020`,
  `battle_family_mapper_required=29810`, and
  `snapshot_has_verified_rule=3885`.
- Global all-card authoritative queue after PG389:
  `target_identity_count=26887`, `xmage_authoritative_source_count=26573`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26573`.
- Running the exact splitter after PG389 on supported units returned
  `proposal_count=0` over `7665` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG390 measured result:

- PG390 promoted `12` fixed damage plus exile-if-dies spells on the new server
  into `xmage_fixed_damage_target_exile_if_dies_spell_v1`.
- The splitter now maps exact local XMage
  `DamageTargetEffect + ExileTargetIfDiesEffect` only when the fixed damage
  amount, supported target class, and Oracle "would die this turn, exile it
  instead" clause agree. Dynamic damage, unsupported targets, and additional
  costs remain blocked.
- Runtime coverage applies damage with an exile-if-dies marker so the damaged
  target is exiled rather than moved to graveyard when lethal damage resolves.
- PostgreSQL postcheck verified `12/12` promoted rows as `verified`, `auto`,
  and hash-backed on the new server.
- PG -> Hermes/SQLite sync and E2E validation passed for PostgreSQL,
  SQLite/Hermes, canonical snapshot, and runtime `get_card_effect`.
- Global all-card authoritative queue after PG390:
  `target_identity_count=26875`, `xmage_authoritative_source_count=26561`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26561`.
- Running the exact splitter after PG390 on supported units returned
  `proposal_count=0` over `7653` considered supported rows until the PG391
  target-player draw mapper was implemented.

PG391 measured result:

- PG391 promoted `2` fixed target-player draw spells on the new server:
  `Inspiration` and `Opportunity`.
- The splitter now maps exact local XMage `DrawCardTargetEffect` plus
  `TargetPlayer` into `xmage_fixed_target_player_draw_spell_v1`, only when
  Oracle text is exactly "Target player draws N cards." and source/Oracle
  fixed counts agree. X/dynamic counts, ability-class variants, and non-exact
  Oracle text remain blocked.
- Runtime coverage resolves `target_player_draw` by honoring a replay-declared
  target first and otherwise choosing the controller for beneficial card draw.
- Focused splitter tests passed `345/345`; focused exact runtime tests passed
  `200/200`; package-builder tests passed `5/5`; and `py_compile` passed.
- PostgreSQL precheck matched `2/2` target card rows on the new server; apply
  upserted `2` rows and deprecated `0` shadows; postcheck verified `2/2`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `2` PostgreSQL rows from the new target,
  updated `2` SQLite rows, and exported `5170` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `2/2` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, and PG-Hermes-SQLite contract `50/50`
  pass.
- Global readiness after PG391: `battle_and_oracle_ready=4034`,
  `battle_family_mapper_required=29796`, and
  `snapshot_has_verified_rule=3899`.
- Global all-card authoritative queue after PG391:
  `target_identity_count=26873`, `xmage_authoritative_source_count=26559`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26559`.
- Running the exact splitter after PG391 on supported units returned
  `proposal_count=0` over `7651` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG392 measured result:

- PG392 promoted `5` permanent activated draw rules with generic discard-card
  activation cost on the new server: `Goblin Picker`, `Mental Discipline`,
  `Merchant of the Vale // Haggle`, `Oread of Mountain's Blaze`, and
  `Rummaging Goblin`.
- The splitter now maps exact local XMage
  `DrawCardSourceControllerEffect + SimpleActivatedAbility` permanent draw
  abilities with generic `DiscardCardCost` or `DiscardTargetCost` only when
  Oracle/source both mean "discard a card" before drawing. Filtered discard
  costs, multiple activated draw abilities, dynamic counts, target-tap,
  graveyard, and non-exact compound text remain blocked.
- Runtime coverage pays the discard activation cost before drawing, records
  discarded card/count/target evidence, and reports net card-resource delta.
  Unsupported filtered discard targets remain skipped rather than executed.
- Full exact splitter tests passed `346/346`, full exact runtime tests passed
  `201/201`, package-builder tests passed `6/6`, and `py_compile` passed for
  the changed scripts.
- PostgreSQL precheck matched `5/5` target card rows on the new server; apply
  upserted `5` rows and deprecated `0` shadows; postcheck verified `5/5`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `5` PostgreSQL rows from the new target,
  updated `5` SQLite rows, and exported `5175` canonical snapshot rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, and
  runtime `get_card_effect` checks for `5/5` cards.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `39/39`, and PG-Hermes-SQLite contract `50/50`
  pass.
- Global all-card authoritative queue after PG392:
  `target_identity_count=26868`, `xmage_authoritative_source_count=26554`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26554`.
- Running the exact splitter after PG392 on supported units returned
  `proposal_count=0` over `7646` considered supported rows. The next cycle must
  implement another exact mapper/runtime subpattern before package generation.

PG393 measured result:

- PG393 promoted `25` simple tap mana-source permanents with safe auxiliary
  text on the new server: `Charcoal Diamond`, `Darksteel Ingot`,
  `Deathbloom Gardener`, `Druid of the Anima`, `Fire Diamond`, `Fire Sprites`,
  `Hedron Crawler`, `Leyline Prowler`, `Lotus Guardian`, `Maraleaf Pixie`,
  `Marble Diamond`, `Moss Diamond`, `Noxious Newt`, `Obelisk of Bant`,
  `Obelisk of Esper`, `Obelisk of Grixis`, `Obelisk of Jund`,
  `Obelisk of Naya`, `Sky Diamond`, `Steward of Valeron`,
  `Sylvan Caryatid`, `Timeless Lotus`, `Urborg Elf`, `Vine Trellis`, and
  `Warden of Geometries`.
- The splitter now maps one simple `{T}: Add ...` mana ability from single-line
  or multi-line Oracle text, strips parenthetical mana reminders, and carries
  safe auxiliary metadata for static self keywords plus enters-tapped state.
  Unsupported neighbor cases remain blocked, including crew/cycling/suspend,
  alternative costs, conditional mana, multiple complex mana abilities, and
  unsupported auxiliary ability classes.
- Runtime coverage keeps `ramp_permanent` behavior exact for these promoted
  permanents, including enters-tapped state so a newly entered tapped mana
  source does not immediately refresh as usable mana.
- Full exact splitter tests passed `350/350`, full exact runtime tests passed
  `202/202`, package-builder tests passed `6/6`, and `py_compile` passed for
  the changed scripts.
- PostgreSQL precheck matched `25/25` target card rows on the new server; apply
  upserted `25` rows and deprecated `16` stale review-only shadows; postcheck
  verified `25/25` promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `7698` PostgreSQL rows from the new target,
  updated `7470` SQLite rows, and exported `5200` canonical snapshot rows.
  Full metadata sync used `postgres_target=127.0.0.1:15432/halder`, matched
  `6200` PostgreSQL cards from `6009` unique requested names, backfilled
  `2699/2699` deck-card cache rows, and left one unrelated unresolved alias:
  `Surgical Suite/Hospital Room`.
- Contract cleanup in the same closeout backfilled missing `oracle_hash` for
  the two remaining trusted executable SQLite/PG curated rows surfaced by the
  audit: `Angel's Grace` and `Seething Song`. The cleanup used
  `public.cards.oracle_text` md5 on the new server, synced SQLite again from
  PostgreSQL, and raised the final PG-Hermes-SQLite contract audit from
  `49 pass / 1 warn` to `50/50 pass`.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot,
  runtime `get_card_effect`, and no-override battle checks for all `25` cards
  against `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and final
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG393:
  `target_identity_count=26843`, `xmage_authoritative_source_count=26529`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26529`.
- Running the exact splitter after PG393 and the hash cleanup on supported
  units returned
  `proposal_count=0` over `7621` considered supported rows. Mana-source
  neighbors now remain explicitly classified, with
  `mana_source_auxiliary_ability_not_supported=305`,
  `mana_source_unsafe_ability_class=133`,
  `mana_source_safe_ability_missing=132`,
  `mana_source_effect_class_not_simple=24`, and
  `mana_source_oracle_not_simple=21`.

PG394 measured result:

- PG394 promoted `24` creature dies token-maker rules on the new server:
  `Beskir Shieldmate`, `Brindle Shoat`, `Brood Weaver`,
  `Conscripted Infantry`, `Deathbloom Thallid`, `Discordant Piper`,
  `Doomed Dissenter`, `Doomed Traveler`, `Dwarven Castle Guard`,
  `Elgaud Inquisitor`, `Filigree Crawler`, `Garrison Cat`,
  `Hunted Witness`, `Infestation Sage`, `Maalfeld Twins`, `Martyr of Dusk`,
  `Myr Sire`, `Penumbra Bobcat`, `Penumbra Kavu`, `Penumbra Spider`,
  `Penumbra Wurm`, `Pretending Poxbearers`, `Tukatongue Thallid`, and
  `Wriggling Grub`.
- The splitter now maps fixed
  `CreateTokenEffect + DiesSourceTriggeredAbility` source rows to
  `xmage_creature_dies_create_tokens_v1` only when XMage has one fixed token
  class/count and Oracle exactly says the creature dies and creates that token.
  It blocks conditional dies text, dynamic counts, non-creature tokens,
  additional token fanout, custom effect text, and unsupported token abilities.
- Runtime coverage adds a dies-token hook to the same battlefield-to-graveyard
  path used by dies-draw and dies-recursion, so bounce/exile/replacement moves
  do not create tokens. The hook emits `dies_token_maker_resolved` and reuses
  the existing token factory for colors, subtypes, artifact creature tokens,
  power/toughness, and safe token keywords.
- Full exact splitter tests passed `354/354`, full exact runtime tests passed
  `203/203`, package-builder tests passed, and `py_compile` passed for the
  changed scripts.
- PostgreSQL precheck matched `24/24` target card rows on the new server; apply
  upserted `24` rows and deprecated `0` shadows; postcheck verified `24/24`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `7722` PostgreSQL rows from
  `database_target=127.0.0.1:15432/halder`, updated `7517` SQLite rows, and
  exported `5224` canonical snapshot rows. Full metadata sync used the same
  new-server target, matched `6200` PostgreSQL cards from `6009` unique
  requested names, backfilled `2699/2699` deck-card cache rows, and left one
  unrelated unresolved alias.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, runtime
  `get_card_effect`, and no-override battle checks for all `24` cards against
  `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG394:
  `target_identity_count=26819`, `xmage_authoritative_source_count=26505`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26505`.
- Running the exact splitter after PG394 on supported units returned
  `proposal_count=0` over `7659` considered supported rows. Remaining
  token-maker neighbors are explicitly blocked, including
  `dies_token_oracle_not_simple=4`, `token_description_not_creature_token=20`,
  `token_source_create_token_not_fixed=28`,
  `token_source_additional_tokens_not_supported=8`,
  `token_source_custom_text_not_supported=9`, and
  `token_literal_description_missing=29`.

PG395 measured result:

- PG395 promoted `7` creature dies fixed life-gain rules on the new server:
  `Anodet Lurker`, `Enatu Golem`, `Grasping Longneck`, `Guardian Automaton`,
  `Highland Game`, `Onulet`, and `Tarpan`.
- The splitter now maps fixed
  `GainLifeEffect + DiesSourceTriggeredAbility` source rows to
  `xmage_creature_dies_gain_life_v1` only when XMage has one fixed life-gain
  amount and Oracle exactly says this creature/card name dies and you gain that
  amount of life. It blocks dynamic/conditional neighbors such as
  `Bottle Golems`, `Centaur Safeguard`, and `Silent-Chant Zubera`.
- Runtime coverage adds a dies-life-gain hook to the same
  battlefield-to-graveyard path used by dies-draw, dies-recursion, and
  dies-token. Bounce/exile/replacement moves do not trigger it. The hook emits
  `dies_life_gain_resolved` with requested/gained life, before/after controller
  life, source, and rule provenance.
- Full exact splitter tests passed `357/357`, full exact runtime tests passed
  `204/204`, package-builder tests passed, and `py_compile` passed for the
  changed scripts.
- PostgreSQL precheck matched `7/7` target card rows on the new server; apply
  upserted `7` rows and deprecated `0` shadows; postcheck verified `7/7`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `7729` PostgreSQL rows from
  `database_target=127.0.0.1:15432/halder`, updated `7524` SQLite rows, and
  exported `5231` canonical snapshot rows. Full metadata sync used the same
  new-server target, matched `6230` PostgreSQL cards from `6039` unique
  requested names, backfilled `2699/2699` deck-card cache rows, and left one
  unrelated unresolved alias.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, runtime
  `get_card_effect`, and no-override battle checks for all `7` cards against
  `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG395:
  `target_identity_count=26812`, `xmage_authoritative_source_count=26498`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26498`.
- Running the exact splitter after PG395 on supported units returned
  `proposal_count=0` over `7652` considered supported rows. Remaining
  life-gain dies neighbors are explicitly blocked by
  `dies_life_gain_amount_not_fixed=3`.

PG396 measured result:

- PG396 promoted `8` creature dies fixed damage rules on the new server:
  `Bogardan Firefiend`, `Careless Celebrant`, `Footlight Fiend`,
  `Goblin Arsonist`, `Mudbutton Torchrunner`, `Perilous Myr`,
  `Pitchburn Devils`, and `Pyre Spawn`.
- The splitter now maps fixed
  `DamageTargetEffect + DiesSourceTriggeredAbility` source rows to
  `xmage_creature_dies_fixed_damage_target_v1` only when XMage has one fixed
  damage amount, Oracle exactly says this creature/card name dies and deals
  that amount of damage, and the XMage target class/filter matches the Oracle
  target. It supports `any target`, `target creature`, and target creature or
  planeswalker. Dynamic/complex neighbors remain blocked, including
  `Blazing Effigy` and `Ember-Fist Zubera`.
- Runtime coverage adds a dies-damage hook to the same
  battlefield-to-graveyard path used by dies-draw, dies-life-gain,
  dies-recursion, and dies-token. Bounce/exile/replacement moves do not trigger
  it. The hook reuses `apply_direct_damage` and emits
  `dies_damage_trigger_resolved` plus the normal `damage_resolved` provenance.
- Full exact splitter tests passed `362/362`, full exact runtime tests passed
  `206/206`, package-builder tests passed, and `py_compile` passed for the
  changed scripts.
- PostgreSQL precheck matched `8/8` target card rows on the new server; apply
  upserted `8` rows and deprecated `0` shadows; postcheck verified `8/8`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `7737` PostgreSQL rows from
  `database_target=127.0.0.1:15432/halder`, updated `7532` SQLite rows, and
  exported `5239` canonical snapshot rows. Full metadata sync used the same
  new-server target, matched `6238` PostgreSQL cards from `6047` unique
  requested names, backfilled `2699/2699` deck-card cache rows, and left one
  unrelated unresolved alias.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, runtime
  `get_card_effect`, and no-override battle checks for all `8` cards against
  `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `50/50` pass.
- Global all-card authoritative queue after PG396:
  `target_identity_count=26804`, `xmage_authoritative_source_count=26490`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26490`.
- Running the exact splitter after PG396 on supported units returned
  `proposal_count=0` over `7644` considered supported rows. Remaining
  dies-damage neighbors are explicitly blocked by
  `dies_damage_amount_not_fixed=1` and `dies_damage_target_not_supported=1`.

PG397 measured result:

- PG397 promoted `17` permanent simple activated damage rules with static
  self-keyword auxiliaries on the new server: `Aven Archer`,
  `Crimson Manticore`, `Cunning Sparkmage`, `Dive Bomber`,
  `Divebomber Griffin`, `Fanatical Firebrand`, `Jeska, Warrior Adept`,
  `Kamahl, Pit Fighter`, `Mawcor`, `Sarpadian Simulacrum`, `Scaldkin`,
  `Shivan Hellkite`, `Skyway Sniper`, `Stinging Barrier`, `Storm Spirit`,
  `Thornwind Faeries`, and `Vulshok Sorcerer`.
- The splitter now accepts `DamageTargetEffect + SimpleActivatedAbility` source
  rows with only safe static self keyword ability classes such as `Flying`,
  `Haste`, `Reach`, `Defender`, and `First Strike`. It preserves
  `keywords`, `_keywords_are_self`, `xmage_ability_classes`, and the exact
  activated damage metadata while still blocking unsupported costs, dynamic
  amounts, compound effects, and unsupported targets.
- Runtime coverage uses the existing
  `xmage_permanent_simple_activated_damage_v1` path and adds focused proof that
  a self-keyword creature keeps the static keyword and can still activate the
  damage ability with rule provenance. The package builder now also carries
  `_keywords_are_self`, `activated_battle_model_scope`,
  `activated_damage_amount`, `_activated_rule_effects`, and XMage class fields
  into E2E required fields.
- Full exact splitter tests passed `364/364`, full exact runtime tests passed
  `207/207`, package-builder tests passed `6/6`, and `py_compile` passed for
  the changed scripts.
- PostgreSQL precheck matched `17/17` target card rows on the new server; apply
  upserted `17` rows and deprecated `0` shadows; postcheck verified `17/17`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `7754` PostgreSQL rows from
  `database_target=127.0.0.1:15432/halder`, updated `7549` SQLite rows, and
  exported `5256` canonical snapshot rows. Full metadata sync used the same
  new-server target, matched `6255` PostgreSQL cards from `6064` unique
  requested names, backfilled `2699/2699` deck-card cache rows, and left one
  unrelated unresolved alias: `Surgical Suite/Hospital Room`.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, runtime
  `get_card_effect`, and no-override battle checks for all `17` cards against
  `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `pass` with `49` pass checks and one existing
  SQLite oracle-hash coverage warning
  (`trusted_executable_rules_missing_oracle_hash=2`).
- Global all-card authoritative queue after PG397:
  `target_identity_count=26787`, `xmage_authoritative_source_count=26473`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26473`.
- Running the exact splitter after PG397 on supported units returned
  `proposal_count=0` over `7627` considered supported rows. The static-keyword
  activated-damage subpattern is therefore closed; remaining
  `direct_damage::targeted_damage_variant_v1` rows are blocked by cost,
  target, dynamic amount, compound effect, or Oracle mismatch reasons.

PG398 measured result:

- PG398 promoted `17` simple tap mana-source permanents with a separate
  activated draw ability on the new server: `Abzan Banner`,
  `Azorius Cluestone`, `Boros Cluestone`, `Dimir Cluestone`,
  `Golgari Cluestone`, `Gruul Cluestone`, `Heart Warden`,
  `Izzet Cluestone`, `Jeskai Banner`, `Letter of Acceptance`,
  `Mardu Banner`, `Orzhov Cluestone`, `Rakdos Cluestone`,
  `Selesnya Cluestone`, `Simic Cluestone`, `Sultai Banner`, and
  `Temur Banner`.
- The splitter now accepts safe mana-source rows whose extra
  `SimpleActivatedAbility` is a fixed draw effect, records the mana-source
  metadata and the activated draw metadata in one executable `effect_json`, and
  still blocks hybrid/unsupported activation costs, non-simple draw Oracle
  text, unsafe mana abilities, source-sacrifice mismatch, and unsupported
  auxiliary abilities. Lockets with hybrid activation costs remain blocked by
  `mana_source_activated_draw_oracle_cost_not_supported`.
- Runtime coverage uses the existing artifact/creature mana-source refresh path
  plus activated utility-artifact cash-in behavior. Focused proof covers a
  permanent that refreshes as a mana source, taps for mana, then later resets
  state and sacrifices itself to draw a card through the activated draw rule.
- Full exact splitter tests passed `366/366`, full exact runtime tests passed
  `208/208`, package-builder tests passed `6/6`, and `py_compile` passed for
  the changed scripts.
- PostgreSQL precheck matched `17/17` target card rows on the new server; apply
  upserted `17` rows and deprecated `2` stale shadow rows; postcheck verified
  `17/17` promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync loaded `7771` PostgreSQL rows from
  `database_target=127.0.0.1:15432/halder`, updated `7566` SQLite rows, and
  exported `5272` canonical snapshot rows. Full metadata sync used the same
  new-server target, matched `6271` PostgreSQL cards from `6080` unique
  requested names, wrote `6199` SQLite alias rows, backfilled `2699/2699`
  deck-card cache rows, and left one unrelated unresolved alias:
  `Surgical Suite/Hospital Room`.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, runtime
  `get_card_effect`, and no-override battle checks for all `17` cards against
  `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `pass` with `49` pass checks and one existing
  warning.
- Global all-card authoritative queue after PG398:
  `target_identity_count=26770`, `xmage_authoritative_source_count=26456`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26456`.
- Running the exact splitter after PG398 on supported units returned
  `proposal_count=0` over `7610` considered supported rows. The simple
  mana-source plus activated draw subpattern is therefore closed; remaining
  mana-source neighbors are explicitly classified under cost, unsafe ability,
  non-simple Oracle, missing tap-cost, source-cost, or auxiliary-ability
  blockers.

PG399 measured result:

- PG399 promoted `8` exact draw rules on the new server: `Distorted Curiosity`,
  `Draconic Lore`, `Into the Story`, `Of One Mind`, `Overflowing Insight`,
  `Pearl of Wisdom`, `Scour the Laboratory`, and `Winged Words`.
- Seven rows use
  `xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1` for fixed
  draw spells with generic self-spell cost reduction and runtime-measurable
  conditions: controlled subtype, controlled creature keyword, opponent
  graveyard count, opponent poison counters, delirium, and controlled Human
  plus non-Human creature. `Overflowing Insight` uses the already supported
  `xmage_fixed_target_player_draw_spell_v1` target-player draw scope.
- The splitter still blocks unsafe neighbors: `Seize the Secrets` remains
  blocked by `draw_self_cost_reduction_condition_not_supported`, and
  `Even the Score` remains blocked by
  `draw_self_cost_reduction_oracle_not_exact_fixed`.
- Full exact splitter tests passed `368/368`, exact runtime tests passed
  `210/210`, package-builder tests passed `6/6`, and `py_compile` passed for
  the changed scripts.
- PostgreSQL precheck matched `8/8` target card rows on the new server; apply
  upserted `8` rows; postcheck verified `8/8` promoted rows as `verified`,
  `auto`, and hash-backed.
- PG -> Hermes/SQLite sync used `database_target=127.0.0.1:15432/halder`,
  loaded `4129` PostgreSQL rows, updated `5220` SQLite rows, and exported
  `5272` canonical snapshot rows. Full metadata sync used the same new-server
  target, matched `6277` PostgreSQL cards from `6082` unique requested names,
  wrote `6204` SQLite alias rows, and backfilled `2699/2699` deck-card cache
  rows.
- E2E validation passed PostgreSQL, SQLite/Hermes, canonical snapshot, runtime
  `get_card_effect`, and no-override battle checks for all `8` promoted cards
  against `database_target=127.0.0.1:15432/halder`.
- PG399b and PG399c were metadata-only integrity backfills, not new card-rule
  semantics. PG399b backfilled `2` PostgreSQL `oracle_hash` values first
  identified through the SQLite audit. PG399c then widened the source-of-truth
  check and backfilled `42` trusted executable PostgreSQL rows with
  `oracle_hash` from current `cards.oracle_text`, without changing any
  executable `effect_json`.
- The PG/Hermes/SQLite contract audit now includes a PostgreSQL-side
  `pg_integrity.battle_rules_trusted_oracle_hash_coverage` check. After
  PG399c and PG -> SQLite sync, the contract audit passed with `51/51` checks
  and no warnings.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `pass`.
- Global all-card authoritative queue after PG399c:
  `target_identity_count=26762`, `xmage_authoritative_source_count=26448`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26448`.
- Running the exact splitter after PG399c on supported units returned
  `proposal_count=0` over `7602` considered supported rows. The fixed draw
  self-cost-reduction and fixed target-player draw spillover are therefore
  closed for currently supported exact scopes.

PG400 measured result:

- PG400 promoted `2` exact static graveyard land-play rules on the new server:
  `Crucible of Worlds` and `Ramunap Excavator`.
- Both rows use `xmage_static_play_lands_from_graveyard_v1`, sourced from
  local XMage `PlayFromGraveyardControllerEffect.playLands()` under
  `SimpleStaticAbility` with exact Oracle text "You may play lands from your
  graveyard.".
- The splitter deliberately left `Perennial Behemoth` blocked by
  `play_lands_from_graveyard_ability_class_not_simple_static` because its XMage
  class also has `UnearthAbility`. That card needs a combined/secondary ability
  lane before it can be considered fully closed.
- Runtime now supports static graveyard land-play permission through
  `choose_land_play_candidate` / `play_land_candidate`, preserving normal hand
  land priority, preserving top-library land permission priority, removing
  graveyard lands through `remove_cards_from_graveyard(...)`, and emitting
  `played_from_graveyard`, `graveyard_land_play_source`, and
  `graveyard_land_play_scope` replay fields.
- Full exact splitter tests passed `371/371`, exact runtime tests passed
  `213/213`, and `py_compile` passed for the changed splitter, runtime, and
  test files.
- PostgreSQL precheck matched `1` Oracle-hash-backed target row for each card
  on the new server. Apply backed up `2` existing rows, deprecated `2` stale
  shadow rows for `Crucible of Worlds`, and upserted `2` verified/auto rules.
  Postcheck verified `2/2` promoted rows as `verified`, `auto`, and
  hash-backed.
- PG -> Hermes/SQLite sync used `database_target=127.0.0.1:15432/halder`,
  loaded `4131` PostgreSQL rows, updated `4128` SQLite rows, and exported
  `5273` canonical snapshot rows. Metadata sync used the same new-server
  target, matched `6278` PostgreSQL cards from `6083` unique requested names,
  wrote `6205` SQLite alias rows, and backfilled `2699/2699` deck-card cache
  rows with `96` local `card_id` updates.
- E2E validation passed PostgreSQL source-of-truth, SQLite/Hermes cache,
  canonical snapshot fallback, runtime `get_card_effect`, and no-override
  stages for both cards against `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `51/51`.
- Global all-card authoritative queue after PG400:
  `target_identity_count=26760`, `xmage_authoritative_source_count=26446`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26446`.
- Running the exact splitter after PG400 on supported units returned
  `proposal_count=0` over `7600` considered supported rows. The static
  graveyard land-play subpattern is therefore closed for currently safe exact
  scopes.

PG401 measured result:

- PG401 promoted `4` exact dynamic graveyard-count damage rules on the new
  server: `Galvanic Bombardment`, `Ire of Kaminari`, `Kindle`, and
  `Scrapyard Salvo`.
- All rows use `xmage_dynamic_graveyard_count_damage_spell_v1`, sourced from
  local XMage `DamageTargetEffect` with a supported dynamic value:
  controller graveyard named-card count plus `2`, all-graveyards named-card
  count plus `2`, controller graveyard subtype count, or controller graveyard
  artifact-card count.
- The splitter deliberately left unsupported neighbors blocked:
  `Frantic Firebolt` remains
  `graveyard_count_damage_adventure_filter_not_supported`; `Harvest Pyre` and
  `Haunting Misery` remain
  `graveyard_count_damage_exile_x_graveyard_cost_not_supported` until a
  separate X-cost/graveyard-exile payment model exists.
- Runtime now computes direct damage with
  `damage_amount_source=graveyard_card_count`, supports
  `controller_graveyard`, `all_graveyards`, and `opponents_graveyards`
  counting scopes, filters by card type, subtype, or name, and emits
  `graveyard_damage_count`, `graveyard_count_scope`, `damage_base_amount`, and
  `damage_per_graveyard_count` in replay events. The target matcher now treats
  `player`/`opponent` as non-permanent target types and restricts
  `player_or_planeswalker` permanent candidates to planeswalkers.
- Full exact splitter tests passed `373/373`, exact runtime tests passed
  `217/217`, and `py_compile` passed for the changed splitter, runtime, and
  test files.
- PostgreSQL precheck matched `1` Oracle-hash-backed target row for each card
  on the new server. Apply backed up `0` existing rows, deprecated `0` shadow
  rows, and upserted `4` verified/auto rules. Postcheck verified `4/4`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync used `database_target=127.0.0.1:15432/halder`,
  loaded `4135` PostgreSQL rows, updated `4130` SQLite rows, and exported
  `5277` canonical snapshot rows. Metadata sync used the same new-server
  target, matched `6282` PostgreSQL cards from `6087` unique requested names,
  wrote `6209` SQLite alias rows, and backfilled `2699/2699` deck-card cache
  rows with `108` local `card_id` updates.
- E2E validation passed PostgreSQL source-of-truth, SQLite/Hermes cache,
  canonical snapshot fallback, runtime `get_card_effect`, and no-override
  stages for all four cards against `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `51/51`.
- Global all-card authoritative queue after PG401:
  `target_identity_count=26756`, `xmage_authoritative_source_count=26442`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26442`.
- Running the exact splitter after PG401 on supported units returned
  `proposal_count=0` over `7596` considered supported rows. The dynamic
  graveyard-count damage subpattern is therefore closed for currently safe
  exact scopes.

PG402 measured result:

- PG402 promoted `1` exact Arcane self-sacrifice graveyard-to-hand recursion
  rule on the new server: `Hana Kami`.
- The row uses `xmage_permanent_simple_activated_graveyard_to_hand_v1`,
  sourced from local XMage `ReturnFromGraveyardToHandTargetEffect` plus
  `SimpleActivatedAbility`, `ManaCostsImpl("{1}{G}")`,
  `SacrificeSourceCost`, and `SubType.ARCANE.getPredicate()`.
- The splitter deliberately left unsupported neighbors blocked:
  `Bonebind Orator` remains blocked by graveyard-zone source exile,
  `Cabal Surgeon` by graveyard-exile activation cost, `Restoration Specialist`
  by multiple distinct targets, `Salvager of Ruin` by "put there this turn"
  watcher requirements, and `Skeleton Shard` by `OrCost`.
- Runtime now matches `arcane_card` graveyard recursion targets, pays `{1}{G}`,
  sacrifices the source, and returns only a matching Arcane card to hand.
- Focused runtime tests passed for the new Arcane self-sacrifice case and the
  existing activated recursion variants; `py_compile` passed for the changed
  splitter, runtime, and test files.
- PostgreSQL precheck matched `1` Oracle-hash-backed target row on the new
  server. Apply backed up `0` existing rows, deprecated `0` shadow rows, and
  upserted `1` verified/auto rule. Postcheck verified `1/1` promoted rows as
  `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync used `database_target=127.0.0.1:15432/halder`,
  first updated the `Hana Kami` rule and then, after the integrity backfill,
  loaded `4136` PostgreSQL rows, updated `4131` SQLite rows, and exported
  `5278` canonical snapshot rows. Metadata sync used the same new-server
  target, matched `6283` PostgreSQL cards from `6088` unique requested names,
  wrote `6210` SQLite alias rows, and backfilled `2699/2699` deck-card cache
  rows with `108` local `card_id` updates.
- PG402 also backfilled `44` old trusted executable PostgreSQL rows with
  `oracle_hash` from `cards.oracle_text`; postcheck left `0` trusted
  executable rules missing hashes.
- E2E validation passed PostgreSQL source-of-truth, SQLite/Hermes cache,
  canonical snapshot fallback, runtime `get_card_effect`, and no-override
  stages for `Hana Kami` against `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `51/51` after the hash backfill.
- Global all-card authoritative queue after PG402:
  `target_identity_count=26755`, `xmage_authoritative_source_count=26441`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26441`.
- Running the exact splitter after PG402 on supported units returned
  `proposal_count=0` over `7595` considered supported rows. The Arcane
  self-sacrifice recursion subpattern is therefore closed for currently safe
  exact scopes.

PG403 measured result:

- PG403 promoted `2` exact dynamic graveyard-count target-creature boost rules
  on the new server: `Festive Funeral` and `Ghoul's Feast`.
- Both rows use
  `xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1`,
  sourced from local XMage `BoostTargetEffect` with
  `CardsInControllerGraveyardCount(StaticFilters.FILTER_CARD_CARDS, null)` or
  `CardsInControllerGraveyardCount(StaticFilters.FILTER_CARD_CREATURES, null)`,
  a single `TargetCreaturePermanent`, no additional costs, and exact
  Oracle/source agreement.
- The splitter deliberately left unsupported neighbors blocked:
  `Growth Cycle` remains blocked by a composite fixed-plus-dynamic named-card
  formula, while `Chill Haunting` and `Weigh Down` require separate models for
  X/additional graveyard-exile costs before they can be promoted.
- Runtime now computes `stat_modifier_until_eot` deltas from
  `stat_modifier_amount_source=graveyard_card_count`, supports controller,
  all-graveyards, and opponents-graveyards count scopes, filters all cards or
  card types through the existing graveyard matcher, and emits dynamic replay
  fields including `graveyard_stat_modifier_count`,
  `graveyard_count_scope`, `power_base_delta`, `toughness_base_delta`,
  `power_delta_per_graveyard_count`, and
  `toughness_delta_per_graveyard_count`.
- Full exact splitter tests passed `377/377`, full exact runtime tests passed
  `220/220`, and `py_compile` passed for the changed splitter, runtime, and
  test files.
- PostgreSQL precheck matched `1` Oracle-hash-backed target row for each card
  on the new server. Apply backed up `0` existing rows, deprecated `0` shadow
  rows, and upserted `2` verified/auto rules. Postcheck verified `2/2`
  promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync used `database_target=127.0.0.1:15432/halder`,
  loaded `2` selected PostgreSQL rows, updated `2` SQLite rows, and exported
  `5280` canonical snapshot rows. Metadata sync used the same new-server
  target, matched `6285` PostgreSQL cards from `6090` unique requested names,
  wrote `6212` SQLite alias rows, and matched `2699/2699` deck-card cache
  rows with `105` local `card_id` updates.
- E2E validation passed PostgreSQL source-of-truth, SQLite/Hermes cache,
  canonical snapshot fallback, runtime `get_card_effect`, and no-override
  stages for both cards against `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `51/51`.
- Global all-card authoritative queue after PG403:
  `target_identity_count=26753`, `xmage_authoritative_source_count=26439`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26439`.
- Running the exact splitter after PG403 on supported units returned
  `proposal_count=0` over `7593` considered supported rows. The dynamic
  graveyard-count target-creature boost subpattern is therefore closed for
  currently safe exact scopes.

PG404 measured result:

- PG404 promoted `14` exact dynamic count target-creature boost rules on the
  new server: `Defile`, `Desert's Due`, `Drag Down`, `Feeding Frenzy`,
  `Gaea's Might`, `Hunger of the Nim`, `Inner Calm, Outer Strength`,
  `Irradiate`, `Might of Alara`, `Might of the Masses`, `Nightmarish End`,
  `Strength of Cedars`, `Warped Physique`, and `Wirewood Pride`.
- All rows use `xmage_dynamic_count_boost_target_creature_until_eot_spell_v1`,
  sourced from local XMage `BoostTargetEffect` with supported dynamic values:
  `PermanentsOnBattlefieldCount` for controller battlefield type/subtype
  counts, all-battlefield subtype counts for `Elf`/`Zombie`, `ArtifactYouControlCount`,
  `CardsInControllerHandCount.ANY`, and `DomainValue.REGULAR`.
- The splitter deliberately left unsupported neighbors blocked: X-spend pump
  spells such as `Death Wind`, `Enrage`, `Howl from Beyond`, and
  `Untamed Might`; multi-target target-pointer spells such as `Agony Warp`,
  `Bounty of Might`, `Dauntless Onslaught`, and `Seeds of Strength`;
  non-count formulas such as greatest mana value or target color count; and
  additional-cost/choice formulas such as `Bloodcurdling Scream` and
  `Pippin's Bravery`.
- Runtime now computes `stat_modifier_until_eot` deltas from
  `battlefield_permanent_count`, `controller_hand_count`, and
  `domain_basic_land_types` in addition to the PG403 graveyard count source.
  It emits generic `power_delta_per_count` and `toughness_delta_per_count`
  replay fields while preserving the previous graveyard-named fields for
  backward compatibility.
- PG404 also fixed a runtime zero-toughness fallback bug: toughness `0` is no
  longer treated as falsy and replaced by power during target stat evaluation.
  This matters for mixed `+X/-X` effects such as `Warped Physique`.
- Full exact splitter tests passed `383/383`, full exact runtime tests passed
  `224/224`, and `py_compile` passed for the changed splitter, runtime, and
  test files.
- PostgreSQL precheck matched `1` Oracle-hash-backed target row for each card
  on the new server. Apply backed up `2` old rows, deprecated `2` stale shadow
  rows for `Defile`, and upserted `14` verified/auto rules. Postcheck verified
  `14/14` promoted rows as `verified`, `auto`, and hash-backed.
- PG -> Hermes/SQLite sync used `database_target=127.0.0.1:15432/halder`,
  loaded `14` selected PostgreSQL rows, updated `16` SQLite rows, and exported
  `5293` canonical snapshot rows. Metadata sync used the same new-server
  target, matched `6298` PostgreSQL cards from `6103` unique requested names,
  wrote `6225` SQLite alias rows, and matched `2699/2699` deck-card cache
  rows with `108` local `card_id` updates.
- E2E validation passed PostgreSQL source-of-truth, SQLite/Hermes cache,
  canonical snapshot fallback, runtime `get_card_effect`, and no-override
  stages for all 14 cards against `database_target=127.0.0.1:15432/halder`.
- Post-package governance passed on the new server: strategy consistency
  `26/26`, operational surface `pass`, legacy contamination `pass`, and
  PG-Hermes-SQLite contract `51/51`.
- Global all-card authoritative queue after PG404:
  `target_identity_count=26739`, `xmage_authoritative_source_count=26425`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26425`.
- Running the exact splitter after PG404 on supported units returned
  `proposal_count=0` over `7579` considered supported rows. The dynamic
  non-graveyard count target-creature boost subpattern is therefore closed for
  currently safe exact scopes.

PG405 measured result:

- PG405 promoted `21` exact dynamic count direct-damage rules on the new
  server: `Armed Response`, `Artillery Blast`, `Divine Retribution`,
  `Dogpile`, `Earth Tremor`, `Feedback Bolt`, `Goblin War Strike`,
  `Ground Assault`, `Massive Raid`, `Mob Justice`, `Outflank`, `Outnumber`,
  `Rockslide Ambush`, `Rumbling Rockslide`, `Seismic Strike`,
  `Spiraling Embers`, `Spire Barrage`, `Spitting Earth`, `Stonefury`,
  `Tribal Flames`, and `Welding Sparks`.
- All rows use `xmage_dynamic_count_damage_spell_v1`, sourced from local XMage
  `DamageTargetEffect` dynamic values including
  `PermanentsOnBattlefieldCount`, `LandsYouControlCount`,
  `CreaturesYouControlCount`, `CardsInControllerHandCount.ANY`,
  `DomainValue.REGULAR`, and fixed-base `IntPlusDynamicValue` wrappers.
- The splitter deliberately left unsupported neighbors blocked: X-spend damage
  spells, target-hand-count spells such as `Storm Seeker` and `Sudden Impact`,
  conditional target-state damage such as `Electrostatic Bolt`, party/spell
  count formulas, greatest mana-value/power formulas, and composite sum counts
  such as creature plus Food/Equipment until those expression families have a
  dedicated runtime contract.
- Runtime now computes direct damage amounts from `battlefield_permanent_count`,
  `controller_hand_count`, and `domain_basic_land_types` in addition to the
  PG401 graveyard count source. Battlefield damage counts can also require
  combat state such as `attacking`, matching the existing target constraint
  vocabulary.
- Exact splitter tests passed `385/385`, exact runtime tests passed `228/228`,
  and `py_compile` passed for the changed splitter, runtime, and test files.
- PostgreSQL precheck matched `21/21` target rows on
  `database_target=127.0.0.1:15432/halder`; apply upserted `21`
  verified/auto/hash-backed rules with `failed_cards=[]` and no backup rows.
- PG -> Hermes/SQLite sync loaded `21` selected PostgreSQL rows, updated `21`
  SQLite rows, and exported `5314` canonical snapshot rows. Metadata sync used
  the same new-server target, matched `6319` PostgreSQL cards from `6124`
  unique requested names, wrote `6246` SQLite alias rows, and matched
  `2699/2699` deck-card cache rows.
- E2E validation passed PostgreSQL source-of-truth, SQLite/Hermes cache,
  canonical snapshot fallback, runtime `get_card_effect`, and no-override
  stages for all 21 cards against `database_target=127.0.0.1:15432/halder`.
- The first post-doc PG/Hermes/SQLite audit exposed `44` old trusted
  executable curated rows without `oracle_hash`. PG405 applied a metadata-only
  integrity backfill on the new server: backup rows `44`, updated rows `44`,
  ambiguous rows `0`, unresolved rows `0`, and trusted executable rules missing
  `oracle_hash` after `0`; `effect_json` and `deck_role_json` were unchanged.
- The integrity backfill was mirrored to Hermes/SQLite with `44` selected
  cards, `66` SQLite inserted/updated rows, and `5314` canonical snapshot rows
  exported.
- Post-package governance passed on the new server after the hash backfill:
  strategy consistency `26/26`, operational surface `pass`, legacy
  contamination `pass`, and PG-Hermes-SQLite contract `51/51`.
- Global all-card authoritative queue after PG405:
  `target_identity_count=26718`, `xmage_authoritative_source_count=26404`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26404`.
- Running the exact splitter after PG405 on supported units returned
  `proposal_count=0` over `7558` considered supported rows. The simple
  non-graveyard dynamic direct-damage count subpattern is therefore closed for
  currently safe exact scopes.

## Why This Is The Best Current Flow

The alternatives were rechecked on 2026-06-29.

### Direct Full XMage Port

Accepted as behavior source, rejected only as a literal Java-code transplant.

- XMage is Java and tied to its own game engine, stack, priority, target,
  watcher, replacement, cost, and event model.
- ManaLoom still needs `effect_json`, `battle_model_scope`, runtime support,
  PostgreSQL lineage, and Hermes sync.
- Therefore XMage is final behavioral truth, while ManaLoom adapters are the
  implementation bridge.

### Card-By-Card Manual Review

Rejected as default.

Reason:

- It closes individual cards but does not compound.
- It repeats the same parser/runtime reasoning for cards in the same semantic
  family.

Use it only for exception cards after higher-leverage lanes are exhausted.

### Oracle-Only Scryfall/MTGJSON Flow

Rejected for battle behavior.

Reason:

- Scryfall and MTGJSON are excellent for card data, identity, rulings,
  legalities, and bulk update speed.
- They do not contain executable rules-engine behavior.

Use them as the identity/hash/data gate, not as battle runtime source.

### 17Lands/Logs/Reddit/Meta-First Flow

Rejected for rule adaptation.

Reason:

- These sources can inform strategy, usage, and deckbuilding heuristics.
- They do not prove card rules or battle execution correctness.

Use them downstream for strategy/deckbuilding, not for card-rule promotion.

### Forge-First Flow

Rejected as primary, accepted as cross-check.

Reason:

- Forge is another Java rules engine, useful for disagreement analysis.
- Using Forge as the main input doubles parser/modeling work while the current
  blocker is already proven inside XMage -> ManaLoom mapping.

Use it only when XMage signal extraction is ambiguous or a high-risk family
needs a second engine reference.

## Current Evidence

Latest Lorehold and opponent replay-scope artifacts:

- before family-mapper wave:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_134228_current_lorehold_6_607_616_manifest.md`
- after family-mapper wave:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_135909_post_adagia_family_mapper_lorehold_6_607_616_manifest.md`
- runtime surface gate:
  `docs/hermes-analysis/master_optimizer_reports/battle_runtime_surface_manifest_20260629_post_adagia_mapper.md`
- external source gate:
  `docs/hermes-analysis/master_optimizer_reports/mtg_battle_external_source_audit_20260629_post_adagia_mapper.md`

Current active scope:

- artifact deck IDs: `[6]`
- learned opponent deck IDs:
  `[25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116]`
- forced Lorehold deck IDs:
  `[6, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]`
- effective deck IDs:
  `[6, 25, 31, 42, 54, 58, 62, 74, 83, 84, 104, 105, 116, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616]`
- actionable XMage-sourced validity rows: `239`
- combined severity counts:
  `{"critical": 1, "high": 207, "medium": 49, "pass": 534}`

Before the 2026-06-29 family-mapper wave:

- structured XMage pull review candidates: `135/239`
- manual mapper backlog: `104/239`
- family counts included:
  `ramp_permanent=49`, `tutor=16`, `free_cast=11`,
  `targeted_interaction=10`, `passive=5`, `manual_model=104`

After the 2026-06-29 family-mapper wave:

- structured XMage pull review candidates: `158/239`
- manual mapper backlog: `81/239`
- net manual backlog reduction: `23` cards
- family counts now include:
  `ramp_permanent=49`, `targeted_interaction=24`, `tutor=14`,
  `free_cast=11`, `passive=11`, `ramp_ritual=4`,
  `life_total_change=2`, `copy_creature_token=1`,
  `copy_spell_engine=1`, `token_maker=1`, `manual_model=81`
- proposal status counts:
  `batch_pg_candidate_after_precheck=8`,
  `split_family_scope_review_required=148`,
  `runtime_family_implementation_required=1`,
  `mapper_metadata_or_test_scenario_required=81`
- PostgreSQL writes in this wave: `0`

Post-contract checkpoint wave:

- contract checkpoint:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260629_143113_contract_checkpoint.md`
- current queue after conservative red utility-land split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_143734_post_red_land_mana_split_manifest.md`
- PG249 package prepared read-only for seven exact runtime-backed cards:
  `Verge Rangers`, `Firesong and Sunspeaker`, `Goliath Daydreamer`,
  `Boros Reckoner`, `Terror of the Peaks`, `Balefire Liege`, `Repercussion`.
- PG249 was not applied. Precheck found one target card row for each selected
  card and the package remains blocked until explicit apply approval.
- `Adagia, Windswept Bastion` stayed out of PG249 because the proposal still
  requires the `station_level_gate` runtime component.
- `Purphoros, God of the Forge` stayed out of PG249 because it is in the
  partial preserve-shadow lane.

Conservative ramp split evidence:

- `Cori Mountain Monastery`, `Fire Nation Palace`,
  `Shinka, the Bloodsoaked Keep`, and `Spinerock Knoll` now split the exact
  red mana mode from the rest of the card using
  `land_tap_one_red_mana_nonmana_ability_pending_v1`.
- This is intentionally not a full-card promotion. Each card has non-mana
  behavior that still requires a separate exact scope before PostgreSQL truth.
- Pattern status counts after the split are:
  `governance_only_pending_pg_apply=7`,
  `ready_for_pg_package_generation=2`,
  `requires_subpattern_split_before_promotion=21`,
  `fragmented_runtime_observation_only=1`.
- The lower ready count is correct: seven cards moved into a prepared PG
  package, and one land subpattern became stricter because generic land-mana
  grouping would have hidden unresolved non-mana abilities.

Post-apply E2E wave:

- PG249 was applied on 2026-06-29 for:
  `Verge Rangers`, `Firesong and Sunspeaker`, `Goliath Daydreamer`,
  `Boros Reckoner`, `Terror of the Peaks`, `Balefire Liege`, `Repercussion`.
- PG249 apply result: `deprecated_shadow_rows=6`, `upserted_rows=7`; postcheck
  showed all seven selected cards with one promoted verified/auto row and
  matching Oracle hash.
- PG249 sync result:
  `pg_rows_loaded=13`, `sqlite_inserted_or_updated=13`; the row count includes
  seven active curated rules plus six deprecated disabled shadow rows.
- Runtime probing found a real model issue: the PG249 `Repercussion` row was
  immediate `direct_damage`, but the card must be a passive enchantment trigger
  so it can enter the battlefield and react to later creature damage.
- PG250 corrected only `Repercussion`: the `direct_damage` row was disabled and
  `battle_rule_v1:d1a0c5cc0035945ec8bfd795da52d017` was promoted as
  `passive` with `creature_damage_controller_reflect_global_v1`.
- The battle runtime now prefers synced `curated` SQLite/PG rules over
  temporary manual runtime waivers, while preserving waivers as fallback for
  missing or stale non-curated rows.
- Final runtime probe:
  `docs/hermes-analysis/master_optimizer_reports/pg249_pg250_runtime_ready_exact_family_batch_20260629_145521_get_card_effect_probe.json`
- Queue after PG249/PG250 apply/sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_145746_post_pg249_pg250_apply_sync_manifest.md`
- PG249/PG250 combined severity counts:
  `{"critical": 1, "high": 200, "medium": 49, "pass": 541}`
- PG249/PG250 actionable XMage-sourced validity rows:
  `ready_for_structured_xmage_pull_review_required=151`,
  `xmage_source_valid_mapper_required=81`.
- PG249/PG250 proposal status counts:
  `batch_pg_candidate_after_precheck=1`,
  `partial_batch_pg_candidate_preserve_shadow_rows_after_precheck=1`,
  `runtime_family_implementation_required=1`,
  `split_family_scope_review_required=148`,
  `mapper_metadata_or_test_scenario_required=81`.
- At that point, the remaining immediate lanes were:
  `Adagia, Windswept Bastion` pending `station_level_gate`,
  `Purphoros, God of the Forge` in preserve-shadow partial lane, and
  `Hazel's Brewmaster` as a runtime-family exception.

This was historical PG249/PG250 state. It is superseded by the subsequent
PG251+ runtime/promotion wave below.

Additional exact runtime/mapping correction:

- `Adagia, Windswept Bastion` was reclassified from generic `token_maker` to
  `copy_creature_token` with scope
  `station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1`.
- Runtime now carries `token_legendary` through copy-token creation and replay
  events.
- Remaining `runtime_family_implementation_required` item is
  `Hazel's Brewmaster`, because XMage shows Food token creation plus static
  ability sharing from creature cards exiled with Hazel. That is not safe to
  collapse into generic token creation.

Subsequent runtime/promotion wave:

- PG251 was applied and synced for `Adagia, Windswept Bastion`,
  `Hazel's Brewmaster`, and `Purphoros, God of the Forge`.
- PG252 promoted sixteen manual runtime-waiver rules into reviewed PostgreSQL
  truth.
- PG253 promoted nine existing focused runtime rules into PostgreSQL.
- PG254 promoted fourteen blink/static/legacy runtime rules and corrected the
  forensic tests to accept synced curated PostgreSQL rules.
- PG255 promoted `Ashnod's Altar`, `Chrome Mox`, and `Mox Diamond` fast-mana
  runtime rules.
- PG256 promoted `Treasonous Ogre` with life-payment red mana runtime support.
- PG257 promoted `Phyrexian Censor` with non-Phyrexian spell-limit and
  enter-tapped static runtime support.
- Queue after PG257:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_162756_post_pg257_phyrexian_censor_static_runtime_manifest.md`
- PG257 combined severity counts:
  `{"critical": 1, "high": 114, "medium": 57, "pass": 619}`
- PG257 actionable unresolved rows in the validity/family/proposal reports:
  `154`.
- PG257 unresolved routing:
  `ready_for_structured_xmage_pull_review_required=91`,
  `xmage_source_valid_mapper_required=63`,
  `runtime_family_required_count=0`.
- PG257 family counts include:
  `manual_model=63`, `ramp_permanent=16`, `tutor=13`,
  `targeted_interaction=12`, `recursion=11`, `free_cast=9`,
  `targeted_protection=8`, `passive=5`, `draw_engine=4`,
  `topdeck_play=3`, `board_wipe_choice=3`, `ramp_ritual=2`.

PG262 exact ritual runtime checkpoint (historical):

- PG262 was applied and synced for `Mana Geyser` and `Burnt Offering`.
- `Mana Geyser` now uses exact scope
  `add_red_for_each_tapped_land_opponents_control_v1`, counting tapped lands
  controlled by opponents instead of a fixed heuristic amount.
- `Burnt Offering` now uses exact scope
  `sacrifice_creature_add_black_or_red_equal_sacrificed_mana_value_v1`,
  using the sacrificed creature mana value instead of a fixed heuristic amount.
- PG262 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg262_exact_ritual_runtime_20260629_package.md`.
- Queue after PG262:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260629_1746_post_pg262_exact_ritual_runtime_manifest.md`.
- PG262 combined severity counts:
  `{"critical": 1, "high": 108, "medium": 45, "pass": 637}`.
- PG262 unresolved routing:
  `ready_for_structured_xmage_pull_review_required=73`,
  `xmage_source_valid_mapper_required=63`,
  `runtime_family_required_count=0`.
- PG262 family counts include:
  `manual_model=63`, `targeted_interaction=12`, `recursion=11`, `tutor=10`,
  `free_cast=9`, `targeted_protection=8`, `ramp_permanent=6`, `passive=5`,
  `draw_engine=4`, `topdeck_play=3`, `board_wipe_choice=3`,
  `copy_spell_engine=1`, `life_total_change=1`.

PG263/PG264 Lorehold runtime-gap checkpoint:

- PG263 was applied and synced for eight Lorehold/opponent runtime-gap cards:
  `Goliath Daydreamer`, `Twinflame Tyrant`, `Verge Rangers`,
  `Boros Reckoner`, `Terror of the Peaks`, `Balefire Liege`,
  `Firesong and Sunspeaker`, and `Repercussion`.
- PG263 apply result: backup rows `17`, deprecated shadow rows `12`,
  upserted rows `8`; E2E validation proved PostgreSQL `8/8`, SQLite `8/8`,
  canonical snapshot `8/8`, and runtime `get_card_effect` `8/8`.
- The E2E validator and package builder now require snapshot/runtime checks
  derived from `expected_rules`, preventing a false-green package with
  `validated_cards=0`.
- The runtime-gap queue now filters cards that already have a synced
  `verified/auto` exact rule in SQLite. This corrected the stale queue from
  `61` raw blocked rows to `27` real pending rows after PG263.
- PG264 implemented and applied the exact Gisela static-damage scope
  `opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1`,
  using local XMage classes
  `GiselaBladeOfGoldnightDoubleDamageEffect` and
  `GiselaBladeOfGoldnightPreventionEffect`.
- PG264 apply result: backup rows `2`, deprecated shadow rows `2`, upserted
  rows `1`; E2E validation proved PostgreSQL `1/1`, SQLite `1/1`, canonical
  snapshot `1/1`, and runtime `get_card_effect` `1/1`.
- Current queue after PG264:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg264_gisela.md`.
- Current proposal report after PG264:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg264_gisela_proposals.md`.
- Current unresolved Lorehold runtime-gap queue: `26` cards,
  `mapper_metadata_or_test_scenario_required=13`,
  `split_family_scope_review_required=13`,
  `safe_for_batch_pg_package_count=0`.

PG267/PG271 runtime-rule checkpoint:

- PG265 was applied and synced for `Lens of Clarity` with exact visibility-only
  topdeck scope `look_top_library_any_time_and_opponent_face_down_creatures_v1`.
- PG266 was applied and synced for `Eight-and-a-Half-Tails` with exact
  activated protection scope
  `creature_body_target_permanent_protection_from_white_make_source_white_activation_runtime_v1`.
- PG267 was applied and synced for `Neheb, the Eternal` with exact postcombat
  mana scope `postcombat_main_add_red_for_opponents_life_lost_this_turn_v1`.
- PG268 was applied and synced for `Cloud Key` with exact chosen-card-type
  cost-reduction scope `chosen_card_type_cost_reduction_v1`.
- PG269 was applied and synced for `Alhammarret's Archive` with exact static
  replacement scope
  `static_double_life_gain_and_draw_except_first_draw_step_v1`.
- PG270 was applied and synced for `Currency Converter` with exact draw-engine
  bookkeeping for discarding, exiling the discarded card from graveyard, moving
  it back to graveyard, and creating Treasure.
- PG271 was applied and synced for `Hidden Retreat` with exact targeted
  instant/sorcery damage-prevention scope
  `activated_put_card_from_hand_on_top_library_prevent_damage_from_target_instant_or_sorcery_spell_v1`.
- PG272 was applied and synced for `Brainstone` with exact executable
  Lorehold first-draw setup scope
  `brainstone_draw_three_put_two_back_for_first_draw_miracle_v1`, replacing
  the stale `unexecuted` scope label while preserving the activated
  tap/sacrifice, draw-three, put-two-back model.
- PG273 was applied and synced for `Codex Shredder` with exact activated
  artifact scopes for `{T}` target-player mill one and `{5}, {T}, sacrifice:
  return target card from your graveyard to hand, using
  `tap_target_player_mill_one_or_five_tap_sacrifice_return_target_card_from_your_graveyard_to_hand_v1`.
- PG274 was applied and synced for `Perpetual Timepiece` with exact activated
  artifact scopes for `{T}` self-mill two and `{2}, exile this artifact:
  shuffle selected graveyard cards into library, using
  `tap_self_mill_two_or_exile_self_shuffle_any_number_graveyard_cards_into_library_v1`.
- PG275 was applied and synced for `Chaos Wand` with exact activated artifact
  runtime for `{4}, {T}` target-opponent library exile until instant/sorcery,
  optional free cast of the hit card, and random bottoming of uncast exiled
  cards, using
  `pay_four_tap_target_opponent_exile_until_instant_sorcery_may_cast_free_bottom_rest_v1`.
- PG276 was applied and synced for `Assemble the Players` with exact static
  top-library permission runtime: look at the top card any time and, once each
  turn, cast a creature spell with power 2 or less from the top of library by
  paying its normal mana cost, using
  `top_library_look_any_time_cast_creature_power_2_or_less_once_each_turn_pay_cost_v1`.
- PG267 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg267_neheb_postcombat_mana_20260630_package.md`.
- PG268 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg268_cloud_key_chosen_type_cost_reduction_20260630_package.md`.
- PG269 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg269_alhammarret_archive_replacements_20260630_package.md`.
- PG270 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg270_currency_converter_draw_engine_20260630_package.md`.
- PG271 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg271_hidden_retreat_damage_prevention_20260630_package.md`.
- PG272 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg272_brainstone_executable_topdeck_20260630_package.md`.
- PG273 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg273_codex_shredder_mill_recursion_20260630_package.md`.
- PG274 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg274_perpetual_timepiece_graveyard_shuffle_20260630_package.md`.
- PG275 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg275_chaos_wand_opponent_library_free_cast_20260630_package.md`.
- PG276 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg276_assemble_the_players_top_library_small_creature_20260630_package.md`.
- PG277 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg277_ghoulcaller_each_player_mill_20260630_package.md`.
- PG277 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg277_ghoulcaller_each_player_mill_20260630_e2e_validation.md`.
- PG278 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg278_lantern_top_reveal_shuffle_20260630_package.md`.
- PG278 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg278_lantern_top_reveal_shuffle_20260630_e2e_validation.md`.
- PG279 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg279_possibility_storm_shared_type_free_cast_20260630_package.md`.
- PG279 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg279_possibility_storm_shared_type_free_cast_20260630_e2e_validation.md`.
- PG280 package evidence:
  `docs/hermes-analysis/master_optimizer_reports/pg280_kayla_music_box_exile_play_20260630_package.md`.
- PG280 E2E validation:
  `docs/hermes-analysis/master_optimizer_reports/pg280_kayla_music_box_exile_play_20260630_e2e_validation.md`.
- Current queue after PG276:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260630_post_pg276_assemble_the_players_manifest.md`.
- Current combined severity counts:
  `{"high": 98, "medium": 42, "pass": 651}`.
- Current unresolved routing:
  `ready_for_structured_xmage_pull_review_required=64`,
  `xmage_source_valid_mapper_required=61`,
  `runtime_family_required_count=0`.
- Current family counts include:
  `manual_model=61`, `targeted_interaction=12`, `recursion=9`, `tutor=10`,
  `free_cast=7`, `targeted_protection=7`, `ramp_permanent=5`, `passive=5`,
  `draw_engine=2`, `topdeck_play=2`, `board_wipe_choice=3`,
  `copy_spell_engine=1`, `life_total_change=1`.
- Current Lorehold runtime-gap queue:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg282_final_eight.md`;
  blocked runtime gaps are now `0` after current SQLite verified/auto filtering.
  The queue still records `61` raw runtime-gap candidates from the older miner,
  but all are filtered by current active rules after PG281/PG282.
- Current Lorehold runtime readiness handoff after PG282:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_candidate_readiness_20260630_post_pg282_final_eight.md`;
  applied/synced runtime packages are not apply-pending and must not be routed
  back to PostgreSQL apply.

`Adagia, Windswept Bastion` is no longer blocked on
`station_level_gate`: the exact scope
`station_12_copy_artifact_or_enchantment_you_control_legendary_token_v1`
now carries `station_level_required=12`, activation cost `{3}{W}`, tap
requirement, controlled artifact/enchantment targets, and legendary token
creation through focused runtime tests and PostgreSQL sync.

Runtime/source revalidation after the mapper wave:

- runtime surface manifest: `147` related Python files, `0` unclassified
  files.
- external source audit: gate `pass`, required gaps `0`, required partials
  `0`, optional gaps `0`.

The main blocker is therefore still not missing XMage source. The blocker is
exact ManaLoom mapper/runtime coverage by family and subpattern. Generic
`xmage_*_review_v1` scopes are useful queue reducers, but they remain
review-only until exact scope, focused tests, PostgreSQL package approval, and
PG -> Hermes sync.

## Source Roles

| Source | Role | May Promote Rules? |
| --- | --- | --- |
| PostgreSQL `card_battle_rules` | Product source of truth | Yes, after approved package |
| Hermes SQLite | Runtime/cache/audit mirror | No |
| Scryfall bulk | Oracle identity/text/rulings/layout/hash | No |
| MTGJSON bulk | Secondary normalized card/ruling/legalities data | No |
| XMage local source | Primary rules-engine reference and signal source | No, only candidates |
| Forge source | Secondary engine cross-check | No, only candidates |
| 17Lands/logs/meta/community | Strategy/deckbuilding evidence | No |
| Pattern registry | Shadow batching/test planning | No |

## Definitive Flow

### Gate 0 - Global Scope Selection

Input:

- PostgreSQL `cards` inventory;
- current legalities and Oracle identity data;
- current trusted battle-rule coverage by `card_id`, normalized name, and
  true Oracle identity aliases;
- deck/replay/learned usage only as QA sampling and smoke-test seeds.

Output:

- all-card readiness report;
- authoritative XMage adaptation queue;
- family/work-unit counts;
- explicit missing-source exception lane.

Rules:

- The base scope is global over all known cards, not Lorehold, registered decks,
  or currently saved decks.
- Replay/deck evidence may prioritize QA validation only.
- Replay/deck evidence does not define rule truth or market demand.

### Gate 1 - Oracle/Data Normalization

Input:

- Scryfall bulk cache;
- MTGJSON/rulings when useful;
- PostgreSQL card identity surfaces.

Output:

- stable card identity;
- Oracle hash;
- layout/faces;
- type/mana/color data;
- rulings references.

Rules:

- Bulk/local cache is the default for scale.
- Named/live API fallback is only for misses.
- A card without identity/hash can be analyzed but cannot be promoted as trusted
  battle behavior unless it has an explicit no-text/no-hash exception.

### Gate 2 - XMage/Forge Source Resolution

Input:

- normalized card names;
- local XMage root `/Users/desenvolvimentomobile/Downloads/mage-master`;
- optional Forge reference for cross-check.

Output:

- local XMage class path;
- constructor metadata;
- ability/effect/target/filter/cost/condition/watcher signals;
- raw excerpt;
- focused scenario draft.

Rules:

- Missing XMage source is an exception lane, not the main queue.
- Forge is used only when XMage is ambiguous or a high-risk family needs a
  second implementation reference.

### Gate 3 - Family Routing

Input:

- XMage extracted signals;
- Oracle text/hash;
- existing ManaLoom family definitions.

Output lanes:

- `batch_metadata_candidate_requires_pg_precheck`
- `split_family_scope_review_required`
- `runtime_family_implementation_required`
- `mapper_metadata_or_test_scenario_required`
- `blocked_missing_xmage_source`

Rules:

- Generic scopes such as `xmage_*_review_v1` are review/split only.
- Generic scopes must never become batch PG candidates.
- Pattern registry rows are `shadow_only`.
- No registry row can execute in battle.

### Gate 4 - Exact Scope Split

Input:

- largest family/scope clusters from the current queue.

Output:

- exact `battle_model_scope`;
- exact `effect_json` schema;
- positive and negative focused test cases;
- runtime support assessment.

Rules:

- Work largest reusable exact-scope clusters first.
- A large family with many fragmented scopes does not lead the queue until it
  is split.
- Do not implement runtime for a broad family label if the cards inside require
  different behavior.
- For global XMage-authoritative batches, run
  `xmage_authoritative_exact_scope_split.py` before package generation; broad
  review scopes cannot skip this bridge.

### Gate 5 - Runtime Implementation

Input:

- exact scope;
- focused test scenarios;
- current `battle_analyst`/runtime capabilities.

Output:

- runtime implementation or proof that existing runtime already supports it;
- focused tests;
- event/provenance assertions for selected logical rule key.

Rules:

- Runtime changes must include tests.
- Tests must exercise the card behavior, not only loading metadata.
- If a candidate card is not drawn/used in battle, battle aggregate alone is not
  proof for that card.

### Gate 6 - PostgreSQL Package

Input:

- exact scoped rule;
- Oracle hash;
- runtime/focused test proof;
- stale shadow-row plan.

Output:

- package doc;
- precheck SQL/output;
- apply SQL/output;
- rollback SQL;
- postcheck SQL/output.

Rules:

- PostgreSQL remains the durable source of truth.
- No PostgreSQL write without explicit approval or approved package workflow.
- Generated/review-only shadows must be disabled or preserved deliberately so
  they do not shadow reviewed rules.

### Gate 7 - Sync And Audit

Input:

- applied PostgreSQL package.

Output:

- PG -> SQLite/Hermes sync report;
- canonical snapshot refresh;
- `get_card_effect`/runtime lookup proof;
- affected deck coherence audit;
- replay/focused battle validation when battle-relevant.

Rules:

- Hermes is cache/runtime evidence, not truth.
- PostgreSQL wins on conflict.
- Global PG/SQLite count differences are routing signals; per-card path must be
  verified directly.

### Gate 8 - Queue Rebuild

Input:

- post-sync current state.

Output:

- fresh effective queue;
- family counts;
- pattern registry;
- next lane recommendation.

Rules:

- Every package/runtime wave must shrink one real queue dimension:
  package-ready, split-scope, runtime-family, manual-mapper, or missing-source.
- If no queue dimension shrinks, the cycle was not an acceleration cycle.

## Current Priority Order

Use the fresh global authoritative queue after every package. As of the
post-PG414 queue on the new server, the next exact runtime-backed work should
be selected from these largest reusable work units, not from deck intuition:

1. `recursion::xmage_graveyard_return_variant_review_v1` - `1799`
2. `draw_engine::xmage_draw_card_variant_review_v1` - `1610`
3. `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1` - `1114`
4. `direct_damage::targeted_damage_variant_v1` - `827`
5. `add_counters::source_add_counters_variant_v1` - `795`
6. `life_gain::xmage_life_gain_variant_review_v1` - `728`
7. `removal_destroy::targeted_destroy_variant_v1` - `612`
8. `tutor::xmage_library_search_variant_review_v1` - `605`
9. `draw_cards::xmage_draw_card_variant_review_v1` - `597`
10. `add_counters::targeted_add_counters_variant_v1` - `459`

Selection rule:

- close any exact package-ready lane first only if it is non-generic and has
  focused runtime/test proof;
- otherwise split the highest reusable work unit into a narrow
  `battle_model_scope` whose XMage source, Oracle text, runtime behavior, and
  negative blockers all agree;
- if the split produces no safe candidates, record the blocker counts and move
  to the next largest reusable work unit;
- do not implement broad `xmage_*_review_v1` behavior directly and do not
  schedule card-by-card work before all reusable subpatterns have been tried.

## Latest Cycle Evidence

PG408 closed the exact simple mana-source / ETB-draw mana-source subpattern on
the new server:

- Split support now accepts simple mana activations with explicit activation
  mana cost and tap/no-tap state, including `{R}: Add {B}`, `{1}: Add {B}`,
  `{1}{G}: Add one mana of any color`, and `{2}: Add one mana of any color`.
- Runtime support now resolves generic ETB triggers for `ramp_permanent`, so
  mana permanents that draw on entry can execute the draw before later mana
  activation.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`402` tests) and
  `test_xmage_exact_scope_runtime.py` (`232` tests). The runtime test exercises
  ETB draw plus paying activation cost for mana.
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg408_mana_etb_draw_new_server`
  produced `13` safe candidates: `Agent of Stromgald`, `Arcum's Astrolabe`,
  `Bog Initiate`, `Energy Refractor`, `Helionaut`, `Llanowar Envoy`,
  `Llanowar Visionary`, `Nomadic Elf`, `Orochi Leafcaller`, `Prismite`,
  `Prophetic Prism`, `Signpost Scarecrow`, and `Viridian Acolyte`.
- Scope split was `9` `xmage_simple_tap_mana_source_permanent_v1` rows and
  `4` `xmage_simple_mana_source_with_etb_draw_v1` rows. The legacy-named
  simple mana-source scope is still controlled by the explicit
  `mana_activation_requires_tap` field, so no-tap activations remain distinct
  in `effect_json`.
- PostgreSQL package `PG408` was applied on the new server:
  `13` upserted rows, `0` deprecated shadow rows, and postcheck `13/13`
  `verified`/`auto` rows with Oracle hashes.
- PG -> SQLite sync loaded `13` PostgreSQL rows, updated `13` SQLite rows, and
  exported `5358` canonical snapshot rows.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `13` selected cards. The generic E2E
  battle scenario count was `0`; card behavior execution is covered by the
  focused runtime test above.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`),
  PG/Hermes/SQLite contract (`51/51`), and legacy contamination (`32/32`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26680` to `26667`, authoritative adapter-required count from `26366`
  to `26353`, creature mana-source work from `351` to `343`, and artifact
  mana-source work from `279` to `274`. The post-PG408 exact split recheck
  produced `proposal_count=0`.

PG409 closed the exact creature ETB graveyard-to-battlefield subpattern on the
new server:

- Split support now maps `ReturnFromGraveyardToBattlefieldTargetEffect` with
  `EntersBattlefieldTriggeredAbility` into
  `xmage_creature_etb_return_graveyard_card_to_battlefield_v1`, including
  land, artifact, and Vampire-or-Wizard creature target filters where XMage and
  Oracle text agree.
- Runtime support now resolves the existing ETB graveyard recursion path with
  battlefield destination for these exact filters; focused tests exercise land
  return and Vampire/Wizard creature selection.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`406` tests),
  `test_xmage_exact_scope_runtime.py` (`234` tests), and explicit package
  builder tests (`7` tests).
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg409_etb_recursion_battlefield_new_server`
  produced `3` safe candidates: `Bloodline Necromancer`, `Quarry Beetle`, and
  `Sharuum the Hegemon`. `Rot Hulk` remained blocked as
  `etb_recursion_battlefield_target_not_supported`.
- PostgreSQL package `PG409` was applied on the new server:
  `3` upserted rows, `0` deprecated shadow rows, and postcheck `3/3`
  `verified`/`auto` rows with Oracle hashes.
- PG -> SQLite sync for the package loaded `3` PostgreSQL rows, updated `3`
  SQLite rows, and exported `5361` canonical snapshot rows.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `3` selected cards. The generic E2E
  battle scenario count was `0`; card behavior execution is covered by the
  focused runtime tests above.
- Contract cleanup in the same closeout backfilled missing `oracle_hash` for
  `44` older trusted executable PostgreSQL rows on
  `127.0.0.1:15432/halder`; postcheck left `0` trusted executable rows without
  `oracle_hash`. Full PG -> SQLite sync then updated `4222` SQLite rows and
  exported `5361` canonical snapshot rows.
- Final governance audits passed after the hash backfill:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51`), and legacy contamination. The post-PG409 exact split recheck
  produced `proposal_count=0`.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26667` to `26664`, authoritative adapter-required count from `26353`
  to `26350`, and the top recursion work unit from `1809` to `1806`; the
  remaining `314` identities are still explicit missing-source exceptions.

PG410 closed the exact self-sacrifice mana-source permanent subpattern on the
new server:

- Split support now maps XMage `SimpleManaAbility` plus `SacrificeSourceCost`
  where the Oracle text and Java source agree on produced mana, optional tap
  cost, and optional activation mana cost. The executable scope is
  `xmage_self_sacrifice_mana_source_permanent_v1`.
- Runtime support treats these permanents as contextual mana sources only:
  `refresh_mana_sources` must not auto-sacrifice them. The battle runtime may
  activate one only when sacrificing it unlocks a real payable spell/action.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`411` tests) and
  `test_xmage_exact_scope_runtime.py` (`236` tests). The runtime tests cover
  both non-refresh behavior and contextual activation.
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg410_self_sacrifice_mana_source_new_server`
  produced `13` safe candidates: `Basal Thrull`, `Blood Pet`, `Blood Vassal`,
  `Catalyst Elemental`, `Coal Golem`, `Composite Golem`, `Crosis's Attendant`,
  `Darigaaz's Attendant`, `Dromar's Attendant`, `Morgue Toad`,
  `Rith's Attendant`, `Satyr Hedonist`, and `Treva's Attendant`.
- PostgreSQL package `PG410` was applied on the new server:
  `13` upserted rows, `0` deprecated shadow rows, and postcheck `13/13`
  `verified`/`auto` rows with Oracle hashes.
- PG -> SQLite sync for the package loaded `13` PostgreSQL rows, updated `13`
  SQLite rows, and exported `5374` canonical snapshot rows.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `13` selected cards. The generic E2E
  battle scenario count was `0`; card behavior execution is covered by the
  focused runtime tests above.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51`), and legacy contamination. The post-PG410 exact split recheck
  produced `proposal_count=0`.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26664` to `26651`, authoritative adapter-required count from `26350`
  to `26337`, creature mana-source work from `343` to `337`, and artifact
  mana-source work from `274` to `267`; the remaining `314` identities are
  still explicit missing-source exceptions.

PG411 closed three exact recursion-to-hand subpatterns on the new server:

- Split support now maps XMage `ReturnFromGraveyardToHandTargetEffect` with
  `AttacksTriggeredAbility` into
  `xmage_permanent_attack_return_graveyard_card_to_hand_v1`, including the
  optional trigger mana cost used by `Eternal Taskmaster`.
- Split/runtime support now handles
  `DealsCombatDamageToAPlayerTriggeredAbility` recursion into
  `xmage_creature_combat_damage_return_graveyard_card_to_hand_v1`, with a
  separate combat-damage resolver instead of reusing attack-declaration logic.
- Activated graveyard-to-hand recursion now accepts
  `ActivateAsSorceryActivatedAbility`, preserves `activation_timing=sorcery`,
  and carries static self keywords such as `reach` on the parent permanent.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`414` tests) and
  `test_xmage_exact_scope_runtime.py` (`238` tests). The runtime tests cover
  combat-damage Arcane recursion and attack-trigger recursion paying `{2}{B}`.
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg411_triggered_recursion_to_hand_new_server`
  produced `3` safe candidates: `Eternal Taskmaster`, `Pillardrop Warden`,
  and `The Unspeakable`.
- PostgreSQL package `PG411` was applied on the new server:
  `3` upserted rows, `0` deprecated shadow rows, and postcheck `3/3`
  `verified`/`auto` rows with Oracle hashes.
- PG -> SQLite sync for the package loaded `3` PostgreSQL rows, updated `3`
  SQLite rows, and exported `5377` canonical snapshot rows.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `3` selected cards. The generic E2E
  battle scenario count was `0`; card behavior execution is covered by the
  focused runtime tests above.
- Contract cleanup in the same closeout backfilled missing `oracle_hash` for
  `44` older trusted executable PostgreSQL rows on
  `127.0.0.1:15432/halder`; postcheck left `0` trusted executable rows without
  `oracle_hash`. Full PG -> SQLite sync then loaded `4243` PostgreSQL rows,
  updated `4238` SQLite rows, and exported `5377` canonical snapshot rows.
- Final governance audits passed after the hash cleanup:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51`), and legacy contamination.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26651` to `26648`, authoritative adapter-required count from `26337`
  to `26334`, and the top recursion work unit from `1806` to `1803`. The
  post-PG411 exact split recheck produced `proposal_count=0`; the remaining
  `314` identities are still explicit missing-source exceptions.

PG412 closed the exact creature ETB dynamic graveyard-count damage subpattern
on the new server:

- Split support now maps XMage `DamageTargetEffect` with
  `EntersBattlefieldTriggeredAbility` where the damage amount is an exact
  supported controller graveyard card count into
  `xmage_creature_etb_dynamic_graveyard_count_damage_v1`.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`415` tests) and
  `test_xmage_exact_scope_runtime.py` (`240` tests). Runtime tests cover
  creature ETB damage counting instant/sorcery cards and creature cards in the
  controller's graveyard.
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg412_etb_graveyard_count_damage_new_server`
  produced `4` safe candidates: `Cyclops Electromancer`, `Lotleth Giant`,
  `Ossuary Rats`, and `Warfire Javelineer`.
- PostgreSQL package `PG412` was applied on the new server:
  `4` upserted rows, `0` deprecated shadow rows, and postcheck `4/4`
  `verified`/`auto` rows with Oracle hashes.
- PG -> SQLite sync for the package loaded `4` PostgreSQL rows, updated `4`
  SQLite rows, and exported `5381` canonical snapshot rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51`), and legacy contamination.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26648` to `26644`, authoritative adapter-required count from `26334`
  to `26330`, and the top recursion work unit from `1803` to `1799`. The
  post-PG412 exact split recheck produced `proposal_count=0`.

PG413 closed the exact static creature protection-from-colors subpattern on the
new server:

- Split support now maps no-effect/no-signal XMage `ProtectionAbility` rows
  into `xmage_static_self_protection_from_colors_creature_v1` only when Oracle
  text and local XMage source agree on exact color protection. Protection from
  artifacts, creatures, monocolored, multicolored, or subtypes remains blocked
  for later dedicated target/permanent matchers.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`417` tests) and
  `test_xmage_exact_scope_runtime.py` (`241` tests). Runtime tests cover
  `protection_from` persistence, target legality rejection for a matching
  colored source, and direct damage resolving as `no_legal_creature_target`.
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg413_static_protection_colors_new_server`
  produced `19` safe candidates. The split also left `12` non-color protection
  rows blocked as `static_protection_oracle_not_color_exact`.
- PostgreSQL package `PG413` was applied on the new server:
  `19` upserted rows, `0` deprecated shadow rows, and postcheck `19/19`
  `verified`/`auto` rows with Oracle hashes.
- PG -> SQLite sync for the package loaded `19` PostgreSQL rows, updated `19`
  SQLite rows, and exported `5400` canonical snapshot rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51`), and legacy contamination.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26644` to `26625` and authoritative adapter-required count from
  `26330` to `26311`. The post-PG413 exact split recheck produced
  `proposal_count=0`; the remaining `314` identities are still explicit
  missing-source exceptions.

PG414 extended the static protection-from-colors subpattern to creatures whose
`ProtectionAbility` is combined with already-supported static self keywords on
the new server:

- Split support now accepts no-effect/no-signal `ProtectionAbility` rows with
  static self keyword abilities such as flying, first strike, defender, double
  strike, trample, vigilance, haste, and lifelink, as long as Oracle text and
  local XMage source agree on exact color protection. `Protection from each
  color` maps to the five colored source protections and still does not cover
  colorless sources.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`419` tests) and
  `test_xmage_exact_scope_runtime.py` (`241` tests). Split tests cover
  `Flying, protection from red` and `Flying, protection from each color`;
  runtime coverage is inherited from the focused protection target-legality
  test and static keyword tests.
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg414_static_keyword_protection_colors_new_server`
  produced `32` safe candidates. The split also left `22` non-color protection
  rows blocked as `static_protection_oracle_not_color_exact`.
- PostgreSQL package `PG414` was applied on the new server:
  `32` upserted rows, `0` deprecated shadow rows, and postcheck `32/32`
  `verified`/`auto` rows with Oracle hashes.
- PG -> SQLite sync for the package loaded `32` PostgreSQL rows, updated `32`
  SQLite rows, and exported `5432` canonical snapshot rows.
- Contract cleanup in the same closeout backfilled missing `oracle_hash` for
  `44` older trusted executable PostgreSQL rows on
  `127.0.0.1:15432/halder`; full PG -> SQLite sync then loaded `4298`
  PostgreSQL rows, updated `4293` SQLite rows, and exported `5432` canonical
  snapshot rows.
- Final governance audits passed after hash cleanup:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51`), and legacy contamination.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26625` to `26593` and authoritative adapter-required count from
  `26311` to `26279`. The post-PG414 exact split recheck produced
  `proposal_count=0`; the remaining `314` identities are still explicit
  missing-source exceptions.

PG415 closed the exact target-keyword-until-EOT attack trigger subpattern and
one newly unlocked already-supported activated target-keyword row on the new
server:

- Split support now maps XMage `GainAbilityTargetEffect` with
  `AttacksTriggeredAbility` into
  `xmage_creature_attack_grant_keyword_target_creature_until_eot_v1` when the
  local Java source and Oracle text agree on target controller, attacking state,
  `another` source exclusion, subtype filters, optional trigger text, and the
  granted keyword. The shared target parser also now recognizes `without
  flying` as an excluded keyword and the implicit creature subtypes `Knight`
  and `Dinosaur` for this target-keyword lane.
- Runtime support now resolves attack-trigger keyword grants during combat:
  the battle runtime chooses a legal target, applies the granted keyword until
  end of turn, emits decision/replay evidence, respects target constraints, and
  cleans the temporary keyword at cleanup.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`423` tests),
  `test_xmage_exact_scope_runtime.py` (`242` tests), and package/sync helper
  tests (`27` tests; existing SQLite `ResourceWarning` messages only).
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg415_attack_target_keyword_new_server`
  produced `11` safe candidates: `Aerial Guide`, `Chasm Drake`,
  `Garrison Griffin`, `Heavenly Qilin`, `Kinsbaile Balloonist`,
  `Majestic Heliopterus`, `Pegasus Courser`, `Roc Charger`,
  `Trailblazing Historian`, `Trained Condor`, and `Trusted Pegasus`.
- PostgreSQL package `PG415` was applied on the new server:
  precheck found `11` target card rows and `0` existing conflicting rule rows;
  apply upserted `11` rows and deprecated `0` shadow rows; postcheck verified
  `11/11` `verified`/`auto` rows with Oracle hashes.
- PG -> Hermes/SQLite sync loaded `11` PostgreSQL rows, updated `11` SQLite
  rows, and exported `5443` canonical snapshot rows. The metadata sync in the
  same cycle matched `6432` PostgreSQL card rows, left `1` unresolved alias, and
  performed `108` `deck_cards.card_id` backfill updates.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `11` selected cards. The generic E2E
  battle scenario count was `0`; card behavior execution is covered by the
  focused runtime test above.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51`), and legacy contamination.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26593` to `26582`, authoritative adapter-required count from `26279`
  to `26268`, and the target-keyword/protection work unit from `1114` to
  `1103`. The post-PG415 exact split recheck produced `proposal_count=0`; the
  remaining `314` identities are still explicit missing-source exceptions.

PG416 closed the exact permanent activated damage with sacrifice-target cost
subpattern on the new server:

- Split support now maps XMage `DamageTargetEffect` permanent activated
  abilities with a fixed damage amount plus simple `SacrificeTargetCost` into
  `xmage_permanent_simple_activated_damage_v1` when Oracle and local Java
  source agree on mana cost, tap requirement, target scope, and sacrifice-cost
  constraints. Supported sacrifice targets in this wave are controlled
  creature, artifact, Goblin, Forest, nonland permanent, and `another`
  creature variants. Dynamic-damage and custom-cost neighbors stay blocked.
- Runtime support now requires a legal sacrifice-cost target before activation,
  chooses a matching controlled permanent, pays mana/tap/source-sacrifice
  costs, moves the sacrificed cost target to graveyard, emits decision/replay
  evidence, and resolves the direct damage.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` (`424` tests) and
  `test_xmage_exact_scope_runtime.py` (`244` tests).
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg416_activated_damage_sacrifice_cost_new_server`
  produced `14` safe candidates: `Arms Dealer`, `Barrage Ogre`,
  `Blazing Hellhound`, `Fodder Cannon`, `Heartwood Giant`, `Hurler Cyclops`,
  `Magmaw`, `Orcish Bloodpainter`, `Orcish Mechanics`, `Orcish Vandal`,
  `Scorched Rusalka`, `Skirsdag Cultist`, `Skull Catapult`, and
  `Tar Pitcher`.
- PostgreSQL package `PG416` was applied on the new server:
  precheck found `14` target card rows; apply upserted `14` rows and deprecated
  `0` shadow rows; postcheck verified `14/14` `verified`/`auto` rows with
  Oracle hashes. The idempotent apply-evidence runner later confirmed
  `promoted_rule_rows=14`, `promoted_verified_auto_rows=14`, and
  `promoted_oracle_hash_rows=14` against `127.0.0.1:15432/halder`.
- PG -> Hermes/SQLite sync loaded `14` PostgreSQL rows, updated `14` SQLite
  rows, and exported `5457` canonical snapshot rows. The metadata sync in the
  same cycle matched `6443` PostgreSQL card rows, left `1` unresolved alias,
  and kept `deck_cards` backfill at `2699/2699` matched rows.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `14` selected cards. The generic E2E
  battle scenario count was `0`; card behavior execution is covered by the
  focused runtime tests above.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51`), and legacy contamination.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26582` to `26568`, authoritative adapter-required count from `26268`
  to `26254`, and the direct-damage work unit from `827` to `813`. The
  post-PG416 exact split recheck produced `proposal_count=0`; the remaining
  `314` identities are still explicit missing-source exceptions.

PG417 closed the exact permanent activated library-search-to-battlefield
subpattern on the new server:

- Split support now maps XMage `SearchLibraryPutInPlayEffect` plus
  `SimpleActivatedAbility` permanents into
  `xmage_permanent_simple_activated_library_search_to_battlefield_v1` when
  Oracle and local Java source agree on search target, count, destination,
  tapped entry, mana cost, tap requirement, and source-sacrifice requirement.
  The mapper also normalizes Oracle costs that sacrifice the named source
  itself. Neighboring costs that sacrifice other permanents, discard, exile, or
  use composite costs remain blocked for later dedicated mappers.
- Runtime support now detects the activated tutor effect, checks tap and
  summoning-sickness restrictions, pays the activated mana cost, taps or
  sacrifices the source when required, chooses the best valid library target
  with existing tutor scoring/constraints, moves selected cards to the
  battlefield, preserves tapped-entry semantics, triggers landfall for tutored
  lands, and emits decision/replay evidence.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` plus
  `test_xmage_exact_scope_runtime.py` (`673` tests total).
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg417_activated_tutor_battlefield_new_server`
  produced `21` safe candidates: `Amrou Scout`, `Bogbrew Witch`,
  `Burnished Hart`, `Cateran Brute`, `Cateran Kidnappers`,
  `Cateran Persuader`, `Dawntreader Elk`, `Diligent Farmhand`,
  `Embodiment of Spring`, `Font of Fertility`, `Frontier Guide`,
  `Moggcatcher`, `Neverwinter Dryad`, `Oashra Cultivator`, `Planar Bridge`,
  `Ramosian Commander`, `Ramosian Lieutenant`, `Ramosian Sergeant`,
  `Seahunter`, `Skyshroud Poacher`, and `Whisper Squad`.
- PostgreSQL package `PG417` was applied on the new server:
  precheck found `21` target card rows; apply promoted `21/21`
  `verified`/`auto` rows with Oracle hashes and deprecated `2` nonmatching
  shadow rows for `Burnished Hart`.
- PG -> Hermes/SQLite sync loaded `21` PostgreSQL rows for the selected cards,
  updated `23` SQLite rows, and exported `5477` canonical snapshot rows. The
  metadata sync in the same cycle matched `6457` PostgreSQL card rows, left
  `1` unresolved alias, and kept `deck_cards` backfill at `2699/2699` matched
  rows.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `21` selected cards. The generic E2E
  battle scenario count was `0`; card behavior execution is covered by the
  focused runtime tests above.
- The PG/Hermes/SQLite contract audit initially exposed `44` pre-existing
  trusted executable PostgreSQL rules without `oracle_hash`. A narrow PG
  backfill populated those hashes from `cards.oracle_text`; the rerun passed
  `51/51` checks.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51` after oracle-hash backfill), and legacy contamination.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26568` to `26547`, authoritative adapter-required count from `26254`
  to `26233`, and the library-tutor work unit from `605` to `584`. The
  post-PG417 exact split recheck produced `proposal_count=0`; the remaining
  `314` identities are still explicit missing-source exceptions.

PG418 closed the exact static cast-as-though-flash permission subpattern on the
new server:

- Split support now maps XMage `CastAsThoughItHadFlashAllEffect` plus
  `SimpleStaticAbility` into
  `xmage_static_cast_spells_as_flash_permission_v1` when Oracle and local Java
  source agree on the exact timing-permission filter and controller scope.
  Supported filters in this wave are nonland spells, artifact spells, sorcery
  spells, historic spells, Sliver spells, creature-or-enchantment spells, and
  green creature spells. Auxiliary `FlashAbility` and safe static self keywords
  are preserved; Leyline/opening-hand, Background, Aura/enchant, conditional,
  triggered, cost-reduction, and compound neighbors remain blocked for dedicated
  mappers.
- Runtime support now matches flash permissions by filter, respects `self` vs
  `any_player`, and blocks non-instant artifact/enchantment/planeswalker/battle
  spells outside main phases unless a matching permission exists. The existing
  Vedalken Orrery nonland-spell behavior remains compatible.
- Focused tests passed:
  `test_xmage_authoritative_exact_scope_split.py` plus
  `test_xmage_exact_scope_runtime.py` (`679` tests total), and
  `test_xmage_batch_pg_package_builder.py` executed directly without errors.
- Exact split:
  `xmage_authoritative_exact_scope_split_20260704_pg418_static_flash_permission_new_server`
  produced `7` safe candidates: `High Fae Trickster`, `Hypersonic Dragon`,
  `Quick Sliver`, `Raff Capashen, Ship's Mage`, `Shimmer Myr`,
  `Vernal Equinox`, and `Yeva, Nature's Herald`.
- PostgreSQL package `PG418` was applied on the new server:
  precheck found `7` target card rows; apply upserted `7` rows and deprecated
  `0` shadow rows; postcheck verified `7/7` `verified`/`auto` rows with Oracle
  hashes.
- PG -> Hermes/SQLite sync loaded `7` PostgreSQL rows for the selected cards,
  updated `7` SQLite rows, and exported `5484` canonical snapshot rows. The
  metadata sync in the same cycle matched `6477` PostgreSQL card rows, left
  `1` unresolved alias, and kept `deck_cards` backfill at `2699/2699` matched
  rows.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `7` selected cards. The generic E2E
  battle scenario count was `0`; card behavior execution is covered by the
  focused runtime tests above.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, PG/Hermes/SQLite contract
  (`51/51`), and legacy contamination.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26547` to `26540`, authoritative adapter-required count from `26233`
  to `26226`, and the static cast-as-flash work unit from `34` to `27`. The
  post-PG418 exact split recheck produced `proposal_count=0`; the remaining
  `314` identities are still explicit missing-source exceptions.

## 2026-07-04 PG419 Static Self Can't-Be-Blocked Creature Closure

- Closed the exact XMage unit
  `xmage_signature::no_effect_class::CantBeBlockedSourceAbility::no_target_class::no_condition_class::no_signal`
  as ManaLoom scope `xmage_static_self_cant_be_blocked_creature_v1`.
- The mapper requires the local XMage source to contain
  `CantBeBlockedSourceAbility` and excludes filtered evasion sources such as
  `CantBeBlockedByCreaturesSourceEffect` and `SimpleEvasionAbility`. The Oracle
  gate accepts only exact self evasion text like `This creature can't be
  blocked.` and still blocks conditional variants.
- Runtime behavior is executable through the existing blocker assignment path:
  cards with `cant_be_blocked`/`unblockable` cannot receive blockers. Focused
  tests now cover positive mapping, negative conditional text, and combat
  blocker assignment.
- The PostgreSQL package promoted `11` cards:
  `Covert Operative`, `Jhessian Infiltrator`, `Latch Seeker`, `Metathran
  Soldier`, `Mist-Cloaked Herald`, `Phantom Ninja`, `Phantom Warrior`,
  `Slither Blade`, `Talas Warrior`, `Tidal Kraken`, and `Triton Shorestalker`.
  Precheck found `11` target rows, `0` existing rule rows, and `0` shadow rows;
  apply inserted/updated `11`; postcheck verified `11/11` promoted rows as
  `verified`/`auto` with Oracle hashes.
- Hermes sync refreshed PostgreSQL card metadata against the new-server target
  `127.0.0.1:15432/halder` and synced `11` PG rules into SQLite. The canonical
  fallback export increased to `5495` rows.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `11` selected cards. Generic battle
  scenario count remained `0`; combat execution is covered by the focused
  runtime test.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26540` to `26529`, authoritative adapter-required count from `26226`
  to `26215`, and the exact cant-be-blocked work unit to zero. The post-PG419
  exact split recheck produced `proposal_count=0`; the remaining `314`
  identities are still explicit missing-source exceptions.

## 2026-07-04 PG420 Static Basic Landwalk Creature Closure

- Closed the exact XMage basic-landwalk no-effect/no-signal units as ManaLoom
  scope `xmage_static_self_basic_landwalk_creature_v1`.
- The mapper accepts only pure `PlainswalkAbility`, `IslandwalkAbility`,
  `SwampwalkAbility`, `MountainwalkAbility`, or `ForestwalkAbility`, with exact
  Oracle text after reminder removal (`plainswalk`, `islandwalk`, `swampwalk`,
  `mountainwalk`, or `forestwalk`) and matching local XMage source. Generic
  `LandwalkAbility` cases such as nonbasic, legendary, or snow landwalk remain
  intentionally excluded for separate scoped adapters.
- Runtime behavior now passes the defending player into
  `attacker_cannot_be_blocked`; absolute unblockable still works without a
  defender, while landwalk only suppresses blockers when the defending player
  controls a land with the matching basic land subtype. Focused tests cover the
  mapper, nonbasic/snow text rejection, matching-land unblockability, and
  nonmatching-land blockability.
- The PostgreSQL package promoted `61` cards:
  `21` swampwalk, `17` forestwalk, `12` mountainwalk, `9` islandwalk, and `2`
  plainswalk identities. Precheck found `61` target rows, `0` existing rule
  rows, and `0` shadow rows; apply inserted/updated `61`; postcheck verified
  `61/61` promoted rows as `verified`/`auto` with Oracle hashes.
- Hermes sync refreshed PostgreSQL card metadata against
  `127.0.0.1:15432/halder` and synced `61` PG rules into SQLite. The canonical
  fallback export increased to `5556` rows.
- PG420 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `61` selected cards. Generic
  battle scenario count remained `0`; conditional combat behavior is covered by
  focused runtime tests.
- PG420b fixed a contract drift discovered by the final PG/Hermes/SQLite audit:
  `44` older trusted executable PostgreSQL rules lacked `oracle_hash`. The
  backfill used `cards.id = card_battle_rules.card_id`, updated `44`, preserved
  rule behavior, synced the affected `44` cards to SQLite, and reduced trusted
  executable missing-hash rows to `0`.
- Final governance audits passed after PG420b:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26529` to `26468`, authoritative adapter-required count from `26215`
  to `26154`, and the basic landwalk exact units to zero. The post-PG420 exact
  split recheck produced `proposal_count=0`; the remaining `314` identities are
  still explicit missing-source exceptions.

## 2026-07-04 PG421 Static Flying Block-Only-Flying Creature Closure

- Closed the exact XMage no-effect/no-signal unit
  `CanBlockOnlyFlyingAbility,FlyingAbility` as ManaLoom scope
  `xmage_static_flying_can_block_only_flying_creature_v1`.
- The mapper accepts only creatures whose local XMage source contains both
  `FlyingAbility` and `CanBlockOnlyFlyingAbility`, with no effects, no extra
  signals, and exact Oracle text after reminder removal:
  `Flying` plus `This creature can block only creatures with flying.`.
  Similar filtered evasion, landwalk, or non-exact block restriction text
  remains blocked for separate adapters.
- Runtime behavior now routes blocker legality through
  `blocker_can_block_attacker`: flying attackers still require flying/reach
  blockers, and creatures with `can_block_only_flying` or
  `block_restriction=creatures_with_flying_only` cannot block nonflying
  attackers. Focused tests cover both rejected nonflying attackers and allowed
  flying attackers.
- The PostgreSQL package promoted `18` cards:
  `Belbe's Percher`, `Cloud Djinn`, `Cloud Dragon`, `Cloud Elemental`,
  `Cloud Pirates`, `Cloud Spirit`, `Cloud Sprite`, `Hoverguard Observer`,
  `Long-Finned Skywhale`, `Rishadan Airship`, `Scrapskin Drake`,
  `Skywinder Drake`, `Stratozeppelid`, `Stronghold Zeppelin`,
  `Tattered Haunter`, `Vaporkin`, `Wanderlight Spirit`, and `Welkin Tern`.
  Precheck found `18` target rows, `0` existing rule rows, and `0` shadow rows;
  apply inserted/updated `18`; postcheck verified `18/18` promoted rows as
  `verified`/`auto` with Oracle hashes.
- Hermes sync refreshed PostgreSQL card metadata against
  `127.0.0.1:15432/halder` and synced `18` PG rules into SQLite. The canonical
  fallback export increased to `5574` rows.
- PG421 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `18` selected cards. Generic
  battle scenario count remained `0`; combat legality is covered by focused
  runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26468` to `26450`, authoritative adapter-required count from `26154`
  to `26136`, and the exact flying block-only-flying work unit to zero. The
  post-PG421 exact split recheck produced `proposal_count=0`; the remaining
  `314` identities are still explicit missing-source exceptions.

## 2026-07-04 PG422 Static Filtered Evasion Creature Closure

- Closed the exact XMage unit
  `CantBeBlockedByCreaturesSourceEffect::SimpleEvasionAbility` as ManaLoom
  scope `xmage_static_filtered_evasion_creature_v1`.
- The mapper accepts only creatures whose Oracle text and local XMage source
  agree on a runtime-supported blocker filter: power threshold, color,
  subtype, artifact, token, or `can't be blocked except by ...` allowed
  blocker filters. Broader conditional evasion remains blocked for separate
  adapters.
- Runtime behavior now extends `blocker_can_block_attacker`: after flying/reach
  and block-only-flying checks, blockers matching
  `cant_be_blocked_by_filters` are rejected, and blockers must match one of
  `can_be_blocked_only_by_filters` when present. Focused tests cover color,
  power, subtype, artifact, and `except by` legalities.
- The PostgreSQL package promoted `21` cards:
  `Amrou Kithkin`, `Amrou Seekers`, `Arlinn's Wolf`,
  `Barrenton Cragtreads`, `Bog Rats`, `Deathcult Rogue`, `Dread Warlock`,
  `Duskmantle Operative`, `Fleet-Footed Monk`, `Goldmeadow Dodger`,
  `Kor Castigator`, `Mudbrawler Raiders`, `Prowling Nightstalker`,
  `Rampart Crawler`, `Raven's Run Dragoon`, `River Darter`,
  `Rubblebelt Runner`, `Sacred Knight`, `Skirk Shaman`, `Sootwalkers`, and
  `Wanderbrine Rootcutters`. Precheck found `21` target rows, `0` existing
  rule rows, and `0` shadow rows; apply inserted/updated `21`; postcheck
  verified `21/21` promoted rows as `verified`/`auto` with Oracle hashes.
- Hermes sync refreshed PostgreSQL card metadata against
  `127.0.0.1:15432/halder` and synced `21` PG rules into SQLite. The canonical
  fallback export increased to `5595` rows.
- PG422 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `21` selected cards. Generic
  battle scenario count remained `0`; combat legality is covered by focused
  runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26450` to `26429`, authoritative adapter-required count from `26136`
  to `26115`, and the exact filtered-evasion work unit to zero. The post-PG422
  exact split recheck produced `proposal_count=0`; the remaining `314`
  identities are still explicit missing-source exceptions.

## 2026-07-04 PG423 Static Cant-Block Creature Closure

- Closed the exact XMage no-effect/no-signal unit `CantBlockAbility` as
  ManaLoom scope `xmage_static_self_cant_block_creature_v1`.
- The mapper accepts only creature permanents with exact Oracle text
  `This creature can't block.` and pure local XMage source containing
  `new CantBlockAbility()` with no activated recursion or other companion
  behavior. Composite cases remain blocked for their own scoped adapters.
- Runtime behavior reuses the existing blocker surface:
  `creatures_for_blocking()` excludes permanents where `creature_cannot_block`
  is true, and focused tests now cover static cant-block mapper output plus
  combat blocker exclusion.
- The PostgreSQL package promoted `13` cards:
  `Ashenmoor Gouger`, `Craven Giant`, `Craven Knight`, `Goblin Raider`,
  `Hulking Cyclops`, `Hulking Goblin`, `Hulking Ogre`, `Jungle Lion`,
  `Ogre Taskmaster`, `Scavenging Scarab`, `Spineless Thug`,
  `Yellow Scarves Troops`, and `Young Wei Recruits`. Precheck found `13`
  target rows, `0` existing rule rows, and `0` shadow rows; apply
  inserted/updated `13`; postcheck verified `13/13` promoted rows as
  `verified`/`auto` with Oracle hashes.
- Hermes sync refreshed PostgreSQL card metadata against
  `127.0.0.1:15432/halder` and synced `13` PG rules into SQLite. The canonical
  fallback export increased to `5608` rows.
- PG423 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `13` selected cards. Generic
  battle scenario count remained `0`; combat blocker exclusion is covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26429` to `26416`, authoritative adapter-required count from `26115`
  to `26102`, and the exact cant-block work unit to zero. The post-PG423 exact
  split recheck produced `proposal_count=0`; the remaining `314` identities
  are still explicit missing-source exceptions.

## 2026-07-04 PG424 Static Horsemanship Creature Closure

- Closed the exact XMage no-effect/no-signal unit `HorsemanshipAbility` as
  ManaLoom scope `xmage_static_self_horsemanship_creature_v1`.
- The mapper accepts only creature permanents whose Oracle text reduces to
  `Horsemanship` after reminder removal and whose local XMage source contains
  direct `HorsemanshipAbility` without gain-ability, simple-evasion, landwalk,
  or cant-be-blocked companion behavior. Temporary-grant and horsemanship
  filter cases remain blocked for separate adapters.
- Runtime behavior now treats horsemanship as a self keyword and extends
  `blocker_can_block_attacker`: an attacker with horsemanship can be blocked
  only by a blocker with horsemanship. Focused tests cover mapper acceptance,
  source rejection, legal horsemanship blockers, illegal ordinary blockers,
  and ordinary attackers that do not require horsemanship blockers.
- The PostgreSQL package promoted `10` cards:
  `Barbarian General`, `Lady Zhurong, Warrior Queen`,
  `Lu Meng, Wu General`, `Shu Cavalry`, `Shu Elite Companions`,
  `Wei Elite Companions`, `Wei Scout`, `Wei Strike Force`,
  `Wu Elite Cavalry`, and `Wu Light Cavalry`. Precheck found `10` target rows,
  `0` existing rule rows, and `0` shadow rows; apply inserted/updated `10`;
  postcheck verified `10/10` promoted rows as `verified`/`auto` with Oracle
  hashes.
- Hermes sync refreshed PostgreSQL card metadata against
  `127.0.0.1:15432/halder` and synced `10` PG rules into SQLite. The canonical
  fallback export increased to `5618` rows.
- PG424 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `10` selected cards. Generic
  battle scenario count remained `0`; combat legality is covered by focused
  runtime tests.
- PG424b fixed a PostgreSQL-only contract drift discovered by the final
  PG/Hermes/SQLite audit: `44` older trusted executable PostgreSQL rules
  lacked `oracle_hash`. The backfill used `cards.id = card_battle_rules.card_id`
  and `cards.oracle_text`, updated `44`, preserved rule behavior, and reduced
  trusted executable missing-hash rows to `0`.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`) after PG424b.
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26416` to `26406`, authoritative adapter-required count from `26102`
  to `26092`, and the exact horsemanship work unit to zero. The post-PG424
  exact split recheck produced `proposal_count=0`; the remaining `314`
  identities are still explicit missing-source exceptions.

## 2026-07-04 PG425 Static Flash Creature Closure

- Closed the exact XMage no-effect/no-signal units where `FlashAbility` appears
  only as a self timing keyword on creature permanents, with any companion
  static self keywords already supported by the ManaLoom runtime.
- The mapper now translates `FlashAbility` to the self keyword `flash` and
  preserves it in `effect_json.keywords`, `_keywords_are_self`, and the
  boolean `flash=true` flag. Unsafe neighbors such as protection flash
  creatures and flash permanents with activated damage stayed outside this
  package and remain separate exact families.
- Runtime behavior already gates spell timing through `card_has_keyword(card,
  "flash")`; focused tests now prove that a flash creature can be cast outside
  main phase while an equivalent ordinary creature cannot.
- The PostgreSQL package promoted `33` cards:
  `Ambush Viper`, `Ashcoat Bear`, `Aven Reedstalker`, `Benalish Knight`,
  `Bounding Wolf`, `Cloaked Siren`, `Crystacean`, `Darksteel Sentinel`,
  `Dawn's Light Archer`, `Faerie Invaders`, `Fire Nation Ambushers`,
  `Galewind Moose`, `Havenwood Wurm`, `Hired Blade`, `Hussar Patrol`,
  `King Cheetah`, `Living Tempest`, `Merfolk of the Depths`,
  `Nephalia Seakite`, `Plumeveil`, `Pouncing Cheetah`, `Raging Kavu`,
  `Riptide Turtle`, `Sentinels of Glen Elendra`, `Skyline Predator`,
  `Spire Monitor`, `Stormrider Spirit`, `Swift Spinner`, `Tangle Spider`,
  `Vexing Gull`, `Wind Strider`, `Winged Coatl`, and `Zealous Guardian`.
  Precheck found `33` target rows, `0` existing rule rows, and `0` shadow rows;
  apply inserted/updated `33`; postcheck verified `33/33` promoted rows as
  `verified`/`auto` with Oracle hashes.
- Hermes sync refreshed PostgreSQL card metadata against
  `127.0.0.1:15432/halder` and synced `33` PG rules into SQLite. The canonical
  fallback export increased to `5651` rows.
- PG425 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `33` selected cards. Generic
  battle scenario count remained `0`; flash timing is covered by focused
  runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26406` to `26373`, authoritative adapter-required count from `26092`
  to `26059`, and the exact static self combat keyword flash work unit to
  zero. The post-PG425 exact split recheck produced `proposal_count=4` only for
  separate next-work candidates: `Bear Trap`, `Springjaw Trap`,
  `Defender of Chaos`, and `Defender of Law`.

## 2026-07-04 PG426 Flash Auxiliary Residual Closure

- Closed the four post-PG425 exact-scope residuals that used `flash` as an
  auxiliary keyword outside the plain static self-keyword creature family:
  `Bear Trap`, `Springjaw Trap`, `Defender of Chaos`, and `Defender of Law`.
- No broad mapper was promoted. The package reused existing exact scopes:
  `xmage_permanent_simple_activated_damage_v1` for flash artifacts with simple
  tap/sacrifice damage activations, and
  `xmage_static_self_protection_from_colors_creature_v1` for flash creatures
  with exact protection from one color.
- Focused tests now cover both combined cases: a flash damage artifact can be
  cast outside main phase and still activate/tap/sacrifice/deal damage, and a
  flash protection creature preserves combat-speed timing while blocking
  illegal targeting from the protected color.
- The PostgreSQL package promoted `4` cards. Precheck found `4` target rows,
  `0` existing rule rows, and `0` shadow rows; apply inserted/updated `4`;
  postcheck verified `4/4` promoted rows as `verified`/`auto` with Oracle
  hashes.
- Hermes sync refreshed PostgreSQL card metadata against
  `127.0.0.1:15432/halder` and synced `4` PG rules into SQLite. The canonical
  fallback export increased to `5655` rows.
- PG426 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `4` selected cards. Generic
  battle scenario count remained `0`; timing/protection/activation semantics
  are covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26373` to `26369`, authoritative adapter-required count from `26059`
  to `26055`, and the exact split recheck now reports `proposal_count=0`.
  The remaining `314` identities are still explicit missing-source exceptions.

## 2026-07-04 PG427 Static Card-Type Protection Closure

- Closed the exact XMage static creature-protection unit where
  `ProtectionAbility` grants self-protection from a card type: artifact,
  enchantment, creature, or land. Broader protection from subtypes,
  multicolor, mana values, or conditional protection remains blocked for
  separate exact adapters.
- The mapper now translates the local XMage source and Oracle text into
  ManaLoom scope `xmage_static_self_protection_from_card_types_creature_v1`
  with `static_effect=self_protection_from_card_types` and
  `protection_from_card_types`. Existing supported self keywords such as
  `flying` and `flash` are preserved on the same rule.
- Runtime behavior now extends target legality: `is_legal_target` rejects a
  source whose card type matches the target permanent's
  `protection_from_card_types`, while nonmatching sources remain legal.
  Focused tests cover artifact-source rejection, nonartifact instant
  allowance, mapper acceptance, and subtype-protection rejection.
- The PostgreSQL package promoted `10` cards:
  `Angelic Curator`, `Azorius First-Wing`, `Beloved Chaplain`,
  `Commander Eesha`, `Horizon Drake`, `Nacatl Savage`, `Needlebug`,
  `Tel-Jilad Chosen`, `Tel-Jilad Outrider`, and `Yavimaya Scion`.
  Precheck found `10` target rows, `0` existing rule rows, and `0` shadow rows;
  apply inserted/updated `10`; postcheck verified `10/10` promoted rows as
  `verified`/`auto` with Oracle hashes.
- Hermes sync refreshed PostgreSQL card metadata against
  `127.0.0.1:15432/halder` and synced `10` PG rules into SQLite. The canonical
  fallback export increased to `5665` rows.
- PG427 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `10` selected cards. Generic
  battle scenario count remained `0`; target legality is covered by focused
  runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26369` to `26359`, authoritative adapter-required count from `26055`
  to `26045`, and the exact split recheck reports `proposal_count=0`.
  The remaining `314` identities are still explicit missing-source exceptions.

## 2026-07-04 PG428 Static Subtype Protection Closure

- Closed the exact XMage static creature-protection unit where
  `ProtectionAbility` grants self-protection from one or more subtypes such as
  Demon, Dragon, Vampire, Werewolf, Zombie, Spirit, Arcane, Elf, or Kavu.
  Protection from monocolored, multicolored, or mana-value ranges remains
  blocked for separate exact adapters.
- The mapper now translates matching local XMage source and Oracle text into
  ManaLoom scope `xmage_static_self_protection_from_subtypes_creature_v1`
  with `static_effect=self_protection_from_subtypes` and
  `protection_from_subtypes`. The same parser also fixed card-type protection
  clauses followed by later keywords, such as `Protection from artifacts;
  reach`.
- Runtime behavior now extends target legality again: `is_legal_target`
  rejects a source whose subtype matches the target permanent's
  `protection_from_subtypes`, while nonmatching subtypes remain legal.
  Focused tests cover subtype-source rejection, nonmatching subtype allowance,
  source/Oracle order normalization, trailing keyword parsing, and explicit
  rejection of multicolored protection.
- The PostgreSQL package promoted `9` cards:
  `Baneslayer Angel`, `Dragonstalker`, `Elite Inquisitor`, `Grave Bramble`,
  `Kitsune Riftwalker`, `Midnight Duelist`, `Nath's Buffoon`,
  `Shoreline Raider`, and `Tel-Jilad Archers`. Precheck found `9` target rows,
  `0` existing rule rows, and `0` shadow rows; apply inserted/updated `9`;
  postcheck verified `9/9` promoted rows as `verified`/`auto` with Oracle
  hashes.
- Hermes sync refreshed PostgreSQL card metadata against
  `127.0.0.1:15432/halder` and synced `9` PG rules into SQLite. The canonical
  fallback export increased to `5674` rows.
- PG428 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `9` selected cards. Generic
  battle scenario count remained `0`; subtype targeting legality is covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync queue rebuild reduced the Commander-legal target identity queue
  from `26359` to `26350`, authoritative adapter-required count from `26045`
  to `26036`, and the exact split recheck reports `proposal_count=0`.
  The remaining `314` identities are still explicit missing-source exceptions.

## 2026-07-04 PG429 Hybrid Locket Mana/Draw Closure

- Closed the hybrid-cost subpattern of
  `xmage_simple_tap_mana_source_with_activated_draw_v1` for the ten Guild
  Lockets: `Azorius Locket`, `Boros Locket`, `Dimir Locket`,
  `Golgari Locket`, `Gruul Locket`, `Izzet Locket`, `Orzhov Locket`,
  `Rakdos Locket`, `Selesnya Locket`, and `Simic Locket`.
- The mapper now accepts Oracle activation costs with hybrid symbols such as
  `{W/U}{W/U}{W/U}{W/U}`. The exact split intentionally selected only the
  Locket mana-source/draw family for PG429; the five neighboring hybrid
  activated destroy/self-boost proposals remain separate next-work candidates
  until their own runtime tests/package cycle.
- Runtime utility-artifact activation now records mana paid from the textual
  activation cost, so hybrid and other non-generic costs produce correct
  `mana_paid` and `resource_delta.mana` values. Focused tests cover an Azorius
  Locket paying two white and two blue mana, sacrificing itself, and drawing
  two cards; the existing Banner self-sacrifice draw path now also asserts
  `mana_paid=3`.
- The E2E validator now sets `MANALOOM_KNOWLEDGE_DB` and
  `MANALOOM_CANONICAL_KNOWN_CARDS_JSON` from its CLI paths before importing the
  battle runtime, preventing accidental validation against the stale sibling
  `manaloom-knowledge/knowledge.db` instead of the operational
  `manaloom-knowledge/scripts/knowledge.db`.
- The PG -> SQLite sync cleanup contract is now explicit: partial selected-card
  syncs preserve unrelated runtime rows, while global syncs remove stale local
  mirror rows absent from the current PostgreSQL plus reviewed-runtime
  snapshot. This fixed a post-PG429 parity failure where `692` stale SQLite
  runtime keys were still shadowing PostgreSQL truth.
- The PostgreSQL package promoted `10` cards. Precheck found `10` target rows,
  `0` existing expected rows, and `2` shadow rows; apply inserted/updated `10`;
  postcheck verified `10/10` promoted rows as `verified`/`auto` with Oracle
  hashes and deprecated the `2` shadow rows.
- Hermes metadata sync and PG -> SQLite sync were run against the operational
  new-server target `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `3854` PostgreSQL runtime rows, wrote `3846` SQLite runtime
  rows, and exported `3821` canonical fallback rows after stale mirror cleanup.
- PG429 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `10` selected cards. Generic
  battle scenario count remained `0`; the actual hybrid activation behavior is
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync readiness and queue rebuilds now surface the all-card/Commander
  legal queue after stale-cache cleanup rather than comparing against the
  pre-cleanup PG428 cache shape. Current Commander-legal authoritative queue:
  `target_identity_count=27032`, `xmage_authoritative_source_count=26718`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26718`.
- The post-PG429 exact split recheck reports `proposal_count=693` safe
  candidates across already-supported exact scopes. Next work must select a
  coherent family/subpattern from that recheck, not blindly promote all
  proposals in one mixed package.

## 2026-07-04 PG430 Static Basic Landwalk New-Server Reconciliation

- Reconciled the PG420 exact basic-landwalk family against the operational
  new-server target `143.198.230.247:5433/halder`. This is not a second
  semantic model: it replays the validated
  `xmage_static_self_basic_landwalk_creature_v1` scope after the PostgreSQL
  target and SQLite cleanup contract changed in PG429.
- The selected package contains the same pure XMage basic-landwalk shape:
  `PlainswalkAbility`, `IslandwalkAbility`, `SwampwalkAbility`,
  `MountainwalkAbility`, or `ForestwalkAbility`, exact Oracle text after
  reminder removal, and matching local XMage source. Nonbasic, legendary, snow,
  or other generic `LandwalkAbility` variants remain outside this scope.
- Runtime behavior was already covered by the focused PG420 tests:
  `attacker_cannot_be_blocked` receives the defending player, landwalk only
  suppresses blockers when the defender controls the matching basic land
  subtype, and absolute unblockable still works without a defender. PG430
  reused those mapper/runtime tests and performed no code mutation.
- The PostgreSQL package promoted `61` cards:
  `21` swampwalk, `17` forestwalk, `12` mountainwalk, `9` islandwalk, and `2`
  plainswalk identities. Precheck found `61` target rows, `0` existing expected
  rows, and `0` shadow rows; apply inserted/updated `61`; postcheck verified
  `61/61` promoted rows as `verified`/`auto` with Oracle hashes.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `3915` PostgreSQL runtime rows, wrote `3907` SQLite runtime
  rows, and exported `3882` canonical fallback rows.
- PG430 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `61` selected cards. Generic
  battle scenario count remained `0`; conditional combat behavior remains
  covered by the focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`). The local stale sibling
  `docs/hermes-analysis/manaloom-knowledge/knowledge.db` was removed after the
  audit warning; the operational SQLite cache remains
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.
- Post-sync Commander-legal queue is now:
  `target_identity_count=26971`, `xmage_authoritative_source_count=26657`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26657`. This is an exact
  reduction of `61` from the post-PG429 queue.
- The post-PG430 exact split recheck reports `proposal_count=632` and
  `safe_for_batch_pg_package_count=632`. Next work should choose one coherent
  family/subpattern from that set, starting with highest leverage where runtime
  behavior is already focused-test covered.

## 2026-07-04 PG431 Static Protection From Colors Closure

- Closed the exact XMage static creature protection-from-colors family as
  ManaLoom scope `xmage_static_self_protection_from_colors_creature_v1`.
- The selected package accepted only no-effect/no-signal `ProtectionAbility`
  creature rows where Oracle and local XMage source agree on color protection
  words. Static self keywords such as flying, first strike, vigilance, trample,
  lifelink, deathtouch, flash, defender, or indestructible are preserved in the
  same executable creature rule when present. Protection from card types and
  subtypes remain in their separate exact scopes.
- Runtime behavior was already covered by focused tests for static protection
  from color, card type, and subtype. PG431 reused the mapper/runtime tests and
  performed no code mutation.
- The PostgreSQL package promoted `53` cards. Precheck found `53` target rows,
  `0` existing expected rows, and `0` shadow rows; apply inserted/updated `53`;
  postcheck verified `53/53` promoted rows as `verified`/`auto` with Oracle
  hashes.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `3968` PostgreSQL runtime rows, wrote `3960` SQLite runtime
  rows, and exported `3935` canonical fallback rows.
- PG431 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `53` selected cards. Generic
  battle scenario count remained `0`; targeting/protection behavior remains
  covered by the focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26918`, `xmage_authoritative_source_count=26604`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26604`. This is an exact
  reduction of `53` from the post-PG430 queue.
- The post-PG431 exact split recheck reports `proposal_count=579` and
  `safe_for_batch_pg_package_count=579`. The largest remaining exact family is
  `xmage_simple_mana_source_permanent` with `34` cards, followed by
  `xmage_permanent_simple_activated_damage` and
  `xmage_static_self_combat_keyword_creature` with `33` cards each.

## 2026-07-04 PG432 Simple Tap Mana Source Closure

- Closed the exact XMage simple permanent mana-source family as ManaLoom scope
  `xmage_simple_tap_mana_source_permanent_v1`.
- The selected package accepted only simple tap mana-source permanents where
  Oracle and local XMage source agree on produced mana. Most selected cards
  generate `1` mana; `Timeless Lotus` generates `5`. Auxiliary, conditional,
  and source-cost mana variants remain separate scopes/blockers.
- Runtime behavior was already covered by focused tests for simple mana
  refresh, fixed distinct symbols, enters-tapped skip, and blocked conditional
  sources. PG432 reused the mapper/runtime tests and performed no code
  mutation.
- The PostgreSQL package promoted `34` cards. Precheck found `34` target rows,
  `0` missing targets, `0` existing expected rows, and `16` shadow rows to
  deprecate; apply/postcheck verified `34/34` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `544`
  affected historical rows; `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4002` PostgreSQL runtime rows, wrote `3994` SQLite runtime
  rows, and exported `3969` canonical fallback rows.
- PG432 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `34` selected cards. Generic
  battle scenario count remained `0`; actual mana behavior remains covered by
  the focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26884`, `xmage_authoritative_source_count=26570`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26570`. This is an exact
  reduction of `34` from the post-PG431 queue.
- The post-PG432 exact split recheck reports `proposal_count=545` and
  `safe_for_batch_pg_package_count=545`. The largest remaining exact families
  are `xmage_permanent_simple_activated_damage` and
  `xmage_static_self_combat_keyword_creature`, with `33` cards each.

## 2026-07-04 PG433 Permanent Simple Activated Damage Closure

- Closed the exact XMage permanent activated direct-damage family as ManaLoom
  scope `xmage_permanent_simple_activated_damage_v1`.
- The selected package accepted only permanents with a narrow
  `SimpleActivatedAbility`/`DamageTargetEffect` source signature where Oracle
  and local XMage source agree on fixed damage amount, target lane, tap
  requirement, mana cost, and source or cost-target sacrifice requirements.
  Dynamic damage amounts, unsupported activation costs, and unsupported target
  lanes remain separate blockers.
- Runtime behavior was already covered by focused tests for mana payment,
  tap/self-sacrifice, sacrifice-target costs, colored costs, static self
  keywords, flash artifacts, creature/flying/blocking target constraints, and
  missing-mana activation refusal. PG433 reused the mapper/runtime tests and
  performed no code mutation.
- The PostgreSQL package promoted `33` cards. Precheck found `33` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `33/33` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4035` PostgreSQL runtime rows, wrote `4027` SQLite runtime
  rows, and exported `4002` canonical fallback rows.
- PG433 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `33` selected cards. Generic
  battle scenario count remained `0`; actual activated-damage behavior remains
  covered by the focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26851`, `xmage_authoritative_source_count=26537`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26537`. This is an exact
  reduction of `33` from the post-PG432 queue.
- The post-PG433 exact split recheck reports `proposal_count=512` and
  `safe_for_batch_pg_package_count=512`. The largest remaining exact family is
  `xmage_static_self_combat_keyword_creature` with `33` cards, followed by
  `xmage_boost_keyword_target_creature_until_eot_spell` with `25` cards and
  `xmage_creature_dies_create_tokens` with `24` cards.

## 2026-07-04 PG434 Static Self Combat Keyword Creature Closure

- Closed the exact XMage static self combat-keyword creature family as
  ManaLoom scope `xmage_static_self_combat_keyword_creature_v1`.
- The selected package accepted only no-effect/no-signal creature rows whose
  local XMage abilities are static self keywords supported by the battle
  runtime. The batch is primarily `flash` creatures, including combinations
  with flying, reach, deathtouch, first strike, haste, defender, trample,
  vigilance, and indestructible. Protection and ward variants remain separate
  exact scopes/blockers.
- Runtime behavior was already covered by focused tests for keyword enrichment
  on permanents, flash timing, and static combat keyword interpretation. PG434
  reused the mapper/runtime tests and performed no code mutation.
- The PostgreSQL package promoted `33` cards. Precheck found `33` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `33/33` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4068` PostgreSQL runtime rows, wrote `4060` SQLite runtime
  rows, and exported `4035` canonical fallback rows.
- PG434 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `33` selected cards. Generic
  battle scenario count remained `0`; actual keyword behavior remains covered
  by the focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26818`, `xmage_authoritative_source_count=26504`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26504`. This is an exact
  reduction of `33` from the post-PG433 queue.
- The post-PG434 exact split recheck reports `proposal_count=479` and
  `safe_for_batch_pg_package_count=479`. The largest remaining exact family is
  `xmage_boost_keyword_target_creature_until_eot_spell` with `25` cards,
  followed by `xmage_creature_dies_create_tokens` and
  `xmage_permanent_simple_activated_target_keyword_until_eot` with `24` cards
  each.

## 2026-07-04 PG435 Boost Plus Keyword Until EOT Closure

- Closed the exact XMage fixed target-creature boost plus until-end-of-turn
  keyword spell family as ManaLoom scope
  `xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1`.
- The selected package accepted only one-shot spell rows with
  `BoostTargetEffect` plus `GainAbilityTargetEffect`, a single target
  creature, fixed power/toughness deltas, one supported granted keyword until
  EOT, and Oracle/XMage agreement on boost amount, target controller, and
  keyword. Dynamic boosts, multi-target boosts, unsupported keywords, and
  complex Oracle text remain separate blockers.
- The batch covers `25` cards across deathtouch, first strike, flying,
  hexproof, indestructible, lifelink, reach, and trample.
- Runtime behavior was already covered by focused tests for stat modifier
  until EOT, keyword grant/cleanup, target selection, and EOT cleanup. PG435
  reused the mapper/runtime tests and performed no code mutation.
- The PostgreSQL package promoted `25` cards. Precheck found `25` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `25/25` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4093` PostgreSQL runtime rows, wrote `4085` SQLite runtime
  rows, and exported `4060` canonical fallback rows.
- PG435 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `25` selected cards. Generic
  battle scenario count remained `0`; actual boost/keyword behavior remains
  covered by the focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26793`, `xmage_authoritative_source_count=26479`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26479`. This is an exact
  reduction of `25` from the post-PG434 queue.
- The post-PG435 exact split recheck reports `proposal_count=454` and
  `safe_for_batch_pg_package_count=454`. The largest remaining exact families
  are `xmage_creature_dies_create_tokens` and
  `xmage_permanent_simple_activated_target_keyword_until_eot`, with `24` cards
  each.

## 2026-07-04 PG436 Permanent Activated Target Keyword Until EOT Closure

- Closed the exact XMage permanent simple activated target-keyword until-end-of
  turn family as ManaLoom scope
  `xmage_permanent_simple_activated_target_keyword_until_eot_v1`.
- The selected package accepted only permanents with a simple activated
  `GainAbilityTargetEffect`, one supported keyword, fixed mana/tap cost data,
  no sacrifice cost, and Oracle/XMage agreement on target controller, target
  constraints, keyword, and duration. Source-sacrifice, unsupported snow or
  complex costs, unsupported target lanes, and protection-style variants remain
  blockers.
- The batch covers `24` cards granting deathtouch, first strike, flying,
  haste, indestructible, lifelink, trample, or vigilance until EOT, including
  target constraints by controller, color, subtype, power, attacking state,
  and exclude-source where present.
- Focused mapper/runtime tests covered activated target-keyword parsing,
  mana/tap payment, summoning-sick tap refusal, source static keyword
  preservation, subtype/color/power/combat target restrictions, and EOT
  cleanup. PG436 reused existing mapper/runtime support and performed no code
  mutation. The focused test lane passed `718` tests.
- The PostgreSQL package promoted `24` cards. Precheck found `24` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `24/24` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4117` PostgreSQL runtime rows, wrote `4109` SQLite runtime
  rows, and exported `4084` canonical fallback rows.
- PG436 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `24` selected cards. Generic
  battle scenario count remained `0`; actual activated target-keyword behavior
  remains covered by the focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26769`, `xmage_authoritative_source_count=26455`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26455`. This is an exact
  reduction of `24` from the post-PG435 queue.
- The post-PG436 exact split recheck reports `proposal_count=430` and
  `safe_for_batch_pg_package_count=430`. The largest remaining exact family is
  `xmage_creature_dies_create_tokens` with `24` cards, followed by
  `xmage_dynamic_count_damage_spell`,
  `xmage_permanent_simple_activated_library_search_to_battlefield`, and
  `xmage_static_filtered_evasion_creature`, with `21` cards each.

## 2026-07-04 PG437 Creature Dies Create Tokens Closure

- Closed the exact XMage creature dies create-creature-tokens family as
  ManaLoom scope `xmage_creature_dies_create_tokens_v1`.
- The selected package accepted only creature permanents with
  `DiesSourceTriggeredAbility` plus a single fixed `CreateTokenEffect`, no
  condition class, no target class, fixed token count, and Oracle/XMage
  agreement on token description, power/toughness, color, artifact flag,
  subtype, and supported token keywords. Conditional death triggers, dynamic
  token counts, non-creature tokens, unsupported token keywords, and multiple
  distinct token bodies remain blockers.
- The batch covers `24` cards creating fixed creature tokens on death,
  including artifact creature tokens, flying/lifelink/reach/trample token
  keywords, colorless tokens, multicolor tokens, and count-two token variants.
- Focused mapper/runtime tests covered dies-token scope extraction, blockers
  for non-creature/dynamic/conditional token sources, graveyard movement
  triggering, token creation, event emission, and logical rule-key retention.
  PG437 reused existing mapper/runtime support and performed no code mutation.
  The focused test lane passed `718` tests.
- The PostgreSQL package promoted `24` cards. Precheck found `24` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `24/24` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4141` PostgreSQL runtime rows, wrote `4133` SQLite runtime
  rows, and exported `4108` canonical fallback rows.
- PG437 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `24` selected cards. Generic
  battle scenario count remained `0`; actual dies-token behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26745`, `xmage_authoritative_source_count=26431`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26431`. This is an exact
  reduction of `24` from the post-PG436 queue.
- The post-PG437 exact split recheck reports `proposal_count=406` and
  `safe_for_batch_pg_package_count=406`. The largest remaining exact families
  are `xmage_dynamic_count_damage_spell`,
  `xmage_permanent_simple_activated_library_search_to_battlefield`, and
  `xmage_static_filtered_evasion_creature`, with `21` cards each.

## 2026-07-04 PG438 Static Filtered Evasion Closure

- Closed the exact XMage static filtered blocker-legality evasion family as
  ManaLoom scope `xmage_static_filtered_evasion_creature_v1`.
- The selected package accepted only creature permanents with
  `SimpleEvasionAbility` plus `CantBeBlockedByCreaturesSourceEffect`, no
  target class, no condition class, and Oracle/XMage agreement on whether the
  creature cannot be blocked by matching blockers or can be blocked only by
  matching blockers. Supported filters include color, artifact, token, power
  comparison, and subtype. Source/Oracle mismatches and unsupported phrasing
  remain blockers.
- The batch covers `21` cards with static blocker restrictions, including
  "can't be blocked by" and "can be blocked only by" variants for colors,
  artifacts, tokens, subtypes, and power thresholds.
- Focused mapper/runtime tests covered Oracle/source reconciliation, color,
  artifact, power, subtype and token filter parsing, legal blocker rejection,
  and allowed-blocker-only logic. PG438 reused existing mapper/runtime support
  and performed no code mutation. The focused test lane passed `718` tests.
- The PostgreSQL package promoted `21` cards. Precheck found `21` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `21/21` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4162` PostgreSQL runtime rows, wrote `4154` SQLite runtime
  rows, and exported `4129` canonical fallback rows.
- PG438 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `21` selected cards. Generic
  battle scenario count remained `0`; actual blocker-legality behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26724`, `xmage_authoritative_source_count=26410`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26410`. This is an exact
  reduction of `21` from the post-PG437 queue.
- The post-PG438 exact split recheck reports `proposal_count=385` and
  `safe_for_batch_pg_package_count=385`. The largest remaining exact families
  are `xmage_dynamic_count_damage_spell` and
  `xmage_permanent_simple_activated_library_search_to_battlefield`, with `21`
  cards each, followed by `xmage_creature_etb_library_search_to_hand` with
  `19` cards.

## 2026-07-04 PG439 Dynamic Count Damage Closure

- Closed the exact XMage dynamic-count direct-damage spell family as ManaLoom
  scope `xmage_dynamic_count_damage_spell_v1`.
- The selected package accepted only instant/sorcery one-shot
  `DamageTargetEffect` cards where Oracle and XMage agree on target scope,
  target constraints, and the dynamic amount source. Supported amount sources
  include battlefield permanent counts, domain basic land type count, and
  controller hand count, with fixed base-plus-count variants where present.
  Composite counts, X-cost variants, unsupported filters, unsupported targets,
  additional costs, and source/Oracle mismatches remain blockers.
- The batch covers `21` cards, including count-by-controlled artifacts,
  Equipment, creatures, attacking creatures, lands, Mountains, Goblins,
  domain, hand size, and fixed base plus count variants.
- Focused mapper/runtime tests covered dynamic battlefield count damage,
  attacking-creature count, domain damage, controller hand-count damage,
  target constraints, blocker lanes for composite/X-cost variants, and
  source/Oracle reconciliation. PG439 reused existing mapper/runtime support
  and performed no code mutation. The focused test lane passed `718` tests.
- The PostgreSQL package promoted `21` cards. Precheck found `21` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `21/21` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4183` PostgreSQL runtime rows, wrote `4175` SQLite runtime
  rows, and exported `4150` canonical fallback rows.
- PG439 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `21` selected cards. Generic
  battle scenario count remained `0`; actual dynamic damage behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26703`, `xmage_authoritative_source_count=26389`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26389`. This is an exact
  reduction of `21` from the post-PG438 queue.
- The post-PG439 exact split recheck reports `proposal_count=364` and
  `safe_for_batch_pg_package_count=364`. The largest remaining exact family is
  `xmage_permanent_simple_activated_library_search_to_battlefield` with `21`
  cards, followed by `xmage_creature_etb_library_search_to_hand` with `19`
  cards and `xmage_static_flying_can_block_only_flying_creature` with `18`
  cards.

## 2026-07-04 PG440 Activated Tutor To Battlefield Closure

- Closed the exact XMage permanent simple activated library-search-to-battlefield
  family as ManaLoom scope
  `xmage_permanent_simple_activated_library_search_to_battlefield_v1`.
- The selected package accepted only permanents with `SimpleActivatedAbility`
  plus `SearchLibraryPutInPlayEffect`, fixed activation cost, supported
  tap/sacrifice requirements, battlefield destination, and Oracle/XMage
  agreement on target, count, enter-tapped flag, and constraints. Supported
  constraints include basic land, Forest, target names, subtype, card type, and
  mana-value ceiling. Non-simple Oracle text, unsupported activation costs,
  ambiguous targets, and source/Oracle mismatches remain blockers.
- The batch covers `21` cards, including Rebel/Mercenary chain tutors, Goblin,
  Merfolk and Elf creature tutors, named-card tutors, basic land ramp,
  Forest-only ramp, count-two land ramp, and any-permanent battlefield tutor.
- Focused mapper/runtime tests covered activated tutor extraction, mana/tap
  payment, summoning-sick tap refusal, sacrifice-source handling, enters-tapped
  handling, subtype and mana-value constraints, count-two land movement, and
  event/logical-key emission. PG440 reused existing mapper/runtime support and
  performed no code mutation. The focused test lane passed `718` tests.
- The PostgreSQL package promoted `21` cards. Precheck found `21` target rows,
  `0` missing targets, `0` existing expected rows, and `2` shadow rows to
  deprecate; apply/postcheck verified `21/21` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `2` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4204` PostgreSQL runtime rows, wrote `4196` SQLite runtime
  rows, and exported `4171` canonical fallback rows.
- PG440 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `21` selected cards. Generic
  battle scenario count remained `0`; actual activated tutor behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26682`, `xmage_authoritative_source_count=26368`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26368`. This is an exact
  reduction of `21` from the post-PG439 queue.
- The post-PG440 exact split recheck reports `proposal_count=343` and
  `safe_for_batch_pg_package_count=343`. The largest remaining exact family is
  `xmage_creature_etb_library_search_to_hand` with `19` cards, followed by
  `xmage_static_flying_can_block_only_flying_creature` with `18` cards and
  `xmage_simple_mana_source_with_activated_draw` with `17` cards.

## 2026-07-04 PG441 Creature ETB Tutor To Hand Closure

- Closed the exact XMage creature enters-the-battlefield library-search-to-hand
  family as ManaLoom scope
  `xmage_creature_etb_library_search_to_hand_v1`.
- The selected package accepted creatures with
  `EntersBattlefieldTriggeredAbility` plus `SearchLibraryPutInHandEffect`,
  fixed tutor count, hand destination, and Oracle/XMage agreement on target
  kind, name/subtype/card-type/mana-value constraints, and optional "up to"
  count. Supported targets include basic land, basic land or Gate, named card,
  Goblin/Aura/Equipment/Vehicle subtypes, low-mana-value creature cards, and
  exact artifact mana-value windows. Oracle/source count mismatches, unsupported
  target filters, non-simple ETB text, and subtype mismatches remain blockers.
- The batch covers `19` cards: Borderland Ranger, Civic Wayfinder, Daru
  Cavalier, Deadeye Quartermaster, Environmental Scientist, Farfinder,
  Gatecreeper Vine, Goblin Matron, Heliod's Pilgrim, Howling Wolf, Nesting Wurm,
  Ranger of Eos, Rune-Scarred Demon, Screaming Seahawk, Squadron Hawk, Sylvan
  Ranger, Totem-Guide Hartebeest, Transit Mage, and Tribute Mage.
- Focused mapper/runtime tests covered the exact-scope split and runtime
  support already present for ETB tutor-to-hand cards; PG441 performed no code
  mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `19` cards. Precheck found `19` target rows,
  `0` missing targets, `0` existing expected rows, and `6` shadow rows to
  deprecate; apply/postcheck verified `19/19` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `6` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4223` PostgreSQL runtime rows, wrote `4215` SQLite runtime
  rows, and exported `4190` canonical fallback rows.
- PG441 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `19` selected cards. Generic
  battle scenario count remained `0`; actual ETB tutor behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26663`, `xmage_authoritative_source_count=26349`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26349`. This is an exact
  reduction of `19` from the post-PG440 queue.
- The post-PG441 exact split recheck reports `proposal_count=324` and
  `safe_for_batch_pg_package_count=324`. The largest remaining exact family is
  `xmage_static_flying_can_block_only_flying_creature` with `18` cards,
  followed by `xmage_simple_mana_source_with_activated_draw` with `17` cards,
  `xmage_permanent_simple_activated_draw_discard` with `15` cards,
  `xmage_dynamic_count_boost_target_creature_until_eot_spell` with `14` cards,
  and `xmage_library_search_spell` with `14` cards.

## 2026-07-04 PG442 Flying Can Block Only Flying Closure

- Closed the exact XMage static flying/can-block-only-flying creature family as
  ManaLoom scope `xmage_static_flying_can_block_only_flying_creature_v1`.
- The selected package accepted creatures whose local XMage class exposes the
  narrow no-effect-class static keyword signature with flying plus the block
  restriction that the creature can block only creatures with flying. The scope
  excludes noncreatures, broader evasion restrictions, protection mixtures, and
  any card whose Oracle/XMage text does not match this exact static combat
  restriction.
- The batch covers `18` cards: Belbe's Percher, Cloud Djinn, Cloud Dragon,
  Cloud Elemental, Cloud Pirates, Cloud Spirit, Cloud Sprite, Hoverguard
  Observer, Long-Finned Skywhale, Rishadan Airship, Scrapskin Drake, Skywinder
  Drake, Stratozeppelid, Stronghold Zeppelin, Tattered Haunter, Vaporkin,
  Wanderlight Spirit, and Welkin Tern.
- Focused mapper/runtime tests covered the exact-scope split and static combat
  restriction support already present for this family; PG442 performed no code
  mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `18` cards. Precheck found `18` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `18/18` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4241` PostgreSQL runtime rows, wrote `4233` SQLite runtime
  rows, and exported `4208` canonical fallback rows.
- PG442 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `18` selected cards. Generic
  battle scenario count remained `0`; actual combat restriction behavior
  remains covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26645`, `xmage_authoritative_source_count=26331`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26331`. This is an exact
  reduction of `18` from the post-PG441 queue.
- The post-PG442 exact split recheck reports `proposal_count=306` and
  `safe_for_batch_pg_package_count=306`. The largest remaining exact family is
  `xmage_simple_mana_source_with_activated_draw` with `17` cards, followed by
  `xmage_permanent_simple_activated_draw_discard` with `15` cards,
  `xmage_dynamic_count_boost_target_creature_until_eot_spell` with `14` cards,
  `xmage_library_search_spell` with `14` cards, and
  `xmage_self_sacrifice_mana_source_permanent` with `13` cards.

## 2026-07-04 PG443 Mana Source With Activated Draw Closure

- Closed the exact XMage simple mana-source with activated draw family as
  ManaLoom scope `xmage_simple_tap_mana_source_with_activated_draw_v1`.
- The selected package accepted permanents with a simple tap mana ability plus a
  separate activated draw ability whose cost and effect are supported by the
  ManaLoom runtime. The scope covers mana rocks/banners/cluestones and Heart
  Warden-style mana creatures where XMage/Oracle agree on mana production and
  the activated draw/sacrifice behavior. Unsupported compound mana-source
  abilities, unusual payment costs, or non-simple draw text remain blockers.
- The batch covers `17` cards: Abzan Banner, Azorius Cluestone, Boros
  Cluestone, Dimir Cluestone, Golgari Cluestone, Gruul Cluestone, Heart Warden,
  Izzet Cluestone, Jeskai Banner, Letter of Acceptance, Mardu Banner, Orzhov
  Cluestone, Rakdos Cluestone, Selesnya Cluestone, Simic Cluestone, Sultai
  Banner, and Temur Banner.
- Focused mapper/runtime tests covered the exact-scope split and static/runtime
  support already present for tap mana plus activated draw; PG443 performed no
  code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `17` cards. Precheck found `17` target rows,
  `0` missing targets, `0` existing expected rows, and `2` shadow rows to
  deprecate; apply/postcheck verified `17/17` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `2` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4258` PostgreSQL runtime rows, wrote `4250` SQLite runtime
  rows, and exported `4225` canonical fallback rows.
- PG443 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `17` selected cards. Generic
  battle scenario count remained `0`; mana/draw behavior remains covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26628`, `xmage_authoritative_source_count=26314`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26314`. This is an exact
  reduction of `17` from the post-PG442 queue.
- The post-PG443 exact split recheck reports `proposal_count=289` and
  `safe_for_batch_pg_package_count=289`. The largest remaining exact family is
  `xmage_permanent_simple_activated_draw_discard` with `15` cards, followed by
  `xmage_dynamic_count_boost_target_creature_until_eot_spell` with `14` cards,
  `xmage_library_search_spell` with `14` cards,
  `xmage_self_sacrifice_mana_source_permanent` with `13` cards, and
  `xmage_static_self_cant_block_creature` with `13` cards.

## 2026-07-04 PG444 Activated Draw Discard Closure

- Closed the exact XMage permanent activated draw/discard family as ManaLoom
  scope `xmage_permanent_simple_activated_draw_discard_v1`.
- The selected package accepted local XMage
  `DrawDiscardControllerEffect + SimpleActivatedAbility` permanents whose
  Oracle text is a supported activated draw/discard pattern. Unsupported costs,
  non-simple activation shapes, or compound draw/discard text remain blocked by
  the splitter instead of becoming executable rows.
- The batch covers `15` cards: Bloodfire Mentor, Captain of Umbar, Dragonborn
  Looter, Emmessi Tome, Erratic Visionary, Facet Reader, Hapless Researcher,
  Jalum Tome, Magus of the Bazaar, Merfolk Looter, Research Assistant,
  Soothsayer Adept, Teferi's Protege, Thought Courier, and Unfulfilled
  Desires.
- Focused mapper/runtime tests covered the exact-scope split and runtime
  support already present for permanent activated draw/discard; PG444 performed
  no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `15` cards. Precheck found `15` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `15/15` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4273` PostgreSQL runtime rows, wrote `4265` SQLite runtime
  rows, and exported `4240` canonical fallback rows.
- PG444 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `15` selected cards. Generic
  battle scenario count remained `0`; activated draw/discard behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26613`, `xmage_authoritative_source_count=26299`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26299`. This is an exact
  reduction of `15` from the post-PG443 queue.
- The post-PG444 exact split recheck reports `proposal_count=274` and
  `safe_for_batch_pg_package_count=274`. The largest remaining exact families
  are `xmage_dynamic_count_boost_target_creature_until_eot_spell` and
  `xmage_library_search_spell` with `14` cards each, followed by
  `xmage_self_sacrifice_mana_source_permanent` and
  `xmage_static_self_cant_block_creature` with `13` cards each, and
  `xmage_fixed_draw_spell` with `12` cards.

## 2026-07-04 PG445 Dynamic Count Boost Closure

- Closed the exact XMage dynamic target-creature boost family as ManaLoom
  scope `xmage_dynamic_count_boost_target_creature_until_eot_spell_v1`.
- The selected package accepted local XMage `BoostTargetEffect` spells where a
  target creature gets a dynamic stat modifier until end of turn and the amount
  is calculated from a runtime-supported count source: controller battlefield
  permanents, controller hand size, domain basic land types, or all-battlefield
  subtype counts. Unsupported filters, compound targets, mixed count sources,
  or extra costs remain blocked by the splitter instead of becoming executable
  rows.
- The batch covers `14` cards: Defile, Desert's Due, Drag Down, Feeding Frenzy,
  Gaea's Might, Hunger of the Nim, Inner Calm, Outer Strength, Irradiate, Might
  of Alara, Might of the Masses, Nightmarish End, Strength of Cedars, Warped
  Physique, and Wirewood Pride.
- Focused mapper/runtime tests covered the exact-scope split and runtime
  support for battlefield-count, hand-count, domain, subtype-count, negative,
  positive, and mixed-stat dynamic boosts; PG445 performed no code mutation.
  The focused test lane passed `718` checks.
- The PostgreSQL package promoted `14` cards. Precheck found `14` target rows,
  `0` missing targets, `0` existing expected rows, and `2` shadow rows to
  deprecate; apply/postcheck verified `14/14` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `2` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4287` PostgreSQL runtime rows, wrote `4279` SQLite runtime
  rows, and exported `4254` canonical fallback rows.
- PG445 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `14` selected cards. Generic
  battle scenario count remained `0`; dynamic boost behavior remains covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26599`, `xmage_authoritative_source_count=26285`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26285`. This is an exact
  reduction of `14` from the post-PG444 queue.
- The post-PG445 exact split recheck reports `proposal_count=260` and
  `safe_for_batch_pg_package_count=260`. The largest remaining exact family is
  `xmage_library_search_spell` with `14` cards, followed by
  `xmage_self_sacrifice_mana_source_permanent` and
  `xmage_static_self_cant_block_creature` with `13` cards each, and
  `xmage_fixed_damage_exile_if_dies_spell` and `xmage_fixed_draw_spell` with
  `12` cards each.

## 2026-07-04 PG446 Library Search Closure

- Closed the exact XMage spell tutor-to-hand family as ManaLoom scope
  `xmage_library_search_to_hand_spell_v1`.
- The selected package accepted local XMage library-search spells whose source
  and Oracle text agree on a supported tutor-to-hand filter. This closes narrow
  tutor rows while leaving broader `xmage_library_search_variant` neighbors
  blocked until their filters, destinations, or special costs have exact runtime
  scopes.
- The batch covers `14` cards: Call the Gatewatch, Cateran Summons, Diabolic
  Tutor, Eerie Procession, Ignite the Beacon, Merchant Scroll, Open the Armory,
  Plea for Guidance, Safewright Quest, Sarkhan's Triumph, Seek the Horizon,
  Solve the Equation, Time of Need, and Trapmaker's Snare.
- Focused mapper/runtime tests covered exact tutor-to-hand split behavior,
  subtype/land-subtype/source-subtype preservation, dynamic-land-count
  blocking, and runtime retrieval paths; PG446 performed no code mutation. The
  focused test lane passed `718` checks.
- The PostgreSQL package promoted `14` cards. Precheck found `14` target rows,
  `0` missing targets, `0` existing expected rows, and `8` shadow rows to
  deprecate; apply/postcheck verified `14/14` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `8` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4301` PostgreSQL runtime rows, wrote `4293` SQLite runtime
  rows, and exported `4268` canonical fallback rows.
- PG446 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `14` selected cards. Generic
  battle scenario count remained `0`; tutor-to-hand behavior remains covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26585`, `xmage_authoritative_source_count=26271`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26271`. This is an exact
  reduction of `14` from the post-PG445 queue.
- The post-PG446 exact split recheck reports `proposal_count=246` and
  `safe_for_batch_pg_package_count=246`. The largest remaining exact families
  are `xmage_self_sacrifice_mana_source_permanent` and
  `xmage_static_self_cant_block_creature` with `13` cards each, followed by
  `xmage_fixed_damage_exile_if_dies_spell` and `xmage_fixed_draw_spell` with
  `12` cards each, and `xmage_static_self_cant_be_blocked_creature` with `11`
  cards.

## 2026-07-04 PG447 Self-Sacrifice Mana Source Closure

- Closed the exact XMage self-sacrifice mana source family as ManaLoom scope
  `xmage_self_sacrifice_mana_source_permanent_v1`.
- The selected package accepted local XMage permanents whose simple activated
  mana ability sacrifices the source itself to produce fixed mana. Runtime
  behavior remains contextual: these sources are not refreshed automatically
  and are sacrificed only when the extra mana unlocks a material action.
- The batch covers `13` cards: Basal Thrull, Blood Pet, Blood Vassal, Catalyst
  Elemental, Coal Golem, Composite Golem, Crosis's Attendant, Darigaaz's
  Attendant, Dromar's Attendant, Morgue Toad, Rith's Attendant, Satyr Hedonist,
  and Treva's Attendant.
- Focused mapper/runtime tests covered simple creature and artifact sacrifice
  mana sources, tap/sacrifice costs, composite mana constructor parsing, source
  constructor color order, multiple-mana-ability blocking, and contextual-only
  activation; PG447 performed no code mutation. The focused test lane passed
  `718` checks.
- The PostgreSQL package promoted `13` cards. Precheck found `13` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `13/13` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4314` PostgreSQL runtime rows, wrote `4306` SQLite runtime
  rows, and exported `4281` canonical fallback rows.
- PG447 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `13` selected cards. Generic
  battle scenario count remained `0`; self-sacrifice mana behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26572`, `xmage_authoritative_source_count=26258`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26258`. This is an exact
  reduction of `13` from the post-PG446 queue.
- The post-PG447 exact split recheck reports `proposal_count=233` and
  `safe_for_batch_pg_package_count=233`. The largest remaining exact family is
  `xmage_static_self_cant_block_creature` with `13` cards, followed by
  `xmage_fixed_damage_exile_if_dies_spell` and `xmage_fixed_draw_spell` with
  `12` cards each, and `xmage_static_self_cant_be_blocked_creature` and
  `xmage_static_self_protection_from_card_types_creature` with `11` cards each.

## 2026-07-04 PG448 Static Can't Block Closure

- Closed the exact XMage static self can't-block creature family as ManaLoom
  scope `xmage_static_self_cant_block_creature_v1`.
- The selected package accepted local XMage creatures with exact
  `CantBlockAbility` source and Oracle text matching the self restriction
  "can't block". Runtime behavior excludes those creatures from blocker
  assignment while leaving other legal blockers available.
- The batch covers `13` cards: Ashenmoor Gouger, Craven Giant, Craven Knight,
  Goblin Raider, Hulking Cyclops, Hulking Goblin, Hulking Ogre, Jungle Lion,
  Ogre Taskmaster, Scavenging Scarab, Spineless Thug, Yellow Scarves Troops,
  and Young Wei Recruits.
- Focused mapper/runtime tests covered exact static source selection,
  non-exact source blocking, and blocker-assignment exclusion; PG448 performed
  no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `13` cards. Precheck found `13` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `13/13` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4327` PostgreSQL runtime rows, wrote `4319` SQLite runtime
  rows, and exported `4294` canonical fallback rows.
- PG448 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `13` selected cards. Generic
  battle scenario count remained `0`; static can't-block behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface, legacy contamination, and
  PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26559`, `xmage_authoritative_source_count=26245`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26245`. This is an exact
  reduction of `13` from the post-PG447 queue.
- The post-PG448 exact split recheck reports `proposal_count=220` and
  `safe_for_batch_pg_package_count=220`. The largest remaining exact families
  are `xmage_fixed_damage_exile_if_dies_spell` and `xmage_fixed_draw_spell`
  with `12` cards each, followed by
  `xmage_static_self_cant_be_blocked_creature` and
  `xmage_static_self_protection_from_card_types_creature` with `11` cards each,
  and `xmage_creature_attack_target_keyword_until_eot` with `10` cards.

## 2026-07-04 PG449 Damage Exile If Dies Closure

- Closed the exact XMage fixed damage plus exile-if-dies spell family as
  ManaLoom scope `xmage_fixed_damage_target_exile_if_dies_spell_v1`.
- The selected package accepted local XMage spells whose source combines
  `DamageTargetEffect` with `ExileTargetIfDiesEffect`, with Oracle/source
  agreement on fixed damage, supported target class, and exile-if-dies
  replacement behavior.
- The batch covers `12` cards: Bot Bashing Time, Elspeth's Smite, Fanged
  Flames, Feed the Flames, Flame-Blessed Bolt, Lava Coil, Magma Spray,
  Obliterating Bolt, Puncturing Blow, Reduce to Ashes, Scorching Dragonfire,
  and Scorchmark.
- Focused mapper/runtime tests covered exact damage plus exile-if-dies source
  selection, creature-or-planeswalker target support, additional-cost blocking,
  activated-permanent blocking, and lethal-damage exile behavior; PG449
  performed no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `12` cards. Precheck found `12` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `12/12` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4339` PostgreSQL runtime rows, wrote `4331` SQLite runtime
  rows, and exported `4306` canonical fallback rows.
- PG449 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `12` selected cards. Generic
  battle scenario count remained `0`; damage plus exile-if-dies behavior
  remains covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26547`, `xmage_authoritative_source_count=26233`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26233`. This is an exact
  reduction of `12` from the post-PG448 queue.
- The post-PG449 exact split recheck reports `proposal_count=208` and
  `safe_for_batch_pg_package_count=208`. The largest remaining exact families
  are `xmage_fixed_draw_spell` with `12` cards,
  `xmage_static_self_cant_be_blocked_creature` and
  `xmage_static_self_protection_from_card_types_creature` with `11` cards each,
  followed by `xmage_creature_attack_target_keyword_until_eot` and
  `xmage_fixed_damage_spell` with `10` cards each.

## 2026-07-04 PG450 Fixed Draw Spell Closure

- Closed the exact XMage fixed source-controller draw spell family as ManaLoom
  scope `xmage_fixed_source_controller_draw_spell_v1`.
- The selected package accepted local XMage spells whose source uses
  `DrawCardSourceControllerEffect`, including supported additional costs for
  sacrificing a creature, sacrificing an artifact or creature, discarding a
  card, or discarding a land.
- The batch covers `12` cards: Altar's Reap, Blood Divination, Corrupted
  Conviction, Costly Plunder, Eviscerator's Insight, Magmatic Insight, Morbid
  Curiosity, Skulltap, Tormenting Voice, Village Rites, Vivisection, and Wild
  Guess.
- Focused mapper/runtime tests covered fixed source-controller draw, target
  player draw separation, supported sacrifice/discard costs, unsupported
  additional-cost blocking, and draw resolution. PG450 performed no code
  mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `12` cards. Precheck found `12` target rows,
  `0` missing targets, `0` existing expected rows, and `8` shadow rows to
  deprecate. Those shadow rows were old `generated`, `needs_review`,
  `review_only` rows for Corrupted Conviction, Magmatic Insight, Tormenting
  Voice, and Village Rites, without Oracle hashes or additional-cost modeling.
  Apply/postcheck verified `12/12` promoted rows as `verified`/`auto` with
  Oracle hashes. The apply backup captured `8` rows; `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4351` PostgreSQL runtime rows, wrote `4343` SQLite runtime
  rows, and exported `4318` canonical fallback rows.
- PG450 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `12` selected cards. Generic
  battle scenario count remained `0`; draw count and supported additional-cost
  behavior remain covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26535`, `xmage_authoritative_source_count=26221`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26221`. This is an exact
  reduction of `12` from the post-PG449 queue.
- The post-PG450 exact split recheck reports `proposal_count=196` and
  `safe_for_batch_pg_package_count=196`. The largest remaining exact families
  are `xmage_static_self_cant_be_blocked_creature` and
  `xmage_static_self_protection_from_card_types_creature` with `11` cards each,
  followed by `xmage_creature_attack_target_keyword_until_eot`,
  `xmage_fixed_damage_spell`, and `xmage_static_self_horsemanship_creature`
  with `10` cards each.

## 2026-07-04 PG451 Static Can't Be Blocked Closure

- Closed the exact XMage static self can't-be-blocked creature family as
  ManaLoom scope `xmage_static_self_cant_be_blocked_creature_v1`.
- The selected package accepted local XMage creatures with exact
  `CantBeBlockedSourceAbility` source and Oracle text matching the self
  restriction that the creature cannot be blocked.
- The batch covers `11` cards: Covert Operative, Jhessian Infiltrator, Latch
  Seeker, Metathran Soldier, Mist-Cloaked Herald, Phantom Ninja, Phantom
  Warrior, Slither Blade, Talas Warrior, Tidal Kraken, and Triton Shorestalker.
- Focused mapper/runtime tests covered exact static source selection,
  filtered-evasion blocking, and blocker-assignment exclusion; PG451 performed
  no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `11` cards. Precheck found `11` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `11/11` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4362` PostgreSQL runtime rows, wrote `4354` SQLite runtime
  rows, and exported `4329` canonical fallback rows.
- PG451 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `11` selected cards. Generic
  battle scenario count remained `0`; unblockable combat assignment behavior
  remains covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26524`, `xmage_authoritative_source_count=26210`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26210`. This is an exact
  reduction of `11` from the post-PG450 queue.
- The post-PG451 exact split recheck reports `proposal_count=185` and
  `safe_for_batch_pg_package_count=185`. The largest remaining exact family is
  `xmage_static_self_protection_from_card_types_creature` with `11` cards,
  followed by `xmage_creature_attack_target_keyword_until_eot`,
  `xmage_fixed_damage_spell`, and `xmage_static_self_horsemanship_creature`
  with `10` cards each, and `xmage_fixed_draw_discard_spell` with `9` cards.

## 2026-07-04 PG452 Static Protection Card Types Closure

- Closed the exact XMage static self protection-from-card-type creature family
  as ManaLoom scope
  `xmage_static_self_protection_from_card_types_creature_v1`.
- The selected package accepted local XMage creatures with exact static
  `ProtectionAbility` source and Oracle/source agreement on protection from a
  card type: artifact, enchantment, creature, or land.
- The batch covers `11` cards: Angelic Curator, Azorius First-Wing, Beloved
  Chaplain, Commander Eesha, Horizon Drake, Nacatl Savage, Needlebug,
  Tel-Jilad Archers, Tel-Jilad Chosen, Tel-Jilad Outrider, and Yavimaya Scion.
- Focused mapper/runtime tests covered exact card-type protection extraction
  and target/combat legality for supported protection scopes; PG452 performed
  no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `11` cards. Precheck found `11` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `11/11` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `11` rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve the exact
  `protection_from_card_types` parameter for each card.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4373` PostgreSQL runtime rows, wrote `4365` SQLite runtime
  rows, and exported `4340` canonical fallback rows.
- PG452 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `11` selected cards. Generic
  battle scenario count remained `0`; protection card-type behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26513`, `xmage_authoritative_source_count=26199`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26199`. This is an exact
  reduction of `11` from the post-PG451 queue.
- The post-PG452 exact split recheck reports `proposal_count=174` and
  `safe_for_batch_pg_package_count=174`. The largest remaining exact families
  are `xmage_creature_attack_target_keyword_until_eot`,
  `xmage_fixed_damage_spell`, and `xmage_static_self_horsemanship_creature`
  with `10` cards each, followed by `xmage_fixed_draw_discard_spell` and
  `xmage_fixed_scry_draw_card_spell` with `9` cards each.

## 2026-07-04 PG453 Attack Target Keyword Closure

- Closed the exact XMage creature attack-trigger keyword family as ManaLoom
  scope `xmage_creature_attack_grant_keyword_target_creature_until_eot_v1`.
- The selected package accepted local XMage creatures whose source grants
  target attacking creature flying until end of turn when the source attacks,
  with Oracle/source agreement on target-controller restrictions.
- The batch covers `10` cards: Aerial Guide, Chasm Drake, Garrison Griffin,
  Heavenly Qilin, Kinsbaile Balloonist, Majestic Heliopterus, Pegasus Courser,
  Roc Charger, Trained Condor, and Trusted Pegasus.
- Focused mapper/runtime tests covered exact attack-trigger keyword extraction,
  legal target selection, replay evidence, and until-end-of-turn cleanup; PG453
  performed no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `10` cards. Precheck found `10` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `10/10` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `10` rows are
  `verified`/`auto`/`curated`, have Oracle hashes, set
  `attack_trigger_target_keyword=true`, and grant `flying` until end of turn.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4383` PostgreSQL runtime rows, wrote `4375` SQLite runtime
  rows, and exported `4350` canonical fallback rows.
- PG453 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `10` selected cards. Generic
  battle scenario count remained `0`; attack-trigger keyword behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26503`, `xmage_authoritative_source_count=26189`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26189`. This is an exact
  reduction of `10` from the post-PG452 queue.
- The post-PG453 exact split recheck reports `proposal_count=164` and
  `safe_for_batch_pg_package_count=164`. The largest remaining exact families
  are `xmage_fixed_damage_spell` and
  `xmage_static_self_horsemanship_creature` with `10` cards each, followed by
  `xmage_fixed_draw_discard_spell` and `xmage_fixed_scry_draw_card_spell` with
  `9` cards each, and `xmage_creature_dies_fixed_damage_target` with `8`
  cards.

## 2026-07-05 PG454 Fixed Damage Closure

- Closed the exact XMage fixed damage spell family as ManaLoom scope
  `xmage_fixed_damage_target_spell_v1`.
- The selected package accepted local XMage one-shot damage spells with exact
  fixed `DamageTargetEffect`, supported target constraints, and supported
  additional costs: discard a card, sacrifice a creature, sacrifice a land, or
  sacrifice an artifact or creature.
- The batch covers `10` cards: Acceptable Losses, Artillerize, Collateral
  Damage, Fiery Conclusion, Improvised Club, Magma Rift, Reckless Abandon,
  Shard Volley, Sonic Burst, and Sonic Seizure.
- Focused mapper/runtime tests covered fixed damage, supported additional-cost
  payment, unsupported additional-cost blocking, target constraints, and damage
  resolution; PG454 performed no code mutation. The focused test lane passed
  `718` checks.
- The PostgreSQL package promoted `10` cards. Precheck found `10` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `10/10` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `10` rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve exact damage,
  supported target constraints, and supported additional costs.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4393` PostgreSQL runtime rows, wrote `4385` SQLite runtime
  rows, and exported `4360` canonical fallback rows.
- PG454 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `10` selected cards. Generic
  battle scenario count remained `0`; fixed-damage behavior remains covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26493`, `xmage_authoritative_source_count=26179`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26179`. This is an exact
  reduction of `10` from the post-PG453 queue.
- The post-PG454 exact split recheck reports `proposal_count=154` and
  `safe_for_batch_pg_package_count=154`. The largest remaining exact family is
  `xmage_static_self_horsemanship_creature` with `10` cards, followed by
  `xmage_fixed_draw_discard_spell` and `xmage_fixed_scry_draw_card_spell` with
  `9` cards each, and `xmage_creature_dies_fixed_damage_target` and
  `xmage_destroy_target_scry_spell` with `8` cards each.

## 2026-07-05 PG455 Static Horsemanship Closure

- Closed the exact XMage static self horsemanship creature family as ManaLoom
  scope `xmage_static_self_horsemanship_creature_v1`.
- The selected package accepted local XMage creatures with exact
  `HorsemanshipAbility.getInstance()` source and exact Oracle text
  `Horsemanship`.
- The batch covers `10` cards: Barbarian General, Lady Zhurong, Warrior Queen,
  Lu Meng, Wu General, Shu Cavalry, Shu Elite Companions, Wei Elite Companions,
  Wei Scout, Wei Strike Force, Wu Elite Cavalry, and Wu Light Cavalry.
- Focused mapper/runtime tests covered exact horsemanship extraction and
  blocker legality where only creatures with horsemanship can block
  horsemanship attackers; PG455 performed no code mutation. The focused test
  lane passed `718` checks.
- The PostgreSQL package promoted `10` cards. Precheck found `10` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `10/10` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `10` rows are
  `verified`/`auto`/`curated`, have Oracle hashes, set
  `static_effect=self_horsemanship`, and expose `keywords=["horsemanship"]`
  plus `horsemanship=true`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4403` PostgreSQL runtime rows, wrote `4395` SQLite runtime
  rows, and exported `4370` canonical fallback rows.
- PG455 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `10` selected cards. Generic
  battle scenario count remained `0`; horsemanship blocker legality remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26483`, `xmage_authoritative_source_count=26169`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26169`. This is an exact
  reduction of `10` from the post-PG454 queue.
- The post-PG455 exact split recheck reports `proposal_count=144` and
  `safe_for_batch_pg_package_count=144`. The largest remaining exact families
  are `xmage_fixed_draw_discard_spell` and
  `xmage_fixed_scry_draw_card_spell` with `9` cards each, followed by
  `xmage_creature_dies_fixed_damage_target`,
  `xmage_destroy_target_scry_spell`, and `xmage_fixed_damage_scry_spell` with
  `8` cards each.

## 2026-07-05 PG456 Fixed Draw Discard Closure

- Closed the exact XMage fixed draw/discard instant-or-sorcery family as
  ManaLoom scope `xmage_fixed_draw_discard_spell_v1`.
- The selected package accepted local XMage spell sources whose executable
  effect is the fixed `DrawDiscardControllerEffect` lane and whose Oracle text
  agrees on draw count, discard count, and operation order.
- The batch covers `9` cards: Ancestral Reminiscence, Careful Study, Catalog,
  Enhanced Awareness, Prying Eyes, Rain of Revelation, Romantic Rendezvous,
  Sift, and Thoughtflare.
- Focused mapper/runtime tests covered draw-then-discard and
  discard-then-draw resolution, including hand/graveyard movement and event
  emission for `draw_discard_spell_resolved`; PG456 performed no code mutation.
  The focused test lane passed `718` checks.
- The PostgreSQL package promoted `9` cards. Precheck found `9` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `9/9` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `9` rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and expose complete
  draw/discard parameters. The selected counts are:
  Ancestral Reminiscence `draw=3 discard=1 draw_then_discard`, Careful Study
  `draw=2 discard=2 draw_then_discard`, Catalog
  `draw=2 discard=1 draw_then_discard`, Enhanced Awareness
  `draw=3 discard=1 draw_then_discard`, Prying Eyes
  `draw=4 discard=2 draw_then_discard`, Rain of Revelation
  `draw=3 discard=1 draw_then_discard`, Romantic Rendezvous
  `draw=2 discard=1 discard_then_draw`, Sift
  `draw=3 discard=1 draw_then_discard`, and Thoughtflare
  `draw=4 discard=2 draw_then_discard`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4412` PostgreSQL runtime rows, wrote `4404` SQLite runtime
  rows, and exported `4379` canonical fallback rows.
- PG456 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `9` selected cards. Generic
  battle scenario count remained `0`; draw/discard spell execution remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26474`, `xmage_authoritative_source_count=26160`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26160`. This is an exact
  reduction of `9` from the post-PG455 queue.
- The post-PG456 exact split recheck reports `proposal_count=135` and
  `safe_for_batch_pg_package_count=135`. The largest remaining exact families
  are `xmage_fixed_scry_draw_card_spell` with `9` cards, followed by
  `xmage_creature_dies_fixed_damage_target`,
  `xmage_destroy_target_scry_spell`, `xmage_fixed_damage_scry_spell`, and
  `xmage_static_self_protection_from_subtypes_creature` with `8` cards each.

## 2026-07-05 PG457 Fixed Scry Draw Closure

- Closed the exact XMage fixed scry/draw instant-or-sorcery family as ManaLoom
  scope `xmage_fixed_scry_and_draw_cards_spell_v1`.
- The selected package accepted local XMage spell sources whose executable
  behavior is fixed `ScryEffect` plus fixed
  `DrawCardSourceControllerEffect`, with Oracle/source agreement on scry count,
  draw count, and resolution order.
- The batch covers `9` cards: Behold the Multiverse, Deliberate, Foresee,
  Introduction to Prophecy, Opt, Preordain, Scour All Possibilities, Serum
  Visions, and Tamiyo's Epiphany.
- Focused mapper/runtime tests covered composite scry/draw resolution,
  top-library reordering, draw movement, and generated event evidence; PG457
  performed no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `9` cards. Precheck found `9` target rows,
  `0` missing targets, `0` existing expected rows, and `6` stale generated
  shadow rows to deprecate; apply/postcheck verified `9/9` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `6` rows;
  `failed_cards=[]`.
- The stale generated shadows were disabled as deprecated rows for Opt (`2`),
  Preordain (`2`), and Serum Visions (`2`), replacing older generated split
  rows with one curated executable composite rule per card.
- Direct PostgreSQL verification confirmed all `9` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and expose complete
  scry/draw parameters. The selected counts are:
  Behold the Multiverse `scry=2 draw=2 scry_then_draw`, Deliberate
  `scry=2 draw=1 scry_then_draw`, Foresee
  `scry=4 draw=2 scry_then_draw`, Introduction to Prophecy
  `scry=2 draw=1 scry_then_draw`, Opt
  `scry=1 draw=1 scry_then_draw`, Preordain
  `scry=2 draw=1 scry_then_draw`, Scour All Possibilities
  `scry=2 draw=1 scry_then_draw`, Serum Visions
  `scry=2 draw=1 draw_then_scry`, and Tamiyo's Epiphany
  `scry=4 draw=2 scry_then_draw`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4421` PostgreSQL runtime rows, wrote `4413` SQLite runtime
  rows, and exported `4388` canonical fallback rows.
- PG457 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `9` selected cards. Generic
  battle scenario count remained `0`; scry/draw spell execution remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26465`, `xmage_authoritative_source_count=26151`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26151`. This is an exact
  reduction of `9` from the post-PG456 queue.
- The post-PG457 exact split recheck reports `proposal_count=126` and
  `safe_for_batch_pg_package_count=126`. The largest remaining exact families
  are `xmage_creature_dies_fixed_damage_target`,
  `xmage_destroy_target_scry_spell`, `xmage_fixed_damage_scry_spell`,
  `xmage_fixed_draw_lose_life_spell`, and
  `xmage_static_self_protection_from_subtypes_creature` with `8` cards each.

## 2026-07-05 PG458 Fixed Draw Lose Life Closure

- Closed the exact XMage fixed draw/life-loss instant-or-sorcery family as
  ManaLoom scopes `xmage_fixed_controller_draw_lose_life_spell_v1` and
  `xmage_fixed_target_player_draw_lose_life_spell_v1`.
- The selected package accepted local XMage spell sources whose executable
  behavior is fixed card draw plus fixed life loss, split by whether the spell
  always affects its controller or targets a player.
- The batch covers `8` cards: Ambition's Cost, Ancient Craving, Blood Pact,
  Harrowing Journey, Night's Whisper, Painful Lesson, Sign in Blood, and
  Succumb to Temptation.
- Focused mapper/runtime tests covered controller draw/life-loss resolution
  and target-player resolution, including lethal opponent targeting;
  PG458 performed no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `8` cards. Precheck found `8` target rows,
  `0` missing targets, `0` existing expected rows, and `4` stale generated
  shadow rows to deprecate; apply/postcheck verified `8/8` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `4` rows;
  `failed_cards=[]`.
- The stale generated shadows were disabled as deprecated rows for Night's
  Whisper (`2`) and Sign in Blood (`2`), replacing older generated rows with
  one curated executable rule per card.
- Direct PostgreSQL verification confirmed all `8` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and expose complete
  draw/life-loss parameters. The selected counts are:
  Ambition's Cost `draw=3 life_loss=3 self`, Ancient Craving
  `draw=3 life_loss=3 self`, Blood Pact
  `draw=2 life_loss=2 target_player`, Harrowing Journey
  `draw=3 life_loss=3 target_player`, Night's Whisper
  `draw=2 life_loss=2 self`, Painful Lesson
  `draw=2 life_loss=2 target_player`, Sign in Blood
  `draw=2 life_loss=2 target_player`, and Succumb to Temptation
  `draw=2 life_loss=2 self`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4429` PostgreSQL runtime rows, wrote `4421` SQLite runtime
  rows, and exported `4396` canonical fallback rows.
- PG458 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `8` selected cards. Generic
  battle scenario count remained `0`; draw/life-loss spell execution remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26457`, `xmage_authoritative_source_count=26143`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26143`. This is an exact
  reduction of `8` from the post-PG457 queue.
- The post-PG458 exact split recheck reports `proposal_count=118` and
  `safe_for_batch_pg_package_count=118`. The largest remaining exact families
  are `xmage_creature_dies_fixed_damage_target`,
  `xmage_destroy_target_scry_spell`, `xmage_fixed_damage_scry_spell`, and
  `xmage_static_self_protection_from_subtypes_creature` with `8` cards each,
  followed by `xmage_creature_dies_gain_life`,
  `xmage_fixed_draw_spell_self_cost_reduction`, and
  `xmage_static_cast_spells_as_flash_permission` with `7` cards each.

## 2026-07-05 PG459 Creature Dies Fixed Damage Closure

- Closed the exact XMage creature dies fixed-damage triggered family as
  ManaLoom scope `xmage_creature_dies_fixed_damage_target_v1`.
- The selected package accepted local XMage creature sources whose executable
  behavior is a `DiesSourceTriggeredAbility` with fixed `DamageTargetEffect`,
  fixed damage amount, and supported target constraints.
- The batch covers `8` cards: Bogardan Firefiend, Careless Celebrant,
  Footlight Fiend, Goblin Arsonist, Mudbutton Torchrunner, Perilous Myr,
  Pitchburn Devils, and Pyre Spawn.
- Focused mapper/runtime tests covered resolving the dies damage trigger when
  the permanent moves to graveyard and not firing when the permanent is exiled;
  PG459 performed no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `8` cards. Precheck found `8` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `8/8` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `8` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve damage amount,
  target family, target constraints, and optionality. The selected parameters
  are: Bogardan Firefiend `2 to creature`, Careless Celebrant
  `2 to creature_or_planeswalker`, Footlight Fiend `1 to any_target`,
  Goblin Arsonist `1 to any_target optional`, Mudbutton Torchrunner
  `3 to any_target`, Perilous Myr `2 to any_target`, Pitchburn Devils
  `3 to any_target`, and Pyre Spawn `3 to any_target`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4437` PostgreSQL runtime rows, wrote `4429` SQLite runtime
  rows, and exported `4404` canonical fallback rows.
- PG459 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `8` selected cards. Generic
  battle scenario count remained `0`; dies-damage behavior remains covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26449`, `xmage_authoritative_source_count=26135`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26135`. This is an exact
  reduction of `8` from the post-PG458 queue.
- The post-PG459 exact split recheck reports `proposal_count=110` and
  `safe_for_batch_pg_package_count=110`. The largest remaining exact families
  are `xmage_destroy_target_scry_spell`,
  `xmage_fixed_damage_scry_spell`, and
  `xmage_static_self_protection_from_subtypes_creature` with `8` cards each,
  followed by `xmage_creature_dies_gain_life`,
  `xmage_fixed_draw_spell_self_cost_reduction`, and
  `xmage_static_cast_spells_as_flash_permission` with `7` cards each.

## 2026-07-05 PG460 Destroy Target Scry Closure

- Closed the exact XMage destroy-target-then-scry spell family as ManaLoom
  scope `xmage_destroy_target_and_scry_spell_v1`.
- The selected package accepted local XMage instant-or-sorcery sources whose
  executable behavior is a fixed `DestroyTargetEffect` followed by fixed
  `ScryEffect`, preserving target type, target constraints, timing, and
  destroy-then-scry resolution order.
- The batch covers `8` cards: Artisan's Sorrow, Expose to Daylight, Get the
  Point, Guiding Bolt, Rubble Reading, Skywhaler's Shot, Tel-Jilad Justice,
  and Vanquish the Foul.
- Focused mapper/runtime tests covered destroy+scry mapping and runtime
  resolution that removes the target before scrying; PG460 performed no code
  mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `8` cards. Precheck found `8` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `8/8` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `8` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve target family,
  target constraints, scry count, timing, and `destroy_then_scry` resolution.
  The selected parameters are: Artisan's Sorrow
  `artifact_or_enchantment scry 2 instant`, Expose to Daylight
  `artifact_or_enchantment scry 1 instant`, Get the Point
  `creature scry 1 instant`, Guiding Bolt `creature power>=4 scry 2 instant`,
  Rubble Reading `land scry 2 sorcery`, Skywhaler's Shot
  `creature power>=3 scry 1 instant`, Tel-Jilad Justice
  `artifact scry 2 instant`, and Vanquish the Foul
  `creature power>=4 scry 1 sorcery`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4445` PostgreSQL runtime rows, wrote `4437` SQLite runtime
  rows, and exported `4412` canonical fallback rows.
- PG460 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `8` selected cards. Generic
  battle scenario count remained `0`; destroy+scry behavior remains covered by
  focused runtime tests.
- A stale zero-byte sibling SQLite artifact at
  `docs/hermes-analysis/manaloom-knowledge/knowledge.db` was removed after the
  first legacy contamination audit correctly failed on it. The rerun legacy
  audit passed against the active operational DB under
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  after stale SQLite cleanup (`32/32`), and PG/Hermes/SQLite contract with live
  PostgreSQL connection (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26441`, `xmage_authoritative_source_count=26127`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26127`. This is an exact
  reduction of `8` from the post-PG459 queue.
- The post-PG460 exact split recheck reports `proposal_count=102` and
  `safe_for_batch_pg_package_count=102`. The largest remaining exact families
  are `xmage_fixed_damage_scry_spell` and
  `xmage_static_self_protection_from_subtypes_creature` with `8` cards each,
  followed by `xmage_creature_dies_gain_life`,
  `xmage_fixed_draw_spell_self_cost_reduction`, and
  `xmage_static_cast_spells_as_flash_permission` with `7` cards each.

## 2026-07-05 PG461 Fixed Damage Scry Closure

- Closed the exact XMage fixed-damage-then-scry spell family as ManaLoom scope
  `xmage_fixed_damage_target_and_scry_spell_v1`.
- The selected package accepted local XMage instant-or-sorcery sources whose
  executable behavior is a fixed `DamageTargetEffect` followed by fixed
  `ScryEffect`, preserving damage amount, target type, target constraints,
  timing, and damage-then-scry resolution order.
- The batch covers `8` cards: Bolt of Keranos, Fateful End, Jaya's Firenado,
  Jaya's Greeting, Lightning Javelin, Magma Jet, Piercing Light, and
  Spark Jolt.
- Focused mapper/runtime tests covered damage+scry mapping and runtime
  resolution; PG461 performed no code mutation. The focused test lane passed
  `718` checks.
- The PostgreSQL package promoted `8` cards. Precheck found `8` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `8/8` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `8` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve damage amount,
  target family, target constraints, scry count, timing, and
  `damage_then_scry` resolution. The selected parameters are:
  Bolt of Keranos `3 damage any_target scry 1 sorcery`, Fateful End
  `3 damage any_target scry 1 instant`, Jaya's Firenado
  `5 damage creature_or_planeswalker scry 1 sorcery`, Jaya's Greeting
  `3 damage creature scry 1 instant`, Lightning Javelin
  `3 damage any_target scry 1 sorcery`, Magma Jet
  `2 damage any_target scry 2 instant`, Piercing Light
  `2 damage attacking_or_blocking creature scry 1 instant`, and Spark Jolt
  `1 damage any_target scry 1 instant`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4453` PostgreSQL runtime rows, wrote `4445` SQLite runtime
  rows, and exported `4420` canonical fallback rows.
- PG461 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `8` selected cards. Generic
  battle scenario count remained `0`; damage+scry behavior remains covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26433`, `xmage_authoritative_source_count=26119`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26119`. This is an exact
  reduction of `8` from the post-PG460 queue.
- The post-PG461 exact split recheck reports `proposal_count=94` and
  `safe_for_batch_pg_package_count=94`. The largest remaining exact family is
  `xmage_static_self_protection_from_subtypes_creature` with `8` cards,
  followed by `xmage_creature_dies_gain_life`,
  `xmage_fixed_draw_spell_self_cost_reduction`, and
  `xmage_static_cast_spells_as_flash_permission` with `7` cards each.

## 2026-07-05 PG462 Static Self Protection From Subtypes Closure

- Closed the exact XMage static self-protection-from-subtypes creature family
  as ManaLoom scope `xmage_static_self_protection_from_subtypes_creature_v1`.
- The selected package accepted local XMage creature sources whose executable
  behavior is static `ProtectionAbility` against exact creature/spell subtypes,
  preserving `target=self`, `target_controller=self`, the protected subtypes,
  and any coexisting self keywords.
- The batch covers `8` cards: Baneslayer Angel, Dragonstalker,
  Elite Inquisitor, Grave Bramble, Kitsune Riftwalker, Midnight Duelist,
  Nath's Buffoon, and Shoreline Raider.
- Focused mapper/runtime tests covered self-protection subtype extraction,
  target/combat legality against matching subtype sources, nonmatching subtype
  allowance, and keyword preservation; PG462 performed no code mutation. The
  focused test lane passed `718` checks.
- The PostgreSQL package promoted `8` cards. Precheck found `8` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `8/8` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `8` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve static effect,
  protected subtypes, target ownership, and auxiliary keywords. The selected
  parameters are: Baneslayer Angel `demon, dragon` plus
  `flying, first_strike, lifelink`, Dragonstalker `dragon` plus `flying`,
  Elite Inquisitor `vampire, werewolf, zombie` plus
  `first_strike, vigilance`, Grave Bramble `zombie` plus `defender`,
  Kitsune Riftwalker `arcane, spirit`, Midnight Duelist `vampire`,
  Nath's Buffoon `elf`, and Shoreline Raider `kavu`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4461` PostgreSQL runtime rows, wrote `4453` SQLite runtime
  rows, and exported `4428` canonical fallback rows.
- PG462 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `8` selected cards. Generic
  battle scenario count remained `0`; subtype-protection behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26425`, `xmage_authoritative_source_count=26111`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26111`. This is an exact
  reduction of `8` from the post-PG461 queue.
- The post-PG462 exact split recheck reports `proposal_count=86` and
  `safe_for_batch_pg_package_count=86`. The largest remaining exact families
  are `xmage_creature_dies_gain_life`,
  `xmage_fixed_draw_spell_self_cost_reduction`, and
  `xmage_static_cast_spells_as_flash_permission` with `7` cards each,
  followed by `xmage_counter_target_draw_card_spell` and
  `xmage_creature_etb_library_search_to_battlefield` with `6` cards each.

## 2026-07-05 PG463 Creature Dies Gain Life Closure

- Closed the exact XMage creature-dies fixed life-gain triggered family as
  ManaLoom scope `xmage_creature_dies_gain_life_v1`.
- The selected package accepted local XMage creature sources whose executable
  behavior is `DiesSourceTriggeredAbility` with fixed `GainLifeEffect`,
  preserving the dies trigger, fixed life amount, and any coexisting self
  keywords.
- The batch covers `7` cards: Anodet Lurker, Enatu Golem,
  Grasping Longneck, Guardian Automaton, Highland Game, Onulet, and Tarpan.
- Focused mapper/runtime tests covered dies life-gain mapping, graveyard
  movement trigger resolution, and keyword preservation; PG463 performed no
  code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `7` cards. Precheck found `7` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `7/7` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `7` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve
  `gain_life_when_this_dies`, `trigger=dies`, and keywords. The selected
  parameters are: Anodet Lurker `3`, Enatu Golem `4`,
  Grasping Longneck `2` plus `reach`, Guardian Automaton `3`,
  Highland Game `2`, Onulet `2`, and Tarpan `1`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4468` PostgreSQL runtime rows, wrote `4460` SQLite runtime
  rows, and exported `4435` canonical fallback rows.
- PG463 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `7` selected cards. Generic
  battle scenario count remained `0`; dies life-gain behavior remains covered
  by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26418`, `xmage_authoritative_source_count=26104`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26104`. This is an exact
  reduction of `7` from the post-PG462 queue.
- The post-PG463 exact split recheck reports `proposal_count=79` and
  `safe_for_batch_pg_package_count=79`. The largest remaining exact families
  are `xmage_fixed_draw_spell_self_cost_reduction` and
  `xmage_static_cast_spells_as_flash_permission` with `7` cards each, followed
  by `xmage_counter_target_draw_card_spell` and
  `xmage_creature_etb_library_search_to_battlefield` with `6` cards each.

## 2026-07-05 PG464 Fixed Draw Self Cost Reduction Closure

- Closed the exact XMage fixed source-controller draw spell family with
  self-only cost-reduction conditions as ManaLoom scope
  `xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1`.
- The selected package accepted local XMage instant-or-sorcery sources whose
  executable behavior is fixed `DrawCardSourceControllerEffect` plus fixed
  `SpellCostReductionSourceEffect`, preserving draw count, timing,
  cost-reduction amount, and the exact condition that reduces only the spell
  itself.
- The batch covers `7` cards: Distorted Curiosity, Draconic Lore,
  Into the Story, Of One Mind, Pearl of Wisdom, Scour the Laboratory, and
  Winged Words.
- Focused mapper/runtime tests covered fixed draw spell extraction, self
  cost-reduction condition preservation, runtime lookup, and package
  generation; PG464 performed no code mutation. The focused test lane passed
  `718` checks.
- The PostgreSQL package promoted `7` cards. Precheck found `7` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `7/7` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `7` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve `draw_count`,
  `cost_reduction_generic`, `cost_reduction_condition`, and timing. The
  selected parameters are: Distorted Curiosity `draw 2, reduce 2 if opponent
  has at least 3 poison counters, sorcery`; Draconic Lore `draw 3, reduce 2 if
  you control a Dragon, instant`; Into the Story `draw 4, reduce 3 if an
  opponent has at least 7 cards in graveyard, instant`; Of One Mind
  `draw 2, reduce 2 if you control a Human and a non-Human creature, sorcery`;
  Pearl of Wisdom `draw 2, reduce 1 if you control an Otter, sorcery`;
  Scour the Laboratory `draw 3, reduce 2 with delirium, instant`; and
  Winged Words `draw 2, reduce 1 if you control a creature with flying,
  sorcery`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4475` PostgreSQL runtime rows, wrote `4467` SQLite runtime
  rows, and exported `4442` canonical fallback rows.
- PG464 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `7` selected cards. Generic
  battle scenario count remained `0`; fixed draw/cost-reduction behavior
  remains covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26411`, `xmage_authoritative_source_count=26097`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26097`. This is an exact
  reduction of `7` from the post-PG463 queue.
- The post-PG464 exact split recheck reports `proposal_count=72` and
  `safe_for_batch_pg_package_count=72`. The largest remaining exact family is
  `xmage_static_cast_spells_as_flash_permission` with `7` cards, followed by
  `xmage_counter_target_draw_card_spell` and
  `xmage_creature_etb_library_search_to_battlefield` with `6` cards each.

## 2026-07-05 PG465 Static Cast Flash Permission Closure

- Closed the exact XMage static cast-as-though-flash permission permanent
  family as ManaLoom scope `xmage_static_cast_spells_as_flash_permission_v1`.
- The selected package accepted local XMage static permission sources whose
  executable behavior is `CastAsThoughItHadFlashAllEffect`, preserving the
  permitted spell filter, whether the permission applies to self or any player,
  the any-player flag, permanent type, and any coexisting self keywords.
- The batch covers `7` cards: High Fae Trickster, Hypersonic Dragon,
  Quick Sliver, Raff Capashen, Ship's Mage, Shimmer Myr, Vernal Equinox, and
  Yeva, Nature's Herald.
- Focused mapper/runtime tests covered cast-as-flash permission extraction,
  filter preservation, self-vs-any-player scope, keyword preservation, and
  runtime lookup; PG465 performed no code mutation. The focused test lane
  passed `718` checks.
- The PostgreSQL package promoted `7` cards. Precheck found `7` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `7/7` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `7` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve
  `flash_permission_filter`, `flash_permission_controller`,
  `flash_permission_any_player`, and keywords. The selected filters are:
  High Fae Trickster `nonland_spells self`, Hypersonic Dragon
  `sorcery_spells self`, Quick Sliver `sliver_spells any_player`,
  Raff Capashen, Ship's Mage `historic_spells self`, Shimmer Myr
  `artifact_spells self`, Vernal Equinox
  `creature_or_enchantment_spells any_player`, and Yeva, Nature's Herald
  `green_creature_spells self`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4482` PostgreSQL runtime rows, wrote `4474` SQLite runtime
  rows, and exported `4449` canonical fallback rows.
- PG465 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `7` selected cards. Generic
  battle scenario count remained `0`; cast-as-flash permission behavior
  remains covered by focused runtime tests.
- A stale zero-byte sibling SQLite artifact at
  `docs/hermes-analysis/manaloom-knowledge/knowledge.db` was removed after the
  first legacy contamination audit correctly failed on it. The rerun legacy
  audit passed against the active operational DB under
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`, and the
  PG/Hermes/SQLite contract rerun used the live PostgreSQL credentials.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  after stale SQLite cleanup (`32/32`), and PG/Hermes/SQLite contract with live
  PostgreSQL connection (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26404`, `xmage_authoritative_source_count=26090`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26090`. This is an exact
  reduction of `7` from the post-PG464 queue.
- The post-PG465 exact split recheck reports `proposal_count=65` and
  `safe_for_batch_pg_package_count=65`. The largest remaining exact families
  are `xmage_counter_target_draw_card_spell` and
  `xmage_creature_etb_library_search_to_battlefield` with `6` cards each,
  followed by `xmage_permanent_simple_activated_draw` with `5` cards.

## 2026-07-05 PG466 Counter Target Draw Card Closure

- Closed the exact XMage counter-target-and-draw-card instant family as
  ManaLoom scope `xmage_counter_target_and_draw_card_spell_v1`.
- The selected package accepted local XMage instant sources whose executable
  behavior is `CounterTargetEffect` followed by fixed
  `DrawCardSourceControllerEffect`, preserving the counter target filter,
  stack target constraints, draw count, `draw_on_counter`, timing, and the
  composite counter/draw resolution model.
- The batch covers `6` cards: Bone to Ash, Contradict, Dismiss, Exclude,
  Halt Order, and Scatter Arc.
- Focused mapper/runtime tests covered counter+draw extraction, target filter
  preservation, composite component preservation, runtime lookup, and package
  generation; PG466 performed no code mutation. The focused test lane passed
  `718` checks.
- The PostgreSQL package promoted `6` cards. Precheck found `6` target rows,
  `0` missing targets, `0` existing expected rows, and `0` shadow rows to
  deprecate; apply/postcheck verified `6/6` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `6` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve
  `target_constraints`, `draw_count=1`, `draw_on_counter=1`, and the two
  composite components. The selected target filters are:
  Bone to Ash `creature_spell`, Contradict `spell`, Dismiss `spell`,
  Exclude `creature_spell`, Halt Order `artifact_spell`, and Scatter Arc
  `noncreature_spell`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4488` PostgreSQL runtime rows, wrote `4480` SQLite runtime
  rows, and exported `4455` canonical fallback rows.
- PG466 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `6` selected cards. Generic
  battle scenario count remained `0`; counter+draw behavior remains covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26398`, `xmage_authoritative_source_count=26084`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26084`. This is an exact
  reduction of `6` from the post-PG465 queue.
- The post-PG466 exact split recheck reports `proposal_count=59` and
  `safe_for_batch_pg_package_count=59`. The largest remaining exact family is
  `xmage_creature_etb_library_search_to_battlefield` with `6` cards, followed
  by `xmage_permanent_simple_activated_draw` with `5` cards.

## 2026-07-05 PG467 Creature ETB Library Search Battlefield Closure

- Closed the exact XMage creature enter-the-battlefield library-search-to-
  battlefield family as ManaLoom scope
  `xmage_creature_etb_library_search_to_battlefield_v1`.
- The selected package accepted local XMage creature sources whose executable
  behavior is `EntersBattlefieldTriggeredAbility` with
  `SearchLibraryPutInPlayEffect`, preserving the searched target, count,
  battlefield destination, and whether the tutored permanent enters tapped.
- The batch covers `6` cards: Farhaven Elf, Kor Cartographer, Ondu Giant,
  Quandrix Cultivator, Quirion Trailblazer, and Wild Wanderer.
- Focused mapper/runtime tests covered ETB tutor extraction, target/tapped
  preservation, runtime lookup, and package generation; PG467 performed no code
  mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `6` cards. Precheck found `6` target rows,
  `0` missing targets, `0` existing expected rows, and `2` generated shadow
  rows to deprecate; apply/postcheck verified `6/6` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `2` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `6` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve
  `trigger=enters_battlefield`, `destination=battlefield`, `count=1`, and the
  selected target/tapped parameters. The selected targets are:
  Farhaven Elf `basic_land_to_battlefield` tapped, Kor Cartographer
  `plains_to_battlefield` tapped, Ondu Giant `basic_land_to_battlefield`
  tapped, Quandrix Cultivator `basic_forest_or_island_to_battlefield` untapped,
  Quirion Trailblazer `basic_land_to_battlefield` tapped, and Wild Wanderer
  `basic_land_to_battlefield` tapped.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4494` PostgreSQL runtime rows, wrote `4486` SQLite runtime
  rows, and exported `4461` canonical fallback rows.
- PG467 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `6` selected cards. Generic
  battle scenario count remained `0`; ETB tutor behavior remains covered by
  focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26392`, `xmage_authoritative_source_count=26078`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26078`. This is an exact
  reduction of `6` from the post-PG466 queue.
- The post-PG467 exact split recheck reports `proposal_count=53` and
  `safe_for_batch_pg_package_count=53`. The largest remaining exact family is
  `xmage_permanent_simple_activated_draw` with `5` cards, followed by several
  `4`-card exact families.

## 2026-07-05 PG468 Permanent Simple Activated Draw Closure

- Closed the exact XMage permanent simple activated draw family as ManaLoom
  scope `xmage_permanent_simple_activated_draw_v1`.
- The selected package accepted local XMage permanent sources whose executable
  behavior is `SimpleActivatedAbility` with `DrawCardSourceControllerEffect`,
  preserving activation mana cost, tap requirement, discard cost, and fixed
  draw count.
- The batch covers `5` cards: Goblin Picker, Mental Discipline,
  Merchant of the Vale // Haggle, Oread of Mountain's Blaze, and Rummaging
  Goblin.
- Focused mapper/runtime tests covered activated draw extraction, activation
  cost fields, discard cost fields, runtime lookup, and package generation;
  PG468 performed no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `5` cards. Precheck found `5` target rows,
  `0` missing targets, `0` existing expected rows, and `0` generated shadow
  rows to deprecate; apply/postcheck verified `5/5` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `5` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve
  `activated_draw_count=1`, `activation_discard_count=1`, the activation mana
  cost, and the tap requirement. The selected costs are:
  Goblin Picker `{R}` with tap, Mental Discipline `{1}{U}` without tap,
  Merchant of the Vale // Haggle `{2}{R}` without tap, Oread of Mountain's
  Blaze `{2}{R}` without tap, and Rummaging Goblin `{0}` with tap.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4499` PostgreSQL runtime rows, wrote `4491` SQLite runtime
  rows, and exported `4466` canonical fallback rows.
- PG468 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `5` selected cards. Generic
  battle scenario count remained `0`; activated draw behavior remains covered
  by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26387`, `xmage_authoritative_source_count=26073`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26073`. This is an exact
  reduction of `5` from the post-PG467 queue.
- The post-PG468 exact split recheck reports `proposal_count=48` and
  `safe_for_batch_pg_package_count=48`. The largest remaining exact families
  are `xmage_creature_etb_draw_lose_life`,
  `xmage_creature_etb_dynamic_graveyard_count_damage`,
  `xmage_destroy_target_spell`, `xmage_dynamic_graveyard_count_damage_spell`,
  `xmage_permanent_simple_activated_self_boost_until_eot`, and
  `xmage_simple_mana_source_with_etb_draw`, each with `4` cards.

## 2026-07-05 PG469 Creature ETB Draw Lose Life Closure

- Closed the exact XMage creature enter-the-battlefield draw-and-lose-life
  family as ManaLoom scope `xmage_creature_etb_draw_lose_life_v1`.
- The selected package accepted local XMage creature sources whose executable
  behavior is `EntersBattlefieldTriggeredAbility` with
  `DrawCardSourceControllerEffect` and `LoseLifeSourceControllerEffect`,
  preserving the ETB trigger and fixed draw/life-loss amounts.
- The batch covers `4` cards: Dusk Legion Zealot, Phyrexian Gargantua,
  Phyrexian Rager, and Tithebearer Giant.
- Focused mapper/runtime tests covered ETB draw/life-loss extraction, fixed
  amount preservation, runtime lookup, and package generation; PG469 performed
  no code mutation. The focused test lane passed `718` checks.
- The PostgreSQL package promoted `4` cards. Precheck found `4` target rows,
  `0` missing targets, `0` existing expected rows, and `0` generated shadow
  rows to deprecate; apply/postcheck verified `4/4` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `4` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve
  `trigger=enters_battlefield`, `etb_draw_count`, and `etb_life_loss`.
  Dusk Legion Zealot, Phyrexian Rager, and Tithebearer Giant each draw `1`
  and lose `1`; Phyrexian Gargantua draws `2` and loses `2`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4503` PostgreSQL runtime rows, wrote `4495` SQLite runtime
  rows, and exported `4470` canonical fallback rows.
- PG469 E2E package validation passed across PostgreSQL, SQLite, canonical
  snapshot, and runtime `get_card_effect` for all `4` selected cards. Generic
  battle scenario count remained `0`; ETB draw/life-loss behavior remains
  covered by focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26383`, `xmage_authoritative_source_count=26069`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26069`. This is an exact
  reduction of `4` from the post-PG468 queue.
- The post-PG469 exact split recheck reports `proposal_count=44` and
  `safe_for_batch_pg_package_count=44`. The largest remaining exact families
  are `xmage_creature_etb_dynamic_graveyard_count_damage`,
  `xmage_destroy_target_spell`, `xmage_dynamic_graveyard_count_damage_spell`,
  `xmage_permanent_simple_activated_self_boost_until_eot`, and
  `xmage_simple_mana_source_with_etb_draw`, each with `4` cards.

## 2026-07-05 PG470 Creature ETB Dynamic Graveyard Damage Closure

- Closed the exact XMage creature enter-the-battlefield dynamic graveyard count
  damage family as ManaLoom scope
  `xmage_creature_etb_dynamic_graveyard_count_damage_v1`.
- The selected package accepted local XMage creature sources whose executable
  behavior is `EntersBattlefieldTriggeredAbility` with `DamageTargetEffect`,
  preserving the ETB trigger, target constraints, graveyard-count filter, count
  scope, and damage multiplier.
- The batch covers `4` cards: Cyclops Electromancer, Lotleth Giant, Ossuary
  Rats, and Warfire Javelineer.
- Focused mapper/runtime tests covered the exact ETB damage model and package
  generation; PG470 performed no code mutation. The focused test lane passed
  `718` checks.
- The PostgreSQL package promoted `4` cards. Precheck found `4` target rows,
  `0` missing targets, `0` existing expected rows, and `0` generated shadow
  rows to deprecate; apply/postcheck verified `4/4` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `4` selected cards. Generic battle
  scenario count remained `0`; ETB dynamic graveyard damage behavior remains
  covered by focused runtime tests.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4507` PostgreSQL runtime rows, wrote `4499` SQLite runtime
  rows, and exported `4474` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26379`, `xmage_authoritative_source_count=26065`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26065`. This is an exact
  reduction of `4` from the post-PG469 queue.
- The post-PG470 exact split recheck reports `proposal_count=40` and
  `safe_for_batch_pg_package_count=40`. The largest remaining exact families
  are `xmage_destroy_target_spell`,
  `xmage_dynamic_graveyard_count_damage_spell`,
  `xmage_permanent_simple_activated_self_boost_until_eot`,
  `xmage_simple_mana_source_with_etb_draw`,
  `xmage_fixed_damage_draw_card_spell`,
  `xmage_fixed_target_player_draw_spell`, and `xmage_x_damage_spell`.

## 2026-07-05 PG471 Destroy Target Spell Closure

- Closed the exact XMage destroy-target spell family as ManaLoom scope
  `xmage_destroy_target_spell_v1`.
- The selected package accepted local XMage spell sources whose executable
  behavior is `DestroyTargetEffect`, preserving target constraints,
  destination, and spell additional sacrifice costs.
- The batch covers `4` cards: Bone Splinters, Embrace Oblivion, Powerstone
  Fracture, and Raze.
- The package builder E2E manifest was tightened to require spell
  additional-cost fields (`additional_cost`, `requires_sacrifice_*`,
  `xmage_additional_cost_class`, and `xmage_additional_cost_target`) so future
  package validation cannot prove only the removal target while missing the
  casting cost behavior.
- Focused mapper/runtime/package tests covered destroy-target sacrifice-cost
  behavior and manifest preservation; the focused test lane passed `719`
  checks.
- The PostgreSQL package promoted `4` cards. Precheck found `4` target rows,
  `0` missing targets, `0` existing expected rows, and `0` generated shadow
  rows to deprecate; apply/postcheck verified `4/4` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `4` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve
  `battle_model_scope=xmage_destroy_target_spell_v1`, target constraints,
  `additional_cost`, `xmage_additional_cost_class=SacrificeTargetCost`, and
  the expected sacrifice target.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `4` selected cards. Generic battle
  scenario count remained `0`; destroy-target sacrifice-cost behavior remains
  covered by focused runtime tests.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4511` PostgreSQL runtime rows, wrote `4503` SQLite runtime
  rows, and exported `4478` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26375`, `xmage_authoritative_source_count=26061`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26061`. This is an exact
  reduction of `4` from the post-PG470 queue.
- The post-PG471 exact split recheck reports `proposal_count=36` and
  `safe_for_batch_pg_package_count=36`. The largest remaining exact families
  are `xmage_dynamic_graveyard_count_damage_spell`,
  `xmage_permanent_simple_activated_self_boost_until_eot`,
  `xmage_simple_mana_source_with_etb_draw`,
  `xmage_fixed_damage_draw_card_spell`,
  `xmage_fixed_target_player_draw_spell`, and `xmage_x_damage_spell`.

## 2026-07-05 PG472 Dynamic Graveyard Count Damage Spell Closure

- Closed the exact XMage dynamic graveyard-count damage spell family as
  ManaLoom scope `xmage_dynamic_graveyard_count_damage_spell_v1`.
- The selected package accepted local XMage spell sources whose executable
  behavior is `DamageTargetEffect` with damage based on graveyard count,
  preserving the count scope, count filter, base amount, per-count multiplier,
  and target constraints.
- The batch covers `4` cards: Galvanic Bombardment, Ire of Kaminari, Kindle,
  and Scrapyard Salvo.
- The package builder E2E manifest was tightened to require dynamic graveyard
  damage fields (`damage_amount_source`, `damage_base_amount`,
  `damage_per_graveyard_count`, `graveyard_count_card_names`, and
  `graveyard_count_subtypes`) so future package validation cannot prove only
  target/damage shape while missing the count formula.
- Focused mapper/runtime/package tests covered named-card, subtype, card-type,
  controller-graveyard, and all-graveyard variants; the focused test lane passed
  `720` checks.
- The PostgreSQL package promoted `4` cards. Precheck found `4` target rows,
  `0` missing targets, `0` existing expected rows, and `0` generated shadow
  rows to deprecate; apply/postcheck verified `4/4` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `4` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve
  `battle_model_scope=xmage_dynamic_graveyard_count_damage_spell_v1`,
  `damage_amount_source=graveyard_card_count`, base amount, per-count
  multiplier, count scope, count filter, and target constraints.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `4` selected cards. Generic battle
  scenario count remained `0`; dynamic graveyard-count damage behavior remains
  covered by focused runtime tests.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4515` PostgreSQL runtime rows, wrote `4507` SQLite runtime
  rows, and exported `4482` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26371`, `xmage_authoritative_source_count=26057`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26057`. This is an exact
  reduction of `4` from the post-PG471 queue.
- The post-PG472 exact split recheck reports `proposal_count=32` and
  `safe_for_batch_pg_package_count=32`. The largest remaining exact families
  are `xmage_permanent_simple_activated_self_boost_until_eot`,
  `xmage_simple_mana_source_with_etb_draw`,
  `xmage_fixed_damage_draw_card_spell`,
  `xmage_fixed_target_player_draw_spell`, and `xmage_x_damage_spell`.

## 2026-07-05 PG473 Permanent Simple Activated Self Boost Closure

- Closed the exact XMage permanent simple activated self-boost family as
  ManaLoom scope `xmage_permanent_simple_activated_self_boost_until_eot_v1`.
- The selected package accepted local XMage creature sources whose executable
  behavior is `SimpleActivatedAbility` with `BoostSourceEffect`, preserving
  hybrid activation cost, no tap requirement, self target, power/toughness
  delta, and until-end-of-turn duration.
- The batch covers `4` cards: Foxfire Oak, Frostburn Weird, Loch Korrigan, and
  Parapet Watchers.
- Focused mapper/runtime/package tests covered activated self-boost cost
  payment, activation gating, automatic profitable use, and cleanup; the
  focused test lane passed `720` checks.
- The PostgreSQL package promoted `4` cards. Precheck found `4` target rows,
  `0` missing targets, `0` existing expected rows, and `0` generated shadow
  rows to deprecate; apply/postcheck verified `4/4` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `4` promoted rows are
  `verified`/`auto`/`curated`, have Oracle hashes, and preserve
  `battle_model_scope=xmage_permanent_simple_activated_self_boost_until_eot_v1`,
  activation cost, hybrid color list, no tap requirement, duration, and
  power/toughness boost values.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `4` selected cards. Generic battle
  scenario count remained `0`; activated self-boost behavior remains covered by
  focused runtime tests.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4519` PostgreSQL runtime rows, wrote `4511` SQLite runtime
  rows, and exported `4486` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy contamination
  (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26367`, `xmage_authoritative_source_count=26053`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26053`. This is an exact
  reduction of `4` from the post-PG472 queue.
- The post-PG473 exact split recheck reports `proposal_count=28` and
  `safe_for_batch_pg_package_count=28`. The largest remaining exact families
  are `xmage_simple_mana_source_with_etb_draw`,
  `xmage_fixed_damage_draw_card_spell`,
  `xmage_fixed_target_player_draw_spell`, and `xmage_x_damage_spell`.

## 2026-07-05 PG474 Simple Mana Source With ETB Draw Closure

- Closed the exact XMage simple mana-source permanent with enter-the-battlefield
  draw family as ManaLoom scope
  `xmage_simple_mana_source_with_etb_draw_v1`.
- The selected package accepted local XMage artifact/creature mana sources
  whose executable behavior is one safe mana ability plus
  `EntersBattlefieldTriggeredAbility` with `DrawCardSourceControllerEffect`,
  preserving the ETB trigger, fixed draw count, activation mana cost,
  tap requirement, produced mana, permanent type, and XMage ability classes.
- The batch covers `4` cards: Arcum's Astrolabe, Energy Refractor,
  Llanowar Visionary, and Prophetic Prism.
- Runtime was tightened before promotion: the natural `cast_spells_v8` ramp
  path now resolves generic permanent ETB triggers and pays
  `activation_mana_cost` through `pay_mana_source_activation_costs` before
  immediate mana production. This prevents the direct resolver from being
  correct while natural battle casts skip ETB draw or generate unpaid mana.
- Focused mapper/runtime/package tests covered direct resolution, natural ramp
  cast ETB draw, mana activation-cost payment, package generation, and exact
  split selection; the focused test lane passed `722` checks.
- The PostgreSQL package promoted `4` cards. Precheck found `4` target rows,
  `0` missing targets, `0` existing expected rows, and `0` generated shadow
  rows to deprecate; apply/postcheck verified `4/4` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `4` promoted rows are
  `verified`/`auto`, have `rule_version=2`, and preserve
  `battle_model_scope=xmage_simple_mana_source_with_etb_draw_v1`,
  `effect=ramp_permanent`, `is_mana_source`, `mana_produced`, `produces`,
  `produced_mana_symbols` where applicable, `activation_mana_cost`,
  `activation_requires_tap`, `mana_activation_requires_tap`,
  `trigger=enters_battlefield`, `trigger_effect=draw_cards`,
  `etb_draw_count=1`, `permanent_type`, and Oracle hash.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `4` selected cards. Generic battle
  scenario count remained `0`; natural battle execution is covered by focused
  runtime test
  `test_natural_ramp_cast_resolves_etb_draw_and_pays_mana_activation_cost`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4523` PostgreSQL runtime rows, wrote `4515` SQLite runtime
  rows, and exported `4490` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`pass`), legacy contamination
  (`pass`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26363`, `xmage_authoritative_source_count=26049`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26049`. This is an exact
  reduction of `4` from the post-PG473 queue.
- The post-PG474 exact split recheck reports `proposal_count=24` and
  `safe_for_batch_pg_package_count=24`. The largest remaining exact families
  are `xmage_fixed_damage_draw_card_spell`,
  `xmage_fixed_target_player_draw_spell`, `xmage_x_damage_spell`,
  `xmage_graveyard_multi_zone_recursion_spell`,
  `xmage_static_play_lands_from_graveyard`, and
  `xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell`.

## 2026-07-05 PG475 Fixed Damage Draw Card Spell Closure

- Closed the exact XMage fixed damage plus draw spell family as ManaLoom scope
  `xmage_fixed_damage_target_and_draw_card_spell_v1`.
- The selected package accepted local XMage spell sources whose executable
  behavior composes `DamageTargetEffect` and
  `DrawCardSourceControllerEffect`, preserving fixed damage amount, fixed draw
  count, target scope, target constraints, and ordered composite components.
- The batch covers `3` cards: Ember Shot, Playful Shove, and Zap.
- The package builder E2E manifest was tightened to require
  `_composite_rule_components`. This prevents a composite damage plus draw
  rule from passing package validation while missing the direct-damage and
  draw-card subeffects that the runtime must execute.
- Focused mapper/runtime/package tests covered exact split selection,
  composite damage plus draw runtime execution, package generation, and
  manifest field preservation; the focused runtime/split lane passed `722`
  checks, and the package-builder test lane also passed.
- The PostgreSQL package promoted `3` cards. Precheck found `3` target rows,
  `0` missing targets, `0` existing expected rows, and `2` generated shadow
  rows to deprecate; apply/postcheck verified `3/3` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `2` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `3` promoted rows are
  `verified`/`auto`, have `rule_version=2`, and preserve
  `battle_model_scope=xmage_fixed_damage_target_and_draw_card_spell_v1`,
  `effect=composite_resolution`, `damage`, `amount`, `draw_count`, `count`,
  `target=any_target`, target constraints, and ordered
  `_composite_rule_components` for `direct_damage` then `draw_cards`.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `3` selected cards. Generic battle
  scenario count remained `0`; composite damage plus draw behavior remains
  covered by focused runtime test
  `test_composite_damage_draw_spell_damages_player_then_draws_once`.
- Additional cache verification confirmed SQLite `battle_card_rules` and
  `known_cards_canonical_snapshot.json` both preserve the two composite
  components.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4526` PostgreSQL runtime rows, wrote `4518` SQLite runtime
  rows, and exported `4493` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy
  contamination (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL
  connection (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26360`, `xmage_authoritative_source_count=26046`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26046`. This is an exact
  reduction of `3` from the post-PG474 queue.
- The post-PG475 exact split recheck reports `proposal_count=21` and
  `safe_for_batch_pg_package_count=21`. The remaining exact families are
  `xmage_x_damage_spell`, `xmage_fixed_target_player_draw_spell`,
  `xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell`,
  `xmage_return_target_to_hand_and_scry_spell`,
  `xmage_graveyard_multi_zone_recursion_spell`,
  `xmage_static_play_lands_from_graveyard`,
  `xmage_permanent_simple_activated_graveyard_to_battlefield`,
  `xmage_permanent_simple_activated_graveyard_to_hand`,
  `xmage_creature_combat_damage_graveyard_to_hand`,
  `xmage_permanent_attack_graveyard_to_hand`, and
  `xmage_permanent_simple_activated_destroy_target`.

## 2026-07-05 PG476 X Damage Spell Closure

- Closed the exact XMage X damage spell family as ManaLoom scope
  `xmage_x_damage_target_spell_v1`.
- The selected package accepted local XMage spell sources whose executable
  behavior is `DamageTargetEffect` where the damage amount is the X value paid
  during cast, preserving `amount=0`, `damage=0`,
  `damage_amount_source=x_value`, target scope, and target constraints.
- The batch covers `3` cards: Blaze, Heat Ray, and Volcanic Geyser.
- The package builder E2E manifest was tightened to require `amount`, including
  `amount=0`. This prevents X-damage rules from passing package validation
  with only `damage_amount_source=x_value` while omitting the explicit base
  amount field used to distinguish X-derived damage from fixed damage.
- Focused mapper/runtime/package tests covered exact split selection,
  runtime cast-context X damage resolution, zero-amount field preservation,
  package generation, and manifest field preservation; the focused
  runtime/split lane passed `722` checks, and the package-builder test lane
  also passed.
- The PostgreSQL package promoted `3` cards. Precheck found `3` target rows,
  `0` missing targets, `0` existing expected rows, and `0` generated shadow
  rows to deprecate; apply/postcheck verified `3/3` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `3` promoted rows are
  `verified`/`auto`, have `rule_version=2`, and preserve
  `battle_model_scope=xmage_x_damage_target_spell_v1`,
  `effect=direct_damage`, `amount=0`, `damage=0`,
  `damage_amount_source=x_value`, target metadata, and Oracle hash.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `3` selected cards. Generic battle
  scenario count remained `0`; X-damage behavior remains covered by focused
  runtime test `test_x_damage_uses_cast_context_x_value`.
- Additional cache verification confirmed SQLite `battle_card_rules` and
  `known_cards_canonical_snapshot.json` both preserve `amount=0`, `damage=0`,
  and `damage_amount_source=x_value`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4529` PostgreSQL runtime rows, wrote `4521` SQLite runtime
  rows, and exported `4496` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy
  contamination (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL
  connection (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26357`, `xmage_authoritative_source_count=26043`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26043`. This is an exact
  reduction of `3` from the post-PG475 queue.
- The post-PG476 exact split recheck reports `proposal_count=18` and
  `safe_for_batch_pg_package_count=18`. The remaining exact families are
  `xmage_fixed_target_player_draw_spell`,
  `xmage_return_target_to_hand_and_scry_spell`,
  `xmage_graveyard_multi_zone_recursion_spell`,
  `xmage_static_play_lands_from_graveyard`,
  `xmage_permanent_simple_activated_graveyard_to_battlefield`,
  `xmage_permanent_simple_activated_graveyard_to_hand`,
  `xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell`,
  `xmage_creature_combat_damage_graveyard_to_hand`,
  `xmage_permanent_attack_graveyard_to_hand`, and
  `xmage_permanent_simple_activated_destroy_target`.

## 2026-07-05 PG477 Fixed Target Player Draw Spell Closure

- Closed the exact XMage fixed target-player draw spell family as ManaLoom
  scope `xmage_fixed_target_player_draw_spell_v1`.
- The selected package accepted local XMage spell sources whose executable
  behavior is `DrawCardTargetEffect`, preserving fixed draw count,
  `target=player`, `target_controller=target_player`,
  `target_player_draw=true`, and `target_preference=self`.
- The batch covers `3` cards: Inspiration, Opportunity, and Overflowing
  Insight.
- Focused mapper/runtime/package tests covered exact split selection,
  default-self target selection, declared target respect, package generation,
  and manifest field preservation; the focused runtime/split lane passed `722`
  checks, and the package-builder test lane also passed.
- The PostgreSQL package promoted `3` cards. Precheck found `3` target rows,
  `0` missing targets, `0` existing expected rows, and `0` generated shadow
  rows to deprecate; apply/postcheck verified `3/3` promoted rows as
  `verified`/`auto` with Oracle hashes. The apply backup captured `0` rows;
  `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `3` promoted rows are
  `verified`/`auto`, have `rule_version=2`, and preserve
  `battle_model_scope=xmage_fixed_target_player_draw_spell_v1`,
  `effect=draw_cards`, target-player metadata, target preference, and Oracle
  hash. Draw counts are Inspiration `2`, Opportunity `4`, and Overflowing
  Insight `7`.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `3` selected cards. Generic battle
  scenario count remained `0`; target-player draw behavior remains covered by
  focused runtime tests
  `test_fixed_target_player_draw_spell_defaults_to_self` and
  `test_fixed_target_player_draw_spell_respects_declared_target`.
- Additional cache verification confirmed SQLite `battle_card_rules` and
  `known_cards_canonical_snapshot.json` both preserve draw counts,
  target-player metadata, and `target_preference=self`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4532` PostgreSQL runtime rows, wrote `4524` SQLite runtime
  rows, and exported `4499` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy
  contamination (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL
  connection (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26354`, `xmage_authoritative_source_count=26040`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26040`. This is an exact
  reduction of `3` from the post-PG476 queue.
- The post-PG477 exact split recheck reports `proposal_count=15` and
  `safe_for_batch_pg_package_count=15`. The remaining exact families are
  `xmage_return_target_to_hand_and_scry_spell`,
  `xmage_graveyard_multi_zone_recursion_spell`,
  `xmage_static_play_lands_from_graveyard`,
  `xmage_permanent_simple_activated_graveyard_to_battlefield`,
  `xmage_permanent_simple_activated_graveyard_to_hand`,
  `xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell`,
  `xmage_creature_combat_damage_graveyard_to_hand`,
  `xmage_permanent_attack_graveyard_to_hand`, and
  `xmage_permanent_simple_activated_destroy_target`.

## 2026-07-05 PG478 Residual Exact Safe Sweep Closure

- Closed the residual exact safe candidates left by the post-PG477 splitter as
  one bulk package across `9` runtime-backed XMage scopes.
- The batch covers `15` cards: Badlands Revival, Bonecaller Cleric, Crucible of
  Worlds, Elvish Hexhunter, Eternal Taskmaster, Festive Funeral, Ghoul's Feast,
  Hana Kami, Pillardrop Warden, Pull Through the Weft, Ramunap Excavator,
  Select for Inspection, The Unspeakable, Valgavoth's Faithful, and Voyage's
  End.
- Runtime scopes promoted in the package:
  `xmage_return_multi_zone_graveyard_cards_spell_v1`,
  `xmage_permanent_simple_activated_graveyard_to_battlefield_v1`,
  `xmage_static_play_lands_from_graveyard_v1`,
  `xmage_permanent_simple_activated_destroy_target_v1`,
  `xmage_permanent_attack_return_graveyard_card_to_hand_v1`,
  `xmage_dynamic_graveyard_count_boost_target_creature_until_eot_spell_v1`,
  `xmage_permanent_simple_activated_graveyard_to_hand_v1`,
  `xmage_return_target_to_hand_and_scry_spell_v1`, and
  `xmage_creature_combat_damage_return_graveyard_card_to_hand_v1`.
- The PostgreSQL package promoted `15` cards. Apply/postcheck verified
  `15/15` promoted rows as `verified`/`auto` with Oracle hashes. The apply
  backup captured `2` shadow rows; `failed_cards=[]`.
- Validation exposed and fixed a canonical snapshot export bug. PostgreSQL and
  SQLite had correct composite XMage rules for Select for Inspection and
  Voyage's End, but the snapshot export could let older Oracle-normalized
  fallback effects (`remove_permanent`/`remove_creature`) overwrite the
  trusted runtime `effect=composite_resolution`. The sync contract now treats
  trusted `manual`/`curated` verified executable rows with explicit runtime
  scope, composite components, or XMage effect metadata as authoritative over
  Oracle normalization during snapshot export.
- Regression test added:
  `test_export_canonical_snapshot_keeps_verified_composite_rule_over_stale_snapshot_effect`.
- Focused runtime/split/sync regression lane passed `752` tests, the
  package-builder test lane passed, and the touched scripts compiled.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  runtime `get_card_effect`, and no-override battle gate for all `15` selected
  cards. The additional SQLite/snapshot manifest verifier also passed,
  including `effect=composite_resolution` for Select for Inspection and
  Voyage's End.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4547` PostgreSQL runtime rows, wrote `4539` SQLite runtime
  rows, and exported `4514` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy
  contamination (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL
  connection (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26339`, `xmage_authoritative_source_count=26025`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26025`.
- The post-PG478 exact split recheck reports `proposal_count=0` and
  `safe_for_batch_pg_package_count=0`. This means the currently implemented
  exact splitter has no more immediate safe package candidates. The next real
  work is implementing/splitting new family subpatterns from the blocked
  reasons, then rebuilding the authoritative queue and exact split.

## 2026-07-05 PG479 Look-Library Pick Bottom Closure

- Closed the exact XMage `LookLibraryAndPickControllerEffect` spell family as
  ManaLoom scope `xmage_look_library_pick_to_hand_rest_bottom_spell_v1`.
- The selected package accepts local XMage spell sources that look at a fixed
  number of top-library cards, put fixed or matching card(s) into hand, and
  put the rest on the bottom of the library. The runtime now preserves
  `rest_destination=library_bottom` instead of treating this family like older
  graveyard-rest `dig_to_hand` behavior.
- The batch covers `15` cards: Adventurous Impulse, Ancient Stirrings,
  Anticipate, Commune with Beavers, Commune with Nature, Commune with Spirits,
  Drawn from Dreams, Forging the Anchor, Impulse, Lead the Stampede, Peer
  Through Depths, Seek the Wilds, Shimmer of Possibility, Sleight of Hand, and
  Stock Up.
- The package preserves per-card `look_count`, `pick_count`, `pick_target`,
  `pick_up_to_count`, `pick_all_matching`, `target_constraints`,
  `rest_destination`, and `library_bottom_order` (`any` or `random`) from the
  XMage source/oracle agreement.
- Focused split/runtime tests passed `726` checks. The package-builder test
  lane passed after extending the E2E manifest whitelist to require
  `library_bottom_order` for this family, and the touched scripts compiled.
- The PostgreSQL package promoted `15` cards. Precheck found `15` target rows,
  `0` missing targets, `0` existing expected rows, and `2` nonmatching shadow
  rows to deprecate. Apply/postcheck verified `15/15` promoted rows as
  `verified`/`auto` with Oracle hashes; `failed_cards=[]`; the backup captured
  `2` rows.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  runtime `get_card_effect`, and no-override battle gate for all `15` selected
  cards. Additional direct cache verification confirmed SQLite and
  `known_cards_canonical_snapshot.json` both preserve the library-pick fields,
  including `library_bottom_order`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. The final
  full sync loaded `4562` PostgreSQL runtime rows, wrote `4554` SQLite runtime
  rows, and exported `4529` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy
  contamination (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL
  connection (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26324`, `xmage_authoritative_source_count=26010`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26010`. This is an exact
  reduction of `15` from the post-PG478 queue.
- The post-PG479 exact split recheck reports `proposal_count=0` and
  `safe_for_batch_pg_package_count=0`. The next real work is another
  family/subpattern implementation from the remaining blocked reasons, led by
  the highest queue-reducing supported work units rather than card-by-card
  manual handling.

## 2026-07-05 PG480 Combat-Damage Draw Closure

- Closed the exact XMage `DrawCardSourceControllerEffect` +
  `DealsCombatDamageToAPlayerTriggeredAbility` creature family as ManaLoom
  scope `xmage_creature_combat_damage_draw_cards_v1`.
- The selected package accepts only fixed-count draw triggers of the form
  “whenever this creature deals combat damage to a player, draw N cards,” with
  source/oracle count agreement and only source-added static self keywords.
  The mapper deliberately blocks damage-scaled draw and sacrifice-then-draw
  neighbors such as Fear of Failed Tests and Impaler Shrike.
- The batch covers `5` cards: Neurok Commando, Nine-Tail White Fox, Scroll
  Thief, Soulknife Spy, and Stealer of Secrets.
- The runtime now resolves combat-damage-to-player draw triggers in the combat
  damage step, calls player-draw follow-up triggers, and emits
  `combat_damage_draw_resolved` evidence with drawn-card and rule-key details.
- The mapper also guards against false positive keyword classes from XMage
  imports/filters by preserving static keywords for this family only when the
  source actually adds that ability. This prevents Stealer of Secrets from
  inheriting a spurious `defender` flag from a filter reference.
- Focused split/runtime/sync tests passed `762` checks. The package-builder
  test lane passed after extending the E2E manifest whitelist for
  `combat_damage_player_draw`, `combat_damage_draw_count`, and optional draw
  metadata, and the touched scripts compiled.
- The PostgreSQL package promoted `5` cards. Precheck found `5` target rows,
  `0` existing expected rows, and `0` nonmatching shadow rows to deprecate.
  Apply/postcheck verified `5/5` promoted rows as `verified`/`auto` with Oracle
  hashes; backup rows were `0`.
- E2E package validation passed across PostgreSQL, SQLite,
  `known_cards_canonical_snapshot.json`, and runtime `get_card_effect` for all
  `5` selected cards. Direct verification confirmed all five expose
  `battle_model_scope=xmage_creature_combat_damage_draw_cards_v1` and
  `combat_damage_draw_count=1`, with no spurious `defender` flag on Stealer of
  Secrets.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. Metadata sync
  matched `5729` PostgreSQL cards and `5640` SQLite cache aliases. The battle
  sync loaded `8172` PostgreSQL rows, wrote `7936` SQLite rows, and exported
  `5711` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`pass`), legacy contamination
  (`pass`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26319`, `xmage_authoritative_source_count=26005`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26005`. This is an exact
  reduction of `5` from the post-PG479 queue.
- The post-PG480 exact split recheck reports `proposal_count=0` and
  `safe_for_batch_pg_package_count=0`. The next work should continue from the
  largest remaining family buckets, starting with recursion and draw-engine
  subpatterns that can be split into runtime-backed exact scopes.

## 2026-07-05 PG481 ETB Draw Patterns Closure

- Closed two exact XMage `DrawCardSourceControllerEffect` +
  `EntersBattlefieldTriggeredAbility` creature subpatterns:
  `xmage_creature_etb_optional_discard_draw_cards_v1` and
  `xmage_creature_etb_dynamic_draw_cards_v1`.
- The optional-discard scope accepts only exact local XMage sources using
  `DoIfCostPaid(new DrawCardSourceControllerEffect(...), new DiscardCardCost())`
  whose Oracle text says "when this creature enters, you may discard a card. If
  you do, draw a card." The runtime now pays the optional discard only when a
  discard candidate exists, draws after the discard resolves, and emits
  `etb_optional_discard_draw_resolved` or explicit skip events.
- The dynamic-draw scope accepts only source/oracle-matched ETB draw counts for
  supported runtime count sources: controlled creatures with +1/+1 counters,
  controlled creatures with a subtype with optional source exclusion, controlled
  creatures with a color, colors among permanents you control, and the maximum
  of controlled subtype creatures vs subtype cards in your graveyard.
- The batch covers `12` cards: Armorcraft Judge, Discerning Peddler,
  Earthshaker Dreadmaw, Fissure Wizard, Immersturm Raider, Keldon Raider,
  Plundering Predator, Prophet of the Scarab, Regal Force, Shinestriker,
  Viashino Racketeer, and Yuyan Archers.
- The mapper deliberately keeps `Liliana's Standard Bearer` blocked because it
  depends on creatures that died under your control this turn, and keeps
  `Treetop Sentries` blocked because forage cost payment needs its own runtime
  contract.
- Focused split/runtime/sync tests passed `769` checks. The package-builder
  test lane passed after extending the manifest whitelist for
  `etb_optional_discard_*`, `etb_dynamic_draw`, and ETB draw-count source
  metadata, and the touched scripts compiled.
- The PostgreSQL package promoted `12` cards. Precheck found `12` target rows,
  `0` existing expected rows, and `0` nonmatching shadow rows to deprecate.
  Apply/postcheck verified `12/12` promoted rows as `verified`/`auto` with
  Oracle hashes; backup rows were `0`.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `12` selected cards. Direct
  verification confirmed all twelve expose the expected battle scopes without
  falling through to unconditional `etb_draw_count`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. Metadata sync
  matched `6701` PostgreSQL cards and `6629` SQLite cache aliases. The battle
  sync loaded `4579` PostgreSQL rows, wrote `7175` SQLite rows, and exported
  `4550` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`pass`), legacy contamination
  (`pass`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26307`, `xmage_authoritative_source_count=25993`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=25993`. This is an exact
  reduction of `12` from the post-PG480 queue and reduces
  `draw_engine::xmage_draw_card_variant_review_v1` from `1605` to `1593`.
- The post-PG481 exact split recheck reports `proposal_count=0` and
  `safe_for_batch_pg_package_count=0`. The next work should continue with a
  new subpattern from the remaining blocked reasons, not rerun this ETB draw
  family.

## 2026-07-05 PG482 Self Add Counters Closure

- Closed the exact XMage `AddCountersSourceEffect` +
  `SimpleActivatedAbility` permanent family as ManaLoom scope
  `xmage_permanent_simple_activated_self_add_counters_v1`.
- The selected scope accepts only fixed self-counter activated abilities where
  Oracle and XMage agree on counter type, counter count, mana/tap activation
  cost, and self target. It deliberately blocks sacrifice-cost self-counter
  activations and dynamic `X` counter activations until those costs/counts have
  their own runtime contracts.
- The batch covers `10` cards: Carnivorous Moss-Beast, Chronomaton, Energizer,
  Hungry Megasloth, Jenara, Asura of War, Jungle Delver, Ruins Recluse,
  Sledding Otter-Penguin, Unholy Officiant, and Verdant Automaton.
- The runtime now pays the real activation mana cost, respects tap and
  summoning-sickness restrictions, adds counters to the source permanent,
  updates creature stats, and emits `utility_permanent_activated` plus
  `utility_permanent_activation` decision-trace evidence.
- Focused split/runtime/sync tests passed `774` checks. The package-builder
  test lane passed after extending the E2E manifest whitelist for
  `activated_add_counters_*` and `counter_count`, and the touched scripts
  compiled.
- The PostgreSQL package promoted `10` cards. Precheck found `10` target rows,
  `0` existing expected rows, and `0` nonmatching shadow rows to deprecate.
  Apply/postcheck verified `10/10` promoted rows as `verified`/`auto` with
  Oracle hashes; backup rows were `0`.
- E2E package validation passed across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `10` selected cards. Direct
  verification confirmed all ten expose
  `battle_model_scope=xmage_permanent_simple_activated_self_add_counters_v1`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. Metadata sync
  matched `6713` PostgreSQL cards and `6641` SQLite cache aliases. The battle
  sync loaded `4589` PostgreSQL rows, wrote `4581` SQLite rows, and exported
  `4560` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`pass`), legacy contamination
  (`pass`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26297`, `xmage_authoritative_source_count=25983`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=25983`. This is an exact
  reduction of `10` from the post-PG481 queue and reduces
  `add_counters::source_add_counters_variant_v1` from `795` to `785`.
- The post-PG482 exact split recheck reports `proposal_count=0` and
  `safe_for_batch_pg_package_count=0`. The next work should continue with the
  highest-impact remaining family buckets: recursion, draw-engine, protection,
  direct damage, and the residual add-counter subpatterns.

## 2026-07-05 PG483 Spell-Cast Add Counters Closure

- Closed the exact XMage `AddCountersSourceEffect` +
  `SpellCastControllerTriggeredAbility` permanent family as ManaLoom scope
  `xmage_spell_cast_add_counters_source_v1`.
- The selected scope accepts only one spell-cast triggered self-counter ability
  with optional static self keywords. Supported filters are noncreature,
  artifact, enchantment, instant-or-sorcery, multicolored, mana-value minimum,
  creature plus mana-value minimum, and color OR filters such as Quirion Dryad.
  It deliberately blocks AdventurePredicate, opponent-turn conditions, Ward or
  other non-static auxiliary ability classes, mixed ETB plus spell-cast counter
  abilities, non-fixed counters, and unsupported target shapes.
- The batch covers `14` cards: Blessed Spirits, Boar-q-pine, Deeproot
  Champion, Electrostatic Infantry, Kurgadon, Lurking Lizards, Mage Tower
  Referee, Pyre Hound, Pyroceratops, Quirion Dryad, Spellgorger Weird, Sprite
  Dragon, Stormkeld Prowler, and Tempest Angler.
- The runtime now resolves matching spell-cast triggers by adding the fixed
  counters to the source permanent, updates creature stats through the shared
  source-counter helper, and emits trigger evidence including trigger spell,
  trigger effect, source zone, card-type/color/multicolor/mana-value filter
  metadata, and replay rule fields.
- Focused split/runtime/sync tests passed `780` checks. Existing non-fatal
  SQLite `ResourceWarning` messages in `battle_analyst_v9.py:5275` remain
  unchanged.
- Current PostgreSQL postcheck on the selected cards returns `14/14` promoted
  rows, `14/14` verified/auto rows, `14/14` Oracle-hash rows, and `0` backup
  rows.
- Direct E2E validation passed across PostgreSQL, SQLite `battle_card_rules`,
  canonical snapshot, and runtime `get_card_effect` for all `14` selected
  cards. All expose
  `battle_model_scope=xmage_spell_cast_add_counters_source_v1`.
- Hermes metadata sync and full PG -> SQLite sync were run against
  `143.198.230.247:5433/halder` and
  `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`. Metadata sync
  matched `6723` PostgreSQL cards and `6651` SQLite cache aliases. The battle
  sync loaded `4603` PostgreSQL rows, wrote `4595` SQLite rows, and exported
  `4574` canonical fallback rows.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`pass`), legacy contamination
  (`pass`), and PG/Hermes/SQLite contract with live PostgreSQL connection
  (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26283`, `xmage_authoritative_source_count=25969`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=25969`. This is an exact
  reduction of `14` from the post-PG482 queue and reduces
  `add_counters::source_add_counters_variant_v1` from `785` to `771`.
- The post-PG483 exact split recheck reports `proposal_count=0` and
  `safe_for_batch_pg_package_count=0`. The next work should continue with a
  new subpattern from the remaining blocked families, led by recursion,
  draw-engine, protection, direct damage, and residual add-counter scopes.

## 2026-07-05 PG484 Extended Board Wipe Closure

- Closed the extended exact XMage `DestroyAllEffect` and `DamageAllEffect`
  board-wipe family as ManaLoom scopes
  `xmage_destroy_all_matching_permanents_spell_v1` and
  `xmage_fixed_damage_all_matching_permanents_spell_v1`.
- The selected scope accepts only single-effect, non-modal, fixed-source
  one-shot spells. It now supports destroy filters for controller, card type
  exclusions, required/excluded colors, required/excluded subtypes, tapped
  state, nonbasic lands, mana value, power, and toughness thresholds. It also
  supports damage-wipe scopes for flying, nonflying, attacking, tapped,
  untapped, and nonartifact creatures.
- The batch covers `26` cards: Acid Rain, Anarchy, Boil, Boiling Seas,
  Citywide Bust, Flashfires, Gale Force, Guan Yu's 1,000-Li March, Marrow
  Shards, Mass Calcify, Nature's Ruin, Perish, Plague Wind, Planar Cleansing,
  Rain of Blades, Retribution of the Meek, Ritual of Soot, Ruination,
  Sandstorm, Shatterstorm, Soulscour, Squall, Their Name Is Death, Tsunami,
  Virtue's Ruin, and Whipflare.
- The runtime now applies structured board-wipe constraints during permanent
  matching and records those constraints in the board-wipe decision trace and
  replay event. Damage wipes now respect the supported per-creature scopes
  before applying fixed damage.
- The parser deliberately blocks unsafe neighbors: multiple `DestroyAllEffect`
  or `DamageAllEffect` sources, modal sources, dynamic damage values such as X,
  battlefield-count/color-spent/devotion counts, death replacement side effects,
  additional damage text, unsupported ability classes, unsupported target
  shapes, and non-simple Oracle text.
- Focused validation passed `475` exact-split tests, `281` runtime tests, and
  `15` package-builder tests. `py_compile` and `git diff --check` also passed.
- PostgreSQL package PG484 applied against `143.198.230.247:5433/halder` and
  promoted `26/26` selected cards as verified/auto rule-version `2` rows with
  matching Oracle hashes. The apply deprecated `8` older shadow rows from the
  selected cards.
- Hermes metadata sync matched `6737` PostgreSQL cards, wrote `6665` SQLite
  cache aliases, and left the known `unresolved=1` residual unchanged. The
  battle-rule sync loaded `4629` PostgreSQL rows, wrote `4621` SQLite rows, and
  exported `4600` canonical fallback rows.
- Generic E2E validation passed across PostgreSQL, SQLite `battle_card_rules`,
  canonical snapshot, and runtime `get_card_effect` for all `26` selected
  cards. The manifest does not define battle-execution scenarios for this
  generic family, so scenario execution remains `0` and concrete behavior proof
  is provided by the focused runtime tests.
- Final governance audits passed:
  XMage strategy (`26/26`), operational surface (`39/39`), legacy
  contamination (`32/32`), and PG/Hermes/SQLite contract with live PostgreSQL
  connection (`51/51`).
- Post-sync Commander-legal queue is now:
  `target_identity_count=26257`, `xmage_authoritative_source_count=25943`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=25943`. This reduces the
  `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` work unit
  from `433` to `407`.
- The post-PG484 exact split recheck reports `proposal_count=0` and
  `safe_for_batch_pg_package_count=0`. The next work should continue with the
  highest-impact remaining work units, currently led by recursion,
  draw-engine, protection, direct damage, residual add-counter variants, life
  gain, targeted removal, draw cards, tutor, and the remaining board-wipe
  blockers.

## Required Artifacts Per Cycle

Every cycle must produce or refresh:

- global all-card readiness report;
- authoritative XMage adaptation queue;
- exact-scope split report for the selected family/subpattern;
- blocked-reason counts for unsafe neighbors;
- focused tests/runtime output for any executable change;
- PostgreSQL package evidence when a durable rule is promoted;
- PG -> Hermes/SQLite sync report after apply;
- canonical snapshot refresh;
- E2E package validation;
- final alignment audits;
- post-sync queue rebuild proving the package reduced a real queue dimension.

## Stop Conditions

A card is considered closed for battle/deckbuilding only when all are true:

1. identity and Oracle hash are known or explicitly excepted;
2. exact local source/reference is recorded or exception lane is documented;
3. `effect_json` has exact scope, not only generic family;
4. focused positive and negative tests pass;
5. runtime either supports the behavior or the behavior is deliberately
   annotation-only;
6. PostgreSQL row is reviewed/trusted when executable behavior is durable;
7. Hermes/SQLite was synced from PostgreSQL after apply;
8. affected deck/replay audit no longer reports the card as unresolved.

## Non-Negotiable Safety Rules

- Do not promote from `xmage_*_review_v1`.
- Do not execute pattern registry rows.
- Do not let Hermes overwrite PostgreSQL.
- Do not join raw multi-row `card_battle_rules`, `card_function_tags`, or
  `card_semantic_tags_v2` directly into deck-card consumers without
  aggregation.
- Do not count a battle swap/test as evidence for a card unless that card was
  drawn/used or the focused test explicitly exercised it.
- Do not start full-XMage parsing work that does not reduce the active queue.

## Practical Next Command

The next productive command should rebuild the global authoritative queue after
any new runtime/package wave, then pick the highest queue-reducing exact scope:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_adaptation_queue.py \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --scope commander_legal_battle_gap \
  --out-prefix docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_$(date -u +%Y%m%d_%H%M%S)_current
```

Then inspect `summary.top_adapter_work_units`, implement the next exact
subpattern, and rerun:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  --queue docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_YYYYMMDD_HHMMSS_current.json \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_YYYYMMDD_HHMMSS_next
```

Do not select work by intuition when the global queue reports disagree.
