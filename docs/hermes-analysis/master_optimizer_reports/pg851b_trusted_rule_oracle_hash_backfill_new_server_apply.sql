\echo 'PG851B trusted rule oracle_hash backfill apply'

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg851b_trusted_rule_oracle_hash_backfill_new_server_20260712;

CREATE TABLE manaloom_deploy_audit.pg851b_trusted_rule_oracle_hash_backfill_new_server_20260712 AS
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
    m.*,
    c.id AS matched_card_id,
    md5(c.oracle_text) AS pg851b_new_oracle_hash,
    COUNT(c.id) OVER (PARTITION BY m.card_id, m.normalized_name, m.logical_rule_key, m.source) AS match_count
  FROM missing m
  LEFT JOIN public.cards c
    ON (
         m.card_id IS NOT NULL AND c.id = m.card_id
       )
    OR (
         m.card_id IS NULL
         AND (
           lower(c.name) = m.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = m.normalized_name
         )
       )
   AND COALESCE(BTRIM(c.oracle_text), '') <> ''
)
SELECT
  matched.*,
  NOW() AS pg851b_backed_up_at
FROM matched
WHERE match_count = 1
  AND pg851b_new_oracle_hash IS NOT NULL;

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
      md5(c.oracle_text) AS new_oracle_hash,
      COUNT(c.id) OVER (PARTITION BY m.card_id, m.normalized_name, m.logical_rule_key, m.source) AS match_count
    FROM missing m
    LEFT JOIN public.cards c
      ON (
           m.card_id IS NOT NULL AND c.id = m.card_id
         )
      OR (
           m.card_id IS NULL
           AND (
             lower(c.name) = m.normalized_name
             OR split_part(lower(c.name), ' // ', 1) = m.normalized_name
           )
         )
     AND COALESCE(BTRIM(c.oracle_text), '') <> ''
  )
  SELECT COUNT(*)
  INTO v_unsafe_rows
  FROM matched
  WHERE match_count <> 1 OR new_oracle_hash IS NULL;

  IF v_unsafe_rows <> 0 THEN
    RAISE EXCEPTION 'PG851B unsafe oracle_hash backfill rows: %', v_unsafe_rows;
  END IF;
END $$;

WITH target AS (
  SELECT
    card_id,
    normalized_name,
    logical_rule_key,
    source,
    pg851b_new_oracle_hash
  FROM manaloom_deploy_audit.pg851b_trusted_rule_oracle_hash_backfill_new_server_20260712
),
updated AS (
  UPDATE public.card_battle_rules br
  SET
    oracle_hash = target.pg851b_new_oracle_hash,
    updated_at = NOW(),
    notes = CONCAT_WS(
      E'\n',
      NULLIF(br.notes, ''),
      'PG851B: backfilled oracle_hash for trusted executable rule from current cards.oracle_text md5 on 2026-07-12.'
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
  (SELECT COUNT(*) FROM manaloom_deploy_audit.pg851b_trusted_rule_oracle_hash_backfill_new_server_20260712) AS backup_rows,
  (SELECT COUNT(*) FROM updated) AS updated_rows;

COMMIT;
