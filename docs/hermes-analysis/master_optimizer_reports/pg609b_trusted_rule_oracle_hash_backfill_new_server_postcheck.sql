WITH missing AS (
  SELECT *
  FROM public.card_battle_rules r
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND COALESCE(r.oracle_hash, '') = ''
),
backup AS (
  SELECT *
  FROM manaloom_deploy_audit.pg609b_trusted_rule_oracle_hash_backfill_new_server_backup
),
current_rows AS (
  SELECT r.*
  FROM public.card_battle_rules r
  JOIN backup b
    USING (normalized_name, logical_rule_key)
),
candidates AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash
  FROM current_rows r
  JOIN public.cards c
    ON (
         (r.card_id IS NOT NULL AND c.id = r.card_id)
         OR (
              r.card_id IS NULL
              AND (
                   lower(c.name) = r.normalized_name
                   OR split_part(lower(c.name), ' // ', 1) = r.normalized_name
              )
            )
       )
  WHERE COALESCE(c.oracle_text, '') <> ''
),
safe_hashes AS (
  SELECT
    normalized_name,
    logical_rule_key,
    min(computed_oracle_hash) AS computed_oracle_hash
  FROM candidates
  GROUP BY normalized_name, logical_rule_key
  HAVING count(DISTINCT computed_oracle_hash) = 1
),
mismatches AS (
  SELECT r.*
  FROM current_rows r
  JOIN safe_hashes s
    USING (normalized_name, logical_rule_key)
  WHERE r.oracle_hash <> s.computed_oracle_hash
)
SELECT
  (SELECT count(*) FROM backup) AS backup_rows,
  (SELECT count(*) FROM current_rows) AS current_backfilled_rows,
  (SELECT count(*) FROM missing) AS trusted_executable_rules_missing_oracle_hash,
  (SELECT count(*) FROM mismatches) AS hash_mismatch_rows;
