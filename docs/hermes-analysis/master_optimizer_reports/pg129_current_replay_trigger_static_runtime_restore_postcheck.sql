WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('faerie mastermind', 'Faerie Mastermind', '92f520c17a15390fa0d0ea1b1272bc6c', 'battle_rule_v1:d71dbf6903f52abd4bfe443bab1dc0a9', '{"ability_kind":"triggered","activated_each_player_draw_cost":"{3}{U}","activated_each_player_draw_count":1,"battle_model_scope":"flash_flying_second_opponent_draw_draw_one_and_activated_each_player_draw_v1","effect":"creature","flash":true,"flying":true,"opponent_second_card_each_turn_draw":1,"power":2,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FaerieMastermind mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('vexing bauble', 'Vexing Bauble', '020e696ec9560830bb82bf0244595d69', 'battle_rule_v1:ad19691a7b388a47b6775f5e16275403', '{"ability_kind":"triggered","activated_generic_one_tap_sacrifice_draw":1,"battle_model_scope":"counter_no_mana_spent_spells_and_cantrip_sacrifice_v1","effect":"artifact","trigger_counter_spell_if_no_mana_was_spent":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VexingBauble mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('nezahal, primal tide', 'Nezahal, Primal Tide', '64ff656e777df4caae96816eccf5a387', 'battle_rule_v1:7b908a525415c4da327930f6d4b29aba', '{"ability_kind":"triggered","activated_discard_cards_to_exile_and_return_tapped_count":3,"battle_model_scope":"cant_be_countered_no_max_hand_opponent_noncreature_cast_draw_exile_blink_v1","cant_be_countered":true,"effect":"creature","no_maximum_hand_size":true,"opponent_casts_noncreature_draw":1,"power":7,"toughness":7}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class NezahalPrimalTide mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg129_current_replay_trigger_static_runtime_restore_2026) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
