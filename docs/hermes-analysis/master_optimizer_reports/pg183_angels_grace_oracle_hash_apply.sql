BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg183_angels_grace_oracle_hash_20260624 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name = 'angel''s grace'
  AND logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227';

WITH expected AS (
  SELECT
    'angel''s grace'::text AS normalized_name,
    'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'::text AS logical_rule_key,
    md5(coalesce(c.oracle_text, '')) AS oracle_hash
  FROM public.cards c
  WHERE lower(c.name) = 'angel''s grace'
),
updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = expected.oracle_hash,
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG183: restored Angel''s Grace oracle_hash after PG -> Hermes sync provenance audit.')
  FROM expected
  WHERE r.normalized_name = expected.normalized_name
    AND r.logical_rule_key = expected.logical_rule_key
    AND (r.oracle_hash IS DISTINCT FROM expected.oracle_hash)
  RETURNING r.*
)
SELECT count(*) AS updated_rows FROM updated;

COMMIT;
