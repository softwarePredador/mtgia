WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('gilded lotus', 'Gilded Lotus', '0d906313802b1626dbd3dc7c6aef19e1', 'battle_rule_v1:1ac9d243b6a4766165275d94ba06bd4b', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":3,"permanent_type":"artifact","produces":"WUBRG","xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GildedLotus translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('somberwald sage', 'Somberwald Sage', '7d9a6d1c55c528e06461984024a21eb7', 'battle_rule_v1:4027d7cc89c26ddd34ac2802c0366134', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_restricted_mana_source_permanent_v1","conditional_mana_modes":[{"color":"W","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"U","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"B","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"R","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"},{"color":"G","mode":"restricted_spell_mana","restriction":"creature_spell","status":"runtime_executor_v1"}],"conditional_mana_modes_status":"runtime_executor_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":3,"permanent_type":"creature","produces":"WUBRG","xmage_ability_classes":["ConditionalAnyColorManaAbility"],"xmage_effect_classes":[],"xmage_mana_ability_classes":["ConditionalAnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SomberwaldSage translated into ManaLoom runtime scope xmage_simple_tap_restricted_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('transdimensional bovine', 'Transdimensional Bovine', 'a704b7c8f7bcf20b5d31300f1d6c18bb', 'battle_rule_v1:ee41e6719a2daf68b63b2c627e0ae39a', '{"activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"keywords":["flying"],"mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"creature","produces":"WUBRG","xmage_effect_classes":["AddManaOfAnyColorEffect"],"xmage_mana_ability_classes":["FlyingAbility","SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TransdimensionalBovine translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg747_multi_any_color_mana_source_new_se_20260711_071909) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
