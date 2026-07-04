# PG446 XMage Library Search Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T23:04:38Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_library_search_spell`
- Battle model scope: `xmage_library_search_to_hand_spell_v1`

## Scope

PG446 promoted local XMage library-search spells whose source and Oracle text
agree on a supported tutor-to-hand filter. This closes the exact spell-family
path for narrow tutor rows and keeps broader `xmage_library_search_variant`
neighbors blocked until their filters, destinations, or special costs have an
exact runtime scope.

Selected cards: Call the Gatewatch, Cateran Summons, Diabolic Tutor, Eerie
Procession, Ignite the Beacon, Merchant Scroll, Open the Armory, Plea for
Guidance, Safewright Quest, Sarkhan's Triumph, Seek the Horizon, Solve the
Equation, Time of Need, and Trapmaker's Snare.

## PostgreSQL Apply

- Precheck: `14` target rows, `0` missing targets, `0` existing expected rows,
  `8` shadow rows to deprecate.
- Apply: transaction committed, `8` backup rows, `8` deprecated shadow rows,
  `14` upserted rows.
- Postcheck: all `14` cards have one promoted `verified`/`auto` rule with an
  Oracle hash; `failed_cards=[]`.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5284` requested unique names, `5469` PostgreSQL cards
  matched, `5379` SQLite alias rows, `2699/2699` deck-card rows matched, `108`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4301` PostgreSQL rows loaded, `4293` SQLite rows
  inserted/updated, `4268` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `14` selected cards. Generic battle
  scenario count remained `0`; tutor-to-hand behavior is covered by focused
  runtime tests and runtime effect resolution.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface, legacy
  contamination, and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26585`,
  `xmage_authoritative_source_count=26271`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26271`.
- Post-sync exact split: `proposal_count=246`,
  `safe_for_batch_pg_package_count=246`.
- Largest remaining exact families: `xmage_self_sacrifice_mana_source_permanent=13`,
  `xmage_static_self_cant_block_creature=13`,
  `xmage_fixed_damage_exile_if_dies_spell=12`, `xmage_fixed_draw_spell=12`,
  and `xmage_static_self_cant_be_blocked_creature=11`.
