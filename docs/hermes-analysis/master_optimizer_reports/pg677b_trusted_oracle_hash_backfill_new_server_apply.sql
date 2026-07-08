BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg677b_trusted_oracle_hash_backfill_backup (
  deploy_id text NOT NULL,
  backed_up_at timestamptz NOT NULL DEFAULT now(),
  card_id uuid NOT NULL,
  card_name text,
  normalized_name text NOT NULL,
  logical_rule_key text NOT NULL,
  previous_oracle_hash text,
  new_oracle_hash text NOT NULL,
  review_status text,
  execution_status text,
  source text,
  rule_version integer,
  PRIMARY KEY (deploy_id, card_id, normalized_name, logical_rule_key)
);

WITH target_rows AS (
  SELECT
    r.card_id,
    c.name AS card_name,
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash AS previous_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS new_oracle_hash,
    r.review_status,
    r.execution_status,
    r.source,
    r.rule_version
  FROM card_battle_rules r
  JOIN cards c ON c.id = r.card_id
  WHERE coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
    AND coalesce(r.execution_status, '') = 'auto'
    AND coalesce(r.review_status, '') IN ('verified', 'active')
)
INSERT INTO manaloom_deploy_audit.pg677b_trusted_oracle_hash_backfill_backup (
  deploy_id,
  card_id,
  card_name,
  normalized_name,
  logical_rule_key,
  previous_oracle_hash,
  new_oracle_hash,
  review_status,
  execution_status,
  source,
  rule_version
)
SELECT
  'pg677b',
  card_id,
  card_name,
  normalized_name,
  logical_rule_key,
  previous_oracle_hash,
  new_oracle_hash,
  review_status,
  execution_status,
  source,
  rule_version
FROM target_rows
ON CONFLICT (deploy_id, card_id, normalized_name, logical_rule_key) DO NOTHING;

WITH updated AS (
  UPDATE card_battle_rules r
  SET
    oracle_hash = b.new_oracle_hash,
    updated_at = now()
  FROM manaloom_deploy_audit.pg677b_trusted_oracle_hash_backfill_backup b
  WHERE b.deploy_id = 'pg677b'
    AND b.card_id = r.card_id
    AND b.normalized_name = r.normalized_name
    AND b.logical_rule_key = r.logical_rule_key
    AND coalesce(r.oracle_hash, '') = ''
  RETURNING r.card_id, r.normalized_name, r.logical_rule_key
)
SELECT count(*) AS updated_rows FROM updated;

COMMIT;
