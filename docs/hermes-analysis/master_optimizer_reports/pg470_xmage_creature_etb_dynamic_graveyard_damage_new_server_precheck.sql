WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cyclops electromancer', 'Cyclops Electromancer', '6fa0a410670c7cae1dbe5a9aa56cc129', 'battle_rule_v1:38b4656bd20b7355310d44e4580bc6cc', '{"ability_kind":"triggered","amount":0,"battle_model_scope":"xmage_creature_etb_dynamic_graveyard_count_damage_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"creature","etb_damage_target":"creature","etb_dynamic_damage":true,"graveyard_count_card_types":["instant","sorcery"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CyclopsElectromancer translated into ManaLoom runtime scope xmage_creature_etb_dynamic_graveyard_count_damage_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic graveyard-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lotleth giant', 'Lotleth Giant', '87bb35781c7f441f3b92bd3ddd1332e5', 'battle_rule_v1:7a8697df610f35c9f5af7d1a0babeba2', '{"ability_kind":"triggered","amount":0,"battle_model_scope":"xmage_creature_etb_dynamic_graveyard_count_damage_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"creature","etb_damage_target":"opponent","etb_dynamic_damage":true,"graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":false,"target":"opponent","target_constraints":{"scope":"opponent"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"opponent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LotlethGiant translated into ManaLoom runtime scope xmage_creature_etb_dynamic_graveyard_count_damage_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic graveyard-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ossuary rats', 'Ossuary Rats', 'efc330b3c7dad6d9bed7b84b60761592', 'battle_rule_v1:3c3475330943e9542421f2d7baafa684', '{"ability_kind":"triggered","amount":0,"battle_model_scope":"xmage_creature_etb_dynamic_graveyard_count_damage_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"creature","etb_damage_target":"creature_or_planeswalker","etb_dynamic_damage":true,"graveyard_count_card_types":["creature"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":false,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"],"controller":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OssuaryRats translated into ManaLoom runtime scope xmage_creature_etb_dynamic_graveyard_count_damage_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic graveyard-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('warfire javelineer', 'Warfire Javelineer', '6fa0a410670c7cae1dbe5a9aa56cc129', 'battle_rule_v1:38b4656bd20b7355310d44e4580bc6cc', '{"ability_kind":"triggered","amount":0,"battle_model_scope":"xmage_creature_etb_dynamic_graveyard_count_damage_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"creature","etb_damage_target":"creature","etb_dynamic_damage":true,"graveyard_count_card_types":["instant","sorcery"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"opponent"},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WarfireJavelineer translated into ManaLoom runtime scope xmage_creature_etb_dynamic_graveyard_count_damage_v1. This row is package-ready only because the source signature is a narrow creature ETB dynamic graveyard-count damage trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
