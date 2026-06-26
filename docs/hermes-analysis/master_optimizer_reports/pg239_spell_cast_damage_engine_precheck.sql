WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('longshot, rebel bowman', 'Longshot, Rebel Bowman', '262ee0e8c9dd03d7ef792501201f0df9', 'battle_rule_v1:17f2c09b361ae9a707f4c27cece88bd0', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":3,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LongshotRebelBowman mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('guttersnipe', 'Guttersnipe', 'f80fdc6153bf00a2198027bfa8b326db', 'battle_rule_v1:5b634b726647d3bd833233759968be5a', '{"ability_kind":"triggered","battle_model_scope":"spell_cast_damage_each_opponent_v1","damage":2,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"spell_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Guttersnipe mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('coruscation mage', 'Coruscation Mage', '825fa07365c51b116f5b708afc4f15ed', 'battle_rule_v1:e3aad3351d48453dc40be9bc1a246917', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":2,"target_controller":"opponents","toughness":2,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CoruscationMage mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('fiery inscription', 'Fiery Inscription', '78584ef3b8696dacc27441e4952b68f1', 'battle_rule_v1:1bd00fa75c597d366720ac22dd18a8fd', '{"ability_kind":"triggered","battle_model_scope":"instant_sorcery_cast_damage_each_opponent_v1","damage":2,"effect":"passive","target_controller":"opponents","trigger":"instant_sorcery_cast","trigger_damage_each_opponent":2,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FieryInscription mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('vivi ornitier', 'Vivi Ornitier', 'f2eaad7fdd9f97fcb314e495fd4f4a4e', 'battle_rule_v1:6a804c9cfcf1b619a6ea8f29e18b790a', '{"ability_kind":"triggered","battle_model_scope":"noncreature_spell_cast_damage_each_opponent_v1","damage":1,"effect":"creature","power":0,"target_controller":"opponents","toughness":3,"trigger":"noncreature_spell_cast","trigger_damage_each_opponent":1,"trigger_effect":"damage_each_opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ViviOrnitier mapped to family spell_cast_damage_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
