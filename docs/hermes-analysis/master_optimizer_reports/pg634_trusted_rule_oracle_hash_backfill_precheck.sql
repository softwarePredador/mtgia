-- PG634 precheck: backfill missing oracle_hash for trusted executable curated/manual rules.
-- This is provenance repair only; it does not change effect_json, review_status,
-- execution_status, source, or logical_rule_key.

WITH target_rows AS (
  SELECT
    cbr.normalized_name,
    cbr.card_name,
    cbr.logical_rule_key,
    cbr.review_status,
    cbr.execution_status,
    cbr.source,
    md5(coalesce(c.oracle_text, '')) AS expected_oracle_hash
  FROM public.card_battle_rules cbr
  JOIN public.cards c ON c.id = cbr.card_id
  WHERE cbr.source IN ('curated', 'manual')
    AND cbr.review_status IN ('verified', 'active')
    AND cbr.execution_status IN ('auto', 'executable')
    AND COALESCE(cbr.oracle_hash, '') = ''
    AND COALESCE(c.oracle_text, '') <> ''
)
SELECT 'target_rows' AS check_name, COUNT(*)::text AS value FROM target_rows
UNION ALL
SELECT 'distinct_cards', COUNT(DISTINCT normalized_name)::text FROM target_rows
UNION ALL
SELECT 'verified_rows', COUNT(*)::text FROM target_rows WHERE review_status = 'verified'
UNION ALL
SELECT 'active_rows', COUNT(*)::text FROM target_rows WHERE review_status = 'active'
UNION ALL
SELECT 'curated_rows', COUNT(*)::text FROM target_rows WHERE source = 'curated'
UNION ALL
SELECT 'manual_rows', COUNT(*)::text FROM target_rows WHERE source = 'manual';
