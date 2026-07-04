WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cyclops electromancer', 'Cyclops Electromancer', '6fa0a410670c7cae1dbe5a9aa56cc129', 'battle_rule_v1:38b4656bd20b7355310d44e4580bc6cc', '{"ability_kind":"triggered","amount":0,"battle_model_scope":"xmage_creature_etb_dynamic_graveyard_count_damage_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"creature","etb_damage_target":"creature","etb_dynamic_damage":true,"graveyard_count_card_types":["instant","sorcery"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CyclopsElectromancer translated into ManaLoom runtime scope xmage_creature_etb_dynamic_graveyard_count_damage_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic graveyard-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lotleth giant', 'Lotleth Giant', '87bb35781c7f441f3b92bd3ddd1332e5', 'battle_rule_v1:7a8697df610f35c9f5af7d1a0babeba2', '{"ability_kind":"triggered","amount":0,"battle_model_scope":"xmage_creature_etb_dynamic_graveyard_count_damage_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"creature","etb_damage_target":"opponent","etb_dynamic_damage":true,"graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":false,"target":"opponent","target_constraints":{"scope":"opponent"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"opponent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LotlethGiant translated into ManaLoom runtime scope xmage_creature_etb_dynamic_graveyard_count_damage_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic graveyard-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ossuary rats', 'Ossuary Rats', 'efc330b3c7dad6d9bed7b84b60761592', 'battle_rule_v1:3c3475330943e9542421f2d7baafa684', '{"ability_kind":"triggered","amount":0,"battle_model_scope":"xmage_creature_etb_dynamic_graveyard_count_damage_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"creature","etb_damage_target":"creature_or_planeswalker","etb_dynamic_damage":true,"graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"],"controller":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OssuaryRats translated into ManaLoom runtime scope xmage_creature_etb_dynamic_graveyard_count_damage_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic graveyard-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warfire javelineer', 'Warfire Javelineer', '6fa0a410670c7cae1dbe5a9aa56cc129', 'battle_rule_v1:38b4656bd20b7355310d44e4580bc6cc', '{"ability_kind":"triggered","amount":0,"battle_model_scope":"xmage_creature_etb_dynamic_graveyard_count_damage_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"creature","etb_damage_target":"creature","etb_dynamic_damage":true,"graveyard_count_card_types":["instant","sorcery"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarfireJavelineer translated into ManaLoom runtime scope xmage_creature_etb_dynamic_graveyard_count_damage_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic graveyard-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg412_etb_graveyard_count_damage_new_server_20260704_154) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
