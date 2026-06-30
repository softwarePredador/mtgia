BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg274_perpetual_timepiece_graveyard_shuffle_20260630 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('perpetual timepiece')
   OR normalized_name LIKE 'perpetual timepiece // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('perpetual timepiece', 'Perpetual Timepiece', '4af52424df5fb9a51bff3fddb1c5c1ff', 'battle_rule_v1:26cffda59616c27dd2e137e165dc2d5d', '{"ability_kind":"activated","activated_self_mill_count":2,"artifact":true,"battle_model_scope":"tap_self_mill_two_or_exile_self_shuffle_any_number_graveyard_cards_into_library_v1","cmc":2.0,"effect":"passive","graveyard_shuffle_activation_cost_generic":2,"graveyard_shuffle_activation_requires_tap":false,"graveyard_shuffle_destination":"library","graveyard_shuffle_exiles_self":true,"graveyard_shuffle_low_library_threshold":8,"graveyard_shuffle_min_targets":1,"graveyard_shuffle_target_controller":"self","graveyard_shuffle_target_count":99,"mana_cost":"{2}","self_mill_activation_requires_tap":true,"self_mill_min_library_after":2}'::jsonb, '{"category":"recursion","effect":"passive","subtype":"activated_self_mill_graveyard_shuffle_artifact","timing":"activated_main_phase"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG274: Perpetual Timepiece exact activated artifact scope from local XMage PerpetualTimepiece.java and focused ManaLoom runtime test; tap self-mill two, or pay two and exile this artifact to shuffle selected graveyard cards into library.', 'deprecate_nonmatching_rows')
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
    RAISE EXCEPTION 'PG274 Perpetual Timepiece package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('perpetual timepiece', 'Perpetual Timepiece', '4af52424df5fb9a51bff3fddb1c5c1ff', 'battle_rule_v1:26cffda59616c27dd2e137e165dc2d5d', '{"ability_kind":"activated","activated_self_mill_count":2,"artifact":true,"battle_model_scope":"tap_self_mill_two_or_exile_self_shuffle_any_number_graveyard_cards_into_library_v1","cmc":2.0,"effect":"passive","graveyard_shuffle_activation_cost_generic":2,"graveyard_shuffle_activation_requires_tap":false,"graveyard_shuffle_destination":"library","graveyard_shuffle_exiles_self":true,"graveyard_shuffle_low_library_threshold":8,"graveyard_shuffle_min_targets":1,"graveyard_shuffle_target_controller":"self","graveyard_shuffle_target_count":99,"mana_cost":"{2}","self_mill_activation_requires_tap":true,"self_mill_min_library_after":2}'::jsonb, '{"category":"recursion","effect":"passive","subtype":"activated_self_mill_graveyard_shuffle_artifact","timing":"activated_main_phase"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG274: Perpetual Timepiece exact activated artifact scope from local XMage PerpetualTimepiece.java and focused ManaLoom runtime test; tap self-mill two, or pay two and exile this artifact to shuffle selected graveyard cards into library.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG274: deprecated stale Perpetual Timepiece shadow/review scope before curated executable self-mill/graveyard-shuffle artifact rule upsert.')
  FROM proposed p
  WHERE (
        r.normalized_name = p.normalized_name
        OR r.normalized_name LIKE p.normalized_name || ' // %'
      )
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('perpetual timepiece', 'Perpetual Timepiece', '4af52424df5fb9a51bff3fddb1c5c1ff', 'battle_rule_v1:26cffda59616c27dd2e137e165dc2d5d', '{"ability_kind":"activated","activated_self_mill_count":2,"artifact":true,"battle_model_scope":"tap_self_mill_two_or_exile_self_shuffle_any_number_graveyard_cards_into_library_v1","cmc":2.0,"effect":"passive","graveyard_shuffle_activation_cost_generic":2,"graveyard_shuffle_activation_requires_tap":false,"graveyard_shuffle_destination":"library","graveyard_shuffle_exiles_self":true,"graveyard_shuffle_low_library_threshold":8,"graveyard_shuffle_min_targets":1,"graveyard_shuffle_target_controller":"self","graveyard_shuffle_target_count":99,"mana_cost":"{2}","self_mill_activation_requires_tap":true,"self_mill_min_library_after":2}'::jsonb, '{"category":"recursion","effect":"passive","subtype":"activated_self_mill_graveyard_shuffle_artifact","timing":"activated_main_phase"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG274: Perpetual Timepiece exact activated artifact scope from local XMage PerpetualTimepiece.java and focused ManaLoom runtime test; tap self-mill two, or pay two and exile this artifact to shuffle selected graveyard cards into library.', 'deprecate_nonmatching_rows')
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
    p.notes,
    p.shadow_handling
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
    'codex-pg274-perpetual-timepiece',
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
