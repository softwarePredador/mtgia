WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('forbidden alchemy', 'Forbidden Alchemy', '4800d22353040527a3f8a9ddaaa3529f', 'battle_rule_v1:e285a4ed5ba76a8a0a9def976a43b0a0', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":true,"look_count":4,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":false,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForbiddenAlchemy translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nagging thoughts', 'Nagging Thoughts', 'd750ade2afb400a96ed4d09a6de448ed', 'battle_rule_v1:0c0c6b5f5d6ac1b30757c2c3d4794c24', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":2,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NaggingThoughts translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('resentful revelation', 'Resentful Revelation', 'c0c873de2a6cb009f2bb3f0e304d6805', 'battle_rule_v1:818eec9a981f612634bc818b78997e22', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"any_card","pick_up_to_count":false,"rest_destination":"graveyard","reveal":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ResentfulRevelation translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tapping at the window', 'Tapping at the Window', 'c85b98ff679c3eac0187834661613f50', 'battle_rule_v1:f81c5a7e4a1474b2f585b16efca99840', '{"battle_model_scope":"xmage_look_library_pick_to_hand_rest_graveyard_spell_v1","count":1,"destination":"hand","effect":"dig_to_hand","instant":false,"look_count":3,"max_count":1,"pick_all_matching":false,"pick_count":1,"pick_target":"creature","pick_up_to_count":true,"rest_destination":"graveyard","reveal":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"library"},"xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"draw","effect":"dig_to_hand","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TappingAtTheWindow translated into ManaLoom runtime scope xmage_look_library_pick_to_hand_rest_graveyard_spell_v1. This row is package-ready only because the source signature is a narrow fixed look-at-library pick-to-hand spell with rest in graveyard with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg578_look_library_graveyard_new_server_20260706_225325) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
