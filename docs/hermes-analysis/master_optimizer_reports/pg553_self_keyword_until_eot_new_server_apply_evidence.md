# PG553 Self Keyword Until EOT New Server Apply Evidence

Status: `closed`

Scope:

- Family: `xmage_permanent_simple_activated_self_keyword_until_eot_v1`
- Selected rules: `43`
- PostgreSQL target: `143.198.230.247:5433/halder`
- Runtime scope: simple activated permanent self-keyword until end of turn.

Database package:

- Precheck: `43` target rows found; `Henge Guardian` had `1` shadow row to deprecate.
- Apply: `deprecated_shadow_rows=1`, `upserted_rows=43`, transaction `COMMIT`.
- Postcheck: `43` promoted rule rows; each promoted row has `review_status=verified`, `execution_status=auto`, `oracle_hash`, and backup evidence.

Sync:

- PostgreSQL rows loaded: `8943`
- SQLite inserted or updated: `8707`
- Canonical snapshot rows exported: `6445`

E2E:

- Status: `pass`
- Battle execution scenarios: `43`
- Replay events: `86`
- Hybrid activation costs covered by package manifest:
  - `Cabaretti Initiate`: `{2}{R/W}`
  - `Riveteers Initiate`: `{1}{B/G}`
  - `Stream Hopper`: `{U/R}`

Post-apply routing:

- Commander-legal battle-gap identities: `25591 -> 25548`
- XMage-authoritative adapter-required identities: `25277 -> 25234`
- Adapter work units: `11363 -> 11356`
- Missing XMage source exceptions remain: `314`
- Final exact split after PG553: `proposal_count=0`, so the next batch requires implementing another subpattern/family.

Final audits:

- `xmage_strategy_consistency_audit`: `pass` (`26/26`)
- `operational_surface_alignment_audit`: `pass`
- `legacy_contamination_audit`: `pass`
- `pg_hermes_sqlite_contract_audit`: `pass` (`51/51`)
