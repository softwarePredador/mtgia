WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fury storm', 'Fury Storm', '5a7a4b3e044452c015ecd91bc9897680', 'battle_rule_v1:1c5fc8fcfccde45171603a1ff05f4f05', '{"ability_kind":"one_shot","battle_model_scope":"copy_target_instant_or_sorcery_spell_may_choose_new_targets_v1","choose_new_targets_status":"may","commander_storm":true,"effect":"copy_spell","instant":true,"may_choose_new_targets":true,"target":"instant_or_sorcery_spell"}'::jsonb, '{"category":"combo_value","effect":"copy_spell","subtype":"stack_copy","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FuryStorm mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg185_fury_storm_copy_spell_20260624_201931) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
