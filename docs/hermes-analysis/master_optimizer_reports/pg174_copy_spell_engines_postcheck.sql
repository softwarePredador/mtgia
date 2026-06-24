WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('double vision', 'Double Vision', '1106bfd584470ed10401167bf452f0a4', 'battle_rule_v1:6b73ccf8b05f7853dcfeae1825b70708', '{"ability_kind":"triggered","battle_model_scope":"first_instant_sorcery_cast_each_turn_copy_own_spell_v1","choose_new_targets_status":"may","effect":"copy_spell","may_choose_new_targets":true,"target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_spell","trigger_first_instant_or_sorcery_each_turn":true}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DoubleVision mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('swarm intelligence', 'Swarm Intelligence', '1acd382841c8fabf16162bd47f9e4a03', 'battle_rule_v1:9f1ee8ecd68dad5bf39139de17c013eb', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_copy_own_spell_v1","choose_new_targets_status":"may","effect":"copy_spell","may_choose_new_targets":true,"target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_spell"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SwarmIntelligence mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg174_copy_spell_engines_20260624_124529) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
