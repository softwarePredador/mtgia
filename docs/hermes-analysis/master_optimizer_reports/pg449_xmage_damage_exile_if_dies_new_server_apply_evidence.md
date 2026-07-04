# PG449 XMage Damage Exile If Dies Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T23:26:57Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_fixed_damage_exile_if_dies_spell`
- Battle model scope: `xmage_fixed_damage_target_exile_if_dies_spell_v1`

## Scope

PG449 promoted fixed damage spells whose local XMage source combines
`DamageTargetEffect` with `ExileTargetIfDiesEffect`. The ManaLoom runtime scope
models fixed damage to the legal target and marks the damaged target to be
exiled if it dies from that damage.

Selected cards: Bot Bashing Time, Elspeth's Smite, Fanged Flames, Feed the
Flames, Flame-Blessed Bolt, Lava Coil, Magma Spray, Obliterating Bolt,
Puncturing Blow, Reduce to Ashes, Scorching Dragonfire, and Scorchmark.

## PostgreSQL Apply

- Precheck: `12` target rows, `0` missing targets, `0` existing expected rows,
  `0` shadow rows to deprecate.
- Apply: transaction committed, `0` backup rows, `0` deprecated shadow rows,
  `12` upserted rows.
- Postcheck: all `12` cards have one promoted `verified`/`auto` rule with an
  Oracle hash; `failed_cards=[]`.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5321` requested unique names, `5506` PostgreSQL cards
  matched, `5416` SQLite alias rows, `2699/2699` deck-card rows matched, `93`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4339` PostgreSQL rows loaded, `4331` SQLite rows
  inserted/updated, `4306` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `12` selected cards. Generic battle
  scenario count remained `0`; damage plus exile-if-dies behavior is covered by
  focused runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface (`39/39`),
  legacy contamination (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26547`,
  `xmage_authoritative_source_count=26233`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26233`.
- Post-sync exact split: `proposal_count=208`,
  `safe_for_batch_pg_package_count=208`.
- Largest remaining exact families: `xmage_fixed_draw_spell=12`,
  `xmage_static_self_cant_be_blocked_creature=11`,
  `xmage_static_self_protection_from_card_types_creature=11`,
  `xmage_creature_attack_target_keyword_until_eot=10`, and
  `xmage_fixed_damage_spell=10`.
