# PG458 XMage Fixed Draw Lose Life Apply Evidence

Status: `closed`.

PG458 promoted fixed draw/life-loss spells into controller and target-player ManaLoom scopes using local XMage source as the behavioral authority.

## Scope

- Deploy ID: `pg458`
- Family: `xmage_fixed_draw_lose_life_spell`
- Battle model scopes: `xmage_fixed_controller_draw_lose_life_spell_v1`, `xmage_fixed_target_player_draw_lose_life_spell_v1`
- Selected cards: `8`
- PostgreSQL target: `143.198.230.247:5433/halder`

## Cards

| Card | Scope | Draw | Life loss | Target controller | Target preference |
| --- | --- | ---: | ---: | --- | --- |
| `Ambition's Cost` | `xmage_fixed_controller_draw_lose_life_spell_v1` | `3` | `3` | `self` | `None` |
| `Ancient Craving` | `xmage_fixed_controller_draw_lose_life_spell_v1` | `3` | `3` | `self` | `None` |
| `Blood Pact` | `xmage_fixed_target_player_draw_lose_life_spell_v1` | `2` | `2` | `target_player` | `self` |
| `Harrowing Journey` | `xmage_fixed_target_player_draw_lose_life_spell_v1` | `3` | `3` | `target_player` | `self` |
| `Night's Whisper` | `xmage_fixed_controller_draw_lose_life_spell_v1` | `2` | `2` | `self` | `None` |
| `Painful Lesson` | `xmage_fixed_target_player_draw_lose_life_spell_v1` | `2` | `2` | `target_player` | `self` |
| `Sign in Blood` | `xmage_fixed_target_player_draw_lose_life_spell_v1` | `2` | `2` | `target_player` | `self` |
| `Succumb to Temptation` | `xmage_fixed_controller_draw_lose_life_spell_v1` | `2` | `2` | `self` | `None` |

## Evidence

- Precheck: `8` target rows, `0` missing targets, `4` stale generated shadow rows to deprecate.
- Apply: transaction committed, `8` rule rows upserted; deprecated generated shadows: `Night's Whisper=2, Sign in Blood=2`.
- Postcheck: `8` verified/auto rows and `8` oracle hash rows.
- Direct PostgreSQL verification: `8` rows with complete draw/life-loss parameters.
- Sync: `4421` SQLite rows inserted/updated; `4396` canonical snapshot rows exported.
- E2E: `pass` across PostgreSQL, SQLite/Hermes, canonical snapshot and runtime lookup.
- Audits: XMage strategy `pass`, operational surface `pass`, legacy contamination `pass`, PG/Hermes/SQLite contract `pass`.

## Post-Sync Queue

- `xmage_authoritative_adapter_required_count`: `26143`
- `xmage_missing_source_exception_count`: `314`
- `xmage_authoritative_parser_gap_count`: `0`
- Post-PG458 safe batch proposals: `118`

## Artifacts

- Consolidated JSON: `docs/hermes-analysis/master_optimizer_reports/pg458_xmage_fixed_draw_lose_life_new_server_apply_evidence.json`
- Raw PostgreSQL apply evidence: `docs/hermes-analysis/master_optimizer_reports/pg458_xmage_fixed_draw_lose_life_new_server_pg_apply_evidence.json`
- E2E validation: `docs/hermes-analysis/master_optimizer_reports/pg458_xmage_fixed_draw_lose_life_new_server_e2e_validation.json`
- Queue recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260705_post_pg458_fixed_draw_lose_life_new_server_commander_legal.md`
- Exact split recheck: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg458_fixed_draw_lose_life_new_server_recheck.md`
