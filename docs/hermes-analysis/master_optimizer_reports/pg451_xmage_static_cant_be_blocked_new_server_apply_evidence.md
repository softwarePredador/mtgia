# PG451 XMage Static Can't Be Blocked Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T23:41:05Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_static_self_cant_be_blocked_creature`
- Battle model scope: `xmage_static_self_cant_be_blocked_creature_v1`

## Scope

PG451 promoted creatures with exact static self-unblockable source:
`CantBeBlockedSourceAbility`, matching Oracle text that the creature cannot be
blocked. Runtime behavior excludes these creatures from legal blocker
assignment while leaving ordinary combat rules unchanged for other attackers.

Selected cards: Covert Operative, Jhessian Infiltrator, Latch Seeker, Metathran
Soldier, Mist-Cloaked Herald, Phantom Ninja, Phantom Warrior, Slither Blade,
Talas Warrior, Tidal Kraken, and Triton Shorestalker.

## PostgreSQL Apply

- Precheck: `11` target rows, `0` missing targets, `0` existing expected rows,
  `0` shadow rows to deprecate.
- Apply: transaction committed, `0` backup rows, `0` deprecated shadow rows,
  `11` upserted rows.
- Postcheck: all `11` cards have one promoted `verified`/`auto` rule with an
  Oracle hash; `failed_cards=[]`.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5344` requested unique names, `5529` PostgreSQL cards
  matched, `5439` SQLite alias rows, `2699/2699` deck-card rows matched, `107`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4362` PostgreSQL rows loaded, `4354` SQLite rows
  inserted/updated, `4329` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `11` selected cards. Generic battle
  scenario count remained `0`; unblockable combat assignment behavior is
  covered by focused runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface (`39/39`),
  legacy contamination (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26524`,
  `xmage_authoritative_source_count=26210`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26210`.
- Post-sync exact split: `proposal_count=185`,
  `safe_for_batch_pg_package_count=185`.
- Largest remaining exact families:
  `xmage_static_self_protection_from_card_types_creature=11`,
  `xmage_creature_attack_target_keyword_until_eot=10`,
  `xmage_fixed_damage_spell=10`,
  `xmage_static_self_horsemanship_creature=10`, and
  `xmage_fixed_draw_discard_spell=9`.
