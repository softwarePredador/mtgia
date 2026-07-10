# PG710 Spell-Cast Token Maker Evidence - 2026-07-10

Status: `applied_synced_validated`.

Scope: XMage authoritative spell-cast token-maker permanents promoted to
ManaLoom runtime scope `xmage_spell_cast_create_creature_token_v1`.

## Selected Cards

- Deeproot Waters
- Efficient Construction
- Etherium Spinner
- Hero of Precinct One
- Lys Alana Huntmaster
- Murmuring Mystic
- Sigil of the Empty Throne
- Talrand, Sky Summoner
- Third Path Iconoclast
- Worthy Knight

Blocked from this exact batch:

- Digsite Engineer, Goblinslide, Skywise Teachings: optional payment cost.
- Whispering Wizard: once-per-turn trigger limit.
- Fable of Wolf and Owl: multiple independent spell-cast token triggers.

## Implementation

- Runtime: `battle_analyst_v9.py`
  - Added `spell_cast_token_filter_matches`.
  - Extended generic spell-cast `token_maker` trigger with structured filters
    for card type, subtype, colors, multicolor, historic, source zone, mana
    value, and artifact-spell static handling.
- Splitter: `xmage_authoritative_exact_scope_split.py`
  - Added `SPELL_CAST_TOKEN_MAKER_UNIT` and
    `SPELL_CAST_TOKEN_MAKER_SCOPE`.
  - Added Oracle/source filter agreement and token phrase validation.
  - Blocks optional payment, multiple triggers, unsupported token classes, and
    once-per-turn trigger limits.
- Package/E2E:
  - Added package fields for `spell_cast_token_*`.
  - Added automatic `spell_cast_token_maker` E2E scenarios with matching and
    nonmatching spells.

## PostgreSQL Apply Evidence

Target: `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`.

Package SQL:

- `docs/hermes-analysis/master_optimizer_reports/pg710_spell_cast_token_maker_new_server_package_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg710_spell_cast_token_maker_new_server_package_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg710_spell_cast_token_maker_new_server_package_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg710_spell_cast_token_maker_new_server_package_rollback.sql`

Results:

- Precheck: 10 Oracle-hash-matched card rows, 0 expected rows already present.
- Apply: backup rows 8, deprecated shadow rows 8, upserted rows 10.
- Postcheck: 10/10 promoted rows verified as `review_status='verified'`,
  `execution_status='auto'`, and expected `oracle_hash`.
- Backup table:
  `manaloom_deploy_audit.pg710_spell_cast_token_maker_new_server_20260710_165748`.

## Sync And Validation

PG -> SQLite/snapshot sync:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg710_spell_cast_token_maker_new_server_pg_to_sqlite_sync.json`
- PG rows loaded: 6210.
- SQLite inserted/updated: 6205.
- Canonical snapshot rows exported: 6161.

E2E:

- Report:
  `docs/hermes-analysis/master_optimizer_reports/pg710_spell_cast_token_maker_new_server_e2e_validation.json`
- Status: pass.
- PG rows: 10.
- SQLite rows: 10.
- Snapshot rows: 10.
- Runtime lookup rows: 10.
- Battle scenarios: 10.
- Token creation: 10/10 scenarios created the expected token from a matching
  spell and did not trigger from the nonmatching spell.

Focused tests:

- Command:
  `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -q`
- Result: `1152 passed, 206 subtests passed`.

Governance audits:

- `xmage_strategy_consistency_audit`: pass, 26/26.
- `operational_surface_alignment_audit`: pass.
- `legacy_contamination_audit`: pass.
- `pg_hermes_sqlite_contract_audit`: pass, 51/51.
- `./scripts/quality_gate.sh server-target`: pass.

## Queue Delta

Readiness after PG710:

- `battle_and_oracle_ready`: 6259.
- `battle_family_mapper_required`: 27617.
- `snapshot_has_verified_rule`: 6284.
- `token_creation` gap family count: 3462.

Commander-legal XMage queue after PG710:

- `target_identity_count`: 24694.
- `xmage_authoritative_source_count`: 24381.
- `xmage_authoritative_adapter_required_count`: 24381.
- `xmage_authoritative_parser_gap_count`: 0.
- `xmage_missing_source_exception_count`: 313.
- `manual_semantic_decision_units_remaining`: 313.

Post-PG710 exact split recheck:

- `proposal_count`: 0.
- `safe_for_batch_pg_package_count`: 0.
- Remaining spell-cast token blockers are intentionally deferred:
  optional payment, once-per-turn limit, and multiple triggers.
