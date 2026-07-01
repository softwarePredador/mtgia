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

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg313_permanent_activated_self_boost_wave.md`

Current measured queue:

- target all-card battle-gap identities: `27452`
- XMage authoritative source resolved: `27138`
- local XMage missing-source exceptions: `314`
- parser gaps after XMage source resolution: `0`
- XMage authoritative adapter required: `27138`
- ManaLoom adapter work-unit keys: `11429`
- authoritative source coverage ratio: `0.9886`

Interpretation:

- The old mental model, "review 28k cards manually", is wrong.
- For `27138` identities, card semantics are accepted from XMage; work is now
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

## PG283-PG313 Exact Adapter Waves

As of 2026-07-01, the PG283-PG313 all-card exact adapter waves are applied and
synced.

Use
`docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py`
after building the authoritative queue. This splitter is the required bridge
between broad XMage work units and PostgreSQL package candidates. It only
selects narrow, runtime-backed signatures and blocks modes, variables,
additional costs, conditional costs, compound effects, and unsupported target
patterns:

- `draw_cards::xmage_draw_card_variant_review_v1` ->
  `xmage_fixed_source_controller_draw_spell_v1`
- `direct_damage::targeted_damage_variant_v1` ->
  `xmage_fixed_damage_target_spell_v1`
- `removal_destroy::targeted_destroy_variant_v1` ->
  `xmage_destroy_target_spell_v1`
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
  `GainLifeEffect + EntersBattlefieldTriggeredAbility` on creatures and fixed
  Oracle/source amount ->
  `xmage_creature_etb_gain_life_v1`
- `draw_engine::xmage_draw_card_variant_review_v1` with
  `DrawCardSourceControllerEffect + EntersBattlefieldTriggeredAbility` on
  creatures and fixed Oracle/source draw count ->
  `xmage_creature_etb_draw_cards_v1`
- `draw_engine::xmage_draw_card_variant_review_v1` with
  `DrawCardSourceControllerEffect + DiesSourceTriggeredAbility` on creatures,
  optional static self keywords, and exact fixed "When/Whenever this creature
  dies, draw N cards" Oracle text ->
  `xmage_creature_dies_draw_cards_v1`
- `draw_engine::xmage_draw_card_variant_review_v1` with
  `DrawCardSourceControllerEffect + SimpleActivatedAbility` on permanents,
  exact fixed Oracle activated draw text, mana/tap/self-sacrifice costs only,
  and no discard, target-tap, life, graveyard, or dynamic "for each" costs ->
  `xmage_permanent_simple_activated_draw_v1`
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
- `direct_damage::targeted_damage_variant_v1` with
  `DamageTargetEffect + SimpleActivatedAbility` on creatures, exact Oracle
  `{T}: ... deals N damage ...`, XMage `TapSourceCost` only, and no mana or
  sacrifice cost ->
  `xmage_creature_tap_fixed_damage_target_activated_v1` with nested
  `xmage_tap_fixed_damage_target_activated_ability_v1`
- `direct_damage::targeted_damage_variant_v1` with
  `DamageTargetEffect + SimpleActivatedAbility` on permanents, exact fixed
  activated damage Oracle text, mana/tap/self-sacrifice source costs only, and
  simple `any target` or `target creature` targets ->
  `xmage_permanent_simple_activated_damage_v1`
- `removal_destroy::targeted_destroy_variant_v1` with
  `DestroyTargetEffect + SimpleActivatedAbility` on permanents, exact activated
  destroy-target Oracle text, mana/tap/source self-sacrifice costs only, no
  discard/exile/OrCost/CompositeCost/sacrifice-target costs, and supported
  battlefield target constraints ->
  `xmage_permanent_simple_activated_destroy_target_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` with
  `ReturnFromGraveyardToHandTargetEffect + SimpleActivatedAbility` on
  permanents, exact Oracle activated graveyard-to-hand text, mana/tap/source
  self-sacrifice costs only, no discard/exile/OrCost/CompositeCost, and
  supported graveyard targets including creature, artifact, enchantment,
  artifact creature, basic land, permanent, instant/sorcery, artifact or
  enchantment, and any card when source and Oracle agree ->
  `xmage_permanent_simple_activated_graveyard_to_hand_v1`
- `xmage_signature::BoostSourceEffect::SimpleActivatedAbility::no_target_class::no_condition_class::activated_ability`
  with exact activated self power/toughness boost text, battlefield permanents,
  simple mana/tap source costs only, no life/discard/sacrifice-target/untap or
  target-tap costs, no hybrid/Phyrexian/untap-symbol costs, no dynamic X boost,
  and no modal/compound text ->
  `xmage_permanent_simple_activated_self_boost_until_eot_v1`
- `removal_exile::targeted_exile_variant_v1` ->
  `xmage_exile_target_spell_v1`
- fixed damage, destroy and exile target spells with XMage/Oracle-matched
  restricted battlefield target constraints for attacking/blocking,
  tapped/untapped, flying, color inclusion/exclusion, power minimum, and mana
  value minimum targets remain in those same exact scopes with structured
  `target_constraints`.
- `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` and
  `ramp_permanent::xmage_creature_mana_source_variant_review_v1` ->
  `xmage_simple_tap_mana_source_permanent_v1`
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
- `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` ->
  `xmage_destroy_all_matching_permanents_spell_v1` and
  `xmage_fixed_damage_all_matching_permanents_spell_v1`
- `add_counters::targeted_add_counters_variant_v1` ->
  `xmage_fixed_add_counters_target_creature_spell_v1`
- `xmage_signature::BoostTargetEffect::no_ability_class::TargetCreaturePermanent::no_condition_class::targeting` ->
  `xmage_fixed_boost_target_creature_until_eot_spell_v1`
- `grant_protection_from_chosen_color::xmage_targeted_protection_variant_review_v1`
  with one `BoostTargetEffect`, one `GainAbilityTargetEffect`, one fixed target
  creature, and exact until-end-of-turn keyword Oracle text ->
  `xmage_fixed_boost_and_keyword_target_creature_until_eot_spell_v1`
- `xmage_signature::no_effect_class::<combat keyword ability classes>::no_target_class::no_condition_class::no_signal` ->
  `xmage_static_self_combat_keyword_creature_v1`
- `token_maker::xmage_signature::CreateTokenEffect::no_ability_class::no_target_class::no_condition_class::token` with
  one fixed `CreateTokenEffect`, a literal token class constructor, no
  additional token fanout, no custom effect text, and token keywords limited to
  `flying` or `haste` ->
  `xmage_fixed_create_creature_tokens_spell_v1`
- `token_maker::xmage_signature::CreateTokenEffect::EntersBattlefieldTriggeredAbility::no_target_class::no_condition_class::token,triggered_ability` with
  one fixed ETB `CreateTokenEffect`, a literal token class constructor, no
  additional token fanout, no custom effect text, and token keywords limited to
  `flying` or `haste` ->
  `xmage_creature_etb_create_tokens_v1`

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
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_gap_family_queue_20260630_post_pg280_kayla_music_box.md`;
  blocked runtime gaps are now `12`, manual mapper backlog remains `0`, and all
  `12` remaining cards are routed to `split_family_scope_review_required`.
  `Ghoulcaller's Bell` is filtered out as a current verified/auto rule after
  PG277, and `Lantern of Insight` is filtered out as a current verified/auto
  rule after PG278; `Possibility Storm` is filtered out as a current
  verified/auto rule after PG279; `Kayla's Music Box` is filtered out as a
  current verified/auto rule after PG280. The remaining split families are `free_cast=1`,
  `passive=2`, `recursion=2`, `board_wipe_choice=2`, `token_maker=2`,
  `topdeck_play=1`, `draw_engine=1`, and `tutor=1`.
