# PG054 Deck 6 L6 Silence-Lock Package

Scope: Deck 6 `high + battle_critical` silence-lock family.

Included cards:

- `Grand Abolisher`
- `Silence`

Excluded from this package:

- `Drannith Magistrate`: current trusted rule models the creature body only;
  the "cast from outside hand" lock needs a separate model/waiver.
- `Ranger-Captain of Eos`: current trusted rule models creature + ETB tutor;
  the sacrifice silence ability needs a separate model/waiver.

Runtime boundary:

- `Silence`: opponent spell-cast lock until end of turn is executable.
- `Grand Abolisher`: opponent spell-cast lock during controller turn is the
  current runtime model. Its activated-ability lock is recorded as
  `annotation_only` in PG054 and is not claimed as a full executor.

Files:

- Precheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_precheck_20260623_013119.sql`
- Apply: `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_apply_20260623_013119.sql`
- Postcheck: `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_postcheck_20260623_013119.sql`
- Rollback: `docs/hermes-analysis/master_optimizer_reports/deck6_l6_silence_lock_pg054_rollback_20260623_013119.sql`

Expected precheck:

- `deck_target_cards=2`
- `target_rule_rows=5`
- `active_curated_rows=3`
- `trusted_missing_hash_rows=3`
- `generated_review_only_rows=2`
- `silence_legacy_active_rows=1`
- `target_active_runtime_rows=2`
- active card-id mismatch metrics: `0`
- `target_names_missing_rules=0`
