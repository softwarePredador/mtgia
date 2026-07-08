WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('corrosive gale', 'Corrosive Gale', '24edc312cafba8795b9ba1e59a05e3a3', 'battle_rule_v1:25c7f4c9dbedefed9b078ce527a817e9', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"x_value","damage_scope":"each_flying_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorrosiveGale translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('savage twister', 'Savage Twister', 'a4af57e79ebe1298b95aa61a63682d77', 'battle_rule_v1:2e2b937faac8ce625a460a43e6324c90', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"x_value","damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SavageTwister translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('windstorm', 'Windstorm', 'a42ed8d7210a9f46cdfe575a29a2edaa', 'battle_rule_v1:7e7f11b920afc3ab4c85edd11c58c824', '{"amount":0,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":0,"damage_amount_source":"x_value","damage_scope":"each_flying_creature","effect":"damage_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Windstorm translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg652_x_damage_wipe_new_server_20260708_012434) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
