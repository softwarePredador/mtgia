WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('borne upon a wind', 'Borne Upon a Wind', '98781dc70ac6e93dcf8ca5c63fce075d', 'battle_rule_v1:ff4327093d44df534a0f3aba335e124d', '{"ability_kind":"one_shot","battle_model_scope":"draw_one_and_source_controller_spells_gain_flash_until_eot_v1","count":1,"effect":"draw_cards","instant":true,"source_controller_spells_have_flash_until_eot":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BorneUponAWind mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('red elemental blast', 'Red Elemental Blast', 'ea84473287e1d30863243dcebf80a012', 'battle_rule_v1:7d7328f000cbeb639e2816886a1eb6c4', '{"ability_kind":"one_shot","battle_model_scope":"counter_target_blue_spell_or_destroy_target_blue_permanent_v1","counter_target_blue_spell":true,"destroy_target_blue_permanent":true,"effect":"modal_spell","instant":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RedElementalBlast mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('consecrated sphinx', 'Consecrated Sphinx', 'a241f637a4819314371b3a7c36d8f6ce', 'battle_rule_v1:17b32b3c6d4d9bca3e737793e4c72218', '{"ability_kind":"triggered","battle_model_scope":"flying_may_draw_two_when_opponent_draws_card_v1","effect":"creature","flying":true,"opponent_draws_card_may_draw":2,"power":4,"toughness":6}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ConsecratedSphinx mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('cyclonic rift', 'Cyclonic Rift', '581d2a5939d6cbf464ecd85a7495604e', 'battle_rule_v1:a477e4ac3fa3dc3fd4429fa8ac2d7939', '{"ability_kind":"one_shot","battle_model_scope":"return_target_nonland_permanent_you_dont_control_or_overload_all_opponents_nonlands_v1","effect":"bounce","instant":true,"overload_bounces_each_nonland_permanent_you_dont_control":true,"overload_cost":"{6}{U}","target":"nonland_permanent_you_dont_control"}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CyclonicRift mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('soul-guide lantern', 'Soul-Guide Lantern', '6a9e4cf9a4397715ccd0737e1b8cf270', 'battle_rule_v1:720260c93bdae63518a0721df51089c3', '{"ability_kind":"triggered","activated_generic_one_tap_sacrifice_draw":1,"activated_tap_sacrifice_exile_each_opponents_graveyard":true,"battle_model_scope":"etb_exile_graveyard_card_or_sacrifice_for_mass_graveyard_exile_or_draw_v1","effect":"artifact","etb_exile_target_card_from_graveyard":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SoulGuideLantern mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg128_current_replay_exact_scope_runtime_restore_2026062) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
