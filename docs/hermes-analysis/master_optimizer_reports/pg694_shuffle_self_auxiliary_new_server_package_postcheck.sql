WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('beacon of destruction', 'Beacon of Destruction', 'ccee105fb1a174dd458dc5445c13863e', 'battle_rule_v1:a2ba8528866f24704935c9079b2fcf65', '{"amount":5,"battle_model_scope":"xmage_fixed_damage_target_spell_v1","damage":5,"effect":"direct_damage","instant":true,"shuffle_self_into_library_on_resolution":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect","xmage_effect_classes":["DamageTargetEffect","ShuffleSpellEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BeaconOfDestruction translated into ManaLoom runtime scope xmage_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blue sun''s zenith', 'Blue Sun''s Zenith', '685bbca229b4aabf8066c96993d3d57a', 'battle_rule_v1:483edcf8cc35ac61fccbb9b90c7b3be0', '{"battle_model_scope":"xmage_fixed_target_player_draw_spell_v1","count":0,"draw_count":0,"draw_count_source":"x_value","effect":"draw_cards","instant":true,"shuffle_self_into_library_on_resolution":true,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_player_draw":true,"target_preference":"self","xmage_effect_class":"DrawCardTargetEffect","xmage_effect_classes":["DrawCardTargetEffect","ShuffleSpellEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlueSunsZenith translated into ManaLoom runtime scope xmage_fixed_target_player_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg694_shuffle_self_auxiliary_new_server_20260709_060255) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
