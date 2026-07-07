\echo 'PG627b oracle_hash integrity backfill postcheck'

WITH trusted_missing AS (
    SELECT cbr.card_id, cbr.logical_rule_key
    FROM public.card_battle_rules cbr
    WHERE cbr.source IN ('curated', 'manual')
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
      AND COALESCE(cbr.oracle_hash, '') = ''
),
backup AS (
    SELECT card_id, logical_rule_key, expected_oracle_hash
    FROM manaloom_deploy_audit.pg627b_oracle_hash_integrity_backfill_new_server_20260707
),
restored AS (
    SELECT b.card_id, b.logical_rule_key
    FROM backup b
    JOIN public.card_battle_rules cbr
      ON cbr.card_id = b.card_id
     AND cbr.logical_rule_key = b.logical_rule_key
     AND cbr.oracle_hash = b.expected_oracle_hash
)
SELECT
    (SELECT COUNT(*) FROM trusted_missing) AS trusted_executable_missing_oracle_hash_rows,
    (SELECT COUNT(*) FROM backup) AS backup_rows,
    (SELECT COUNT(*) FROM restored) AS restored_rows;
