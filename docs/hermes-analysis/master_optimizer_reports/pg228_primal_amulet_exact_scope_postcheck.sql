WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('primal amulet // primal wellspring', 'Primal Amulet // Primal Wellspring', 'e90d3ae05767c87dbd3b02c470af4827', 'battle_rule_v1:d05b887f76ae9cd5cee7c89045dc65cc', '{"ability_kind":"static","applies_to_card_types":["instant","sorcery"],"battle_model_scope":"artifact_instant_sorcery_cost_reduction_charge_transform_to_any_color_spell_copy_land_v1","cost_reduction_applies_to":"instant_sorcery_spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction","transform_counter_threshold":4,"transform_optional":true,"transform_remove_all_named_counters":true,"transform_to":{"battle_model_scope":"artifact_instant_sorcery_cost_reduction_charge_transform_to_any_color_spell_copy_land_v1","choose_new_targets_status":"may","copy_when_mana_spent_card_types":["instant","sorcery"],"copy_when_mana_spent_to_cast_matching_spell":true,"effect":"land","is_mana_source":true,"mana_produced":1,"may_choose_new_targets":true,"name":"Primal Wellspring","produces":"WUBRG","target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_when_mana_spent","type_line":"Land"},"trigger":"instant_sorcery_cast","trigger_counter_count":1,"trigger_counter_type":"charge","trigger_effect":"add_named_counter_then_transform"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PrimalAmulet mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
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
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg228_primal_amulet_exact_scope_20260626_061537) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
