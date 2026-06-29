# PG249 XMage Batch PostgreSQL Package

Status: `applied_postchecked_synced`.

This package was generated from XMage batch proposals. No SQL was executed by the builder.

- Generated at: `2026-06-29T14:33:48+00:00`
- Selected cards: `["Verge Rangers", "Firesong and Sunspeaker", "Goliath Daydreamer", "Boros Reckoner", "Terror of the Peaks", "Balefire Liege", "Repercussion"]`
- Families: `{"free_cast": 1, "targeted_interaction": 5, "topdeck_play": 1}`

Files:

- precheck: `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_precheck.sql`
- apply: `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_apply.sql`
- rollback: `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_rollback.sql`
- postcheck: `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_postcheck.sql`
- manifest: `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_manifest.json`
- package: `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_package.md`

Apply gate:

- Do not run apply SQL without explicit approval for the exact command.
- Required sequence after approval: precheck, apply, postcheck, PG -> SQLite sync, focused/family tests, affected deck coherence audit.

Precheck evidence:

- Command executed read-only on 2026-06-29:
  `psql -v ON_ERROR_STOP=1 -f docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_precheck.sql`
- Output artifact:
  `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_precheck.out`
- Result: `7` rows matched, `target_card_rows=1` for every selected card.
- Existing shadow rows that apply would deprecate:
  `Firesong and Sunspeaker=2`, `Goliath Daydreamer=1`,
  `Terror of the Peaks=1`, `Verge Rangers=2`.
- Apply approval was granted by the user on 2026-06-29 and the package was
  applied.

Apply evidence:

- pre-apply output:
  `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_144646_preapply.out`
- apply output:
  `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_144646_apply.out`
- postcheck output:
  `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_144646_postcheck.out`
- Apply result: `deprecated_shadow_rows=6`, `upserted_rows=7`.
- Postcheck result: every selected card had `promoted_rule_rows=1`,
  `promoted_verified_auto_rows=1`, and `promoted_oracle_hash_rows=1`.

SQLite/Hermes sync evidence:

- PG249 sync report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg249_runtime_ready_exact_family_batch_20260629_144739.json`
- SQLite lookup:
  `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_144739_sqlite_lookup.out`
- PostgreSQL lookup:
  `docs/hermes-analysis/master_optimizer_reports/pg249_runtime_ready_exact_family_batch_20260629_144739_pg_lookup.out`
- Sync result: `pg_rows_loaded=13`, `sqlite_inserted_or_updated=13`.
- The `13` rows are the seven active curated rules plus six deprecated disabled
  shadow rows.

Runtime correction:

- Post-apply runtime probing showed `Repercussion` could not remain an
  immediate `direct_damage` rule, because the enchantment must enter the
  battlefield and trigger passively.
- PG250 corrected only `Repercussion` while preserving the PG249 backup and
  rollback lineage.
- Final runtime probe:
  `docs/hermes-analysis/master_optimizer_reports/pg249_pg250_runtime_ready_exact_family_batch_20260629_145521_get_card_effect_probe.json`

Focused runtime evidence:

- `python3 -m pytest docs/hermes-analysis/manaloom-knowledge/scripts/test_verge_rangers_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_goliath_daydreamer_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_terror_of_the_peaks_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_boros_reckoner_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_repercussion_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_firesong_and_sunspeaker_runtime.py docs/hermes-analysis/manaloom-knowledge/scripts/test_balefire_liege_runtime.py -q`
- Result: `20 passed`.

Excluded from this package:

- `Adagia, Windswept Bastion`: excluded because its current proposal still
  declares `runtime_missing_components=["station_level_gate"]`.
- `Purphoros, God of the Forge`: excluded because the current lane is
  `partial_batch_pg_candidate_preserve_shadow_rows_after_precheck`, not the
  first exact non-partial batch lane.
