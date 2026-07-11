WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('mind shatter', 'Mind Shatter', '5ad00d59d9cc2d3aaf9398fbdbd48d40', 'battle_rule_v1:1b25f787ae9880c65de48da3519f68b8', '{"battle_model_scope":"xmage_dynamic_target_player_discard_spell_v1","count":0,"discard_count":0,"discard_count_source":"x_value","discard_random":true,"effect":"target_player_discard","instant":false,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_discard":true,"target_preference":"opponent","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"target_player_discard","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MindShatter translated into ManaLoom runtime scope xmage_dynamic_target_player_discard_spell_v1. This row is package-ready only because the source signature is a narrow dynamic target-player discard spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mind twist', 'Mind Twist', '5ad00d59d9cc2d3aaf9398fbdbd48d40', 'battle_rule_v1:1b25f787ae9880c65de48da3519f68b8', '{"battle_model_scope":"xmage_dynamic_target_player_discard_spell_v1","count":0,"discard_count":0,"discard_count_source":"x_value","discard_random":true,"effect":"target_player_discard","instant":false,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_discard":true,"target_preference":"opponent","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"target_player_discard","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MindTwist translated into ManaLoom runtime scope xmage_dynamic_target_player_discard_spell_v1. This row is package-ready only because the source signature is a narrow dynamic target-player discard spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('voices from the void', 'Voices from the Void', '1117d691447c76ad8e4026f5dc427ca9', 'battle_rule_v1:456abb2380ee9484953eed010e3e50cd', '{"battle_model_scope":"xmage_dynamic_target_player_discard_spell_v1","count":0,"discard_count":0,"discard_count_source":"domain_basic_land_types","discard_random":false,"effect":"target_player_discard","instant":false,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_discard":true,"target_preference":"opponent","xmage_effect_class":"DiscardTargetEffect"}'::jsonb, '{"category":"unknown","effect":"target_player_discard","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VoicesFromTheVoid translated into ManaLoom runtime scope xmage_dynamic_target_player_discard_spell_v1. This row is package-ready only because the source signature is a narrow dynamic target-player discard spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg775_dynamic_target_player_discard_new_20260711_170300) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
