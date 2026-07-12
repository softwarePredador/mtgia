\echo 'PG819 trusted rule oracle_hash backfill apply'

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg819_trusted_rule_oracle_hash_backfill_new_server_20260712 AS
SELECT
  br.*,
  md5(c.oracle_text) AS pg819_new_oracle_hash,
  NOW() AS pg819_backed_up_at
FROM public.card_battle_rules br
JOIN public.cards c ON c.id = br.card_id
WHERE br.review_status = 'verified'
  AND br.execution_status = 'auto'
  AND COALESCE(BTRIM(br.oracle_hash), '') = ''
  AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL;

WITH target AS (
  SELECT
    br.card_id,
    br.normalized_name,
    br.logical_rule_key,
    br.source,
    md5(c.oracle_text) AS new_oracle_hash
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.review_status = 'verified'
    AND br.execution_status = 'auto'
    AND COALESCE(BTRIM(br.oracle_hash), '') = ''
    AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL
),
updated AS (
  UPDATE public.card_battle_rules br
  SET
    oracle_hash = target.new_oracle_hash,
    updated_at = NOW(),
    notes = CONCAT_WS(
      E'\n',
      NULLIF(br.notes, ''),
      'PG819: backfilled oracle_hash for trusted verified/auto rule from current cards.oracle_text md5 on 2026-07-12.'
    )
  FROM target
  WHERE br.card_id = target.card_id
    AND br.normalized_name IS NOT DISTINCT FROM target.normalized_name
    AND br.logical_rule_key IS NOT DISTINCT FROM target.logical_rule_key
    AND br.source IS NOT DISTINCT FROM target.source
  RETURNING br.card_id, br.normalized_name, br.logical_rule_key, br.source
)
SELECT
  (SELECT COUNT(*) FROM manaloom_deploy_audit.pg819_trusted_rule_oracle_hash_backfill_new_server_20260712) AS backup_rows,
  (SELECT COUNT(*) FROM updated) AS updated_rows;

COMMIT;
