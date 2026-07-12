\echo 'PG819 trusted rule oracle_hash backfill precheck'

WITH target AS (
  SELECT
    br.card_id,
    c.name AS postgres_card_name,
    br.card_name,
    br.normalized_name,
    br.logical_rule_key,
    br.source,
    br.review_status,
    br.execution_status,
    br.rule_version,
    br.oracle_hash AS old_oracle_hash,
    md5(c.oracle_text) AS new_oracle_hash,
    br.effect_json ->> 'battle_model_scope' AS battle_model_scope
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.review_status = 'verified'
    AND br.execution_status = 'auto'
    AND COALESCE(BTRIM(br.oracle_hash), '') = ''
    AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL
)
SELECT
  COUNT(*) AS would_backfill_rows,
  COUNT(DISTINCT card_id) AS distinct_cards,
  COUNT(DISTINCT (card_id, normalized_name, logical_rule_key, source)) AS distinct_rule_keys,
  COUNT(*) FILTER (WHERE old_oracle_hash IS NULL) AS null_hash_rows,
  COUNT(*) FILTER (WHERE old_oracle_hash = '') AS empty_hash_rows,
  COUNT(*) FILTER (WHERE new_oracle_hash = md5('')) AS empty_oracle_hash_rows
FROM target;

SELECT EXISTS (
  SELECT 1
  FROM information_schema.tables
  WHERE table_schema = 'manaloom_deploy_audit'
    AND table_name = 'pg819_trusted_rule_oracle_hash_backfill_new_server_20260712'
) AS backup_table_already_exists;

WITH target AS (
  SELECT
    c.name AS postgres_card_name,
    br.card_name,
    br.normalized_name,
    br.source,
    br.review_status,
    br.execution_status,
    br.rule_version,
    br.logical_rule_key,
    md5(c.oracle_text) AS new_oracle_hash,
    br.effect_json ->> 'battle_model_scope' AS battle_model_scope
  FROM public.card_battle_rules br
  JOIN public.cards c ON c.id = br.card_id
  WHERE br.review_status = 'verified'
    AND br.execution_status = 'auto'
    AND COALESCE(BTRIM(br.oracle_hash), '') = ''
    AND NULLIF(BTRIM(c.oracle_text), '') IS NOT NULL
)
SELECT *
FROM target
ORDER BY postgres_card_name, logical_rule_key, source
LIMIT 120;
