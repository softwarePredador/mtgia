# PG452 XMage Static Protection Card Types Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T23:51:29Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_static_self_protection_from_card_types_creature`
- Battle model scope: `xmage_static_self_protection_from_card_types_creature_v1`

## Scope

PG452 promoted creatures with exact static self `ProtectionAbility` source where
the local XMage class and Oracle text agree that the creature has protection
from a card type: artifact, enchantment, creature, or land.

Selected cards: Angelic Curator, Azorius First-Wing, Beloved Chaplain,
Commander Eesha, Horizon Drake, Nacatl Savage, Needlebug, Tel-Jilad Archers,
Tel-Jilad Chosen, Tel-Jilad Outrider, and Yavimaya Scion.

Protection parameters: Angelic Curator = artifact, Azorius First-Wing =
enchantment, Beloved Chaplain = creature, Commander Eesha = creature, Horizon
Drake = land, and Nacatl Savage, Needlebug, Tel-Jilad Archers, Tel-Jilad
Chosen, Tel-Jilad Outrider, and Yavimaya Scion = artifact.

## PostgreSQL Apply

- Precheck: `11` target rows, `0` missing targets, `0` existing expected rows,
  `0` shadow rows to deprecate.
- Apply: transaction committed, `0` backup rows, `0` deprecated shadow rows,
  `11` upserted rows.
- Postcheck: all `11` cards have one promoted `verified`/`auto` rule with an
  Oracle hash; `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `11` promoted rows are
  `verified`/`auto`/`curated`, have an Oracle hash, and expose
  `protection_from_card_types` matching the selected scope.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5354` requested unique names, `5539` PostgreSQL cards
  matched, `5449` SQLite alias rows, `2699/2699` deck-card rows matched, `95`
  card-id rows updated, `1` unresolved alias (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4373` PostgreSQL rows loaded, `4365` SQLite rows
  inserted/updated, `4340` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `11` selected cards. Generic battle
  scenario count remained `0`; protection card-type behavior is covered by
  focused runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface (`39/39`),
  legacy contamination (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26513`,
  `xmage_authoritative_source_count=26199`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26199`.
- Post-sync exact split: `proposal_count=174`,
  `safe_for_batch_pg_package_count=174`.
- Largest remaining exact families:
  `xmage_creature_attack_target_keyword_until_eot=10`,
  `xmage_fixed_damage_spell=10`,
  `xmage_static_self_horsemanship_creature=10`,
  `xmage_fixed_draw_discard_spell=9`, and
  `xmage_fixed_scry_draw_card_spell=9`.
