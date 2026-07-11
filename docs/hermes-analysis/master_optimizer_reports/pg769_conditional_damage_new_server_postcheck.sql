WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('brimstone volley', 'Brimstone Volley', '02f000051d4db8a3d84b433567e89144', 'battle_rule_v1:7868b204951be252cf4635a66bd5f57e', '{"amount":3,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":5,"conditional_damage_base_amount":3,"conditional_damage_condition":"creature_died_this_turn","damage":3,"effect":"direct_damage","instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BrimstoneVolley translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cackling flames', 'Cackling Flames', '3440d07184666beefdc0a9831dd13f42', 'battle_rule_v1:6e3f08546bdf0fa9f9b019e74a204440', '{"amount":3,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":5,"conditional_damage_base_amount":3,"conditional_damage_condition":"controller_has_no_cards_in_hand","damage":3,"effect":"direct_damage","instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CacklingFlames translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('galvanic blast', 'Galvanic Blast', '2e22d198dc9c8c0717abc47e8d346b9e', 'battle_rule_v1:a078536486d9c8b999602fd911d25c1f', '{"amount":2,"battle_model_scope":"xmage_conditional_fixed_damage_target_spell_v1","conditional_damage_amount":4,"conditional_damage_artifact_threshold":3,"conditional_damage_base_amount":2,"conditional_damage_condition":"controlled_artifacts_gte","damage":2,"effect":"direct_damage","instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["ConditionalOneShotEffect","DamageTargetEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GalvanicBlast translated into ManaLoom runtime scope xmage_conditional_fixed_damage_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg769_conditional_damage_new_server_cond_20260711_151731) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
