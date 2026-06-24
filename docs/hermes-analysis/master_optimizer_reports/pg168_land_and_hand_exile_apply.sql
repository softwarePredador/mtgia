BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg168_land_and_hand_exile_20260624_113000 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('elvish spirit guide', 'mountain', 'plains')
   OR normalized_name LIKE 'elvish spirit guide // %'
   OR normalized_name LIKE 'mountain // %'
   OR normalized_name LIKE 'plains // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('elvish spirit guide', 'Elvish Spirit Guide', '75a6071aad90d25b26b269458f953bb0', 'battle_rule_v1:89b51a84d293b0e0f3ed43c40aeee4d9', '{"ability_kind":"activated","battle_model_scope":"hand_exile_add_one_green_mana_ritual_v1","effect":"ramp_ritual","hand_exile_mana_ability":true,"mana_produced":1,"produces":"G"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishSpiritGuide mapped to family ramp_ritual; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mountain', 'Mountain', 'b3614279f2405f7c1cabda2d7252852b', 'battle_rule_v1:8a2127a2777cd1a0992c74c621621796', '{"ability_kind":"activated","basic_land_types":["Mountain"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"R"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mountain mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('plains', 'Plains', '0159e87a7fe9f2edbdb9408db4e6cba8', 'battle_rule_v1:f7fde69c51ea340cdfeda1544dea220b', '{"ability_kind":"activated","basic_land_types":["Plains"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"W"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Plains mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('elvish spirit guide', 'Elvish Spirit Guide', '75a6071aad90d25b26b269458f953bb0', 'battle_rule_v1:89b51a84d293b0e0f3ed43c40aeee4d9', '{"ability_kind":"activated","battle_model_scope":"hand_exile_add_one_green_mana_ritual_v1","effect":"ramp_ritual","hand_exile_mana_ability":true,"mana_produced":1,"produces":"G"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishSpiritGuide mapped to family ramp_ritual; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mountain', 'Mountain', 'b3614279f2405f7c1cabda2d7252852b', 'battle_rule_v1:8a2127a2777cd1a0992c74c621621796', '{"ability_kind":"activated","basic_land_types":["Mountain"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"R"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mountain mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('plains', 'Plains', '0159e87a7fe9f2edbdb9408db4e6cba8', 'battle_rule_v1:f7fde69c51ea340cdfeda1544dea220b', '{"ability_kind":"activated","basic_land_types":["Plains"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"W"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Plains mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('elvish spirit guide', 'Elvish Spirit Guide', '75a6071aad90d25b26b269458f953bb0', 'battle_rule_v1:89b51a84d293b0e0f3ed43c40aeee4d9', '{"ability_kind":"activated","battle_model_scope":"hand_exile_add_one_green_mana_ritual_v1","effect":"ramp_ritual","hand_exile_mana_ability":true,"mana_produced":1,"produces":"G"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishSpiritGuide mapped to family ramp_ritual; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mountain', 'Mountain', 'b3614279f2405f7c1cabda2d7252852b', 'battle_rule_v1:8a2127a2777cd1a0992c74c621621796', '{"ability_kind":"activated","basic_land_types":["Mountain"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"R"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Mountain mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('plains', 'Plains', '0159e87a7fe9f2edbdb9408db4e6cba8', 'battle_rule_v1:f7fde69c51ea340cdfeda1544dea220b', '{"ability_kind":"activated","basic_land_types":["Plains"],"battle_model_scope":"basic_one_color_land_v1","effect":"land","mana_produced":1,"produces":"W"}'::jsonb, '{"category":"ramp","effect":"land","subtype":"mana_base","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Plains mapped to family land; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
