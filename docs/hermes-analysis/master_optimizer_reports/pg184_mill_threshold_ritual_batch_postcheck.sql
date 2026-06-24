WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('brain freeze', 'Brain Freeze', 'ae7c7b244cb9842dde5c406ae7773fca', 'battle_rule_v1:b992316c10714f267a5a33a4c62795d4', '{"ability_kind":"one_shot","battle_model_scope":"storm_target_player_mill_fixed_count_v1","effect":"brain_freeze","instant":true,"mill_count":3,"storm":true,"target":"player"}'::jsonb, '{"category":"combo_value","effect":"mill","subtype":"library_mill","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BrainFreeze mapped to family mill_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('cabal ritual', 'Cabal Ritual', '549542c2ab124b22c3757819f8d2d44e', 'battle_rule_v1:1842b9d1707a9f8b0fb6ca71e5585e0e', '{"ability_kind":"one_shot","battle_model_scope":"threshold_three_or_five_black_mana_ritual_v1","effect":"ramp_ritual","instant":true,"mana_produced":3,"produces":"B","threshold_graveyard_count":7,"threshold_mana_produced":5}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CabalRitual mapped to family ramp_ritual; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg184_mill_threshold_ritual_batch_20260624_192504) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
