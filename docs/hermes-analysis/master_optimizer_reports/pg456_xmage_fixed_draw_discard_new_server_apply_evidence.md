# PG456 XMage Fixed Draw Discard Apply Evidence

Status: `closed`.

PG456 promoted fixed draw/discard instant-or-sorcery cards into `xmage_fixed_draw_discard_spell_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg456`
- Family: `xmage_fixed_draw_discard_spell`
- Battle model scope: `xmage_fixed_draw_discard_spell_v1`
- Selected cards: `9`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Draw | Discard | Order | Random discard |
| --- | ---: | ---: | --- | --- |
| `Ancestral Reminiscence` | `3` | `1` | `draw_then_discard` | `False` |
| `Careful Study` | `2` | `2` | `draw_then_discard` | `False` |
| `Catalog` | `2` | `1` | `draw_then_discard` | `False` |
| `Enhanced Awareness` | `3` | `1` | `draw_then_discard` | `False` |
| `Prying Eyes` | `4` | `2` | `draw_then_discard` | `False` |
| `Rain of Revelation` | `3` | `1` | `draw_then_discard` | `False` |
| `Romantic Rendezvous` | `2` | `1` | `discard_then_draw` | `False` |
| `Sift` | `3` | `1` | `draw_then_discard` | `False` |
| `Thoughtflare` | `4` | `2` | `draw_then_discard` | `False` |

## Evidence

- Precheck: `9` target rows, `0` missing targets, `0` shadow rows to deprecate.
- Apply: transaction committed, `9` rule rows upserted.
- Postcheck: `9` verified/auto rows and `9` oracle hash rows.
- Direct PostgreSQL verification: `9` rows with complete draw/discard parameters.
- Sync: `4404` SQLite rows inserted/updated; `4379` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26160`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG456 safe batch proposals: `135`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg456_xmage_fixed_draw_discard_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg456_xmage_fixed_draw_discard_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg456_xmage_fixed_draw_discard_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg456_fixed_draw_discard_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg456_fixed_draw_discard_new_server_recheck.md`
