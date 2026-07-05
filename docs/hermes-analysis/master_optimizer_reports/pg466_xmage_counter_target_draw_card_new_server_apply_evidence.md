# PG466 XMage Counter Target Draw Card Apply Evidence

Status: `closed`.

PG466 promoted counter-target-and-draw-card instants into `xmage_counter_target_and_draw_card_spell_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg466`
- Family: `xmage_counter_target_draw_card_spell`
- Battle model scope: `xmage_counter_target_and_draw_card_spell_v1`
- Selected cards: `6`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Counter target | Draw | Composite components |
| --- | --- | --- | --- |
| `Bone to Ash` | `creature_spell` | `1` | `2` |
| `Contradict` | `spell` | `1` | `2` |
| `Dismiss` | `spell` | `1` | `2` |
| `Exclude` | `creature_spell` | `1` | `2` |
| `Halt Order` | `artifact_spell` | `1` | `2` |
| `Scatter Arc` | `noncreature_spell` | `1` | `2` |

## Evidence

- Precheck: `6` target rows, `0` missing targets, `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `6` rule rows upserted.
- Postcheck: `6` verified/auto rows and `6` oracle hash rows.
- Direct PostgreSQL verification: `6` rows with exact target constraints, `draw_count=1`, `draw_on_counter=1`, and composite counter/draw components.
- Sync: `4480` SQLite rows inserted/updated; `4455` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26084`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG466 safe batch proposals: `59`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg466_xmage_counter_target_draw_card_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg466_xmage_counter_target_draw_card_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg466_xmage_counter_target_draw_card_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg466_counter_target_draw_card_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg466_counter_target_draw_card_new_server_recheck.md`
