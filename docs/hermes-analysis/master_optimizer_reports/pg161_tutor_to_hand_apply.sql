BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg161_tutor_to_hand_20260624_094937 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('demonic tutor', 'diabolic intent', 'spellseeker', 'sylvan scrying', 'trophy mage')
   OR normalized_name LIKE 'demonic tutor // %'
   OR normalized_name LIKE 'diabolic intent // %'
   OR normalized_name LIKE 'spellseeker // %'
   OR normalized_name LIKE 'sylvan scrying // %'
   OR normalized_name LIKE 'trophy mage // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('demonic tutor', 'Demonic Tutor', '7c881aaacf79f25b41c9788cf307e795', 'battle_rule_v1:c7ff42f8ce9a2bca4470fba16cab034a', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DemonicTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('diabolic intent', 'Diabolic Intent', 'f9559e8f061153f5b7b70303f2f322f4', 'battle_rule_v1:e83b8e386f8ebf8e037dab9688873ce0', '{"ability_kind":"one_shot","battle_model_scope":"sacrifice_creature_any_tutor_to_hand_v1","effect":"tutor","instant":false,"requires_sacrifice_creature":true,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DiabolicIntent mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('spellseeker', 'Spellseeker', 'bf9a9c70cf24b529d0246eadd91693ee', 'battle_rule_v1:8367cbf70da28b3f24fef4a034deae63', '{"ability_kind":"triggered","battle_model_scope":"spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1","effect":"creature","etb_tutor_status":"runtime_library_to_hand","etb_tutor_target":"cheap_instant_or_sorcery","oracle_runtime_scope":"creature_etb_instant_or_sorcery_mana_value_lte_2_to_hand_runtime","power":1,"toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Spellseeker mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sylvan scrying', 'Sylvan Scrying', '00c22a38ec99c54ac1e7fb02a6230ed9', 'battle_rule_v1:200b39b38bf6e0159b901a483e9ee85d', '{"ability_kind":"one_shot","battle_model_scope":"land_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"land_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SylvanScrying mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('trophy mage', 'Trophy Mage', '5b696e4c373fb6e0b78e1d3229809a51', 'battle_rule_v1:9fc4f9774e576f908fd306318ce50ef7', '{"ability_kind":"triggered","battle_model_scope":"trophy_mage_etb_artifact_mana_value_3_to_hand_v1","effect":"creature","etb_tutor_status":"runtime_library_to_hand","etb_tutor_target":"artifact_mana_value_3","oracle_runtime_scope":"creature_etb_artifact_mana_value_3_to_hand_runtime","power":2,"toughness":2}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TrophyMage mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
  counts AS (
    SELECT
      p.card_name,
      p.normalized_name,
      p.oracle_hash,
      count(c.id) AS target_card_rows,
      min(c.id::text)::uuid AS canonical_card_id
    FROM proposed p
    LEFT JOIN public.cards c
      ON (
           lower(c.name) = p.normalized_name
           OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
         )
     AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
    GROUP BY p.card_name, p.normalized_name, p.oracle_hash
  )
  SELECT jsonb_agg(counts ORDER BY card_name)
    INTO v_missing
  FROM counts
  WHERE target_card_rows < 1;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'XMage batch package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('demonic tutor', 'Demonic Tutor', '7c881aaacf79f25b41c9788cf307e795', 'battle_rule_v1:c7ff42f8ce9a2bca4470fba16cab034a', '{"ability_kind":"one_shot","battle_model_scope":"any_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DemonicTutor mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('diabolic intent', 'Diabolic Intent', 'f9559e8f061153f5b7b70303f2f322f4', 'battle_rule_v1:e83b8e386f8ebf8e037dab9688873ce0', '{"ability_kind":"one_shot","battle_model_scope":"sacrifice_creature_any_tutor_to_hand_v1","effect":"tutor","instant":false,"requires_sacrifice_creature":true,"target":"any_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class DiabolicIntent mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('spellseeker', 'Spellseeker', 'bf9a9c70cf24b529d0246eadd91693ee', 'battle_rule_v1:8367cbf70da28b3f24fef4a034deae63', '{"ability_kind":"triggered","battle_model_scope":"spellseeker_etb_instant_or_sorcery_mana_value_2_or_less_to_hand_v1","effect":"creature","etb_tutor_status":"runtime_library_to_hand","etb_tutor_target":"cheap_instant_or_sorcery","oracle_runtime_scope":"creature_etb_instant_or_sorcery_mana_value_lte_2_to_hand_runtime","power":1,"toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Spellseeker mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('sylvan scrying', 'Sylvan Scrying', '00c22a38ec99c54ac1e7fb02a6230ed9', 'battle_rule_v1:200b39b38bf6e0159b901a483e9ee85d', '{"ability_kind":"one_shot","battle_model_scope":"land_tutor_to_hand_v1","effect":"tutor","instant":false,"target":"land_to_hand"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SylvanScrying mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('trophy mage', 'Trophy Mage', '5b696e4c373fb6e0b78e1d3229809a51', 'battle_rule_v1:9fc4f9774e576f908fd306318ce50ef7', '{"ability_kind":"triggered","battle_model_scope":"trophy_mage_etb_artifact_mana_value_3_to_hand_v1","effect":"creature","etb_tutor_status":"runtime_library_to_hand","etb_tutor_target":"artifact_mana_value_3","oracle_runtime_scope":"creature_etb_artifact_mana_value_3_to_hand_runtime","power":2,"toughness":2}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TrophyMage mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

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
  JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
canonical_target_cards AS (
  SELECT
    p.*,
    min(m.card_id::text)::uuid AS card_id,
    min(m.db_card_name) AS db_card_name
  FROM proposed p
  JOIN matched_cards m
    USING (normalized_name, card_name, oracle_hash)
  GROUP BY
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    p.logical_rule_key,
    p.effect_json,
    p.deck_role_json,
    p.source,
    p.confidence,
    p.review_status,
    p.execution_status,
    p.notes
),
upserted AS (
  INSERT INTO public.card_battle_rules (
    normalized_name,
    card_id,
    card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    rule_version,
    oracle_hash,
    notes,
    reviewed_by,
    reviewed_at,
    created_at,
    updated_at,
    last_seen_at,
    logical_rule_key,
    execution_status
  )
  SELECT
    normalized_name,
    card_id,
    db_card_name,
    effect_json,
    deck_role_json,
    source,
    confidence,
    review_status,
    2,
    oracle_hash,
    notes,
    'codex-xmage-batch',
    now(),
    now(),
    now(),
    now(),
    logical_rule_key,
    execution_status
  FROM canonical_target_cards
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET
    card_id = EXCLUDED.card_id,
    card_name = EXCLUDED.card_name,
    effect_json = EXCLUDED.effect_json,
    deck_role_json = EXCLUDED.deck_role_json,
    source = EXCLUDED.source,
    confidence = EXCLUDED.confidence,
    review_status = EXCLUDED.review_status,
    rule_version = EXCLUDED.rule_version,
    oracle_hash = EXCLUDED.oracle_hash,
    notes = EXCLUDED.notes,
    reviewed_by = EXCLUDED.reviewed_by,
    reviewed_at = EXCLUDED.reviewed_at,
    updated_at = EXCLUDED.updated_at,
    last_seen_at = EXCLUDED.last_seen_at,
    execution_status = EXCLUDED.execution_status
  RETURNING *
)
SELECT count(*) AS upserted_rows FROM upserted;

COMMIT;
