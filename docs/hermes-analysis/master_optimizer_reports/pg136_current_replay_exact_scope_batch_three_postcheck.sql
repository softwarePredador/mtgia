WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('agatha''s soul cauldron', 'Agatha''s Soul Cauldron', 'af1a041d197bc91a562e38f80a2dfe7c', 'battle_rule_v1:76e9323694b00b6306976685792c0d10', '{"ability_kind":"triggered","activated_tap_exile_target_card_from_graveyard":true,"battle_model_scope":"graveyard_exile_counter_and_ability_grant_artifact_v1","creature_exile_reflexive_plus_one_counter":true,"effect":"passive","mana_as_any_color_for_creature_activations":true,"plus_one_counter_creatures_gain_activated_abilities_of_exiled_creatures":true}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AgathasSoulCauldron mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('necropotence', 'Necropotence', 'd7d453f73283bfb2c4cd21b991813bec', 'battle_rule_v1:91b849724b09ff0a6865c7daac918382', '{"ability_kind":"triggered","activated_exile_top_card_face_down":true,"activated_pay_life":1,"activated_put_exiled_card_into_hand_next_end_step":true,"battle_model_scope":"skip_draw_discard_exile_pay_life_face_down_draw_next_end_step_v1","discard_trigger_exiles_discarded_card_from_graveyard":true,"effect":"draw_engine","skip_draw_step":true}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Necropotence mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg136_current_replay_exact_scope_batch_three_20260624_01) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
