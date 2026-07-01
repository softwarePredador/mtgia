WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('battlegrowth', 'Battlegrowth', 'd74d53451d59e6a2c4eb906c03981054', 'battle_rule_v1:45bd50b433b58cf44d2dab3030945c4a', '{"battle_model_scope":"xmage_fixed_add_counters_target_creature_spell_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"support","effect":"add_counters","subtype":"plus_one_counters","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Battlegrowth translated into ManaLoom runtime scope xmage_fixed_add_counters_target_creature_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blight rot', 'Blight Rot', 'f6b9e8b446c30f40c90aca935f88d4e6', 'battle_rule_v1:384af23b01a4c11b57e6155b3a252e34', '{"battle_model_scope":"xmage_fixed_add_counters_target_creature_spell_v1","count":4,"counter_count":4,"counter_type":"-1/-1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"removal","effect":"add_counters","subtype":"negative_counters","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlightRot translated into ManaLoom runtime scope xmage_fixed_add_counters_target_creature_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scar', 'Scar', '53c8b48a1b03617cb95fe3dadb7b508e', 'battle_rule_v1:eed840032344df0fc06d337052c1dae7', '{"battle_model_scope":"xmage_fixed_add_counters_target_creature_spell_v1","count":1,"counter_count":1,"counter_type":"-1/-1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"removal","effect":"add_counters","subtype":"negative_counters","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Scar translated into ManaLoom runtime scope xmage_fixed_add_counters_target_creature_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg290_xmage_add_counters_spell_wave_20260701_090340) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
