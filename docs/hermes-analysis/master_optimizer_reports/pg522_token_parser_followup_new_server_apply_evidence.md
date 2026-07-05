# PG522 Token Parser Follow-up Apply Evidence

- Generated at: `2026-07-05T18:22:05.964602+00:00`
- Deploy ID: `xmage_pg522_token_parser_followup_new_server`
- Status: `applied_synced_validated`
- Source of truth: PostgreSQL `card_battle_rules`
- Runtime scopes:
  - `xmage_creature_dies_create_tokens_v1`
  - `xmage_permanent_simple_activated_create_token_v1`

## Scope

PG522 is a parser/manifest follow-up to the token waves. It does not broaden
token behavior generally. It promotes only local-XMage token rows whose runtime
support already existed but whose token class parsing was too narrow:

- no-arg token constructors delegating to another public constructor with fixed
  literal `super(name, description)` metadata;
- named artifact-creature token descriptions such as `with flying named Wasp`
  where the keyword is already runtime-supported.

Unsupported token behavior remains blocked, including infect, changeling,
banding, decayed, death triggers printed on the token, activated abilities on
the token, multiple token effects, dynamic token counts, and non-creature
tokens without exact runtime support.

## Promoted Cards

| Card | Scope | Token |
| --- | --- | --- |
| `Symbiotic Beast` | `xmage_creature_dies_create_tokens_v1` | dies -> four `1/1 green Insect` tokens |
| `Symbiotic Elf` | `xmage_creature_dies_create_tokens_v1` | dies -> two `1/1 green Insect` tokens |
| `Symbiotic Wurm` | `xmage_creature_dies_create_tokens_v1` | dies -> seven `1/1 green Insect` tokens |
| `The Hive` | `xmage_permanent_simple_activated_create_token_v1` | `{5}, {T}` -> one `1/1 colorless Insect artifact creature token with flying named Wasp` |

## Precheck

`{"cards": ["Symbiotic Beast", "Symbiotic Elf", "Symbiotic Wurm", "The Hive"], "existing_expected_rows_before": 0, "missing_targets": [], "row_count": 4, "total_target_card_rows": 4, "would_deprecate_shadow_rows": 0}`

## Postcheck

`{"backup_rows": 0, "cards": ["Symbiotic Beast", "Symbiotic Elf", "Symbiotic Wurm", "The Hive"], "failed_cards": [], "promoted_oracle_hash_rows": 4, "promoted_rule_rows": 4, "promoted_verified_auto_rows": 4, "row_count": 4}`

## Sync And Runtime Evidence

PostgreSQL -> Hermes/SQLite sync:

- `selected_card_count=4`
- `pg_rows_loaded=4`
- `sqlite_inserted_or_updated=4`
- `canonical_snapshot_rows_exported=6047`

E2E package validation:

- PostgreSQL source of truth: `pass`, validated rows `4`.
- SQLite Hermes cache: `pass`, validated rows `4`.
- canonical snapshot fallback: `pass`, validated cards `4`.
- runtime `get_card_effect`: `pass`, validated cards `4`.
- battle execution no override: `pass`.

Focused runtime smoke:

- `The Hive` loaded from `get_card_effect` with
  `battle_model_scope=xmage_permanent_simple_activated_create_token_v1`.
- Activating `The Hive` with five generic mana created one `Wasp` permanent
  as an artifact creature token with subtype `Insect` and `keywords=["flying"]`.
- `Symbiotic Elf` loaded from `get_card_effect` with
  `battle_model_scope=xmage_creature_dies_create_tokens_v1`,
  `dies_token_count=2`, `dies_token_name="Insect Token"`, and
  `dies_token_subtype="Insect"`.

Focused tests:

- `python3 -m unittest test_xmage_authoritative_exact_scope_split.py test_xmage_exact_scope_runtime.py test_xmage_batch_pg_package_builder.py test_battle_package_end_to_end_validation.py test_sync_battle_card_rules_pg_selection.py`
- `Ran 876 tests`
- `OK`

## Queue Delta

Before PG522, the post-PG521 authoritative queue reported:

- `target_identity_count=25969`
- `xmage_authoritative_source_count=25655`
- `xmage_authoritative_adapter_required_count=25655`

After PG522:

- `target_identity_count=25965`
- `xmage_authoritative_source_count=25651`
- `xmage_missing_source_exception_count=314`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_authoritative_adapter_required_count=25651`
- `battle_and_oracle_ready=4985`
- `battle_family_mapper_required=28888`
- final exact-scope split `proposal_count=0`
- final exact-scope split `safe_for_batch_pg_package_count=0`
