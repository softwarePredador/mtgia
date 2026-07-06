WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('elemental bond', 'Elemental Bond', '5a691f455e7c6bc07be2216acc17dd12', 'battle_rule_v1:bd1c61d07d0cfba06bd4b9cd2c8e3563', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"enchantment","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElementalBond translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('garruk''s packleader', 'Garruk''s Packleader', '75e46cdf177b60f8222c11dd2a23fe4a', 'battle_rule_v1:0f60b037ce53a92cb805467893c4b09b', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":true,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_power_min":3,"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GarruksPackleader translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mary jane watson', 'Mary Jane Watson', 'cf34165c6f4e6d223d5a808d08d31820', 'battle_rule_v1:cc844d8be9823c1e24a8a527104759b7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["spider"],"trigger_limit_each_turn":1,"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaryJaneWatson translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wirewood savage', 'Wirewood Savage', 'd9bea46f134c92b206b9825d99fd4536', 'battle_rule_v1:082b3870153de03b308b0b1845fac9a3', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"any","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":true,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WirewoodSavage translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woodland liege', 'Woodland Liege', 'b88741308258706f6b2a4bcc27621de9', 'battle_rule_v1:0b327e4ff0cfb5815d7d2b7cf7adea6d', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_enters_draw_trigger_v1","effect":"creature","trigger":"creature_you_control_enters","trigger_another_creature_enters":false,"trigger_controller_scope":"self","trigger_draw_count":1,"trigger_effect":"draw_cards","trigger_entering_card_types":["creature"],"trigger_entering_subtypes":["beast"],"trigger_optional":false,"xmage_ability_class":"EntersBattlefieldAllTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodlandLiege translated into ManaLoom runtime scope xmage_creature_enters_draw_trigger_v1. This row is package-ready only because the source signature is a narrow permanent trigger when a creature enters and controller draws cards with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg579_creature_enters_draw_new_server_20260706_231755) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
