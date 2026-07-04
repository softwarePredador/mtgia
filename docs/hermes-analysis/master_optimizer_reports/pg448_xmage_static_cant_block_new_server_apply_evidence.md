# PG448 XMage Static Can't Block Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T23:17:31Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_static_self_cant_block_creature`
- Battle model scope: `xmage_static_self_cant_block_creature_v1`

## Scope

PG448 promoted local XMage creatures with the exact static self restriction
`CantBlockAbility`, matching Oracle text of "can't block". Runtime behavior
excludes these creatures from blocker assignment while leaving other legal
blockers available.

Selected cards: Ashenmoor Gouger, Craven Giant, Craven Knight, Goblin Raider,
Hulking Cyclops, Hulking Goblin, Hulking Ogre, Jungle Lion, Ogre Taskmaster,
Scavenging Scarab, Spineless Thug, Yellow Scarves Troops, and Young Wei
Recruits.

## PostgreSQL Apply

- Precheck: `13` target rows, `0` missing targets, `0` existing expected rows,
  `0` shadow rows to deprecate.
- Apply: transaction committed, `0` backup rows, `0` deprecated shadow rows,
  `13` upserted rows.
- Postcheck: all `13` cards have one promoted `verified`/`auto` rule with an
  Oracle hash; `failed_cards=[]`.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5308` requested unique names, `5493` PostgreSQL cards
  matched, `5403` SQLite alias rows, `2699/2699` deck-card rows matched, `108`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4327` PostgreSQL rows loaded, `4319` SQLite rows
  inserted/updated, `4294` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `13` selected cards. Generic battle
  scenario count remained `0`; static can't-block behavior is covered by
  focused runtime blocker-assignment tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface, legacy
  contamination, and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26559`,
  `xmage_authoritative_source_count=26245`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26245`.
- Post-sync exact split: `proposal_count=220`,
  `safe_for_batch_pg_package_count=220`.
- Largest remaining exact families: `xmage_fixed_damage_exile_if_dies_spell=12`,
  `xmage_fixed_draw_spell=12`, `xmage_static_self_cant_be_blocked_creature=11`,
  `xmage_static_self_protection_from_card_types_creature=11`, and
  `xmage_creature_attack_target_keyword_until_eot=10`.
