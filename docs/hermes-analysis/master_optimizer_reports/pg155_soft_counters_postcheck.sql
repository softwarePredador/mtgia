WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('mana leak', 'Mana Leak', 'aa3909e9100ef2fcd477df4032dc46f1', 'battle_rule_v1:931721bf8cd596a9aa7616f828ce8f2f', '{"ability_kind":"one_shot","battle_model_scope":"counter_spell_unless_controller_pays_three_v1","effect":"counter_spell","instant":true,"target":"spell","unless_controller_pays_generic":3}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ManaLeak mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('miscast', 'Miscast', 'dff145f1eaaa76d6f9e44e688bb29726', 'battle_rule_v1:3c9a71293fcab9fdbd66cd5099141f41', '{"ability_kind":"one_shot","battle_model_scope":"counter_instant_or_sorcery_unless_controller_pays_three_v1","effect":"counter_spell","instant":true,"target":"instant_or_sorcery_spell","unless_controller_pays_generic":3}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Miscast mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('spell pierce', 'Spell Pierce', 'f657ad73b97962b41b932ebf17bb6e47', 'battle_rule_v1:4c4f4dc3409b8b13423f2939f1a2c488', '{"ability_kind":"one_shot","battle_model_scope":"counter_noncreature_spell_unless_controller_pays_two_v1","effect":"counter_spell","instant":true,"target":"noncreature_spell","unless_controller_pays_generic":2}'::jsonb, '{"category":"interaction","effect":"targeted_interaction","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SpellPierce mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg155_soft_counters_20260624_082943) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
