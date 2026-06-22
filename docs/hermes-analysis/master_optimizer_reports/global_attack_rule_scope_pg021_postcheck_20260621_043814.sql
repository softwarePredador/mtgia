\pset pager off

WITH rows AS (
  SELECT
    normalized_name,
    logical_rule_key,
    effect_json,
    deck_role_json,
    notes
  FROM card_battle_rules
  WHERE (normalized_name, logical_rule_key) IN (
    ('silent arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'),
    ('magus of the moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a'),
    ('ensnaring bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5')
  )
),
checks AS (
  SELECT
    count(*) AS rule_rows,
    bool_or(
      normalized_name = 'silent arbiter'
      AND effect_json->>'battle_model_scope' = 'silent_arbiter_global_single_attacker_v2'
      AND effect_json ? 'max_attackers'
      AND NOT (effect_json ? 'max_attackers_against_you')
    ) AS silent_global_ok,
    bool_or(
      normalized_name = 'magus of the moat'
      AND effect_json->>'battle_model_scope' = 'magus_of_the_moat_global_flying_attack_filter_v2'
      AND effect_json->>'attack_requires_keyword' = 'flying'
    ) AS magus_global_ok,
    bool_or(
      normalized_name = 'ensnaring bridge'
      AND effect_json->>'battle_model_scope' = 'ensnaring_bridge_controller_hand_size_power_filter_v2'
      AND effect_json ? 'max_attacker_power_by_controller_hand_size'
      AND NOT (effect_json ? 'max_attacker_power_by_defender_hand_size')
    ) AS bridge_controller_hand_ok
  FROM rows
)
SELECT
  'pg021_global_attack_rule_scope_postcheck' AS check_name,
  rule_rows,
  silent_global_ok,
  magus_global_ok,
  bridge_controller_hand_ok,
  (
    rule_rows = 3
    AND silent_global_ok
    AND magus_global_ok
    AND bridge_controller_hand_ok
  ) AS postcheck_passed
FROM checks;

SELECT
  'pg021_global_attack_rule_scope_rows' AS check_name,
  normalized_name,
  logical_rule_key,
  effect_json,
  deck_role_json,
  notes
FROM card_battle_rules
WHERE (normalized_name, logical_rule_key) IN (
  ('silent arbiter', 'battle_rule_v1:6f6089b73fb8f7f9aee20cacb64fffc7'),
  ('magus of the moat', 'battle_rule_v1:439de5be33887bbce5dde1cfb367774a'),
  ('ensnaring bridge', 'battle_rule_v1:1ea5840419f4343c05a661e79d6829d5')
)
ORDER BY normalized_name;
