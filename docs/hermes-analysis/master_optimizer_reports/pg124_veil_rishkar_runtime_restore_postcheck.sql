WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('rishkar, peema renegade', 'Rishkar, Peema Renegade', 'f8292a28b5787943930f045618fcb8c9', 'battle_rule_v1:3e4f3afe97ce898401c128885bdf6fc3', '{"ability_kind":"triggered","battle_model_scope":"rishkar_counter_mana_creature_waiver_v1","countered_creatures_tap_for_mana":true,"effect":"creature","etb_plus_one_counter_targets":2,"power":2,"produces":"G","toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class RishkarPeemaRenegade mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('veil of summer', 'Veil of Summer', '2de390b3ac2c9680e9c3b8b5fe09d103', 'battle_rule_v1:345e8a0b063c6d805551bfb85618f0f6', '{"ability_kind":"one_shot","battle_model_scope":"veil_of_summer_draw_and_protection_waiver_v1","conditional_draw_if_opponent_cast_blue_or_black_spell_this_turn":true,"controller_and_permanents_hexproof_from_colors_until_eot":["U","B"],"count":1,"effect":"draw_cards","instant":true,"spells_you_control_cant_be_countered_this_turn":true}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VeilOfSummer mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg124_veil_rishkar_runtime_restore_20260623_234800) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
