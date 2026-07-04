BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg399b_backfill_oracle_hashes_new_server_2') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg399b_backfill_oracle_hashes_new_server_2 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg399b_backfill_oracle_hashes_new_server_2 AS
SELECT *
FROM public.card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('angel''s grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
  ('seething song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
);

WITH target(normalized_name, card_name, logical_rule_key) AS (
  VALUES
    ('angel''s grace', 'Angel''s Grace', 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'),
    ('seething song', 'Seething Song', 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7')
),
candidate AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash
  FROM target t
  JOIN public.card_battle_rules r
    ON r.normalized_name = t.normalized_name
   AND r.logical_rule_key = t.logical_rule_key
  JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.source = 'curated'
    AND r.review_status = 'verified'
    AND r.execution_status = 'auto'
    AND coalesce(r.oracle_hash, '') = ''
    AND coalesce(c.oracle_text, '') <> ''
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = c.computed_oracle_hash,
    updated_at = now(),
    notes = concat_ws(
      E'\n',
      nullif(r.notes, ''),
      'PG399b: backfilled oracle_hash from current PostgreSQL cards.oracle_text after PG/Hermes contract audit.'
    )
  FROM candidate c
  WHERE r.normalized_name = c.normalized_name
    AND r.logical_rule_key = c.logical_rule_key
  RETURNING r.normalized_name, r.card_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS updated_rows
FROM updated;

COMMIT;
