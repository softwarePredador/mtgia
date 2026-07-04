# PG447 XMage Self-Sacrifice Mana Source Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T23:10:27Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_self_sacrifice_mana_source_permanent`
- Battle model scope: `xmage_self_sacrifice_mana_source_permanent_v1`

## Scope

PG447 promoted local XMage permanents whose simple activated mana ability
sacrifices the source itself to produce fixed mana. Runtime behavior is
contextual: these sources are not refreshed automatically and are sacrificed
only when the extra mana unlocks a material action.

Selected cards: Basal Thrull, Blood Pet, Blood Vassal, Catalyst Elemental, Coal
Golem, Composite Golem, Crosis's Attendant, Darigaaz's Attendant, Dromar's
Attendant, Morgue Toad, Rith's Attendant, Satyr Hedonist, and Treva's Attendant.

## PostgreSQL Apply

- Precheck: `13` target rows, `0` missing targets, `0` existing expected rows,
  `0` shadow rows to deprecate.
- Apply: transaction committed, `0` backup rows, `0` deprecated shadow rows,
  `13` upserted rows.
- Postcheck: all `13` cards have one promoted `verified`/`auto` rule with an
  Oracle hash; `failed_cards=[]`.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5296` requested unique names, `5481` PostgreSQL cards
  matched, `5391` SQLite alias rows, `2699/2699` deck-card rows matched, `79`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4314` PostgreSQL rows loaded, `4306` SQLite rows
  inserted/updated, `4281` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `13` selected cards. Generic battle
  scenario count remained `0`; self-sacrifice mana behavior is covered by
  focused runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface, legacy
  contamination, and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26572`,
  `xmage_authoritative_source_count=26258`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26258`.
- Post-sync exact split: `proposal_count=233`,
  `safe_for_batch_pg_package_count=233`.
- Largest remaining exact families: `xmage_static_self_cant_block_creature=13`,
  `xmage_fixed_damage_exile_if_dies_spell=12`, `xmage_fixed_draw_spell=12`,
  `xmage_static_self_cant_be_blocked_creature=11`, and
  `xmage_static_self_protection_from_card_types_creature=11`.
