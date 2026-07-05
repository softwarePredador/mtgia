# PG521 XMage X Create Tokens Apply Evidence

- Generated at: `2026-07-05T18:07:00+00:00`
- Deploy ID: `xmage_pg521_x_create_tokens_new_server`
- Status: `applied_synced_validated`
- Source of truth: PostgreSQL `card_battle_rules`
- Runtime scope: `xmage_x_create_creature_tokens_spell_v1`

## Scope

PG521 promotes exact local-XMage one-shot spells whose source uses:

`new CreateTokenEffect(new TokenClass(), GetXValue.instance)`

Only non-land creature tokens are accepted in this package. Contextual dynamic
counts such as creatures you control, attacking creatures, creatures that died
this turn, and land creature tokens remain blocked until separate runtime
support exists.

## Promoted Cards

| Card | Token | Count |
| --- | --- | --- |
| `Goblin Offensive` | `1/1 red Goblin creature token` | `X` |
| `Secure the Wastes` | `1/1 white Warrior creature token` | `X` |

## PostgreSQL Evidence

Precheck:

- `target_card_rows=1` for both selected cards.
- `Goblin Offensive` had no existing rule rows.
- `Secure the Wastes` had 2 old shadow rows selected for deprecation.
- `would_deprecate_shadow_rows=2`.

Apply:

- `deprecated_shadow_rows=2`
- `upserted_rows=2`
- transaction committed.

Postcheck:

- both selected cards have `promoted_rule_rows=1`.
- both selected cards have `promoted_verified_auto_rows=1`.
- both selected cards have `promoted_oracle_hash_rows=1`.
- deploy backup table captured 2 preexisting rows.

SQL package:

- `docs/hermes-analysis/master_optimizer_reports/pg521_xmage_pg521_x_create_tokens_new_server_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg521_xmage_pg521_x_create_tokens_new_server_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg521_xmage_pg521_x_create_tokens_new_server_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg521_xmage_pg521_x_create_tokens_new_server_rollback.sql`

## Sync And Runtime Evidence

PostgreSQL -> Hermes/SQLite sync:

- `selected_card_count=2`
- `pg_rows_loaded=4` because selected names include 2 deprecated shadow rows for
  `Secure the Wastes`.
- `sqlite_inserted_or_updated=4`
- `canonical_snapshot_rows_exported=6043`
- exact E2E validation confirmed 2 promoted executable rules.

E2E package validation:

- PostgreSQL source of truth: `pass`, validated rows `2`.
- SQLite Hermes cache: `pass`, validated rows `2`.
- canonical snapshot fallback: `pass`, validated cards `2`.
- runtime `get_card_effect`: `pass`, validated cards `2`.
- battle execution no override: `pass`.

Focused runtime smoke:

- `Goblin Offensive` loaded from `get_card_effect` with
  `battle_model_scope=xmage_x_create_creature_tokens_spell_v1`.
- With `_cast_context.x_value=3`, battle runtime created 3 `Goblin Token`
  permanents with `power=1`, `toughness=1`, and `colors=["R"]`.

Focused tests:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py test_xmage_batch_pg_package_builder.py`
- `Ran 851 tests`
- `OK`

Final audits:

- strategy consistency: `pass`, 26 checks.
- operational surface alignment: `pass`.
- legacy contamination: `pass`.
- PG/Hermes/SQLite contract: `pass`, 51 checks.

## Queue Delta

Before PG521, the post-PG520 authoritative queue reported:

- `target_identity_count=25971`
- `xmage_authoritative_source_count=25657`
- `xmage_authoritative_adapter_required_count=25657`

After PG521:

- `target_identity_count=25969`
- `xmage_authoritative_source_count=25655`
- `xmage_authoritative_adapter_required_count=25655`
- `battle_and_oracle_ready=4981`
- `battle_family_mapper_required=28892`
- final exact-scope split `proposal_count=0`
- final exact-scope split `safe_for_batch_pg_package_count=0`

## Residual Boundary

PG521 deliberately does not promote:

- land creature tokens such as `Awaken the Woods`, because the runtime must
  model land-token type and mana behavior before that is exact.
- contextual dynamic token counts such as token per Elf, per attacking creature,
  per creature that died this turn, or greatest power.
- token classes with unsupported keyword/runtime behavior.
- multiple token effects or `.withAdditionalTokens` rows.

Those cards require separate adapter/runtime work before PostgreSQL promotion.
