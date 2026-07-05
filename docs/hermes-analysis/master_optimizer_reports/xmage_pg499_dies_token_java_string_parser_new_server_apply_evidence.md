# PG499 Dies Token Java String Parser Apply Evidence

- Generated at: `2026-07-05T10:26:00Z`
- Deploy id: `xmage_pg499_dies_token_java_string_parser_new_server`
- PostgreSQL target: `143.198.230.247:5433/halder`
- Status: applied, postchecked, synced to Hermes SQLite, and rechecked against the rebuilt Commander-legal queue.

## Scope

PG499 closes the exact XMage runtime scope
`xmage_creature_dies_create_tokens_v1` for keyworded creature tokens created by
a `DiesSourceTriggeredAbility + CreateTokenEffect` shape when the token class
has a parseable Java `super(name, description)` descriptor.

Promoted cards:

- `Conclave Cavalier`: dies, creates two `2/2` green and white `Elf Knight`
  creature tokens with vigilance.
- `Mausoleum Guard`: dies, creates two `1/1` white `Spirit` creature tokens
  with flying.

## Parser And Runtime Changes

- `xmage_authoritative_exact_scope_split.py` now parses Java string literals in
  token constructors through balanced call-argument parsing and simple string
  concatenation evaluation instead of a narrow regex.
- Token descriptions with escaped quotes are decoded before safety filtering.
- Plural Oracle matching now handles descriptions containing `token with` and
  `token named`, allowing "two ... tokens with flying" to match a singular
  XMage token descriptor.
- Safety filters deliberately block dynamic/custom token descriptions such as
  `it has`, `gets`, `get +`, and `for each`.
- Runtime coverage is represented by
  `test_pg499_dies_token_maker_creates_keyworded_tokens`, which exercises
  `move_creature_from_battlefield` and verifies token count, name, subtype,
  color, power/toughness, keyword flags, and replay rule provenance.

## Package Evidence

- Candidate split:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_pg499_token_java_string_parser_candidate.json`
  reported `proposal_count=2` and `safe_for_batch_pg_package_count=2`.
- Package:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg499_dies_token_java_string_parser_new_server_package.md`.
- Precheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg499_dies_token_java_string_parser_new_server_precheck.out`
  found `target_card_rows=1` for each promoted card and no existing executable
  rows or shadow rows to deprecate.
- Apply:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg499_dies_token_java_string_parser_new_server_apply.out`
  reported `upserted_rows=2`, `deprecated_shadow_rows=0`, and `COMMIT`.
- Postcheck:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg499_dies_token_java_string_parser_new_server_postcheck.out`
  confirmed `promoted_rule_rows=1`, `promoted_verified_auto_rows=1`, and
  `promoted_oracle_hash_rows=1` for both promoted cards.
- PG -> Hermes/SQLite sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg499_dies_token_java_string_parser_new_server_pg_to_sqlite_sync.json`
  loaded `8417` PostgreSQL rows, inserted or updated `8181` SQLite rows, and
  exported `5946` canonical fallback snapshot rows.
- SQLite validation:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg499_dies_token_java_string_parser_new_server_sqlite_validation.json`
  returned `status=pass`, `validated_card_count=2`, and `issue_count=0`.

## Test And Audit Evidence

- Splitter unit suite:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg499_token_java_string_parser_splitter_tests.out`
  passed `507` tests.
- Battle suite before sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg499_token_java_string_parser_full_battle_suite.out`
  passed `380` tests.
- Battle suite after sync:
  `docs/hermes-analysis/master_optimizer_reports/xmage_pg499_dies_token_java_string_parser_new_server_full_battle_suite_post_sync.out`
  passed `380` tests and includes
  `PASS test_pg499_dies_token_maker_creates_keyworded_tokens`.
- PG/Hermes/SQLite contract:
  `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260705_post_pg499_dies_token_java_string_parser_new_server.md`
  passed `51/51` checks.
- Final splitter recheck against the rebuilt post-PG499 queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260705_post_pg499_dies_token_java_string_parser_new_server_final_recheck.json`
  reported `proposal_count=0` and `safe_for_batch_pg_package_count=0`.

## Queue Impact

The rebuilt Commander-legal authoritative queue is:

- `target_identity_count=26074`
- `xmage_authoritative_source_count=25760`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25760`

This is an exact reduction of `2` target identities and `2` adapter-required
identities from the post-PG498 queue.

Global readiness after PG499:

- `battle_and_oracle_ready=4876`
- `battle_family_mapper_required=28997`
- `generic_runtime_or_no_card_rule=360`
- `oracle_data_sync=4`
- `commander_legality_sync=3`
- `oracle_identity_rule_link_or_copy=2`

## Residual Boundaries

- `Deathknell Berserker` and `Tuktuk the Explorer` remain blocked as
  `dies_token_oracle_not_simple`.
- Token classes with mana abilities, custom text, dynamic boosts, or variable
  token counts remain blocked for separate runtime families.
- PG499 must not be reused for custom/dynamic token creation; it is limited to
  fixed creature-token descriptors that match the exact Oracle token phrase.
