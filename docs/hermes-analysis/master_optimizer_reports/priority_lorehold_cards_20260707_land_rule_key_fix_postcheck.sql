WITH expected(normalized_name, expected_key, expected_scope) AS (
  VALUES
    (
      'command tower',
      'battle_rule_v1:8a974d0b2c767176f8066c7932447896',
      'commander_identity_land_mana_source_v1'
    ),
    (
      'turbulent steppe',
      'battle_rule_v1:a614845f052c61eaa22e619e7b288e17',
      'land_enters_tapped_unless_opponents_control_lands_count_mana_source_v1'
    )
)
SELECT
  expected.normalized_name,
  expected.expected_key,
  expected.expected_scope,
  count(rule.*) FILTER (
    WHERE rule.logical_rule_key = expected.expected_key
      AND rule.effect_json->>'battle_model_scope' = expected.expected_scope
      AND rule.review_status IN ('verified', 'active')
      AND rule.execution_status != 'disabled'
  ) AS matching_runtime_rows,
  count(rule.*) FILTER (
    WHERE rule.logical_rule_key = 'battle_rule_v1:603c776839827f2f21cef8b62e22a1be'
      AND rule.effect_json->>'battle_model_scope' = expected.expected_scope
      AND rule.review_status IN ('verified', 'active')
      AND rule.execution_status != 'disabled'
  ) AS remaining_generic_key_rows
FROM expected
LEFT JOIN public.card_battle_rules rule
  ON rule.normalized_name = expected.normalized_name
GROUP BY expected.normalized_name, expected.expected_key, expected.expected_scope
ORDER BY expected.normalized_name;
