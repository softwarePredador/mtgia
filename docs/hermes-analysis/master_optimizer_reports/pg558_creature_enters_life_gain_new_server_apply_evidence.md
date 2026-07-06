# PG558 Creature-Enters Life Gain New Server Apply Evidence

Status: `applied_and_validated`.

PG558 promoted `9` exact creature-enters life-gain trigger rows on the new
server for:

- `Ajani's Welcome`
- `Bogwater Lumaret`
- `Essence Warden`
- `Healer of the Pride`
- `Hinterland Sanctifier`
- `Impassioned Orator`
- `Kor Celebrant`
- `Soul Warden`
- `Soul's Attendant`

## Source And Scope

- exact split report:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260706_pg558_creature_enters_life_gain_candidate.md`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg558_creature_enters_life_gain_new_server_package_package.md`
- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg558_creature_enters_life_gain_new_server_package_manifest.json`

The package adds `xmage_creature_enters_life_gain_trigger_v1` for exact XMage
`GainLifeEffect` rows backed by:

- `EntersBattlefieldAllTriggeredAbility`
- `EntersBattlefieldControlledTriggeredAbility`
- `EntersBattlefieldThisOrAnotherTriggeredAbility`

## Apply Evidence

- precheck: `9/9` target card rows, `0` existing matching rules, `0` shadow
  rows to deprecate;
- apply: `upserted_rows=9`, `deprecated_shadow_rows=0`;
- postcheck: `9/9` promoted rows, `9/9` verified/auto rows, `9/9` oracle-hash
  rows.

Database target during sync/E2E: `143.198.230.247:5433/halder`.

## Validation

- `py_compile` passed for the exact splitter, battle runtime, package builder,
  and package E2E validator;
- exact-scope unittest: `633` tests passed;
- battle runtime unittest: `337` tests passed;
- package/E2E pytest: `54` tests passed;
- PG -> SQLite sync loaded `8,986` PostgreSQL rows, updated `8,750` SQLite
  rows, and exported `6,487` canonical snapshot rows;
- package E2E: `status=pass`, `scenario_count=9`, `event_count=9`;
- E2E validated PostgreSQL source-of-truth rows, Hermes SQLite cache, canonical
  snapshot fallback, runtime `get_card_effect`, and battle execution for every
  promoted card;
- final exact-scope recheck: `proposal_count=0`,
  `safe_for_batch_pg_package_count=0`;
- final audits passed: XMage strategy `26/26`, PG-Hermes-SQLite `51/51`,
  operational surface `pass`, legacy contamination `pass`.

## Queue Impact

- pre-cycle `target_identity_count=25514`;
- post-cycle `target_identity_count=25505`;
- post-cycle `xmage_authoritative_source_count=25191`;
- post-cycle `xmage_missing_source_exception_count=314`;
- post-cycle `xmage_authoritative_parser_gap_count=0`;
- post-cycle `xmage_authoritative_adapter_required_count=25191`;
- post-cycle `adapter_work_unit_count=11354`;
- `life_gain::xmage_life_gain_variant_review_v1` fell from `702` to `693`.

## Readiness Snapshot

- `snapshot_has_verified_rule=5267`;
- `battle_and_oracle_ready=5445`;
- `battle_family_mapper_required=28428`;
- ready-product QA `battle_and_oracle_ready=269`;
- ready-product QA `battle_family_mapper_required=94`.

## Runtime Semantics

- controlled creature-enter triggers now support `trigger_effect=gain_life`
  using `trigger_gain_life`;
- global creature-enter triggers now resolve life gain for opponent-controlled
  entering creatures when the source says `creature_enters`;
- another-creature-only triggers skip the source permanent itself;
- replay events record `trigger_resolved`, `effect=gain_life`,
  `life_gain_requested`, `life_gained`, and life before/after.

## Residual Boundary

PG558 does not promote noncreature enters-the-battlefield filters, subtype-only
creature filters such as Beast-specific triggers, token-only filters, optional
noncreature triggers, or any life-gain row with additional unrelated abilities.
Those require their own exact mapper/runtime package.
