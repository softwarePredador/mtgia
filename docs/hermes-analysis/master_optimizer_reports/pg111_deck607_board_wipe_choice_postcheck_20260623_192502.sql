WITH wanted(normalized_name, expected_hash, expected_rule_key, expected_effect, expected_scope) AS (
  VALUES
    (
      'promise of loyalty',
      '21dd715160fde6e50b8edc015ce83b0f',
      'battle_rule_v1:78fff8e218103b0710bc5ee9cf174ee9',
      'vow_counter_each_player_sacrifice_rest',
      'each_player_choose_creature_vow_counter_sacrifice_other_creatures_attack_restriction_v1'
    ),
    (
      'starfall invocation',
      '3429884949eac8ffe09d86dc85bee1ae',
      'battle_rule_v1:58cfb4628b4a4a879f6f9c5e0ab3ee5f',
      'gift_destroy_all_creatures_return_own_destroyed_creature',
      'gift_card_destroy_all_creatures_return_one_own_creature_destroyed_this_way_v1'
    ),
    (
      'tragic arrogance',
      'efdf5d051aaa7f94b12c4dccbbfd7d3d',
      'battle_rule_v1:d4d676e6ecea500f7aca4cbc7f7ae04a',
      'selective_nonland_sacrifice',
      'controller_chooses_artifact_creature_enchantment_planeswalker_per_player_sacrifice_other_nonlands_v1'
    )
),
target_rules AS (
  SELECT
    w.normalized_name,
    count(r.*) AS matching_target_rows,
    bool_and(r.review_status IN ('verified', 'active')) AS review_ok,
    bool_and(r.execution_status IN ('auto', 'executable')) AS execution_ok,
    bool_and(r.oracle_hash = w.expected_hash) AS hash_ok,
    bool_and(r.effect_json->>'effect' = w.expected_effect) AS effect_ok,
    bool_and(r.effect_json->>'battle_model_scope' = w.expected_scope) AS scope_ok
  FROM wanted w
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = w.normalized_name
   AND r.logical_rule_key = w.expected_rule_key
  GROUP BY w.normalized_name
),
shadow_rules AS (
  SELECT
    w.normalized_name,
    count(r.*) FILTER (
      WHERE r.logical_rule_key <> w.expected_rule_key
    ) AS shadow_rows,
    count(r.*) FILTER (
      WHERE r.logical_rule_key <> w.expected_rule_key
        AND r.review_status = 'deprecated'
        AND r.execution_status = 'disabled'
    ) AS disabled_shadow_rows
  FROM wanted w
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = w.normalized_name
  GROUP BY w.normalized_name
)
SELECT
  tr.normalized_name,
  tr.matching_target_rows,
  tr.review_ok,
  tr.execution_ok,
  tr.hash_ok,
  tr.effect_ok,
  tr.scope_ok,
  sr.shadow_rows,
  sr.disabled_shadow_rows
FROM target_rules tr
JOIN shadow_rules sr USING (normalized_name)
ORDER BY tr.normalized_name;

SELECT
  normalized_name,
  logical_rule_key,
  review_status,
  execution_status,
  rule_version,
  oracle_hash,
  effect_json,
  deck_role_json,
  reviewed_by
FROM public.card_battle_rules
WHERE normalized_name IN (
  'promise of loyalty',
  'starfall invocation',
  'tragic arrogance'
)
ORDER BY normalized_name, review_status, execution_status, logical_rule_key;
