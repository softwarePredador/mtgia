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

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260701_post_pg292_static_keyword_creature_wave.md`

Current measured queue:

- target all-card battle-gap identities: `30844`
- XMage authoritative source resolved: `27908`
- local XMage missing-source exceptions: `2936`
- parser gaps after XMage source resolution: `0`
- ManaLoom adapter work-unit keys: `12065`
- authoritative source coverage ratio: `0.9048`

Interpretation:

- The old mental model, "review 28k cards manually", is wrong.
- For `27908` identities, card semantics are accepted from XMage; work is now
  adapter implementation and effect-family classification.
- `2936` identities remain residual exceptions because the local XMage checkout
  did not resolve a source class in the all-card scope. These are a separate
  official/Forge/manual-model or product-exclusion lane, not a reason to slow
  the XMage-resolved adapter queue.
- Generic `xmage_*_review_v1` scopes and fallback manual-model hints are
  adapter work-unit names. Fallback hints must be split by real XMage Java
  class/effect/ability signatures; they are blocked only from executable PG
  promotion until ManaLoom has the matching runtime adapter.
- This goal stops only when the refreshed global queue has no remaining
  `xmage_authoritative_adapter_required`, no `xmage_authoritative_parser_gap`,
  and every `xmage_missing_source_exception` is classified into an explicit
  official/Forge/manual-model or product-exclusion lane with evidence.

## PG283-PG292 Exact Adapter Waves

As of 2026-07-01, the PG283-PG292 all-card exact adapter waves are applied and
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
- `removal_exile::targeted_exile_variant_v1` ->
  `xmage_exile_target_spell_v1`
- `ramp_permanent::xmage_artifact_mana_source_variant_review_v1` and
  `ramp_permanent::xmage_creature_mana_source_variant_review_v1` ->
  `xmage_simple_tap_mana_source_permanent_v1`
- `counter_spell::counter_target_stack_object_variant_v1` ->
  `xmage_counter_target_spell_v1`
- `bounce::targeted_return_to_hand_variant_v1` ->
  `xmage_return_target_to_hand_spell_v1`
- `recursion::xmage_graveyard_return_variant_review_v1` ->
  `xmage_return_target_graveyard_card_to_hand_spell_v1`
- `board_wipe::xmage_mass_removal_or_sacrifice_variant_review_v1` ->
  `xmage_destroy_all_matching_permanents_spell_v1` and
  `xmage_fixed_damage_all_matching_permanents_spell_v1`
- `add_counters::targeted_add_counters_variant_v1` ->
  `xmage_fixed_add_counters_target_creature_spell_v1`
- `xmage_signature::BoostTargetEffect::no_ability_class::TargetCreaturePermanent::no_condition_class::targeting` ->
  `xmage_fixed_boost_target_creature_until_eot_spell_v1`
- `xmage_signature::no_effect_class::<combat keyword ability classes>::no_target_class::no_condition_class::no_signal` ->
  `xmage_static_self_combat_keyword_creature_v1`

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
