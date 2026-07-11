BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg747_hash_backfill_20260711_0730 AS
SELECT *
FROM public.card_battle_rules r
WHERE r.execution_status = 'auto'
  AND r.review_status IN ('verified', 'active')
  AND nullif(r.oracle_hash, '') IS NULL
  AND r.card_id IS NOT NULL;

DO $$
DECLARE
  v_unmatched integer;
BEGIN
  SELECT count(*)
    INTO v_unmatched
  FROM public.card_battle_rules r
  LEFT JOIN public.cards c
    ON c.id = r.card_id
  WHERE r.execution_status = 'auto'
    AND r.review_status IN ('verified', 'active')
    AND nullif(r.oracle_hash, '') IS NULL
    AND c.id IS NULL;

  IF v_unmatched <> 0 THEN
    RAISE EXCEPTION 'PG747 oracle_hash backfill abort: trusted executable rules without resolvable cards.card_id rows: %', v_unmatched;
  END IF;
END $$;

WITH updated AS (
  UPDATE public.card_battle_rules r
  SET
    oracle_hash = md5(coalesce(c.oracle_text, '')),
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG747 integrity backfill: oracle_hash filled from cards.oracle_text md5 without changing runtime effect.')
  FROM public.cards c
  WHERE c.id = r.card_id
    AND r.execution_status = 'auto'
    AND r.review_status IN ('verified', 'active')
    AND nullif(r.oracle_hash, '') IS NULL
  RETURNING r.normalized_name, r.logical_rule_key, r.oracle_hash
)
SELECT count(*) AS backfilled_rows
FROM updated;

COMMIT;
