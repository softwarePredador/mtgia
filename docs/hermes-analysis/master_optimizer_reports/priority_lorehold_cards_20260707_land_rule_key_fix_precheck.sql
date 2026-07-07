SELECT
  normalized_name,
  card_name,
  logical_rule_key,
  effect_json->>'battle_model_scope' AS battle_model_scope,
  oracle_hash,
  review_status,
  execution_status
FROM public.card_battle_rules
WHERE normalized_name IN ('command tower', 'turbulent steppe')
ORDER BY normalized_name, logical_rule_key;
