WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('staff of the death magus', 'Staff of the Death Magus', '6e3e892396a3eccf623fb24278ef0e77', 'battle_rule_v1:b43661ecacee1b78222d4666ca0668f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Swamp"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["B"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheDeathMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('staff of the flame magus', 'Staff of the Flame Magus', '740022ae19fce6083641bf3e53006bd8', 'battle_rule_v1:2899ce7517b2a1bf50b0c3a3d2e430b8', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Mountain"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheFlameMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('staff of the mind magus', 'Staff of the Mind Magus', '8c37616774b35da378bfce71bb3102f8', 'battle_rule_v1:550da3321ec860395b2f273063ac205f', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Island"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["U"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheMindMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('staff of the sun magus', 'Staff of the Sun Magus', '94b91159d89bea64aa7cb60274e6d5ee', 'battle_rule_v1:9e125d88232f6a6fcfba20431bd38b54', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Plains"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["W"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheSunMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('staff of the wild magus', 'Staff of the Wild Magus', '553a03ca3ee9c8d2a734232e75356ee4', 'battle_rule_v1:c6cfa36d344f737192ba4b06fe8001f1', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Forest"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["G"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheWildMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg713_staff_spell_or_land_life_gain_new_20260710_181601) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
