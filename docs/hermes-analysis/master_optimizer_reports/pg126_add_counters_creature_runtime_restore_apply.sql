BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg126_add_counters_creature_runtime_restore_20260624_000 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('carrion feeder', 'icatian moneychanger', 'warden of the grove', 'wildborn preserver');

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('carrion feeder', 'Carrion Feeder', 'aa7a8c93f13391b97e99e8ab170090b2', 'battle_rule_v1:98705567ca9c39c0389d04fd0f5d9c98', '{"ability_kind":"triggered","activation_cost":"sacrifice_creature","battle_model_scope":"sacrifice_creature_put_plus_one_counter_on_self_cant_block_v1","cant_block":true,"effect":"creature","power":1,"self_add_plus_one_counter":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CarrionFeeder mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('icatian moneychanger', 'Icatian Moneychanger', '40b1aa102ad1d51470f23051be0ceca9', 'battle_rule_v1:52cac2abd4e1ea92330cfc12ba51ec5a', '{"ability_kind":"triggered","activation_cost":"sacrifice_self","activation_only_your_upkeep":true,"battle_model_scope":"credit_counter_upkeep_growth_sacrifice_for_life_v1","effect":"creature","enters_with_credit_counters":3,"etb_damage_controller":3,"gain_life_per_credit_counter":true,"power":0,"toughness":2,"upkeep_add_credit_counter":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class IcatianMoneychanger mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('warden of the grove', 'Warden of the Grove', 'ceb13a31308fc0f6e25631a6266a257a', 'battle_rule_v1:ccfa4a6a8d4e8d3b93cbef43611c3694', '{"ability_kind":"triggered","battle_model_scope":"end_step_plus_one_counter_and_other_nontoken_creature_endures_x_v1","effect":"creature","end_step_add_plus_one_counter":1,"other_nontoken_creature_endures_equal_to_source_counters":true,"power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WardenOfTheGrove mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wildborn preserver', 'Wildborn Preserver', 'ef7f70900e5cc27e77031ae20d6b3770', 'battle_rule_v1:5695544e75290878fdfdfa602648642d', '{"ability_kind":"triggered","another_nonhuman_etb_optional_pay_x_for_x_plus_one_counters_on_self":true,"battle_model_scope":"flash_reach_nonhuman_etb_pay_x_put_x_plus_one_counters_on_self_v1","effect":"creature","flash":true,"power":2,"reach":true,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WildbornPreserver mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('carrion feeder', 'Carrion Feeder', 'aa7a8c93f13391b97e99e8ab170090b2', 'battle_rule_v1:98705567ca9c39c0389d04fd0f5d9c98', '{"ability_kind":"triggered","activation_cost":"sacrifice_creature","battle_model_scope":"sacrifice_creature_put_plus_one_counter_on_self_cant_block_v1","cant_block":true,"effect":"creature","power":1,"self_add_plus_one_counter":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CarrionFeeder mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('icatian moneychanger', 'Icatian Moneychanger', '40b1aa102ad1d51470f23051be0ceca9', 'battle_rule_v1:52cac2abd4e1ea92330cfc12ba51ec5a', '{"ability_kind":"triggered","activation_cost":"sacrifice_self","activation_only_your_upkeep":true,"battle_model_scope":"credit_counter_upkeep_growth_sacrifice_for_life_v1","effect":"creature","enters_with_credit_counters":3,"etb_damage_controller":3,"gain_life_per_credit_counter":true,"power":0,"toughness":2,"upkeep_add_credit_counter":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class IcatianMoneychanger mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('warden of the grove', 'Warden of the Grove', 'ceb13a31308fc0f6e25631a6266a257a', 'battle_rule_v1:ccfa4a6a8d4e8d3b93cbef43611c3694', '{"ability_kind":"triggered","battle_model_scope":"end_step_plus_one_counter_and_other_nontoken_creature_endures_x_v1","effect":"creature","end_step_add_plus_one_counter":1,"other_nontoken_creature_endures_equal_to_source_counters":true,"power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WardenOfTheGrove mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wildborn preserver', 'Wildborn Preserver', 'ef7f70900e5cc27e77031ae20d6b3770', 'battle_rule_v1:5695544e75290878fdfdfa602648642d', '{"ability_kind":"triggered","another_nonhuman_etb_optional_pay_x_for_x_plus_one_counters_on_self":true,"battle_model_scope":"flash_reach_nonhuman_etb_pay_x_put_x_plus_one_counters_on_self_v1","effect":"creature","flash":true,"power":2,"reach":true,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WildbornPreserver mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ('carrion feeder', 'Carrion Feeder', 'aa7a8c93f13391b97e99e8ab170090b2', 'battle_rule_v1:98705567ca9c39c0389d04fd0f5d9c98', '{"ability_kind":"triggered","activation_cost":"sacrifice_creature","battle_model_scope":"sacrifice_creature_put_plus_one_counter_on_self_cant_block_v1","cant_block":true,"effect":"creature","power":1,"self_add_plus_one_counter":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CarrionFeeder mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('icatian moneychanger', 'Icatian Moneychanger', '40b1aa102ad1d51470f23051be0ceca9', 'battle_rule_v1:52cac2abd4e1ea92330cfc12ba51ec5a', '{"ability_kind":"triggered","activation_cost":"sacrifice_self","activation_only_your_upkeep":true,"battle_model_scope":"credit_counter_upkeep_growth_sacrifice_for_life_v1","effect":"creature","enters_with_credit_counters":3,"etb_damage_controller":3,"gain_life_per_credit_counter":true,"power":0,"toughness":2,"upkeep_add_credit_counter":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class IcatianMoneychanger mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('warden of the grove', 'Warden of the Grove', 'ceb13a31308fc0f6e25631a6266a257a', 'battle_rule_v1:ccfa4a6a8d4e8d3b93cbef43611c3694', '{"ability_kind":"triggered","battle_model_scope":"end_step_plus_one_counter_and_other_nontoken_creature_endures_x_v1","effect":"creature","end_step_add_plus_one_counter":1,"other_nontoken_creature_endures_equal_to_source_counters":true,"power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WardenOfTheGrove mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wildborn preserver', 'Wildborn Preserver', 'ef7f70900e5cc27e77031ae20d6b3770', 'battle_rule_v1:5695544e75290878fdfdfa602648642d', '{"ability_kind":"triggered","another_nonhuman_etb_optional_pay_x_for_x_plus_one_counters_on_self":true,"battle_model_scope":"flash_reach_nonhuman_etb_pay_x_put_x_plus_one_counters_on_self_v1","effect":"creature","flash":true,"power":2,"reach":true,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WildbornPreserver mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
