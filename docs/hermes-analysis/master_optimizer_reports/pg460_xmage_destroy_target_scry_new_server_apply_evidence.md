# PG460 XMage Destroy Target Scry Apply Evidence

Status: `closed`.

PG460 promoted destroy-target-then-scry spells into `xmage_destroy_target_and_scry_spell_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg460`
- Family: `xmage_destroy_target_scry_spell`
- Battle model scope: `xmage_destroy_target_and_scry_spell_v1`
- Selected cards: `8`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Target | Scry | Timing | Target constraints |
| --- | --- | ---: | --- | --- |
| `Artisan's Sorrow` | `artifact_or_enchantment` | `2` | `instant` | `{'card_types': ['artifact', 'enchantment']}` |
| `Expose to Daylight` | `artifact_or_enchantment` | `1` | `instant` | `{'card_types': ['artifact', 'enchantment']}` |
| `Get the Point` | `creature` | `1` | `instant` | `{'card_types': ['creature']}` |
| `Guiding Bolt` | `creature` | `2` | `instant` | `{'power_min': 4, 'card_types': ['creature']}` |
| `Rubble Reading` | `land` | `2` | `sorcery` | `{'card_types': ['land']}` |
| `Skywhaler's Shot` | `creature` | `1` | `instant` | `{'power_min': 3, 'card_types': ['creature']}` |
| `Tel-Jilad Justice` | `artifact` | `2` | `instant` | `{'card_types': ['artifact']}` |
| `Vanquish the Foul` | `creature` | `1` | `sorcery` | `{'power_min': 4, 'card_types': ['creature']}` |

## Evidence

- Precheck: `8` target rows, `0` missing targets, `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `8` rule rows upserted.
- Postcheck: `8` verified/auto rows and `8` oracle hash rows.
- Direct PostgreSQL verification: `8` rows with complete destroy+scry parameters.
- Sync: `4437` SQLite rows inserted/updated; `4412` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26127`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG460 safe batch proposals: `102`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg460_xmage_destroy_target_scry_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg460_xmage_destroy_target_scry_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg460_xmage_destroy_target_scry_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg460_destroy_target_scry_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg460_destroy_target_scry_new_server_recheck.md`
