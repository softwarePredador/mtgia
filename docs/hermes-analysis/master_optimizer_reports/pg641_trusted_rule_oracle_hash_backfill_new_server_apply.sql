\echo 'PG641 trusted rule oracle_hash backfill apply'

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg641_trusted_rule_oracle_hash_backfill_new_server_20260707 (
  normalized_name text NOT NULL,
  logical_rule_key text NOT NULL,
  card_name text NOT NULL,
  card_id uuid,
  previous_oracle_hash text,
  computed_oracle_hash text NOT NULL,
  previous_updated_at timestamptz,
  previous_notes text,
  backed_up_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (normalized_name, logical_rule_key)
);

WITH backup_rows AS (
  INSERT INTO manaloom_deploy_audit.pg641_trusted_rule_oracle_hash_backfill_new_server_20260707 (
    normalized_name,
    logical_rule_key,
    card_name,
    card_id,
    previous_oracle_hash,
    computed_oracle_hash,
    previous_updated_at,
    previous_notes,
    backed_up_at
  )
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.card_name,
    r.card_id,
    r.oracle_hash AS previous_oracle_hash,
    md5(COALESCE(c.oracle_text, '')) AS computed_oracle_hash,
    r.updated_at AS previous_updated_at,
    r.notes AS previous_notes,
    now() AS backed_up_at
  FROM public.card_battle_rules r
  JOIN public.cards c ON c.id = r.card_id
  WHERE r.source IN ('manual', 'curated')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
  ON CONFLICT (normalized_name, logical_rule_key) DO NOTHING
  RETURNING normalized_name, logical_rule_key
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = md5(COALESCE(c.oracle_text, '')),
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      NULLIF(r.notes, ''),
      'PG641 metadata integrity backfill: restored oracle_hash from cards.oracle_text for trusted executable rules.'
    )
  FROM public.cards c
  WHERE c.id = r.card_id
    AND r.source IN ('manual', 'curated')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
  RETURNING r.normalized_name, r.logical_rule_key
)
SELECT
  (SELECT COUNT(*) FROM backup_rows) AS inserted_backup_rows,
  (SELECT COUNT(*) FROM updated) AS updated_rows;

COMMIT;
