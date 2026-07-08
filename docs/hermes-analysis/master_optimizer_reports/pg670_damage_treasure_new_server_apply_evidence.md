# PG670 Damage Target Create Treasure - New Server Apply Evidence

- Date: 2026-07-08
- Target: new-server PostgreSQL via `server/bin/with_new_server_pg.sh`
- Package: `pg670_damage_treasure_new_server_package`
- Candidate source: `xmage_authoritative_exact_scope_split_20260708_pg670_damage_treasure_new_server_candidate`

## Scope

Promoted one XMage-authoritative exact runtime scope:

- `Improvised Weaponry`
- `battle_model_scope`: `xmage_fixed_damage_target_create_treasure_spell_v1`
- Runtime behavior: deal 2 damage to any target, then create 1 Treasure for the spell controller after damage resolution.

## Precheck

Command:

```bash
./server/bin/with_new_server_pg.sh bash -lc 'psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg670_damage_treasure_new_server_package_precheck.sql'
```

Result:

```text
target_card_rows=1
existing_rule_rows=0
expected_rule_rows_before=0
would_deprecate_shadow_rows=0
canonical_card_id=0e7dfbf5-f4f2-421e-ae09-1d97afc50115
```

## Apply

Command:

```bash
./server/bin/with_new_server_pg.sh bash -lc 'psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg670_damage_treasure_new_server_package_apply.sql'
```

Result:

```text
deprecated_shadow_rows=0
upserted_rows=1
commit=ok
```

## Postcheck

Command:

```bash
./server/bin/with_new_server_pg.sh bash -lc 'psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg670_damage_treasure_new_server_package_postcheck.sql'
```

Result:

```text
promoted_rule_rows=1
promoted_verified_auto_rows=1
promoted_oracle_hash_rows=1
backup_rows=0
```
