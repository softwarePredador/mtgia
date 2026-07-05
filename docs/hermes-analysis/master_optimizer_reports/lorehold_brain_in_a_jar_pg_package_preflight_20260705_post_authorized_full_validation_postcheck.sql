WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('brain in a jar', 'Brain in a Jar', '41468898bf6400763de517269fdeb456', 'battle_rule_v1:aedfa4929249f55c1d607effe109f3f3', '{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"charge","activated_add_counters_target":"self","activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_tap":true,"additional_costs_policy":"runtime_followup_required_for_nontrivial_additional_costs","alternative_costs_payable":false,"battle_model_scope":"xmage_brain_in_a_jar_charge_counter_free_cast_scry_v1","brain_in_a_jar_free_cast":true,"cast_without_paying_mana_cost":true,"effect":"topdeck_manipulation","free_cast_card_types":["instant","sorcery"],"free_cast_exactly_one_card":true,"free_cast_from_zone":"hand","free_cast_mana_value_match":"source_charge_counters_after_add","free_cast_max_cards":1,"free_cast_optional":true,"free_cast_timing":"during_brain_in_a_jar_ability_resolution","replay_required_fields":["activation_kind","charge_counters_before","charge_counters_after","eligible_spell_names","selected_spell","selected_spell_mana_value","cast_without_paying_mana_cost","removed_charge_counters","scry_count","scry_looked_at","scry_kept_on_top","scry_bottomed","scry_top_after"],"secondary_activation_cost_generic":3,"secondary_activation_cost_mana":"{3}","secondary_activation_remove_counter_type":"charge","secondary_activation_remove_x_counters":true,"secondary_activation_requires_tap":true,"secondary_activation_scry_count_source":"removed_charge_counters","source_card":"Brain in a Jar","x_value_default_when_cast_without_paying_mana_cost":0,"xmage_cost_classes":["GenericManaCost","TapSourceCost","RemoveVariableCountersSourceCost"],"xmage_effect_classes":["AddCountersSourceEffect","BrainInAJarCastEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"topdeck_manipulation","lane":"topdeck_miracle_engine","package":"topdeck_miracle_access"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'Brain in a Jar exact runtime package: local XMage class plus ManaLoom adapter for add charge counter, exact mana-value free-cast from hand, and remove X charge counters to scry X. Package is prepared only; apply requires explicit PostgreSQL approval.', 'preserve_existing_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status,
    r.effect_json,
    r.rule_version
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  p.effect_json->>'battle_model_scope' AS expected_scope,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  count(r.*) FILTER (WHERE r.effect_json->>'battle_model_scope' = p.effect_json->>'battle_model_scope') AS promoted_scope_rows,
  count(r.*) FILTER (WHERE (r.effect_json->>'brain_in_a_jar_free_cast')::boolean IS TRUE) AS promoted_brain_free_cast_rows,
  count(r.*) FILTER (WHERE r.rule_version >= 2) AS promoted_rule_version_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.lorehold_brain_in_a_jar_pg_package_20260705_post_authorized_full_validation_backup) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash, expected_scope
ORDER BY p.card_name;
