WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('staff of the death magus', 'Staff of the Death Magus', '6e3e892396a3eccf623fb24278ef0e77', 'battle_rule_v1:b43661ecacee1b78222d4666ca0668f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Swamp"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["B"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheDeathMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('staff of the flame magus', 'Staff of the Flame Magus', '740022ae19fce6083641bf3e53006bd8', 'battle_rule_v1:2899ce7517b2a1bf50b0c3a3d2e430b8', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Mountain"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheFlameMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('staff of the mind magus', 'Staff of the Mind Magus', '8c37616774b35da378bfce71bb3102f8', 'battle_rule_v1:550da3321ec860395b2f273063ac205f', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Island"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["U"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheMindMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('staff of the sun magus', 'Staff of the Sun Magus', '94b91159d89bea64aa7cb60274e6d5ee', 'battle_rule_v1:9e125d88232f6a6fcfba20431bd38b54', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Plains"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["W"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheSunMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('staff of the wild magus', 'Staff of the Wild Magus', '553a03ca3ee9c8d2a734232e75356ee4', 'battle_rule_v1:c6cfa36d344f737192ba4b06fe8001f1', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","land_enter_gain_life":true,"land_enter_gain_life_amount":1,"land_enter_gain_life_subtypes":["Forest"],"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["G"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"OrTriggeredAbility","xmage_ability_classes":["EntersBattlefieldControlledTriggeredAbility","OrTriggeredAbility","SpellCastControllerTriggeredAbility"],"xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StaffOfTheWildMagus translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
