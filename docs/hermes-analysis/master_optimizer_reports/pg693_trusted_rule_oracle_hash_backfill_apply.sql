BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg693_trusted_rule_oracle_hash_backfill_backup (
  normalized_name text NOT NULL,
  logical_rule_key text NOT NULL,
  card_id uuid,
  card_name text NOT NULL,
  old_oracle_hash text,
  new_oracle_hash text NOT NULL,
  backed_up_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (normalized_name, logical_rule_key)
);

WITH target AS (
  SELECT
    b.normalized_name,
    b.logical_rule_key,
    b.card_id,
    b.card_name,
    b.oracle_hash AS old_oracle_hash,
    md5(coalesce(c.oracle_text, '')) AS new_oracle_hash
  FROM card_battle_rules b
  JOIN cards c ON c.id = b.card_id
  WHERE b.execution_status IN ('auto', 'executable')
    AND b.review_status IN ('verified', 'active')
    AND coalesce(b.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
),
backup_insert AS (
  INSERT INTO manaloom_deploy_audit.pg693_trusted_rule_oracle_hash_backfill_backup (
    normalized_name,
    logical_rule_key,
    card_id,
    card_name,
    old_oracle_hash,
    new_oracle_hash
  )
  SELECT
    normalized_name,
    logical_rule_key,
    card_id,
    card_name,
    old_oracle_hash,
    new_oracle_hash
  FROM target
  ON CONFLICT (normalized_name, logical_rule_key) DO NOTHING
  RETURNING 1
)
SELECT count(*) AS backed_up_rows
FROM backup_insert;

WITH target AS (
  SELECT
    b.normalized_name,
    b.logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS new_oracle_hash
  FROM card_battle_rules b
  JOIN cards c ON c.id = b.card_id
  WHERE b.execution_status IN ('auto', 'executable')
    AND b.review_status IN ('verified', 'active')
    AND coalesce(b.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
),
updated AS (
  UPDATE card_battle_rules b
  SET
    oracle_hash = target.new_oracle_hash,
    updated_at = now()
  FROM target
  WHERE b.normalized_name = target.normalized_name
    AND b.logical_rule_key = target.logical_rule_key
  RETURNING b.normalized_name, b.logical_rule_key
)
SELECT count(*) AS updated_rows
FROM updated;

COMMIT;
