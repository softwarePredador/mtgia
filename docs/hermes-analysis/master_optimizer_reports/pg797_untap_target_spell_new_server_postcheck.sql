WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('burst of energy', 'Burst of Energy', '88069268f224445e059a0a0aba2f5a82', 'battle_rule_v1:5233e85f30c26d13a9da6a9d2117387d', '{"battle_model_scope":"xmage_untap_target_spell_v1","duration":"immediate","effect":"stat_modifier_until_eot_untap_target","instant":true,"modifies_stats":false,"power_boost":0,"power_delta":0,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":0,"toughness_delta":0,"untap_target":true,"up_to_count":false,"xmage_effect_class":"UntapTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BurstOfEnergy translated into ManaLoom runtime scope xmage_untap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that untaps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg797_untap_target_spell_new_server_20260712_010534) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
