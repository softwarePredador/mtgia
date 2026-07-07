BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg604b_trusted_rule_oracle_hash_backfill_new_server_backup (
  card_id uuid NOT NULL,
  card_name text,
  normalized_name text NOT NULL,
  logical_rule_key text NOT NULL,
  previous_oracle_hash text,
  previous_updated_at timestamptz,
  backed_up_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (card_id, logical_rule_key)
);

WITH missing AS (
  SELECT
    r.card_id,
    r.card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.updated_at
  FROM public.card_battle_rules r
  WHERE r.source IN ('curated', 'manual')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
),
candidates AS (
  SELECT
    m.card_id,
    m.card_name,
    m.normalized_name,
    m.logical_rule_key,
    m.oracle_hash,
    m.updated_at,
    COUNT(c.*) AS matched_card_rows,
    COUNT(DISTINCT md5(COALESCE(c.oracle_text, ''))) AS distinct_hashes,
    MIN(md5(COALESCE(c.oracle_text, ''))) AS computed_oracle_hash
  FROM missing m
  LEFT JOIN public.cards c
    ON c.id = m.card_id
  GROUP BY
    m.card_id,
    m.card_name,
    m.normalized_name,
    m.logical_rule_key,
    m.oracle_hash,
    m.updated_at
),
safe_candidates AS (
  SELECT *
  FROM candidates
  WHERE matched_card_rows > 0
    AND distinct_hashes = 1
),
backup_insert AS (
  INSERT INTO manaloom_deploy_audit.pg604b_trusted_rule_oracle_hash_backfill_new_server_backup (
    card_id,
    card_name,
    normalized_name,
    logical_rule_key,
    previous_oracle_hash,
    previous_updated_at
  )
  SELECT
    sc.card_id,
    sc.card_name,
    sc.normalized_name,
    sc.logical_rule_key,
    sc.oracle_hash,
    sc.updated_at
  FROM safe_candidates sc
  ON CONFLICT (card_id, logical_rule_key) DO NOTHING
  RETURNING 1
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = sc.computed_oracle_hash,
    updated_at = now()
  FROM safe_candidates sc
  WHERE r.card_id = sc.card_id
    AND r.logical_rule_key = sc.logical_rule_key
    AND COALESCE(r.oracle_hash, '') = ''
  RETURNING r.card_name, r.normalized_name, r.logical_rule_key, r.oracle_hash
)
SELECT
  (SELECT COUNT(*) FROM safe_candidates) AS safe_candidates,
  (SELECT COUNT(*) FROM backup_insert) AS backup_rows_inserted,
  (SELECT COUNT(*) FROM updated) AS rows_updated;

COMMIT;
