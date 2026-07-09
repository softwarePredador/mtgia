WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('burst of strength', 'Burst of Strength', 'cfdf1d006ec4a004b932482218590cee', 'battle_rule_v1:085839334ad80f440ae0a12b576361d2', '{"battle_model_scope":"xmage_fixed_add_counters_and_untap_target_creature_spell_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"untap_target":true,"up_to_count":false,"xmage_effect_classes":["AddCountersTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"add_counters","subtype":"plus_one_counters","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BurstOfStrength translated into ManaLoom runtime scope xmage_fixed_add_counters_and_untap_target_creature_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds fixed counters to one target creature and untaps it with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dragonscale boon', 'Dragonscale Boon', '75254a881f708d93984214d32480bb31', 'battle_rule_v1:8cb1a93aad935ca2838cbc890bdd2343', '{"battle_model_scope":"xmage_fixed_add_counters_and_untap_target_creature_spell_v1","count":2,"counter_count":2,"counter_type":"+1/+1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"untap_target":true,"up_to_count":false,"xmage_effect_classes":["AddCountersTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"add_counters","subtype":"plus_one_counters","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DragonscaleBoon translated into ManaLoom runtime scope xmage_fixed_add_counters_and_untap_target_creature_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds fixed counters to one target creature and untaps it with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg697_add_counters_untap_target_new_serv_20260709_065617) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
