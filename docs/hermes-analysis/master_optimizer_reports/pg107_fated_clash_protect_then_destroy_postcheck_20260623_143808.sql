WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'fated clash'
),
rule_rows AS (
  SELECT *
  FROM public.card_battle_rules
  WHERE normalized_name = 'fated clash'
),
backup_rows AS (
  SELECT count(*) AS count
  FROM manaloom_deploy_audit.pg107_fated_clash_protect_then_destroy_20260623_143808
)
SELECT
  (SELECT count(*) FROM target_card) AS target_card_rows,
  (SELECT count(*) FROM target_card WHERE oracle_hash = '14445ec4dd93171e67d19058efe24d9c') AS card_oracle_hash_match_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:15d0a672ca7e8d3cb7dff9fbd6ee2326') AS promoted_rule_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:15d0a672ca7e8d3cb7dff9fbd6ee2326' AND review_status = 'verified' AND execution_status = 'auto') AS promoted_verified_auto_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:15d0a672ca7e8d3cb7dff9fbd6ee2326' AND oracle_hash = '14445ec4dd93171e67d19058efe24d9c') AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key = 'battle_rule_v1:15d0a672ca7e8d3cb7dff9fbd6ee2326' AND effect_json->>'effect' = 'fated_clash_protect_then_destroy') AS promoted_expected_effect_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key <> 'battle_rule_v1:15d0a672ca7e8d3cb7dff9fbd6ee2326' AND review_status NOT IN ('deprecated', 'rejected') AND execution_status <> 'disabled') AS active_shadow_rows,
  (SELECT count(*) FROM rule_rows WHERE logical_rule_key <> 'battle_rule_v1:15d0a672ca7e8d3cb7dff9fbd6ee2326' AND review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable') AND effect_json->>'effect' = 'board_wipe') AS active_rows_still_claiming_plain_board_wipe,
  (SELECT count(*) FROM rule_rows WHERE review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable') AND coalesce(oracle_hash, '') = '') AS trusted_missing_oracle_hash_rows,
  (SELECT count FROM backup_rows) AS backup_rows;

SELECT
  normalized_name,
  card_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  rule_version,
  oracle_hash,
  effect_json,
  deck_role_json,
  notes
FROM public.card_battle_rules
WHERE normalized_name = 'fated clash'
ORDER BY logical_rule_key;
