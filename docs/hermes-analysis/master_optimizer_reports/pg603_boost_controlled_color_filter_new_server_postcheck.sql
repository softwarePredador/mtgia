WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('guardians'' pledge', 'Guardians'' Pledge', '7e8abb39dd94877bb29f3b5505330abd', 'battle_rule_v1:d498740178408798a7a7dd58d99cb5f5', '{"battle_model_scope":"xmage_fixed_boost_controlled_creatures_until_eot_spell_v1","creature_filter":{"colors":["W"]},"effect":"controlled_stat_modifier_until_eot","instant":true,"power_delta":2,"sorcery":false,"target":"controlled_w_creatures","target_constraints":{"card_types":["creature"],"controller":"self","creature_filter":{"colors":["W"]}},"target_controller":"self","toughness_delta":2,"xmage_effect_class":"BoostControlledEffect"}'::jsonb, '{"category":"unknown","effect":"controlled_stat_modifier_until_eot","target":"controlled_w_creatures","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardiansPledge translated into ManaLoom runtime scope xmage_fixed_boost_controlled_creatures_until_eot_spell_v1. This row is package-ready only because the source signature is a narrow fixed controlled-creature boost until end of turn spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg603_boost_controlled_color_filter_new_20260707_080717) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
