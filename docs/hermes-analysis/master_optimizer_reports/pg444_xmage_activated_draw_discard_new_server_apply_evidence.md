# PG444 XMage Activated Draw Discard Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T22:48:15Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_permanent_simple_activated_draw_discard`
- Battle model scope: `xmage_permanent_simple_activated_draw_discard_v1`

## Scope

PG444 promoted local XMage `DrawDiscardControllerEffect + SimpleActivatedAbility`
permanents whose Oracle text is a supported activated draw/discard pattern.
The package did not promote generic review rows and did not introduce a manual
override path.

Selected cards: Bloodfire Mentor, Captain of Umbar, Dragonborn Looter, Emmessi
Tome, Erratic Visionary, Facet Reader, Hapless Researcher, Jalum Tome, Magus of
the Bazaar, Merfolk Looter, Research Assistant, Soothsayer Adept, Teferi's
Protege, Thought Courier, and Unfulfilled Desires.

## PostgreSQL Apply

- Precheck: `15` target rows, `0` missing targets, `0` existing expected rows,
  `0` shadow rows to deprecate.
- Apply: transaction committed, `0` backup rows, `0` deprecated shadow rows,
  `15` upserted rows.
- Postcheck: all `15` cards have one promoted `verified`/`auto` rule with an
  Oracle hash; `failed_cards=[]`.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5255` requested unique names, `5440` PostgreSQL cards
  matched, `5350` SQLite alias rows, `2699/2699` deck-card rows matched, `96`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4273` PostgreSQL rows loaded, `4265` SQLite rows
  inserted/updated, `4240` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `15` selected cards. Generic battle
  scenario count remained `0`; the family behavior is covered by focused
  runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface, legacy
  contamination, and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26613`,
  `xmage_authoritative_source_count=26299`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26299`.
- Post-sync exact split: `proposal_count=274`,
  `safe_for_batch_pg_package_count=274`.
- Largest remaining exact families: `xmage_dynamic_count_boost_target_creature_until_eot_spell=14`,
  `xmage_library_search_spell=14`, `xmage_self_sacrifice_mana_source_permanent=13`,
  `xmage_static_self_cant_block_creature=13`, and `xmage_fixed_draw_spell=12`.
