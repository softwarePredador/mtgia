WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dwell on the past', 'Dwell on the Past', '56186be506e23ca8577f2631a950f7ca', 'battle_rule_v1:c8d07ae1642f1792017f5037a500f23d', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":4,"destination":"library_shuffle","effect":"recursion","instant":false,"library_controller":"target_player","sorcery":true,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DwellOnThePast translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('krosan reclamation', 'Krosan Reclamation', 'bce73a05bed813794d698fe9623dc47c', 'battle_rule_v1:96e29173e026d208c085eba9c46eeb90', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":2,"destination":"library_shuffle","effect":"recursion","flashback_cost":"{1}{G}","flashback_status":"runtime_executor_v1","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KrosanReclamation translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('memory''s journey', 'Memory''s Journey', '6c9de0cfefccac64e5774ae0c6510a59', 'battle_rule_v1:50505be06d0d57f05f3dadbfbe32fd43', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":3,"destination":"library_shuffle","effect":"recursion","flashback_cost":"{G}","flashback_status":"runtime_executor_v1","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MemorysJourney translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stream of consciousness', 'Stream of Consciousness', '56186be506e23ca8577f2631a950f7ca', 'battle_rule_v1:8ead478fb37e561206c410fdf144df3a', '{"battle_model_scope":"xmage_put_target_graveyard_card_on_library_spell_v1","count":4,"destination":"library_shuffle","effect":"recursion","instant":true,"library_controller":"target_player","sorcery":false,"target":"any_card","target_constraints":{"controller":"target_player","scope":"any_card","zone":"graveyard"},"target_controller":"target_player","target_graveyard_controller":"target_player","up_to_count":true,"xmage_effect_class":"TargetPlayerShufflesTargetCardsEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StreamOfConsciousness translated into ManaLoom runtime scope xmage_put_target_graveyard_card_on_library_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg352_xmage_graveyard_shuffle_to_library_spell_wave_2026) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
