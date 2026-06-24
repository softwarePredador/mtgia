WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('wan shi tong, librarian', 'Wan Shi Tong, Librarian', 'cec9147cf2498a1c06969597acfea508', 'battle_rule_v1:c18481f9ac5f3681e11384c838d732c9', '{"ability_kind":"triggered","battle_model_scope":"flash_flying_vigilance_etb_x_counters_draw_half_x_opponent_search_growth_v1","effect":"creature","etb_add_x_plus_one_counters":true,"etb_draw_half_x_rounded_down":true,"flash":true,"flying":true,"opponent_search_library_add_counter_and_draw":true,"power":1,"toughness":1,"vigilance":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WanShiTongLibrarian mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('hullbreaker horror', 'Hullbreaker Horror', '8339fa3591d36c5d0460156fbf96d8fe', 'battle_rule_v1:e27cba51b13efd4db7efaebf7878b572', '{"ability_kind":"triggered","battle_model_scope":"flash_cant_be_countered_cast_spell_bounce_spell_or_nonland_v1","cant_be_countered":true,"cast_spell_trigger_bounce_nonland_permanent":true,"cast_spell_trigger_bounce_spell_you_dont_control":true,"effect":"creature","flash":true,"power":7,"toughness":8}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HullbreakerHorror mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('teferi, time raveler', 'Teferi, Time Raveler', '7c2d3586e1633bcaf4f26d7b01a6c266', 'battle_rule_v1:35ae547c02c12ce35e09945d4791f7ad', '{"ability_kind":"static","battle_model_scope":"opponents_sorcery_speed_only_plus1_sorcery_flash_minus3_bounce_draw_v1","effect":"planeswalker","minus_three_bounce_up_to_one_artifact_creature_or_enchantment_draw":1,"opponents_can_cast_only_as_sorcery":true,"plus_one_sorceries_have_flash_until_your_next_turn":true,"starting_loyalty":4}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TeferiTimeRaveler mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg131_current_replay_precision_scope_runtime_restore_202) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
