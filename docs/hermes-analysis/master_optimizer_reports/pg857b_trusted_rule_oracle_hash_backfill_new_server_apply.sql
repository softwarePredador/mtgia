\echo 'PG857B trusted rule oracle_hash backfill apply'

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg857b_trusted_rule_oracle_hash_backfill_new_server_20260713;

CREATE TABLE manaloom_deploy_audit.pg857b_trusted_rule_oracle_hash_backfill_new_server_20260713 AS
WITH missing AS (
  SELECT br.*
  FROM public.card_battle_rules br
  WHERE br.source IN ('curated', 'manual')
    AND br.review_status = 'verified'
    AND br.execution_status IN ('auto', 'executable')
    AND COALESCE(br.oracle_hash, '') = ''
),
matched AS (
  SELECT
    m.card_id,
    m.normalized_name,
    m.logical_rule_key,
    m.source,
    COUNT(c.id) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS matched_card_rows,
    COUNT(DISTINCT md5(c.oracle_text)) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS distinct_oracle_hashes,
    MIN(md5(c.oracle_text)) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS pg857b_new_oracle_hash
  FROM missing m
  LEFT JOIN public.cards c
    ON c.id = m.card_id
  GROUP BY m.card_id, m.normalized_name, m.logical_rule_key, m.source
),
safe AS (
  SELECT *
  FROM matched
  WHERE matched_card_rows = 1
    AND distinct_oracle_hashes = 1
    AND pg857b_new_oracle_hash IS NOT NULL
)
SELECT
  br.*,
  safe.pg857b_new_oracle_hash,
  NOW() AS pg857b_backed_up_at
FROM public.card_battle_rules br
JOIN safe
  ON safe.card_id = br.card_id
 AND safe.normalized_name = br.normalized_name
 AND safe.logical_rule_key = br.logical_rule_key
 AND safe.source = br.source
WHERE COALESCE(br.oracle_hash, '') = '';

DO $$
DECLARE
  v_unsafe_rows integer;
BEGIN
  WITH missing AS (
    SELECT br.*
    FROM public.card_battle_rules br
    WHERE br.source IN ('curated', 'manual')
      AND br.review_status = 'verified'
      AND br.execution_status IN ('auto', 'executable')
      AND COALESCE(br.oracle_hash, '') = ''
  ),
  matched AS (
    SELECT
      m.card_id,
      m.normalized_name,
      m.logical_rule_key,
      m.source,
      COUNT(c.id) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS matched_card_rows,
      COUNT(DISTINCT md5(c.oracle_text)) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS distinct_oracle_hashes,
      MIN(md5(c.oracle_text)) FILTER (WHERE COALESCE(BTRIM(c.oracle_text), '') <> '') AS new_oracle_hash
    FROM missing m
    LEFT JOIN public.cards c
      ON c.id = m.card_id
    GROUP BY m.card_id, m.normalized_name, m.logical_rule_key, m.source
  )
  SELECT COUNT(*)
  INTO v_unsafe_rows
  FROM matched
  WHERE matched_card_rows <> 1
     OR distinct_oracle_hashes <> 1
     OR new_oracle_hash IS NULL;

  IF v_unsafe_rows <> 0 THEN
    RAISE EXCEPTION 'PG857B unsafe oracle_hash backfill rows: %', v_unsafe_rows;
  END IF;
END $$;

WITH target AS (
  SELECT
    card_id,
    normalized_name,
    logical_rule_key,
    source,
    pg857b_new_oracle_hash
  FROM manaloom_deploy_audit.pg857b_trusted_rule_oracle_hash_backfill_new_server_20260713
),
updated AS (
  UPDATE public.card_battle_rules br
  SET
    oracle_hash = target.pg857b_new_oracle_hash,
    updated_at = NOW(),
    notes = CONCAT_WS(
      E'\n',
      NULLIF(br.notes, ''),
      'PG857B: backfilled oracle_hash for trusted executable rule from current cards.oracle_text md5 on 2026-07-13.'
    )
  FROM target
  WHERE br.card_id = target.card_id
    AND br.normalized_name = target.normalized_name
    AND br.logical_rule_key = target.logical_rule_key
    AND br.source = target.source
    AND COALESCE(br.oracle_hash, '') = ''
  RETURNING br.card_id, br.normalized_name, br.logical_rule_key, br.source
)
SELECT
  (SELECT COUNT(*) FROM manaloom_deploy_audit.pg857b_trusted_rule_oracle_hash_backfill_new_server_20260713) AS backup_rows,
  (SELECT COUNT(*) FROM updated) AS updated_rows;

COMMIT;
