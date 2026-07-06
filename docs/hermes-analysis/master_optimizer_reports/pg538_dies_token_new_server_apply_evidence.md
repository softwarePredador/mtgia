# PG538 Dies Token New Server Apply Evidence

Generated UTC: `2026-07-06T00:15:51Z`

## Scope

- Package: `pg538_dies_token_new_server`
- Family: `xmage_creature_dies_create_tokens`
- Runtime scope: `xmage_creature_dies_create_tokens_v1`
- Cards promoted:
  - `Carrier Thrall`
  - `Gravpack Monoist`

## PostgreSQL Package

- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg538_dies_token_new_server_package_manifest.json`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg538_dies_token_new_server_package_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg538_dies_token_new_server_package_apply.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg538_dies_token_new_server_package_rollback.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg538_dies_token_new_server_package_postcheck.sql`

## Apply Result

- Precheck:
  - `Carrier Thrall`: `target_card_rows=1`, existing expected row `0`, shadow rows `0`
  - `Gravpack Monoist`: `target_card_rows=1`, existing expected row `0`, shadow rows `0`
- Apply:
  - backup rows: `0`
  - deprecated shadow rows: `0`
  - upserted rows: `2`
- Postcheck:
  - `Carrier Thrall`: promoted rows `1`, verified/auto rows `1`, oracle hash rows `1`
  - `Gravpack Monoist`: promoted rows `1`, verified/auto rows `1`, oracle hash rows `1`

Manual PostgreSQL row verification:

| Card | Logical rule key | Status | Execution | Rule version | Scope | Token | Tapped | Sacrifice for colorless |
| --- | --- | --- | --- | ---: | --- | --- | --- | --- |
| `Carrier Thrall` | `battle_rule_v1:9862b96824b4a0eff6fa32e596659d8a` | `verified` | `auto` | 2 | `xmage_creature_dies_create_tokens_v1` | `Eldrazi Scion Token` | false | true |
| `Gravpack Monoist` | `battle_rule_v1:04f881988479704e8e63231c87908d7f` | `verified` | `auto` | 2 | `xmage_creature_dies_create_tokens_v1` | `Robot Token` | true | false |

## Runtime And Sync Evidence

- PostgreSQL -> SQLite sync:
  - report: `docs/hermes-analysis/master_optimizer_reports/pg538_dies_token_new_server_pg_to_sqlite_sync.json`
  - PostgreSQL rows loaded: `2`
  - SQLite inserted/updated: `2`
  - canonical snapshot rows exported: `6198`
- Package E2E:
  - report: `docs/hermes-analysis/master_optimizer_reports/pg538_dies_token_new_server_e2e_validation.md`
  - status: `pass`
  - scenarios: `2`
  - `Carrier Thrall`: created `1` `Eldrazi Scion Token`, sacrifice-for-colorless-mana validated
  - `Gravpack Monoist`: created `1` tapped `Robot Token`, self `flying` validated

## Post-Sync Queue Evidence

- Pre-cycle queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_pg538_source_commander_legal.md`
  - `target_identity_count=25814`
  - `xmage_authoritative_source_count=25500`
  - `xmage_authoritative_adapter_required_count=25500`
  - `token_maker=2375`
- Post-cycle queue: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg538_dies_token_new_server_commander_legal.md`
  - `target_identity_count=25812`
  - `xmage_authoritative_source_count=25498`
  - `xmage_authoritative_adapter_required_count=25498`
  - `token_maker=2373`
- Final exact-scope split:
  - report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg538_dies_token_new_server_final.md`
  - `proposal_count=0`
  - `safe_for_batch_pg_package_count=0`
  - `dies_token_oracle_not_simple=3`

## Final Audits

- XMage strategy: `26/26` pass
- PG/Hermes/SQLite contract: `51/51` pass
- Operational surface: `39/39` pass
- Legacy contamination: `32/32` pass

Residual boundary: PG538 only authorizes fixed creature dies triggers that create modeled creature tokens under `xmage_creature_dies_create_tokens_v1`. It does not authorize conditional dies token triggers, dynamic token counts, token choices, activated token makers, named legendary token exceptions, recursion tokens, or token ability payloads outside the fields validated in the package E2E.
