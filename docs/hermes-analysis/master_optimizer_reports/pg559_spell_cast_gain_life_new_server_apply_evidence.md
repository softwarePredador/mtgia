# PG559 Spell-Cast Life Gain New Server Apply Evidence

Status: `applied_and_validated`.

PG559 promoted `4` exact spell-cast life-gain trigger rows on the new server
for:

- `Contemplation`
- `Dawnhart Geist`
- `God-Pharaoh's Faithful`
- `Student of Ojutai`

## Source And Scope

- exact split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_pg559_spell_cast_gain_life_candidate.md`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg559_spell_cast_gain_life_new_server_package_package.md`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg559_spell_cast_gain_life_new_server_package_manifest.json`

The package adds `xmage_spell_cast_gain_life_v1` for exact XMage
`GainLifeEffect` rows backed by `SpellCastControllerTriggeredAbility`.

Supported filters in this cycle:

- any spell;
- enchantment spell;
- noncreature spell;
- color-filtered spell using XMage `ColorPredicate`.

## Apply Evidence

- precheck: `4/4` target card rows, `0` existing matching rules, `0` shadow
  rows to deprecate;
- apply: `upserted_rows=4`, `deprecated_shadow_rows=0`;
- postcheck: `4/4` promoted rows, `4/4` verified/auto rows, `4/4` oracle-hash
  rows.

Database target during apply/sync/E2E: `143.198.230.247:5433/halder`.

## Validation

- `py_compile` passed for the exact splitter, battle runtime, package builder,
  and package E2E validator;
- exact-scope unittest: `637` tests passed;
- battle runtime unittest: `338` tests passed;
- package/E2E pytest: `56` tests passed;
- PG -> SQLite sync loaded `8,990` PostgreSQL rows, updated `8,754` SQLite
  rows, and exported `6,491` canonical snapshot rows;
- package E2E: `status=pass`, `scenario_count=4`, `event_count=4`;
- E2E validated PostgreSQL source-of-truth rows, Hermes SQLite cache, canonical
  snapshot fallback, runtime `get_card_effect`, and battle execution for every
  promoted card;
- final exact-scope recheck: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`;
- final audits passed: XMage strategy `26/26`, PG-Hermes-SQLite `51/51`,
  operational surface `pass`, legacy contamination `pass`.

## Queue Impact

- pre-cycle `target_identity_count=25505`;
- post-cycle `target_identity_count=25501`;
- post-cycle `xmage_authoritative_source_count=25187`;
- post-cycle `xmage_missing_source_exception_count=314`;
- post-cycle `xmage_authoritative_parser_gap_count=0`;
- post-cycle `xmage_authoritative_adapter_required_count=25187`;
- post-cycle `adapter_work_unit_count=11354`;
- `life_gain::xmage_life_gain_variant_review_v1` fell from `693` to `689`.

## Readiness Snapshot

- `snapshot_has_verified_rule=5271`;
- `battle_and_oracle_ready=5449`;
- `battle_family_mapper_required=28424`;
- ready-product QA `battle_and_oracle_ready=269`;
- ready-product QA `battle_family_mapper_required=94`.

## Runtime Semantics

- `trigger_spell_cast_engines` now resolves controller life gain for exact
  `trigger_effect=gain_life` spell-cast triggers;
- supported filters are checked through `spell_cast_gain_life_filter_matches`;
- noncreature triggers skip creature spells;
- replay events record `trigger_resolved`, `effect=gain_life`,
  `life_gain_requested`, `life_gained`, life before/after,
  `trigger_spell_type_line`, `trigger_spell_source_zone`, and the supported
  spell filter metadata.

## Residual Boundary

PG559 does not promote `SpellCastAllTriggeredAbility` rows that trigger when
any player casts a spell, OR-combined triggers such as spell-cast plus landfall,
optional-cost spell-cast life gain, Adventure-specific filters, dynamic
life-gain amounts, or rows with unrelated auxiliary effects. Those require
their own exact mapper/runtime package.
