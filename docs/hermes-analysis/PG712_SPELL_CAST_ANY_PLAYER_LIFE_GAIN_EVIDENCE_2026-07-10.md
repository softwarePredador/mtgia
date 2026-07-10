# PG712 Spell-Cast Any-Player Life Gain Evidence - 2026-07-10

Status: `applied_validated_new_server`.

## Scope

Implemented and promoted the exact XMage -> ManaLoom scope
`xmage_spell_cast_gain_life_v1` for the simple lucky-charm pattern:

- `Angel's Feather`
- `Demon's Horn`
- `Dragon's Claw`
- `Kraken's Eye`
- `Wurm's Tooth`

XMage source pattern:

- `SpellCastAllTriggeredAbility(new GainLifeEffect(...), color filter, true)`
- Custom `TriggeredAbilityImpl` classes for `Kraken's Eye` and `Wurm's Tooth`
  using `SPELL_CAST` plus `spell.getColor(game).isBlue/isGreen()`.

Runtime behavior proven:

- The permanent's controller gains life when any player, including an opponent,
  casts the matching colored spell.
- Nonmatching spell colors do not trigger the rule.

## Code Changes

- `xmage_authoritative_exact_scope_split.py`
  - Added any-player spell-cast gain-life parsing.
  - Added `StaticValue.get(1)` amount parsing for `GainLifeEffect`.
  - Added custom `KrakensEyeAbility` and `WurmsToothAbility` support.
  - Kept optional-cost variants blocked.
- `battle_analyst_v9.py`
  - Added runtime pass for `spell_cast_gain_life_any_player` permanents
    controlled by non-casting players.
- `xmage_batch_pg_package_builder.py`
  - Added `spell_cast_gain_life_any_player` to required field allowlist.
  - E2E scenarios now use opponent-cast matching spells for any-player rules.
  - Nonmatching spell colors are selected to truly differ from the required
    color.
- `battle_package_end_to_end_validation.py`
  - Added support for `matching_spell_controller` and
    `nonmatching_spell_controller`.

## Validation

Focused tests:

```bash
python3 -m pytest \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q
```

Result:

- `1164 passed, 206 subtests passed`

Compile check:

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_authoritative_exact_scope_split.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_batch_pg_package_builder.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_package_end_to_end_validation.py
```

Result: pass.

## PostgreSQL Package

Generated package:

- `docs/hermes-analysis/master_optimizer_reports/pg712_spell_cast_any_player_life_gain_new_server_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg712_spell_cast_any_player_life_gain_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg712_spell_cast_any_player_life_gain_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg712_spell_cast_any_player_life_gain_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg712_spell_cast_any_player_life_gain_new_server_rollback.sql`

Precheck:

- target rows: `5`
- existing rule rows: `0`
- shadow rows to deprecate: `0`

Apply:

- upserted rows: `5`
- deprecated shadow rows: `0`

Postcheck:

- promoted rule rows: `5`
- promoted verified/auto rows: `5`
- promoted oracle hash rows: `5`

## Sync And E2E

PG -> SQLite/snapshot sync:

- database target: `127.0.0.1:15432/halder`
- PG rows loaded: `6224`
- SQLite inserted/updated: `6219`
- canonical snapshot rows exported: `6175`

E2E package validation:

- status: `pass`
- PostgreSQL source of truth: `5/5`
- SQLite Hermes cache: `5/5`
- canonical snapshot fallback: `5/5`
- runtime `get_card_effect`: `5/5`
- battle execution: `5/5`
- all five scenarios show `trigger_spell_controller = Opponent` and
  `life_after = 21`.

## Readiness Impact

Post-PG712 global readiness:

- `snapshot_has_verified_rule`: `6298`
- `battle_and_oracle_ready`: `6273`
- `battle_family_mapper_required`: `27603`
- `generic_runtime_or_no_card_rule`: `359`
- `commander_illegal_block`: `2997`
- `digital_non_commander_rule_exception`: `3`
- `official_oracle_identity_unavailable`: `3`

Post-PG712 Commander-legal XMage queue:

- target identities: `24680`
- XMage authoritative source: `24367`
- missing source exceptions: `313`
- parser gaps: `0`
- adapter required: `24367`
- `life_gain::xmage_life_gain_variant_review_v1`: `658`

Post-PG712 exact-scope recheck:

- proposal count: `0`
- safe for batch PG package: `0`

Interpretation: this adapter/runtime extension is fully consumed for the
currently supported exact scopes. The next global progress step requires a new
family/subpattern implementation.

## Final Audits

- `pg_hermes_sqlite_contract_audit_20260710_post_pg712_spell_cast_any_player_life_gain_new_server_final`: pass, `51/51`
- `xmage_strategy_consistency_audit_20260710_post_pg712_spell_cast_any_player_life_gain_new_server_final`: pass, `26/26`
- `operational_surface_alignment_audit_20260710_post_pg712_spell_cast_any_player_life_gain_new_server_final`: pass
- `legacy_contamination_audit_20260710_post_pg712_spell_cast_any_player_life_gain_new_server_final`: pass
- `./scripts/quality_gate.sh server-target`: pass
