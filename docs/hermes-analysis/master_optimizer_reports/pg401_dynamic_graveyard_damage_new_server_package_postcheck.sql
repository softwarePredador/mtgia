WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('galvanic bombardment', 'Galvanic Bombardment', 'a63030de85a8efbe5d5cfb5812aacad0', 'battle_rule_v1:01661b56bea5a3130cd2584b41e60ad2', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Galvanic Bombardment"],"graveyard_count_scope":"controller_graveyard","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GalvanicBombardment translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ire of kaminari', 'Ire of Kaminari', '7a164fc97eec2cf77b86d03b602ac26c', 'battle_rule_v1:14bbef0a7472d0051f179a1f39198391', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_scope":"controller_graveyard","graveyard_count_subtypes":["arcane"],"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IreOfKaminari translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kindle', 'Kindle', 'daa81fd00aeae9e0b48d50f284a4f46f', 'battle_rule_v1:a9db350295df3f3a11a1a18a541cd671', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Kindle"],"graveyard_count_scope":"all_graveyards","instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kindle translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scrapyard salvo', 'Scrapyard Salvo', '65339ed7621226246a5b84a9f684b333', 'battle_rule_v1:75b7f7990c05194d68d794d77aade7d6', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_types":["artifact"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrapyardSalvo translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg401_dynamic_graveyard_damage_new_server_20260704_11040) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
