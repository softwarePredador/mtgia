WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('archdruid''s charm', 'Archdruid''s Charm', 'c4df44104e459fecc46e4cb91708c4cd', 'battle_rule_v1:8737c73f1ba15aa4c12ddd7ed2fe2864', '{"ability_kind":"one_shot","battle_model_scope":"search_creature_or_land_or_counter_fight_or_exile_artifact_enchantment_v1","effect":"modal_spell","instant":true,"mode_exile_target_artifact_or_enchantment":true,"mode_put_plus_one_counter_on_controlled_creature_then_fight":true,"mode_search_creature_or_land_reveal_put_land_battlefield_tapped_else_hand":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ArchdruidsCharm mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sink into stupor', 'Sink into Stupor', 'aa830204ff7fdbc43fd5b4b84b30ede1', 'battle_rule_v1:4055b69675e84cc871d1b5d1268ac119', '{"ability_kind":"one_shot","battle_model_scope":"return_target_spell_or_opponent_nonland_permanent_or_tapped_blue_land_v1","effect":"bounce","instant":true,"land_side_add_mana":"U","land_side_pay_three_life_else_tapped":true,"target":"spell_or_opponent_nonland_permanent"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SinkIntoStupor mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('ruthless technomancer', 'Ruthless Technomancer', '0723f53d95b32cfc0e68da4f2fb9552e', 'battle_rule_v1:90563f719a1a22cb76142cf78207bc25', '{"ability_kind":"triggered","activated_cost":"{2}{B}","activated_sacrifice_x_artifacts_return_creature_with_power_x_or_less":true,"battle_model_scope":"etb_sacrifice_another_creature_create_treasures_and_x_artifact_reanimate_v1","effect":"creature","etb_may_sacrifice_another_creature_create_treasures_equal_power":true,"power":2,"toughness":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RuthlessTechnomancer mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('emperor of bones', 'Emperor of Bones', 'c38cbc86cb985c9ee97265b67e59bb42', 'battle_rule_v1:be03995844cb037cb44bce18d4f06bc4', '{"ability_kind":"triggered","adapt_cost":"{1}{B}","adapt_counters":2,"battle_model_scope":"combat_exile_adapt_finality_reanimate_v1","beginning_of_combat_exile_up_to_one_card_from_graveyard":true,"counters_trigger_reanimate_exiled_creature_with_finality_haste_and_sacrifice_eot":true,"effect":"creature","power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class EmperorOfBones mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('disciple of freyalise', 'Disciple of Freyalise', '3fb90a15cdcaba88791217be1f8cdaff', 'battle_rule_v1:050c819a19a33f85e0bceaac645fa7ba', '{"ability_kind":"triggered","battle_model_scope":"etb_sacrifice_another_creature_gain_draw_power_or_tapped_green_land_v1","effect":"creature","etb_may_sacrifice_another_creature_gain_life_and_draw_equal_power":true,"land_side_add_mana":"G","land_side_pay_three_life_else_tapped":true,"power":3,"toughness":3}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DiscipleOfFreyalise mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('vibrance', 'Vibrance', '9f9398d4a93c0733a5ac19a0c9e50dd3', 'battle_rule_v1:d6ec311db4082874f2ec217353e116b4', '{"ability_kind":"triggered","battle_model_scope":"evoke_etb_red_damage_or_green_land_tutor_lifegain_v1","effect":"creature","etb_if_green_green_spent_gain_life":2,"etb_if_green_green_spent_search_land_to_hand":true,"etb_if_red_red_spent_damage_any_target":3,"evoke_cost":"{R/G}{R/G}","power":4,"toughness":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Vibrance mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg134_current_replay_exact_scope_batch_two_20260624_0113) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
