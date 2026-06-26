# PG239 Spell Cast Damage Engine Progress 2026-06-26

## Scope

- close the reusable XMage -> ManaLoom family for battlefield permanents that
  damage each opponent on `spell_cast`, `noncreature_spell_cast`, or
  `instant_sorcery_cast`
- PostgreSQL writes: `true`
- canonical SQLite/Hermes sync: `true`
- target outcome: promote the whole `spell_cast_damage_engine` batch, rerun the
  live queue/matrix/audits, and reduce the Lorehold-routing backlog without
  opening a new benchmark cycle yet

## Runtime / Mapper Proof

Verified in the current code state before PG apply:

- `python3 -m unittest test_xmage_to_manaloom_effect_hints.py`
  - `233` tests passed
- `python3 -m unittest test_xmage_semantic_family_batch_pipeline.py`
  - `218` tests passed
- targeted battle proof:
  - `test_pg239_coruscation_mage_damages_each_opponent_only_on_noncreature_spell_cast`
  - result: `ok`

What changed in code:

- new exact XMage mapper for:
  - `spell_cast_damage_each_opponent_v1`
  - `noncreature_spell_cast_damage_each_opponent_v1`
  - `instant_sorcery_cast_damage_each_opponent_v1`
- new semantic family:
  - `spell_cast_damage_engine`
- battle runtime now executes
  `damage_each_opponent` triggers from
  `spell_cast` and `noncreature_spell_cast`,
  not only from `instant_sorcery_cast`

## Pre-Sync Discovery

Fresh pipeline prefix before PG apply:

- `xmage_current_replay_batch_pipeline_20260626_pg239_coruscation_runtime_v1`

Operational discovery from that run:

- new family surfaced:
  - `spell_cast_damage_engine=5`
- new PG-ready residual:
  - `package_ready_unprepared=5`
- affected cards:
  - `Longshot, Rebel Bowman`
  - `Guttersnipe`
  - `Coruscation Mage`
  - `Fiery Inscription`
  - `Vivi Ornitier`

Key deltas from the prior post-PG238 state:

- `ready_for_structured_xmage_pull_review_required: 65 -> 69`
- `xmage_source_valid_mapper_required: 321 -> 317`
- `proposal_status.batch_pg_candidate_after_precheck: 0 -> 5`
- matrix:
  - `needs_rule_before_strategy: 243 -> 241`
  - `package_ready: 0 -> 2`

## PG239 Package

- manifest:
  `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_manifest.json`
- package:
  `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_package.md`
- selected cards: `5`

### Precheck

- output:
  `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_precheck.out`
- target rows:
  - `1` per card
- existing shadow rows:
  - `2` per card
- total rows to deprecate:
  - `10`

### Apply

- output:
  `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_apply.out`
- result:
  - `deprecated_shadow_rows=10`
  - `upserted_rows=5`

### Postcheck

- output:
  `docs/hermes-analysis/master_optimizer_reports/pg239_spell_cast_damage_engine_postcheck.out`
- each card finished with:
  - `promoted_rule_rows=1`
  - `promoted_verified_auto_rows=1`
  - `promoted_oracle_hash_rows=1`

## PG -> SQLite / Hermes Sync

- report:
  `docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg239_spell_cast_damage_engine_20260626.json`
- result:
  - `pg_rows_loaded=5`
  - `sqlite_inserted_or_updated=16`
  - `selected_card_count=5`

## Post-Sync Pipeline / Queue / Audit

Fresh post-sync prefix:

- `xmage_current_replay_batch_pipeline_20260626_pg239_spell_cast_damage_engine_postsync_v1`

Key outputs:

- manifest:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg239_spell_cast_damage_engine_postsync_v1_manifest.json`
- proposals:
  `docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260626_pg239_spell_cast_damage_engine_postsync_v1_proposals.json`
- effective queue:
  `docs/hermes-analysis/master_optimizer_reports/xmage_effective_queue_20260626_pg239_spell_cast_damage_engine_postsync_v1.json`
- strategy audit:
  `docs/hermes-analysis/master_optimizer_reports/xmage_strategy_consistency_audit_20260626_pg239_spell_cast_damage_engine_postsync_v1.json`
- matrix:
  `docs/hermes-analysis/master_optimizer_reports/lorehold_ideal_candidate_matrix_20260626_pg239_spell_cast_damage_engine_postsync_v1.json`

Operational deltas that matter:

- effective queue:
  - `package_ready_unprepared: 5 -> 0`
  - residual backlog is now:
    - `manual_mapper_backlog=318`
    - `split_scope_backlog=59`
    - `runtime_family_backlog=4`
    - `blocked_missing_xmage_source=4`
- strategy consistency audit:
  - `18/18 pass`
- severity:
  - `high: 346 -> 341`
  - `pass: 553 -> 557`
- validity:
  - `ready_for_structured_xmage_pull_review_required: 69 -> 64`

Matrix deltas:

- `battle_ready: 720 -> 722`
- `watchlist_candidate: 323 -> 324`
- `low_priority: 172 -> 171`
- `needs_rule_before_strategy: 241 -> 241`

Lorehold-scoped routing deltas:

- `Coruscation Mage`
  - `low_priority / package_ready -> watchlist_candidate / battle_ready`
- `Vivi Ornitier`
  - `low_priority / package_ready -> watchlist_candidate / battle_ready`
- Lorehold-touching `needs_rule_before_strategy`:
  - `70 -> 69`

## Operational Conclusion

- the `spell_cast_damage_engine` slice is closed end to end:
  mapper -> runtime -> tests -> PG239 package -> PG apply -> SQLite sync ->
  fresh queue/matrix/audit
- this slice improved the live routing layer without reopening benchmark work
- the next Lorehold-first unresolved targets remain:
  `Currency Converter`, `Firesong and Sunspeaker`, `Magmakin Artillerist`,
  `Bolt Bend`, and `Penance`
- benchmark/generation remains intentionally deferred until more
  Lorehold-touching `needs_rule_before_strategy` rows are closed
