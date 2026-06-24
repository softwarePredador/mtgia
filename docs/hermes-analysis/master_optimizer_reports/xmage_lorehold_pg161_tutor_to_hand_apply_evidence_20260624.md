# PG161 XMage Tutor-to-Hand Apply Evidence

Date: `2026-06-24`
Branch: `codex/xmage-absorption-20260623`
Deploy id: `PG161`
Scope: `Demonic Tutor`, `Diabolic Intent`, `Sylvan Scrying`, `Spellseeker`, `Trophy Mage`

## Local implementation

Files changed:

- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py`
- `docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py`

Structured scopes added:

- `any_tutor_to_hand_v1`
- `sacrifice_creature_any_tutor_to_hand_v1`
- `land_tutor_to_hand_v1`
- `spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1`
- `trophy_mage_etb_artifact_mana_value_3_to_hand_v1`

Runtime additions:

- `library_tutor_candidates(...)` now recognizes:
  - `cheap_instant_or_sorcery`
  - `artifact_mana_value_3`

## Local validation

Commands:

```bash
python3 -m py_compile \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_to_manaloom_effect_hints.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/xmage_semantic_family_classifier.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_analyst_v9.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py \
  docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py

python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_to_manaloom_effect_hints.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/test_xmage_semantic_family_batch_pipeline.py
python3 docs/hermes-analysis/manaloom-knowledge/scripts/battle_zone_transition_tests.py
```

Results:

- `test_xmage_to_manaloom_effect_hints.py`: `Ran 106 tests ... OK`
- `test_xmage_semantic_family_batch_pipeline.py`: `Ran 103 tests ... OK`
- `battle_zone_transition_tests.py`: exit `0`

## Presync real pipeline

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --battle-artifact-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_052838 \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --include-deck-id 6 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg161_tutor_to_hand_presync_real_v1
```

Summary:

- `severity_counts={"high": 192, "medium": 36, "pass": 306}`
- `validity_status_counts={"ready_for_structured_xmage_pull_review_required": 5, "xmage_source_valid_mapper_required": 206}`
- `proposal_status_counts={"batch_pg_candidate_after_precheck": 5, "mapper_metadata_or_test_scenario_required": 206}`

Batch candidates:

- `Demonic Tutor` -> `any_tutor_to_hand_v1`
- `Diabolic Intent` -> `sacrifice_creature_any_tutor_to_hand_v1`
- `Sylvan Scrying` -> `land_tutor_to_hand_v1`
- `Spellseeker` -> `spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1`
- `Trophy Mage` -> `trophy_mage_etb_artifact_mana_value_3_to_hand_v1`

## PostgreSQL package

Artifacts:

- `docs/hermes-analysis/master_optimizer_reports/pg161_tutor_to_hand_precheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg161_tutor_to_hand_apply.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg161_tutor_to_hand_postcheck.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg161_tutor_to_hand_rollback.sql`
- `docs/hermes-analysis/master_optimizer_reports/pg161_tutor_to_hand_manifest.json`
- `docs/hermes-analysis/master_optimizer_reports/pg161_tutor_to_hand_package.md`

## Precheck

Command path:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
  -f ../docs/hermes-analysis/master_optimizer_reports/pg161_tutor_to_hand_precheck.sql
```

Returned rows:

- `Demonic Tutor`: `target_card_rows=1`, `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`
- `Diabolic Intent`: `target_card_rows=1`, `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`
- `Spellseeker`: `target_card_rows=1`, `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`
- `Sylvan Scrying`: `target_card_rows=1`, `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`
- `Trophy Mage`: `target_card_rows=1`, `existing_rule_rows=2`, `would_deprecate_shadow_rows=2`

## Apply

Command path:

```bash
cd /Users/desenvolvimentomobile/Documents/rafa/mtg/mtgia/server
set -a && source .env && set +a
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
  -f ../docs/hermes-analysis/master_optimizer_reports/pg161_tutor_to_hand_apply.sql
```

Result:

- `deprecated_shadow_rows=10`
- `upserted_rows=5`
- transaction `COMMIT`

## Postcheck

Returned rows:

- all 5 cards: `promoted_rule_rows=1`
- all 5 cards: `promoted_verified_auto_rows=1`
- all 5 cards: `promoted_oracle_hash_rows=1`
- audit backup rows: `10`

Audit table:

- `manaloom_deploy_audit.pg161_tutor_to_hand_20260624_094937`

Direct PG verification:

- `Demonic Tutor | curated | verified | auto | rule_version=2 | any_tutor_to_hand_v1`
- `Diabolic Intent | curated | verified | auto | rule_version=2 | sacrifice_creature_any_tutor_to_hand_v1`
- `Spellseeker | curated | verified | auto | rule_version=2 | spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1`
- `Sylvan Scrying | curated | verified | auto | rule_version=2 | land_tutor_to_hand_v1`
- `Trophy Mage | curated | verified | auto | rule_version=2 | trophy_mage_etb_artifact_mana_value_3_to_hand_v1`

## Hermes sync

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/sync_battle_card_rules_pg.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --apply-sqlite-from-pg \
  --include-needs-review \
  --only-card 'Demonic Tutor' \
  --only-card 'Diabolic Intent' \
  --only-card 'Sylvan Scrying' \
  --only-card 'Spellseeker' \
  --only-card 'Trophy Mage' \
  --report docs/hermes-analysis/master_optimizer_reports/battle_card_rules_sqlite_from_pg_pg161_tutor_to_hand_20260624.json
```

Summary:

- `selected_card_count=5`
- `pg_rows_loaded=15`
- `sqlite_inserted_or_updated=15`
- `canonical_snapshot_rows_exported=3220`

Canonical snapshot selected scopes:

- `Demonic Tutor` -> `any_tutor_to_hand_v1`
- `Diabolic Intent` -> `sacrifice_creature_any_tutor_to_hand_v1`
- `Sylvan Scrying` -> `land_tutor_to_hand_v1`
- `Spellseeker` -> `spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1`
- `Trophy Mage` -> `trophy_mage_etb_artifact_mana_value_3_to_hand_v1`

## Postsync real pipeline

Command:

```bash
python3 docs/hermes-analysis/manaloom-knowledge/scripts/xmage_current_replay_batch_pipeline.py \
  --sqlite-db docs/hermes-analysis/manaloom-knowledge/scripts/knowledge.db \
  --battle-artifact-dir /Users/desenvolvimentomobile/.manaloom-agents/artifacts/battle-strategy-audit/20260624_052838 \
  --xmage-root /Users/desenvolvimentomobile/Downloads/mage-master \
  --include-deck-id 6 \
  --output-prefix docs/hermes-analysis/master_optimizer_reports/xmage_current_replay_batch_pipeline_20260624_pg161_postsync_real_v1
```

Authoritative summary:

- `severity_counts={"high": 187, "medium": 36, "pass": 311}`
- `validity_status_counts={"xmage_source_valid_mapper_required": 206}`
- `proposal_status_counts={"mapper_metadata_or_test_scenario_required": 206}`

Net effect:

- before PG161: `206 mapper_required + 5 ready batch candidates`
- after PG161: `206 mapper_required`
