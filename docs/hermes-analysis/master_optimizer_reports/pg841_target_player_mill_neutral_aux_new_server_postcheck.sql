WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('compelling argument', 'Compelling Argument', '82a9f5a1f8315892f0960af7b59f63e6', 'battle_rule_v1:38770bcda919ef9e031373d431e6297d', '{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","count":5,"effect":"mill_cards","instant":false,"mill_count":5,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"wincon","effect":"mill_cards","subtype":"library_mill","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CompellingArgument translated into ManaLoom runtime scope xmage_fixed_target_player_mill_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-player mill spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dream twist', 'Dream Twist', 'ed85794e26652c5d6dea1a8233573b90', 'battle_rule_v1:02e8f20591b2756e23be238f8b32cd03', '{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","count":3,"effect":"mill_cards","instant":true,"mill_count":3,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"wincon","effect":"mill_cards","subtype":"library_mill","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DreamTwist translated into ManaLoom runtime scope xmage_fixed_target_player_mill_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-player mill spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg841_target_player_mill_neutral_aux_new_20260712_194543) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
