BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg127_creature_variant_runtime_restore_20260624_001336 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('colossal skyturtle', 'abigale, eloquent first-year', 'glen elendra archmage');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('colossal skyturtle', 'Colossal Skyturtle', '05180c03fc1bcfd31ff9d6fc65edfaad', 'battle_rule_v1:d4e643cbd0c20a5a58ca11b06c217a5e', '{"ability_kind":"one_shot","battle_model_scope":"flying_ward_channel_regrowth_or_bounce_creature_v1","channel_return_graveyard_card_to_hand":"{2}{G}","channel_return_target_creature_to_hand":"{1}{U}","effect":"creature","flying":true,"power":6,"toughness":5,"ward_cost":"{2}"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ColossalSkyturtle mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('abigale, eloquent first-year', 'Abigale, Eloquent First-Year', 'daac542cd4b7cf8f12bb55ffac868d1a', 'battle_rule_v1:212147ed06811dba5af5e2c58100c716', '{"ability_kind":"triggered","battle_model_scope":"etb_strip_other_creature_abilities_and_grant_keyword_counters_v1","effect":"creature","etb_grants_keyword_counters":["flying","first_strike","lifelink"],"etb_other_target_creature_loses_all_abilities":true,"first_strike":true,"flying":true,"lifelink":true,"power":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AbigaleEloquentFirstYear mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('glen elendra archmage', 'Glen Elendra Archmage', 'f05e697db3bcfb65a827970c08d1446a', 'battle_rule_v1:180387d5d5fc0c2417eb7372ed7a5909', '{"ability_kind":"activated","activated_counter_noncreature_spell_cost":"{U}","activation_cost":"sacrifice_self","battle_model_scope":"flying_persist_sacrifice_self_counter_noncreature_spell_v1","effect":"creature","flying":true,"persist":true,"power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GlenElendraArchmage mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
      ON lower(c.name) = p.normalized_name
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
    ('colossal skyturtle', 'Colossal Skyturtle', '05180c03fc1bcfd31ff9d6fc65edfaad', 'battle_rule_v1:d4e643cbd0c20a5a58ca11b06c217a5e', '{"ability_kind":"one_shot","battle_model_scope":"flying_ward_channel_regrowth_or_bounce_creature_v1","channel_return_graveyard_card_to_hand":"{2}{G}","channel_return_target_creature_to_hand":"{1}{U}","effect":"creature","flying":true,"power":6,"toughness":5,"ward_cost":"{2}"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ColossalSkyturtle mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('abigale, eloquent first-year', 'Abigale, Eloquent First-Year', 'daac542cd4b7cf8f12bb55ffac868d1a', 'battle_rule_v1:212147ed06811dba5af5e2c58100c716', '{"ability_kind":"triggered","battle_model_scope":"etb_strip_other_creature_abilities_and_grant_keyword_counters_v1","effect":"creature","etb_grants_keyword_counters":["flying","first_strike","lifelink"],"etb_other_target_creature_loses_all_abilities":true,"first_strike":true,"flying":true,"lifelink":true,"power":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AbigaleEloquentFirstYear mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('glen elendra archmage', 'Glen Elendra Archmage', 'f05e697db3bcfb65a827970c08d1446a', 'battle_rule_v1:180387d5d5fc0c2417eb7372ed7a5909', '{"ability_kind":"activated","activated_counter_noncreature_spell_cost":"{U}","activation_cost":"sacrifice_self","battle_model_scope":"flying_persist_sacrifice_self_counter_noncreature_spell_v1","effect":"creature","flying":true,"persist":true,"power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GlenElendraArchmage mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'XMage batch package: deprecated stale shadow before curated batch rule upsert.')
  FROM proposed p
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('colossal skyturtle', 'Colossal Skyturtle', '05180c03fc1bcfd31ff9d6fc65edfaad', 'battle_rule_v1:d4e643cbd0c20a5a58ca11b06c217a5e', '{"ability_kind":"one_shot","battle_model_scope":"flying_ward_channel_regrowth_or_bounce_creature_v1","channel_return_graveyard_card_to_hand":"{2}{G}","channel_return_target_creature_to_hand":"{1}{U}","effect":"creature","flying":true,"power":6,"toughness":5,"ward_cost":"{2}"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ColossalSkyturtle mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('abigale, eloquent first-year', 'Abigale, Eloquent First-Year', 'daac542cd4b7cf8f12bb55ffac868d1a', 'battle_rule_v1:212147ed06811dba5af5e2c58100c716', '{"ability_kind":"triggered","battle_model_scope":"etb_strip_other_creature_abilities_and_grant_keyword_counters_v1","effect":"creature","etb_grants_keyword_counters":["flying","first_strike","lifelink"],"etb_other_target_creature_loses_all_abilities":true,"first_strike":true,"flying":true,"lifelink":true,"power":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AbigaleEloquentFirstYear mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('glen elendra archmage', 'Glen Elendra Archmage', 'f05e697db3bcfb65a827970c08d1446a', 'battle_rule_v1:180387d5d5fc0c2417eb7372ed7a5909', '{"ability_kind":"activated","activated_counter_noncreature_spell_cost":"{U}","activation_cost":"sacrifice_self","battle_model_scope":"flying_persist_sacrifice_self_counter_noncreature_spell_v1","effect":"creature","flying":true,"persist":true,"power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GlenElendraArchmage mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON lower(c.name) = p.normalized_name
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
