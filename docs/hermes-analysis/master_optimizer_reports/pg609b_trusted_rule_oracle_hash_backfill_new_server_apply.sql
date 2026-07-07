BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg609b_trusted_rule_oracle_hash_backfill_new_server_backup;

CREATE TABLE manaloom_deploy_audit.pg609b_trusted_rule_oracle_hash_backfill_new_server_backup AS
SELECT *
FROM public.card_battle_rules r
WHERE r.review_status IN ('verified', 'active')
  AND r.execution_status = 'auto'
  AND COALESCE(r.oracle_hash, '') = '';

DO $$
DECLARE
  v_target_count integer;
  v_safe_count integer;
  v_conflict_count integer;
  v_missing_count integer;
BEGIN
  WITH target AS (
    SELECT
      r.normalized_name,
      r.logical_rule_key,
      r.card_id
    FROM public.card_battle_rules r
    WHERE r.review_status IN ('verified', 'active')
      AND r.execution_status = 'auto'
      AND COALESCE(r.oracle_hash, '') = ''
  ),
  candidates AS (
    SELECT
      t.normalized_name,
      t.logical_rule_key,
      md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash
    FROM target t
    JOIN public.cards c
      ON (
           (t.card_id IS NOT NULL AND c.id = t.card_id)
           OR (
                t.card_id IS NULL
                AND (
                     lower(c.name) = t.normalized_name
                     OR split_part(lower(c.name), ' // ', 1) = t.normalized_name
                )
              )
         )
    WHERE COALESCE(c.oracle_text, '') <> ''
  ),
  grouped AS (
    SELECT
      normalized_name,
      logical_rule_key,
      count(DISTINCT computed_oracle_hash) AS distinct_hashes
    FROM candidates
    GROUP BY normalized_name, logical_rule_key
  )
  SELECT
    count(*),
    count(g.*) FILTER (WHERE g.distinct_hashes = 1),
    count(g.*) FILTER (WHERE g.distinct_hashes <> 1),
    count(*) FILTER (WHERE g.logical_rule_key IS NULL)
  INTO v_target_count, v_safe_count, v_conflict_count, v_missing_count
  FROM target t
  LEFT JOIN grouped g
    USING (normalized_name, logical_rule_key);

  IF v_target_count <> v_safe_count OR v_conflict_count <> 0 OR v_missing_count <> 0 THEN
    RAISE EXCEPTION
      'PG609B oracle_hash backfill aborted: target=%, safe=%, conflicts=%, missing=%',
      v_target_count,
      v_safe_count,
      v_conflict_count,
      v_missing_count;
  END IF;
END $$;

WITH target AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.card_id
  FROM public.card_battle_rules r
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND COALESCE(r.oracle_hash, '') = ''
),
candidates AS (
  SELECT
    t.normalized_name,
    t.logical_rule_key,
    md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash
  FROM target t
  JOIN public.cards c
    ON (
         (t.card_id IS NOT NULL AND c.id = t.card_id)
         OR (
              t.card_id IS NULL
              AND (
                   lower(c.name) = t.normalized_name
                   OR split_part(lower(c.name), ' // ', 1) = t.normalized_name
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
updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = s.computed_oracle_hash,
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG609B metadata-only oracle_hash integrity backfill from public.cards.oracle_text.'
    )
  FROM safe_hashes s
  WHERE r.normalized_name = s.normalized_name
    AND r.logical_rule_key = s.logical_rule_key
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status = 'auto'
    AND COALESCE(r.oracle_hash, '') = ''
  RETURNING r.*
)
SELECT count(*) AS backfilled_rows
FROM updated;

COMMIT;
