WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('demonic tutor', 'Demonic Tutor', '7c881aaacf79f25b41c9788cf307e795', 'battle_rule_v1:c7ff42f8ce9a2bca4470fba16cab034a', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DemonicTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('diabolic intent', 'Diabolic Intent', 'f9559e8f061153f5b7b70303f2f322f4', 'battle_rule_v1:e83b8e386f8ebf8e037dab9688873ce0', '{"ability_kind":"one_shot","battle_model_scope":"sacrifice_creature_any_tutor_to_hand_v1","effect":"tutor","instant":false,"requires_sacrifice_creature":true,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DiabolicIntent mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('spellseeker', 'Spellseeker', 'bf9a9c70cf24b529d0246eadd91693ee', 'battle_rule_v1:8367cbf70da28b3f24fef4a034deae63', '{"ability_kind":"triggered","battle_model_scope":"spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1","effect":"creature","etb_tutor_status":"runtime_library_to_hand","etb_tutor_target":"cheap_instant_or_sorcery","oracle_runtime_scope":"creature_etb_instant_or_sorcery_mana_value_lte_2_to_hand_runtime","power":1,"toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Spellseeker mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sylvan scrying', 'Sylvan Scrying', '00c22a38ec99c54ac1e7fb02a6230ed9', 'battle_rule_v1:200b39b38bf6e0159b901a483e9ee85d', '{"ability_kind":"one_shot","battle_model_scope":"land_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"land_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SylvanScrying mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('trophy mage', 'Trophy Mage', '5b696e4c373fb6e0b78e1d3229809a51', 'battle_rule_v1:9fc4f9774e576f908fd306318ce50ef7', '{"ability_kind":"triggered","battle_model_scope":"trophy_mage_etb_artifact_mana_value_3_to_hand_v1","effect":"creature","etb_tutor_status":"runtime_library_to_hand","etb_tutor_target":"artifact_mana_value_3","oracle_runtime_scope":"creature_etb_artifact_mana_value_3_to_hand_runtime","power":2,"toughness":2}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TrophyMage mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
