# PG454 XMage Fixed Damage Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-05T00:04:15Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_fixed_damage_spell`
- Battle model scope: `xmage_fixed_damage_target_spell_v1`

## Scope

PG454 promoted fixed direct-damage spells whose local XMage source and Oracle
text agree on fixed damage, supported targets, and supported additional costs:
discard a card, sacrifice a creature, sacrifice a land, or sacrifice an
artifact or creature.

Selected cards: Acceptable Losses, Artillerize, Collateral Damage, Fiery
Conclusion, Improvised Club, Magma Rift, Reckless Abandon, Shard Volley, Sonic
Burst, and Sonic Seizure.

Direct PostgreSQL verification confirmed the modeled damage/cost pairs:
Acceptable Losses `5/discard_card`, Artillerize
`5/sacrifice_artifact_or_creature`, Collateral Damage `3/sacrifice_creature`,
Fiery Conclusion `5/sacrifice_creature`, Improvised Club
`4/sacrifice_artifact_or_creature`, Magma Rift `5/sacrifice_land`, Reckless
Abandon `4/sacrifice_creature`, Shard Volley `3/sacrifice_land`, Sonic Burst
`4/discard_card`, and Sonic Seizure `3/discard_card`.

## PostgreSQL Apply

- Precheck: `10` target rows, `0` missing targets, `0` existing expected rows,
  `0` shadow rows to deprecate.
- Apply: transaction committed, `0` backup rows, `0` deprecated shadow rows,
  `10` upserted rows.
- Postcheck: all `10` cards have promoted `verified`/`auto` rules with Oracle
  hashes; `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `10` promoted rows are
  `verified`/`auto`/`curated`, have an Oracle hash, and preserve exact damage,
  supported target constraints, and supported additional costs.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5375` requested unique names, `5560` PostgreSQL cards
  matched, `5470` SQLite alias rows, `2699/2699` deck-card rows matched, `96`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4393` PostgreSQL rows loaded, `4385` SQLite rows
  inserted/updated, `4360` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `10` selected cards. Generic battle
  scenario count remained `0`; fixed-damage and supported additional-cost
  behavior are covered by focused runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface (`39/39`),
  legacy contamination (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26493`,
  `xmage_authoritative_source_count=26179`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26179`.
- Post-sync exact split: `proposal_count=154`,
  `safe_for_batch_pg_package_count=154`.
- Largest remaining exact families:
  `xmage_static_self_horsemanship_creature=10`,
  `xmage_fixed_draw_discard_spell=9`,
  `xmage_fixed_scry_draw_card_spell=9`,
  `xmage_creature_dies_fixed_damage_target=8`, and
  `xmage_destroy_target_scry_spell=8`.
