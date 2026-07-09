WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('gird for battle', 'Gird for Battle', '3ec3205f9c7582e0e521c48d34632663', 'battle_rule_v1:370f47a81ed9d92f11b41968a8cbe6cf', '{"battle_model_scope":"xmage_fixed_add_counters_target_creatures_spell_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"support","effect":"add_counters","subtype":"plus_one_counters","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GirdForBattle translated into ManaLoom runtime scope xmage_fixed_add_counters_target_creatures_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds fixed counters to exact target creatures with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leo''s guidance', 'Leo''s Guidance', 'f38609e8728ba9dc858053e333269d1d', 'battle_rule_v1:1a72396e764ce4abd22f1d1d569031f8', '{"battle_model_scope":"xmage_fixed_add_counters_and_untap_target_creatures_spell_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":3,"target_count_max":3,"target_count_min":0,"untap_target":true,"up_to_count":true,"xmage_effect_classes":["AddCountersTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"add_counters","subtype":"plus_one_counters","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeosGuidance translated into ManaLoom runtime scope xmage_fixed_add_counters_and_untap_target_creatures_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds fixed counters to exact target creatures and untaps them with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reap what is sown', 'Reap What Is Sown', 'f3e88f23e30bfabb3b2da14d43b3a47e', 'battle_rule_v1:34ad232119cc27683aabda01ee0aaecf', '{"battle_model_scope":"xmage_fixed_add_counters_target_creatures_spell_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":3,"target_count_max":3,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"support","effect":"add_counters","subtype":"plus_one_counters","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReapWhatIsSown translated into ManaLoom runtime scope xmage_fixed_add_counters_target_creatures_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds fixed counters to exact target creatures with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg698_add_counters_multi_target_new_serv_20260709_071744) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
