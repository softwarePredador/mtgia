# PG852 Activated X Damage New Server Evidence

Date: 2026-07-12

Scope: promote the XMage authoritative activated X-damage subpattern into
ManaLoom executable battle rules for:

- Ballista Squad
- Cinder Elemental
- Pain Kami

Runtime change:

- `battle_analyst_v9.py` now treats activated direct-damage rules with
  `damage_amount_source` as executable even when fixed `amount` is `0`.
- `{X}` activation costs are materialized from `x_value`/`e2e_x_value` before
  affordability, payment, replay trace, and E2E checks.

PostgreSQL package:

- Package manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg852_activated_x_damage_new_server_package_manifest.json`
- Precheck:
  `3/3` target card rows found, `0` existing expected rows, `0` shadow rows to
  deprecate.
- Apply:
  `3` rows upserted, `0` shadow rows deprecated.
- Postcheck:
  `3/3` promoted rows, `3/3` `verified_auto` rows, and `3/3` matching Oracle
  hash rows.
- Direct PG validation after apply:
  `pg852_verified_rows=3`, `trusted_missing_hash=0`.

Sync and E2E:

- PG -> SQLite/snapshot sync:
  `10556` PostgreSQL rows loaded, `10334` SQLite rows inserted/updated, `7820`
  canonical snapshot rows exported.
- PG card metadata -> Hermes sync:
  `8757` PostgreSQL cards matched, `8696` SQLite alias rows written,
  `deck_cards` backfill `2699/2699`.
- Package E2E:
  `pass` for PostgreSQL source of truth, SQLite/Hermes cache, canonical
  snapshot fallback, runtime `get_card_effect`, and `3` battle execution
  scenarios.
- E2E battle execution:
  Ballista Squad dealt `3` damage to an attacking/blocking creature target;
  Cinder Elemental dealt `3` damage to the opponent; Pain Kami dealt `3`
  damage to a creature target.

Audits:

- XMage strategy consistency:
  `pass`, `26/26` checks.
- Operational surface alignment:
  `pass`.
- PG/Hermes/SQLite contract:
  `pass`, `51/51` checks.

Readiness delta:

- `snapshot_has_any_rule`: `8023` -> `8026`
- `snapshot_has_verified_rule`: `6873` -> `6876`
- `battle_and_oracle_ready`: `6766` -> `6769`
- `battle_family_mapper_required`: `27028` -> `27025`

Post-PG852 XMage queue:

- `target_identity_count=24114`
- `xmage_authoritative_source_count=23801`
- `xmage_missing_source_exception_count=313`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=23801`

Residual:

- The global objective remains active. This batch closed the activated
  X-damage subpattern for 3 Commander-legal identities; the remaining work is
  still family/subpattern adapter work, not card-by-card manual handling.
