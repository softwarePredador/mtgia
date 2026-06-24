BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg176_damage_controller_pain_sources_20260624_131434 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('elves of deep shadow', 'talisman of curiosity', 'tarnished citadel')
   OR normalized_name LIKE 'elves of deep shadow // %'
   OR normalized_name LIKE 'talisman of curiosity // %'
   OR normalized_name LIKE 'tarnished citadel // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('elves of deep shadow', 'Elves of Deep Shadow', '5dd30cbea74064369bcba667795049e2', 'battle_rule_v1:1272fb910383d34360702e343ec16b37', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_black_pain_mana_dork_v1","damage_on_tap":1,"effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"B","tap_damage_status":"annotation_only","toughness":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"mana_creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvesOfDeepShadow mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('talisman of curiosity', 'Talisman of Curiosity', '212d43a126a54d9aabbf1dec21b93acb', 'battle_rule_v1:c4df4800bcf67bfd2ded6ea1fc6a8efa', '{"ability_kind":"activated","battle_model_scope":"pain_talisman_color_pair_partial_v1","effect":"ramp_permanent","life_for_colored_mana":1,"mana_produced":1,"produces":"CUG"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TalismanOfCuriosity mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('tarnished citadel', 'Tarnished Citadel', 'd8bdb24e586e16274f0bd42e40e2dc58', 'battle_rule_v1:d5663032352408a845b7602f9cb5adf9', '{"ability_kind":"activated","battle_model_scope":"colorless_or_any_color_pain_land_v1","effect":"land","life_for_colored_mana":3,"life_loss_on_colored_mana_status":"annotation_only","mana_produced":1,"produces":"CWUBRG"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TarnishedCitadel mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('elves of deep shadow', 'Elves of Deep Shadow', '5dd30cbea74064369bcba667795049e2', 'battle_rule_v1:1272fb910383d34360702e343ec16b37', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_black_pain_mana_dork_v1","damage_on_tap":1,"effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"B","tap_damage_status":"annotation_only","toughness":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"mana_creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvesOfDeepShadow mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('talisman of curiosity', 'Talisman of Curiosity', '212d43a126a54d9aabbf1dec21b93acb', 'battle_rule_v1:c4df4800bcf67bfd2ded6ea1fc6a8efa', '{"ability_kind":"activated","battle_model_scope":"pain_talisman_color_pair_partial_v1","effect":"ramp_permanent","life_for_colored_mana":1,"mana_produced":1,"produces":"CUG"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TalismanOfCuriosity mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('tarnished citadel', 'Tarnished Citadel', 'd8bdb24e586e16274f0bd42e40e2dc58', 'battle_rule_v1:d5663032352408a845b7602f9cb5adf9', '{"ability_kind":"activated","battle_model_scope":"colorless_or_any_color_pain_land_v1","effect":"land","life_for_colored_mana":3,"life_loss_on_colored_mana_status":"annotation_only","mana_produced":1,"produces":"CWUBRG"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TarnishedCitadel mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('elves of deep shadow', 'Elves of Deep Shadow', '5dd30cbea74064369bcba667795049e2', 'battle_rule_v1:1272fb910383d34360702e343ec16b37', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_black_pain_mana_dork_v1","damage_on_tap":1,"effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"B","tap_damage_status":"annotation_only","toughness":1}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"mana_creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvesOfDeepShadow mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('talisman of curiosity', 'Talisman of Curiosity', '212d43a126a54d9aabbf1dec21b93acb', 'battle_rule_v1:c4df4800bcf67bfd2ded6ea1fc6a8efa', '{"ability_kind":"activated","battle_model_scope":"pain_talisman_color_pair_partial_v1","effect":"ramp_permanent","life_for_colored_mana":1,"mana_produced":1,"produces":"CUG"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TalismanOfCuriosity mapped to family ramp_permanent; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('tarnished citadel', 'Tarnished Citadel', 'd8bdb24e586e16274f0bd42e40e2dc58', 'battle_rule_v1:d5663032352408a845b7602f9cb5adf9', '{"ability_kind":"activated","battle_model_scope":"colorless_or_any_color_pain_land_v1","effect":"land","life_for_colored_mana":3,"life_loss_on_colored_mana_status":"annotation_only","mana_produced":1,"produces":"CWUBRG"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TarnishedCitadel mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
