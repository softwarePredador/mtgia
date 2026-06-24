WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('lotho, corrupt shirriff', 'Lotho, Corrupt Shirriff', '44735ae3d1d2459d0d25c8023930b6a1', 'battle_rule_v1:c5987c2df49d9fa483a1cc9a5ac26fbb', '{"ability_kind":"triggered","battle_model_scope":"opponent_second_spell_each_turn_create_treasure_life_loss_v1","controller_loses_life_on_trigger":1,"draw_on_enter":false,"effect":"ramp_engine","is_creature_permanent":true,"opponent_second_spell_each_turn":true,"power":2,"toughness":1,"treasure_count":1,"trigger":"opponent_spell"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LothoCorruptShirriff mapped to family ramp_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('prized statue', 'Prized Statue', 'f8c4faf999ea6d3721761c9c0e9b2d2f', 'battle_rule_v1:5409aaaddafe0d4a8f2beef5869dccb1', '{"ability_kind":"triggered","battle_model_scope":"artifact_etb_or_dies_create_treasure_v1","dies_or_graveyard_from_battlefield_treasure":true,"effect":"ramp_permanent","enters_treasure":1,"treasure_count":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PrizedStatue mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg139_current_replay_batch_two_lotho_prized_statue_20260) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
