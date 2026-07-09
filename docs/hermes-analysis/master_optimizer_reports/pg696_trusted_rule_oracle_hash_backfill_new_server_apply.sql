\echo 'PG696 trusted rule oracle_hash backfill apply'

BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DROP TABLE IF EXISTS manaloom_deploy_audit.pg696_trusted_rule_oracle_hash_backfill_new_server_20260709;

CREATE TABLE manaloom_deploy_audit.pg696_trusted_rule_oracle_hash_backfill_new_server_20260709 AS
SELECT
  b.normalized_name,
  b.logical_rule_key,
  b.card_id,
  b.card_name,
  b.oracle_hash AS old_oracle_hash,
  md5(coalesce(c.oracle_text, '')) AS new_oracle_hash,
  now() AS backed_up_at
FROM public.card_battle_rules b
JOIN public.cards c ON c.id = b.card_id
WHERE b.execution_status IN ('auto', 'executable')
  AND b.review_status IN ('verified', 'active')
  AND coalesce(b.oracle_hash, '') = ''
  AND btrim(coalesce(c.oracle_text, '')) <> '';

DO $$
DECLARE
  v_unsafe_count integer;
BEGIN
  SELECT count(*)
    INTO v_unsafe_count
  FROM public.card_battle_rules b
  LEFT JOIN public.cards c ON c.id = b.card_id
  WHERE b.execution_status IN ('auto', 'executable')
    AND b.review_status IN ('verified', 'active')
    AND coalesce(b.oracle_hash, '') = ''
    AND (
      b.card_id IS NULL
      OR c.id IS NULL
      OR btrim(coalesce(c.oracle_text, '')) = ''
    );

  IF v_unsafe_count > 0 THEN
    RAISE EXCEPTION 'PG696 abort: % trusted executable rules lack oracle_hash and safe cards.oracle_text source', v_unsafe_count;
  END IF;
END $$;

WITH updated AS (
  UPDATE public.card_battle_rules b
  SET
    oracle_hash = backup.new_oracle_hash,
    notes = concat_ws(E'\n', nullif(b.notes, ''), 'PG696 2026-07-09: metadata-only oracle_hash backfill from cards.oracle_text after reviewed-rule sync regression.'),
    updated_at = now(),
    last_seen_at = now()
  FROM manaloom_deploy_audit.pg696_trusted_rule_oracle_hash_backfill_new_server_20260709 backup
  WHERE b.normalized_name = backup.normalized_name
    AND b.logical_rule_key = backup.logical_rule_key
  RETURNING b.normalized_name, b.logical_rule_key
)
SELECT count(*) AS oracle_hash_rows_backfilled
FROM updated;

COMMIT;