- Current Lorehold runtime readiness handoff after PG280:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_runtime_candidate_readiness_20260630_post_pg280_kayla_music_box.md`;
  `Hidden Retreat` and `Brainstone` are `pg_package_applied_synced`, not
  apply-pending. The paired post-PG280 runtime-gap queue filters `Codex
  Shredder`, `Perpetual Timepiece`, `Chaos Wand`, `Assemble the Players`,
  `Ghoulcaller's Bell`, `Lantern of Insight`, `Possibility Storm`, and
  `Kayla's Music Box` as current verified/auto active rules.

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

### Gate 0 - Scope Selection

Input:

- latest battle/replay artifact scope;
- forced deck IDs such as Lorehold deck 6 and relevant learned opponent decks;
- any explicit user-specified decks.

Output:

- `aggregate_scope.effective_deck_ids`
- combined deck-card coherence report

Rules:

- Replay/deck evidence prioritizes work.
- Replay/deck evidence does not define rule truth.

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

Use this order until a fresh E2E queue changes it:

1. Close any exact package-ready lane only if it is non-generic and has focused
   runtime/test proof.
2. Split and test `ramp_permanent` because it currently has `49` cards and is
   turn-timing critical.
3. Split and test `targeted_interaction` because it now has `24` cards after
   blink, redirect, multi-damage, and target-untap routing.
4. Split and test `tutor` because it has `14` cards and strongly affects
   combo/deck search behavior.
5. Split and test `free_cast` because it has `11` cards and high runtime risk.
6. Split and test `passive`, `recursion`, `targeted_protection`,
   `ramp_ritual`, and `life_total_change` in that order unless a replay/deck
   priority makes one urgent.
7. Treat the remaining `token_maker` runtime item as an exact Hazel's
   Brewmaster exception, not as permission to implement a generic token-maker
   executor.
8. Work the remaining `manual_model` backlog by adding mapper patterns, not by
   reviewing one card at a time.

## Required Artifacts Per Cycle

Every cycle must produce or refresh:

- current replay/deck scope manifest;
- combined coherence report;
- XMage index;
- validity audit;
- semantic family report;
- proposal report;
- shadow pattern registry;
- focused tests/runtime output for any executable change;
- PostgreSQL package evidence when a durable rule is promoted;
- PG -> Hermes sync report after apply;
- post-sync deck/replay audit.

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

The next productive command should rebuild the current queue after any new
runtime/package wave, then pick the highest queue-reducing exact scope:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --skip-materialize \
  --include-deck-id 6 \
  --include-deck-id 607 \
  --include-deck-id 608 \
  --include-deck-id 609 \
  --include-deck-id 610 \
  --include-deck-id 611 \
  --include-deck-id 612 \
  --include-deck-id 613 \
  --include-deck-id 614 \
  --include-deck-id 615 \
  --include-deck-id 616 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_$(date -u +%Y%m%d_%H%M%S)_current
```

Then use the manifest/family/proposal/pattern reports to select the next exact
scope. Do not select work by intuition when the queue reports disagree.
