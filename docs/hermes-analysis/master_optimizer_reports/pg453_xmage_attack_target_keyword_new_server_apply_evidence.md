# PG453 XMage Attack Target Keyword Apply Evidence

- Status: `closed`
- Generated UTC: `2026-07-04T23:58:42Z`
- Database target: `143.198.230.247:5433/halder`
- SQLite DB: `docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db`
- Family: `xmage_creature_attack_target_keyword_until_eot`
- Battle model scope:
  `xmage_creature_attack_grant_keyword_target_creature_until_eot_v1`

## Scope

PG453 promoted creatures with exact attack-triggered keyword-granting source:
when the source attacks, target attacking creature gains flying until end of
turn. The promoted rows preserve the target-controller restriction from XMage
and Oracle: `any` for four cards and `self` for six cards.

Selected cards: Aerial Guide, Chasm Drake, Garrison Griffin, Heavenly Qilin,
Kinsbaile Balloonist, Majestic Heliopterus, Pegasus Courser, Roc Charger,
Trained Condor, and Trusted Pegasus.

## PostgreSQL Apply

- Precheck: `10` target rows, `0` missing targets, `0` existing expected rows,
  `0` shadow rows to deprecate.
- Apply: transaction committed, `0` backup rows, `0` deprecated shadow rows,
  `10` upserted rows.
- Postcheck: all `10` cards have promoted `verified`/`auto` rules with Oracle
  hashes; `failed_cards=[]`.
- Direct PostgreSQL verification confirmed all `10` promoted rows are
  `verified`/`auto`/`curated`, have an Oracle hash, set
  `attack_trigger_target_keyword=true`, and grant `flying` until end of turn.

## Sync And Runtime Evidence

- Focused mapper/runtime/package tests: `718` checks passed.
- Metadata sync: `5365` requested unique names, `5550` PostgreSQL cards
  matched, `5460` SQLite alias rows, `2699/2699` deck-card rows matched,
  `107` card-id rows updated, `1` unresolved alias
  (`Surgical Suite/Hospital Room`).
- Full PG -> SQLite sync: `4383` PostgreSQL rows loaded, `4375` SQLite rows
  inserted/updated, `4350` canonical fallback rows exported.
- E2E package validation: pass across PostgreSQL, SQLite, canonical snapshot,
  and runtime `get_card_effect` for all `10` selected cards. Generic battle
  scenario count remained `0`; attack-trigger keyword behavior is covered by
  focused runtime tests.

## Governance And Queue

- Final audits passed: XMage strategy (`26/26`), operational surface (`39/39`),
  legacy contamination (`32/32`), and PG/Hermes/SQLite contract (`51/51`).
- Post-sync Commander-legal queue: `target_identity_count=26503`,
  `xmage_authoritative_source_count=26189`,
  `xmage_missing_source_exception_count=314`, `parser_gap=0`, and
  `xmage_authoritative_adapter_required_count=26189`.
- Post-sync exact split: `proposal_count=164`,
  `safe_for_batch_pg_package_count=164`.
- Largest remaining exact families:
  `xmage_fixed_damage_spell=10`,
  `xmage_static_self_horsemanship_creature=10`,
  `xmage_fixed_draw_discard_spell=9`,
  `xmage_fixed_scry_draw_card_spell=9`, and
  `xmage_creature_dies_fixed_damage_target=8`.
