# PG464 XMage Fixed Draw Self Cost Reduction Apply Evidence

Status: `closed`.

PG464 promoted fixed draw spells with self cost-reduction conditions into `xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1` using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg464`
- Family: `xmage_fixed_draw_spell_self_cost_reduction`
- Battle model scope: `xmage_fixed_source_controller_draw_spell_self_cost_reduction_v1`
- Selected cards: `7`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Draw | Reduction | Condition | Timing |
| --- | --- | --- | --- | --- |
| `Distorted Curiosity` | `2` | `2` | `opponent_poison_counters_at_least` | `sorcery` |
| `Draconic Lore` | `3` | `2` | `control_subtype` | `instant` |
| `Into the Story` | `4` | `3` | `opponent_graveyard_cards_at_least` | `instant` |
| `Of One Mind` | `2` | `2` | `control_human_and_nonhuman_creature` | `sorcery` |
| `Pearl of Wisdom` | `2` | `1` | `control_subtype` | `sorcery` |
| `Scour the Laboratory` | `3` | `2` | `delirium` | `instant` |
| `Winged Words` | `2` | `1` | `control_creature_with_keyword` | `sorcery` |

## Evidence

- Precheck: `7` target rows, `0` missing targets, `0` stale generated shadow rows to deprecate.
- Apply: transaction committed, `7` rule rows upserted.
- Postcheck: `7` verified/auto rows and `7` oracle hash rows.
- Direct PostgreSQL verification: `7` rows with complete draw and self cost-reduction parameters.
- Sync: `4467` SQLite rows inserted/updated; `4442` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26097`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG464 safe batch proposals: `72`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg464_xmage_fixed_draw_self_cost_reduction_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg464_xmage_fixed_draw_self_cost_reduction_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg464_xmage_fixed_draw_self_cost_reduction_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg464_fixed_draw_self_cost_reduction_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg464_fixed_draw_self_cost_reduction_new_server_recheck.md`
