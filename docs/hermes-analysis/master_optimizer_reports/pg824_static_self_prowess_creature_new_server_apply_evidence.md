# PG824 Static Self Prowess Creature Evidence

Status: `applied_and_validated`

Generated at: `2026-07-12T10:01:51Z`

## Scope

- Deploy id: `PG824`
- Slug: `pg824_static_self_prowess_creature_new_server`
- Family: `xmage_static_self_prowess_creature`
- Runtime scope: `xmage_static_self_prowess_creature_v1`
- Cards promoted: `23`
- Source: local XMage exact no-effect/no-signal `ProwessAbility` creature rows, optionally with safe static self keywords.

Cards:

- `Bloodfire Expert`
- `Dragon Bell Monk`
- `Dragon-Style Twins`
- `Elementalist Adept`
- `Iguana Parrot`
- `Jeskai Brushmaster`
- `Jeskai Student`
- `Jeskai Windscout`
- `Lightning Visionary`
- `Lotus Path Djinn`
- `Mistral Singer`
- `Monastery Swiftspear`
- `Niblis of Dusk`
- `Nimble-Blade Khenra`
- `Ringwarden Owl`
- `Riverwheel Aerialists`
- `Sanguinary Mage`
- `Stormchaser Mage`
- `Thor Odinson`
- `Umara Entangler`
- `Vedalken Blademaster`
- `Whirlwind Adept`
- `Wing Commando`

## PostgreSQL Package

- Package: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_package.md`
- Manifest: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_manifest.json`
- Precheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_precheck.sql`
- Apply SQL: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_apply.sql`
- Postcheck SQL: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_postcheck.sql`
- Rollback SQL: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_package_rollback.sql`

Precheck on new-server PostgreSQL:

- `target_card_rows=1` for all `23` cards.
- `expected_rule_rows_before=0` for all `23` cards.
- `would_deprecate_shadow_rows=0` for all `23` cards.

Apply on new-server PostgreSQL:

- `deprecated_shadow_rows=0`
- `upserted_rows=23`

Postcheck on new-server PostgreSQL:

- `promoted_rule_rows=1` for all `23` cards.
- `promoted_verified_auto_rows=1` for all `23` cards.
- `promoted_oracle_hash_rows=1` for all `23` cards.
- `backup_rows=0`

## Sync And Runtime Evidence

PG -> SQLite sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_pg_to_sqlite_sync.json`
- `pg_rows_loaded=23`
- `sqlite_inserted_or_updated=23`
- `selected_card_count=23`
- `canonical_snapshot_rows_exported=7722`

PG metadata -> Hermes cache sync:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_metadata_sync.json`
- `postgres_target=127.0.0.1:15432/halder`
- `postgres_cards_matched=8661`
- `sqlite_cache_alias_rows=8600`
- `deck_cards matched=2699/2699`
- `card_id_rows_updated=87`
- Residual unresolved metadata sample: `Surgical Suite/Hospital Room`

Battle package E2E:

- Report: `docs/hermes-analysis/master_optimizer_reports/pg824_static_self_prowess_creature_new_server_e2e_validation.md`
- Status: `pass`
- PostgreSQL source of truth: `23` rows validated.
- SQLite Hermes cache: `23` rows validated.
- Canonical snapshot fallback: `23` cards validated.
- Runtime `get_card_effect`: `23` cards validated.
- Battle execution: `23` scenarios and `23` trigger events.

Focused tests:

```text
python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_exact_scope_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py -k "prowess"
5 passed, 2028 deselected
```

## Post-Apply Global State

Readiness:

- Report: `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260712_post_pg824_static_self_prowess_creature_new_server.md`
- `battle_and_oracle_ready=6667`
- Previous post-PG823B value: `6644`
- Delta: `+23`
- `snapshot_has_verified_rule=6774`
- `snapshot_has_any_rule=7928`
- `battle_family_mapper_required=27127`
- `battle_rule_verification_required=70`

XMage authoritative queue:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260712_post_pg824_static_self_prowess_creature_new_server_commander_legal.md`
- `target_identity_count=24216`
- `xmage_authoritative_source_count=23903`
- `xmage_authoritative_adapter_required_count=23903`
- `xmage_authoritative_parser_gap_count=0`
- `xmage_missing_source_exception_count=313`

Exact split recheck:

- Report: `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260712_post_pg824_static_self_prowess_creature_new_server_recheck.md`
- `safe_for_batch_pg_package_count=0`
- `proposal_count=2`
- Remaining proposals: `Codie, Vociferous Codex` and `Strixhaven Stadium`, both `runtime_partial_requires_family_runtime`.

## Final Audits

- `pg_hermes_sqlite_contract_audit_20260712_post_pg824_static_self_prowess_creature_new_server_final`: `pass`, `51/51`.
- `xmage_strategy_consistency_audit_20260712_post_pg824_static_self_prowess_creature_new_server_final`: `pass`, `26/26`.
- `operational_surface_alignment_audit_20260712_post_pg824_static_self_prowess_creature_new_server_final`: `pass`, `48/48`.
- `legacy_contamination_audit_20260712_post_pg824_static_self_prowess_creature_new_server_final`: `pass`, `32/32`.
- `./scripts/quality_gate.sh server-target`: `pass`.

## Next Work Unit

The current post-PG824 split has no immediately safe batch package. The two remaining split proposals are partial mana-source rows where XMage has modeled mana plus unmodeled auxiliary behavior:

- `Codie, Vociferous Codex`
- `Strixhaven Stadium`

The next implementation should either add a family runtime for the auxiliary behavior or keep them blocked and choose the next high-reduction exact family from the queue.
