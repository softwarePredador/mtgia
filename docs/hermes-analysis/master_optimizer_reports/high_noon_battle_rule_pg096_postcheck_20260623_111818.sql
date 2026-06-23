SELECT
  COUNT(*) FILTER (WHERE lower(c.name) = 'high noon') AS card_rows,
  COUNT(*) FILTER (
    WHERE lower(c.name) = 'high noon'
      AND md5(coalesce(c.oracle_text, '')) = 'dfec584c3cfdf4eb34b8a1e1d4f7da3a'
  ) AS expected_oracle_hash_rows,
  COUNT(*) FILTER (
    WHERE cbr.normalized_name = 'high noon'
      AND cbr.logical_rule_key = 'battle_rule_v1:fca6c4be65cae378901514ff6c8417d1'
      AND cbr.review_status = 'verified'
      AND cbr.execution_status = 'auto'
      AND cbr.source = 'curated'
      AND cbr.oracle_hash = 'dfec584c3cfdf4eb34b8a1e1d4f7da3a'
      AND cbr.effect_json->>'effect' = 'passive'
      AND cbr.effect_json->>'ability_kind' = 'static'
      AND cbr.effect_json->>'battle_model_scope' = 'high_noon_one_spell_per_turn_static_activated_five_damage_annotation_v1'
  ) AS exact_pg096_rule_rows,
  COUNT(*) FILTER (
    WHERE cbr.normalized_name = 'high noon'
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
      AND cbr.effect_json->>'effect' = 'remove_creature'
  ) AS trusted_executable_false_removal_rows,
  COUNT(*) FILTER (
    WHERE cbr.normalized_name = 'high noon'
      AND cbr.review_status IN ('verified', 'active')
      AND cbr.execution_status IN ('auto', 'executable')
      AND coalesce(cbr.oracle_hash, '') = ''
  ) AS trusted_executable_without_oracle_hash_rows,
  COUNT(*) FILTER (
    WHERE cbr.normalized_name = 'high noon'
      AND cbr.review_status = 'deprecated'
      AND cbr.execution_status = 'disabled'
      AND cbr.effect_json->>'effect' = 'remove_creature'
  ) AS deprecated_false_removal_rows
FROM cards c
LEFT JOIN card_battle_rules cbr
  ON cbr.card_id = c.id
WHERE lower(c.name) = 'high noon';
