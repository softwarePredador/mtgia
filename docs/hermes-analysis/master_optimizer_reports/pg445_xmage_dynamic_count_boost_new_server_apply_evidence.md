# PG445 XMage Dynamic Count Boost Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T22:58:21Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_dynamic_count_boost_target_creature_until_eot_spell`
- Battle model scope: `xmage_dynamic_count_boost_target_creature_until_eot_spell_v1`

## Scope

PG445 promoted local XMage `BoostTargetEffect` spells where target creature gets
a dynamic stat modifier until end of turn and the amount is calculated from a
runtime-supported count source: controller battlefield permanents, controller
hand size, domain basic land types, or all-battlefield subtype counts.

Selected cards: Defile, Desert's Due, Drag Down, Feeding Frenzy, Gaea's Might,
Hunger of the Nim, Inner Calm, Outer Strength, Irradiate, Might of Alara, Might
of the Masses, Nightmarish End, Strength of Cedars, Warped Physique, and
Wirewood Pride.

## PostgreSQL Apply

- Precheck: `14` target rows, `0` missing targets, `0` existing expected rows,
  `2` shadow rows to deprecate.
- Apply: transaction committed, `2` backup rows, `2` deprecated shadow rows,
  `14` upserted rows.
- Postcheck: all `14` cards have one promoted `verified`/`auto` rule with an
  Oracle hash; `failed_cards=[]`.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5270` requested unique names, `5455` PostgreSQL cards
  matched, `5365` SQLite alias rows, `2699/2699` deck-card rows matched, `105`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4287` PostgreSQL rows loaded, `4279` SQLite rows
  inserted/updated, `4254` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `14` selected cards. Generic battle
  scenario count remained `0`; dynamic count boost behavior is covered by
  focused runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface, legacy
  contamination, and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26599`,
  `xmage_authoritative_source_count=26285`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26285`.
- Post-sync exact split: `proposal_count=260`,
  `safe_for_batch_pg_package_count=260`.
- Largest remaining exact families: `xmage_library_search_spell=14`,
  `xmage_self_sacrifice_mana_source_permanent=13`,
  `xmage_static_self_cant_block_creature=13`,
  `xmage_fixed_damage_exile_if_dies_spell=12`, and `xmage_fixed_draw_spell=12`.
