# PG450 XMage Fixed Draw Spell Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T23:35:10Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_fixed_draw_spell`
- Battle model scope: `xmage_fixed_source_controller_draw_spell_v1`

## Scope

PG450 promoted fixed draw spells whose local XMage source uses
`DrawCardSourceControllerEffect`, including supported additional costs for
sacrificing a creature, sacrificing an artifact or creature, discarding a card,
or discarding a land.

Selected cards: Altar's Reap, Blood Divination, Corrupted Conviction, Costly
Plunder, Eviscerator's Insight, Magmatic Insight, Morbid Curiosity, Skulltap,
Tormenting Voice, Village Rites, Vivisection, and Wild Guess.

## PostgreSQL Apply

- Precheck: `12` target rows, `0` missing targets, `0` existing expected rows,
  `8` shadow rows to deprecate.
- Shadow inspection: the 8 rows were old `generated`, `needs_review`,
  `review_only` rows for Corrupted Conviction, Magmatic Insight, Tormenting
  Voice, and Village Rites; they lacked Oracle hashes and did not model the
  additional cost.
- Apply: transaction committed, `8` backup rows, `8` deprecated shadow rows,
  `12` upserted rows.
- Postcheck: all `12` cards have one promoted `verified`/`auto` rule with an
  Oracle hash; `failed_cards=[]`.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5333` requested unique names, `5518` PostgreSQL cards
  matched, `5428` SQLite alias rows, `2699/2699` deck-card rows matched, `108`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4351` PostgreSQL rows loaded, `4343` SQLite rows
  inserted/updated, `4318` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `12` selected cards. Generic battle
  scenario count remained `0`; draw count and supported additional-cost behavior
  are covered by focused runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface (`39/39`),
  legacy contamination (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26535`,
  `xmage_authoritative_source_count=26221`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26221`.
- Post-sync exact split: `proposal_count=196`,
  `safe_for_batch_pg_package_count=196`.
- Largest remaining exact families:
  `xmage_static_self_cant_be_blocked_creature=11`,
  `xmage_static_self_protection_from_card_types_creature=11`,
  `xmage_creature_attack_target_keyword_until_eot=10`,
  `xmage_fixed_damage_spell=10`, and
  `xmage_static_self_horsemanship_creature=10`.
