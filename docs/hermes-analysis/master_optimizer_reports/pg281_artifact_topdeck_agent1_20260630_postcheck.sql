WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('leyline dowser', 'Leyline Dowser', '763c7f1b28df8d4a0cd0957cecb52929', 'battle_rule_v1:c8c65b5b5f3bb5683f8b944f864284ac', '{"ability_kind":"activated","activated_self_mill_count":1,"activation_cost_generic":1,"activation_requires_tap":true,"battle_model_scope":"pay_one_tap_mill_one_instant_sorcery_to_hand_tap_legendary_creature_to_untap_v1","effect":"passive","graveyard_to_hand_target":"milled_instant_or_sorcery_this_way","mill_count":1,"milled_card_types_to_hand":["instant","sorcery"],"permanent_type":"artifact","secondary_untap_source_by_tapping_legendary_creature":true,"self_mill_activation_requires_tap":true,"target_constraints":{"card_types":["creature"],"controller_scope":"source_controller"}}'::jsonb, '{"category":"recursion","effect":"recursion","subtype":"mill_one_spell_to_hand_utility_artifact","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LeylineDowser mapped to family recursion; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('orcish spy', 'Orcish Spy', '3db8959a9384e0c35d17fe89ad50d2da', 'battle_rule_v1:fb3a5267bf97f7634af6f31db2316382', '{"ability_kind":"activated","activation_requires_tap":true,"alternate_zone_permission":false,"battle_model_scope":"tap_look_top_three_target_player_library_v1","effect":"topdeck_play","look_target_player_library_top_count":3,"may_cast_without_paying_mana_cost":false,"play_lands_from_top_library":false,"power":1,"target_constraints":{"target":"player"},"toughness":1}'::jsonb, '{"category":"ramp","effect":"topdeck_play","subtype":"play_lands_from_library","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class OrcishSpy mapped to family topdeck_play; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('prototype portal', 'Prototype Portal', '14a3433526473af8426745e64f3ad35a', 'battle_rule_v1:60d4479197c6e201840dd9a929ea5945', '{"ability_kind":"triggered_and_activated","activated_create_token_copy_of_imprinted_card":true,"activation_requires_tap":true,"activation_x_cost_source":"imprinted_card_mana_value","battle_model_scope":"imprint_artifact_from_hand_create_token_copy_x_mana_value_v1","effect":"passive","imprint_artifact_card_from_hand_on_enter":true,"permanent_type":"artifact","token_copy_source":"imprinted_card"}'::jsonb, '{"category":"payoff","effect":"token_maker","subtype":"artifact_imprint_copy_token","timing":"triggered_and_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PrototypePortal mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('pyxis of pandemonium', 'Pyxis of Pandemonium', '2cb0261a10477dc1aa31d444646d248f', 'battle_rule_v1:b232f0d7c82204280509251715881187', '{"ability_kind":"activated","activated_each_player_exile_top_face_down":true,"activated_put_exiled_permanents_onto_battlefield":true,"activation_requires_tap":true,"alternate_zone_permission":true,"battle_model_scope":"tap_each_player_exile_top_face_down_seven_tap_sacrifice_put_exiled_permanents_onto_battlefield_v1","effect":"passive","final_activation_cost_generic":7,"final_activation_requires_sacrifice":true,"may_cast_without_paying_mana_cost":false,"permanent_type":"artifact","put_permanent_cards_from_exile_onto_battlefield":true}'::jsonb, '{"category":"combo_value","effect":"free_cast","subtype":"source_exile_then_put_permanents_onto_battlefield","timing":"activated_alternate_zone_permission"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PyxisOfPandemonium mapped to family free_cast; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg281_artifact_topdeck_agent1_20260630_20260630_133609) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
