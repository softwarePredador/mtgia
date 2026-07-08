SELECT
  count(*) AS remaining_trusted_executable_missing_hash_rows
FROM public.card_battle_rules r
WHERE r.review_status IN ('verified', 'verified_auto', 'approved', 'trusted', 'active')
  AND coalesce(r.execution_status, '') NOT IN ('disabled', 'shadow_only', 'blocked', 'review_only')
  AND (r.oracle_hash IS NULL OR btrim(r.oracle_hash) = '');

SELECT
  count(*) AS backfilled_rows_with_expected_hash
FROM public.card_battle_rules r
JOIN manaloom_deploy_audit.pg652b_trusted_oracle_hash_backfill_20260708 b
  ON b.card_id = r.card_id
 AND b.logical_rule_key = r.logical_rule_key
JOIN public.cards c ON c.id = r.card_id
WHERE r.oracle_hash = md5(coalesce(c.oracle_text, ''));

SELECT
  r.card_name,
  r.normalized_name,
  r.logical_rule_key,
  r.oracle_hash,
  r.effect_json->>'effect' AS effect,
  r.effect_json->>'battle_model_scope' AS battle_model_scope
FROM public.card_battle_rules r
JOIN manaloom_deploy_audit.pg652b_trusted_oracle_hash_backfill_20260708 b
  ON b.card_id = r.card_id
 AND b.logical_rule_key = r.logical_rule_key
ORDER BY r.card_name, r.logical_rule_key;
