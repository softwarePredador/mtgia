# PG496 ETB Self-Target Add-Counters Apply Evidence

- Deploy ID: `xmage_pg496_etb_self_add_counters_new_server`
- PostgreSQL target: `143.198.230.247:5433/halder`
- Backup table: `manaloom_deploy_audit.xmage_pg496_etb_self_add_counters_new_se_20260705_090433`
- Selected cards: `5`
- Cards: Baleful Ammit, Crocodile of the Crossing, Kujar Seedsculptor, Ornery Kudu, Teyo's Lightshield
- Scope: `xmage_creature_etb_add_counters_target_creature_v1`
- Target controller: `self`

## Precheck

- `target_card_rows=1` for each selected card.
- `existing_rule_rows=0` for each selected card.
- `expected_rule_rows_before=0` for each selected card.
- `would_deprecate_shadow_rows=0`.

## Apply

```text
BEGIN
CREATE SCHEMA
SELECT 0
DO
 deprecated_shadow_rows
------------------------
                      0
(1 row)

 upserted_rows
---------------
             5
(1 row)

COMMIT
```

## Postcheck

- `promoted_rule_rows=1` for each selected card.
- `promoted_verified_auto_rows=1` for each selected card.
- `promoted_oracle_hash_rows=1` for each selected card.
- `backup_rows=0` for each selected card.

## Sync And Validation

- Metadata sync: `5937` PostgreSQL cards matched, `5848` SQLite cache alias rows, `108` deck-card id updates, `unresolved=1`.
- Battle-rule sync: `8380` PostgreSQL rows loaded, `8144` SQLite rows inserted/updated, `5914` canonical snapshot rows exported.
- E2E status: `pass` across PostgreSQL, SQLite Hermes cache, canonical snapshot fallback, and runtime `get_card_effect`.
- Focused runtime behavior: `test_pg496_etb_add_counters_self_negative_targets_own_expendable_creature` passed in the full battle suite.
- Full splitter suite: `495` tests OK.
- Full battle suite: `623` PASS lines.
- Final audits: XMage strategy, operational surface, legacy contamination, deckbuilding contract surface, and PG/Hermes/SQLite contract all passed.

## Queue Impact

- Commander-legal target identities: `26111`.
- XMage source-backed remaining: `25797`.
- Missing XMage source exceptions: `314`.
- Parser gaps: `0`.
- Adapter required remaining: `25797`.
- Global readiness: `battle_and_oracle_ready=4839`, `battle_family_mapper_required=29034`.
