BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg649_trusted_rule_oracle_hash_backfill_20260707;

CREATE TABLE manaloom_deploy_audit.pg649_trusted_rule_oracle_hash_backfill_20260707 AS
SELECT r.*
FROM public.card_battle_rules r
JOIN public.cards c ON c.id = r.card_id
WHERE r.review_status IN ('verified', 'active')
  AND r.execution_status <> 'disabled'
  AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '')
  AND btrim(coalesce(c.oracle_text, '')) <> '';

DO $$
DECLARE
  v_bad_count integer;
BEGIN
  SELECT count(*)
    INTO v_bad_count
  FROM public.card_battle_rules r
  LEFT JOIN public.cards c ON c.id = r.card_id
  WHERE r.review_status IN ('verified', 'active')
    AND r.execution_status <> 'disabled'
    AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '')
    AND (
      r.card_id IS NULL
      OR c.id IS NULL
      OR btrim(coalesce(c.oracle_text, '')) = ''
    );

  IF v_bad_count > 0 THEN
    RAISE EXCEPTION 'PG649 abort: found % trusted active rules with missing hash but no safe card oracle_text source', v_bad_count;
  END IF;
END $$;

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = md5(coalesce(c.oracle_text, '')),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG649: oracle_hash backfilled from cards.oracle_text for trusted active rule.'),
    updated_at = now(),
    last_seen_at = now()
  FROM public.cards c
  WHERE c.id = r.card_id
    AND r.review_status IN ('verified', 'active')
    AND r.execution_status <> 'disabled'
    AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '')
    AND btrim(coalesce(c.oracle_text, '')) <> ''
  RETURNING r.card_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS oracle_hash_rows_backfilled
FROM updated;

COMMIT;
