WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('braingeyser', 'Braingeyser', '78e39da16151432bf4531a2564e131d7', 'battle_rule_v1:b2b961d83ba712e8f3f89286d992cae3', '{"battle_model_scope":"xmage_fixed_target_player_draw_spell_v1","count":0,"draw_count":0,"draw_count_source":"x_value","effect":"draw_cards","instant":false,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_draw":true,"target_preference":"self","xmage_effect_class":"DrawCardTargetEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Braingeyser translated into ManaLoom runtime scope xmage_fixed_target_player_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stroke of genius', 'Stroke of Genius', '78e39da16151432bf4531a2564e131d7', 'battle_rule_v1:eef4ebe872b6121026312deb1000fb46', '{"battle_model_scope":"xmage_fixed_target_player_draw_spell_v1","count":0,"draw_count":0,"draw_count_source":"x_value","effect":"draw_cards","instant":true,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_draw":true,"target_preference":"self","xmage_effect_class":"DrawCardTargetEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StrokeOfGenius translated into ManaLoom runtime scope xmage_fixed_target_player_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg693_target_player_x_draw_20260709_052610) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
