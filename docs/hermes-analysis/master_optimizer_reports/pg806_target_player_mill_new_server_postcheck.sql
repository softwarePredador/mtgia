WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('glimpse the unthinkable', 'Glimpse the Unthinkable', 'e16b3be95a08354fc076ff23a883f997', 'battle_rule_v1:26e090742b0b13e87d1f9bf6fc965891', '{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","count":10,"effect":"mill_cards","instant":false,"mill_count":10,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"wincon","effect":"mill_cards","subtype":"library_mill","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GlimpseTheUnthinkable translated into ManaLoom runtime scope xmage_fixed_target_player_mill_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-player mill spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mind sculpt', 'Mind Sculpt', 'f42f6fc25a0f27270644bb87317e60ce', 'battle_rule_v1:88cc251a233283c4f9a4337283de4c3a', '{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","count":7,"effect":"mill_cards","instant":false,"mill_count":7,"sorcery":true,"target":"player","target_constraints":{"players":["opponent"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"opponent","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"wincon","effect":"mill_cards","subtype":"library_mill","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MindSculpt translated into ManaLoom runtime scope xmage_fixed_target_player_mill_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-player mill spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tome scour', 'Tome Scour', 'abf0b04f9971161f7dfaf8449ebbdc8f', 'battle_rule_v1:38770bcda919ef9e031373d431e6297d', '{"battle_model_scope":"xmage_fixed_target_player_mill_spell_v1","count":5,"effect":"mill_cards","instant":false,"mill_count":5,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_mill":true,"target_player_scope":"any","target_preference":"opponent","xmage_effect_class":"MillCardsTargetEffect"}'::jsonb, '{"category":"wincon","effect":"mill_cards","subtype":"library_mill","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TomeScour translated into ManaLoom runtime scope xmage_fixed_target_player_mill_spell_v1. This row is package-ready only because the source signature is a narrow fixed target-player mill spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg806_target_player_mill_new_server_targ_20260712_044819) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
