WITH target_card AS (
  SELECT id, name, md5(coalesce(oracle_text, '')) AS oracle_hash
  FROM public.cards
  WHERE lower(name) = 'repercussion'
     OR split_part(lower(name), ' // ', 1) = 'repercussion'
),
current_rules AS (
  SELECT
    normalized_name,
    logical_rule_key,
    review_status,
    execution_status,
    oracle_hash,
    effect_json->>'effect' AS effect,
    effect_json->>'battle_model_scope' AS battle_model_scope
  FROM public.card_battle_rules
  WHERE normalized_name = 'repercussion'
     OR normalized_name LIKE 'repercussion // %'
)
SELECT
  (SELECT count(*) FROM target_card WHERE oracle_hash = '8e1ed4f8063ab89dd8906878a6232862') AS target_card_rows,
  (SELECT count(*) FROM current_rules) AS current_rule_rows,
  (SELECT count(*) FROM current_rules WHERE review_status IN ('verified', 'active') AND execution_status IN ('auto', 'executable')) AS active_runtime_rows,
  jsonb_agg(to_jsonb(current_rules) ORDER BY logical_rule_key) AS current_rules
FROM current_rules;
