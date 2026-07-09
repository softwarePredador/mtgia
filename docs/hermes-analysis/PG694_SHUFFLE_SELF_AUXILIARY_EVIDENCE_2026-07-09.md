# PG694 Shuffle Self Auxiliary Evidence - 2026-07-09

Status: `applied_validated_committed_candidate`.

PG694 promotes the narrow XMage `ShuffleSpellEffect.getInstance()` auxiliary
when paired with an already runtime-backed primary spell effect. This closes the
case where the spell performs its main resolution and then shuffles itself into
its owner's library instead of going to graveyard.

## Scope

Promoted cards:

- `Beacon of Destruction`
- `Blue Sun's Zenith`

Exact source signatures:

- `Beacon of Destruction`: `DamageTargetEffect(5)` plus
  `ShuffleSpellEffect.getInstance()`.
- `Blue Sun's Zenith`: `DrawCardTargetEffect(GetXValue.instance)` plus
  `ShuffleSpellEffect.getInstance()`.

Explicitly not promoted:

- `Red Sun's Zenith` remains blocked by
  `damage_shuffle_exile_if_dies_not_supported` because XMage also has
  `DealtDamageToCreatureBySourceDies`; that exile-if-dies behavior needs its
  own exact adapter.

## Runtime And Tests

Runtime changes:

- `battle_analyst_v9.py` now resolves
  `shuffle_self_into_library_on_resolution` as a spell destination of
  `library`.
- `finish_resolved_spell(...)` moves the spell to controller library, shuffles,
  and emits `spell_shuffled_into_library_on_resolution`.
- `target_player_draw` now passes `effect_data` to spell finalization, so
  `Blue Sun's Zenith` can draw X and still resolve to library.

Package/validator changes:

- `xmage_authoritative_exact_scope_split.py` maps exact
  `DamageTargetEffect + ShuffleSpellEffect` and
  `DrawCardTargetEffect + ShuffleSpellEffect` pairs.
- `xmage_batch_pg_package_builder.py` carries
  `shuffle_self_into_library_on_resolution` into required effect fields and E2E
  scenarios.
- `battle_package_end_to_end_validation.py` validates the replay event and that
  the spell card is present in controller library after resolution.

Test evidence:

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_authoritative_exact_scope_split.py docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_batch_pg_package_builder.py docs/hermes-analysis/manaloom-knowledge/scripts/test_battle_package_end_to_end_validation.py`
- Result: `1093 passed`.

## PostgreSQL Apply Evidence

Database target:

- `127.0.0.1:15432/halder` via `server/bin/with_new_server_pg.sh`.

Precheck:

- `Beacon of Destruction`: `target_card_rows=1`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=2`.
- `Blue Sun's Zenith`: `target_card_rows=1`,
  `expected_rule_rows_before=0`, `would_deprecate_shadow_rows=2`.

Apply:

- backup table rows: `4`;
- deprecated shadow rows: `4`;
- upserted verified executable rows: `2`.

Postcheck:

- `Beacon of Destruction`: `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`.
- `Blue Sun's Zenith`: `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, `promoted_oracle_hash_rows=1`.

## Sync And E2E

PG -> SQLite/runtime sync:

- `pg_rows_loaded=6123`;
- `sqlite_inserted_or_updated=6108`;
- `canonical_snapshot_rows_exported=6085`.

Metadata sync:

- `postgres_cards_matched=7237`;
- `sqlite_cache_alias_rows=7156`;
- `deck_cards.card_id_rows_updated=108`;
- `unresolved_count=1` (`Surgical Suite/Hospital Room`, pre-existing alias
  issue outside this package).

Package E2E:

- status: `pass`;
- stages passed: PostgreSQL source of truth, SQLite/Hermes cache, canonical
  snapshot fallback, runtime lookup, battle execution;
- battle scenarios: `2`;
- emitted events: `7`;
- `Beacon of Destruction`: dealt `5` damage and
  `shuffled_self_into_library=true`;
- `Blue Sun's Zenith`: drew `3` cards from X value and
  `shuffled_self_into_library=true`.

## Post-PG694 Queue State

Global readiness:

- `snapshot_has_verified_rule=6211` (up from `6209`);
- `battle_and_oracle_ready=6183` (up from `6181`);
- `battle_family_mapper_required=27693` (down from `27695`).

XMage authoritative queue:

- `target_identity_count=24770`;
- `xmage_authoritative_source_count=24457`;
- `xmage_authoritative_adapter_required_count=24457`;
- `xmage_authoritative_parser_gap_count=0`;
- `xmage_missing_source_exception_count=313`;
- `adapter_work_unit_count=11305`.

Exact split recheck:

- `proposal_count=0`;
- `safe_for_batch_pg_package_count=0`.

Final gates:

- `xmage_strategy_consistency_audit`: `pass`, `26/26`;
- `pg_hermes_sqlite_contract_audit`: `pass`, `51/51`;
- `operational_surface_alignment_audit`: `pass`;
- `legacy_contamination_audit`: `pass`;
- `scripts/quality_gate.sh server-target`: `pass`.

## Evidence Artifacts

- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_pg694_shuffle_probe_v2.md`
- `docs/hermes-analysis/master_optimizer_reports/pg694_shuffle_self_auxiliary_new_server_package_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg694_shuffle_self_auxiliary_new_server_precheck_evidence.out`
- `docs/hermes-analysis/master_optimizer_reports/pg694_shuffle_self_auxiliary_new_server_apply_evidence.out`
- `docs/hermes-analysis/master_optimizer_reports/pg694_shuffle_self_auxiliary_new_server_postcheck_evidence.out`
- `docs/hermes-analysis/master_optimizer_reports/pg694_shuffle_self_auxiliary_new_server_pg_to_sqlite_sync_runtime_only.json`
- `docs/hermes-analysis/master_optimizer_reports/pg694_shuffle_self_auxiliary_new_server_metadata_sync.json`
- `docs/hermes-analysis/master_optimizer_reports/pg694_shuffle_self_auxiliary_new_server_e2e_validation.md`
- `docs/hermes-analysis/master_optimizer_reports/global_card_oracle_battle_readiness_20260709_post_pg694_shuffle_self_auxiliary_new_server.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_adaptation_queue_20260709_post_pg694_shuffle_self_auxiliary_new_server_commander_legal.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_authoritative_exact_scope_split_20260709_post_pg694_shuffle_self_auxiliary_new_server_recheck.md`
- `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260709_post_pg694_shuffle_self_auxiliary_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/pg_hermes_sqlite_contract_audit_20260709_post_pg694_shuffle_self_auxiliary_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/operational_surface_alignment_audit_20260709_post_pg694_shuffle_self_auxiliary_new_server_final.md`
- `docs/hermes-analysis/master_optimizer_reports/legacy_contamination_audit_20260709_post_pg694_shuffle_self_auxiliary_new_server_final.md`
