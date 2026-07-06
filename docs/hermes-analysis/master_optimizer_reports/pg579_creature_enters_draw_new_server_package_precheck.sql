WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('elemental bond', 'Elemental Bond', '5a691f455e7c6bc07be2216acc17dd12', 'battle_rule_v1:bd1c61d07d0cfba06bd4b9cd2c8e3563', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"enchantment","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElementalBond translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('garruk''s packleader', 'Garruk''s Packleader', '75e46cdf177b60f8222c11dd2a23fe4a', 'battle_rule_v1:0f60b037ce53a92cb805467893c4b09b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GarruksPackleader translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mary jane watson', 'Mary Jane Watson', 'cf34165c6f4e6d223d5a808d08d31820', 'battle_rule_v1:cc844d8be9823c1e24a8a527104759b7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["spider"],"trigger_limit_each_turn":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaryJaneWatson translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wirewood savage', 'Wirewood Savage', 'd9bea46f134c92b206b9825d99fd4536', 'battle_rule_v1:082b3870153de03b308b0b1845fac9a3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"any","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WirewoodSavage translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woodland liege', 'Woodland Liege', 'b88741308258706f6b2a4bcc27621de9', 'battle_rule_v1:0b327e4ff0cfb5815d7d2b7cf7adea6d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodlandLiege translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
