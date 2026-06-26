WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('longshot, rebel bowman', 'Longshot, Rebel Bowman', '262ee0e8c9dd03d7ef792501201f0df9', 'battle_rule_v1:17f2c09b361ae9a707f4c27cece88bd0', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":3,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LongshotRebelBowman mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('guttersnipe', 'Guttersnipe', 'f80fdc6153bf00a2198027bfa8b326db', 'battle_rule_v1:5b634b726647d3bd833233759968be5a', '{"ability_kind":"triggered","battle_model_scope":"spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Guttersnipe mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('coruscation mage', 'Coruscation Mage', '825fa07365c51b116f5b708afc4f15ed', 'battle_rule_v1:e3aad3351d48453dc40be9bc1a246917', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CoruscationMage mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('fiery inscription', 'Fiery Inscription', '78584ef3b8696dacc27441e4952b68f1', 'battle_rule_v1:1bd00fa75c597d366720ac22dd18a8fd', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_damage_each_opponent_v1","damage":2,"effect":"passive","target_controller":"opponents","trigger":"instant_sorcery_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FieryInscription mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('vivi ornitier', 'Vivi Ornitier', 'f2eaad7fdd9f97fcb314e495fd4f4a4e', 'battle_rule_v1:6a804c9cfcf1b619a6ea8f29e18b790a', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":0,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ViviOrnitier mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg239_spell_cast_damage_engine_20260626_101944) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
