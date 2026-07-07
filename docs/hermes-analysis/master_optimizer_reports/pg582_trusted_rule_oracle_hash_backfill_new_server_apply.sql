BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg582_trusted_rule_oracle_hash_backfill_backup AS
SELECT
  r.normalized_name,
  r.logical_rule_key,
  r.card_name,
  r.oracle_hash AS previous_oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
  r.updated_at AS previous_updated_at,
  CURRENT_TIMESTAMP AS backed_up_at
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE false;

INSERT INTO manaloom_deploy_audit.pg582_trusted_rule_oracle_hash_backfill_backup (
  normalized_name,
  logical_rule_key,
  card_name,
  previous_oracle_hash,
  computed_oracle_hash,
  previous_updated_at,
  backed_up_at
)
SELECT
  r.normalized_name,
  r.logical_rule_key,
  r.card_name,
  r.oracle_hash AS previous_oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS computed_oracle_hash,
  r.updated_at AS previous_updated_at,
  CURRENT_TIMESTAMP AS backed_up_at
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE r.source IN ('manual', 'curated')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = ''
  AND NOT EXISTS (
    SELECT 1
    FROM manaloom_deploy_audit.pg582_trusted_rule_oracle_hash_backfill_backup b
    WHERE b.normalized_name = r.normalized_name
      AND b.logical_rule_key = r.logical_rule_key
  );

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET oracle_hash = md5(coalesce(c.oracle_text, '')),
      updated_at = CURRENT_TIMESTAMP
  FROM public.cards c
  WHERE c.id = r.card_id
    AND r.source IN ('manual', 'curated')
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status IN ('auto', 'executable')
    AND COALESCE(r.oracle_hash, '') = ''
  RETURNING r.normalized_name, r.card_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS updated_rows FROM updated;

COMMIT;
