# PG455 XMage Static Horsemanship Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-05T00:09:38Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_static_self_horsemanship_creature`
- Battle model scope: `xmage_static_self_horsemanship_creature_v1`

## Scope

PG455 promoted creatures with exact static self Horsemanship source:
`HorsemanshipAbility.getInstance()` and exact Oracle text `Horsemanship`.
Runtime treats horsemanship as an evasion keyword: a creature with
horsemanship cannot be blocked except by creatures with horsemanship.

Selected cards: Barbarian General, Lady Zhurong, Warrior Queen, Lu Meng, Wu
General, Shu Cavalry, Shu Elite Companions, Wei Elite Companions, Wei Scout,
Wei Strike Force, Wu Elite Cavalry, and Wu Light Cavalry.

## PostgreSQL Apply

- Precheck: `10` target rows, `0` missing targets, `0` existing expected rows,
  `0` shadow rows to deprecate.
- Apply: transaction committed, `0` backup rows, `0` deprecated shadow rows,
  `10` upserted rows.
- Postcheck: all `10` cards have promoted `verified`/`auto` rules with Oracle
  hashes; `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `10` promoted rows are
  `verified`/`auto`/`curated`, have an Oracle hash, set
  `static_effect=self_horsemanship`, and expose `keywords=["horsemanship"]`
  plus `horsemanship=true`.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5385` requested unique names, `5570` PostgreSQL cards
  matched, `5480` SQLite alias rows, `2699/2699` deck-card rows matched, `97`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4403` PostgreSQL rows loaded, `4395` SQLite rows
  inserted/updated, `4370` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `10` selected cards. Generic battle
  scenario count remained `0`; horsemanship blocker legality is covered by
  focused runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface (`39/39`),
  legacy contamination (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26483`,
  `xmage_authoritative_source_count=26169`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26169`.
- Post-sync exact split: `proposal_count=144`,
  `safe_for_batch_pg_package_count=144`.
- Largest remaining exact families:
  `xmage_fixed_draw_discard_spell=9`,
  `xmage_fixed_scry_draw_card_spell=9`,
  `xmage_creature_dies_fixed_damage_target=8`,
  `xmage_destroy_target_scry_spell=8`, and
  `xmage_fixed_damage_scry_spell=8`.
