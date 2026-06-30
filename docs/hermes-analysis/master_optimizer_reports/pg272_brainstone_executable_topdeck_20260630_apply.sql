BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg272_brainstone_executable_topdeck_20260630 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('brainstone')
   OR normalized_name LIKE 'brainstone // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('brainstone', 'Brainstone', '3c13a2b77d527812c94eae8a9c6f9615', 'battle_rule_v1:6aab083c9a25b2af50c2069683da5131', '{"ability_kind":"activated","activation_cost_generic":2,"activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"brainstone_draw_three_put_two_back_for_first_draw_miracle_v1","can_setup_lorehold_miracle_draw":true,"cmc":1.0,"draw_count":3,"effect":"topdeck_manipulation","hand_to_top_exchange":true,"put_from_hand_on_top_count":2,"requires_sacrifice_artifact":true}'::jsonb, '{"category":"draw","effect":"topdeck_manipulation","subtype":"activated_draw_topdeck_filter","timing":"activated_opponent_upkeep_first_draw_setup"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG272: Brainstone exact executable topdeck/miracle setup scope from local XMage Brainstone.java and focused ManaLoom runtime test; activated {2}, tap, sacrifice: draw three, then put two cards from hand on top. Replaces stale unexecuted scope label while preserving activated-filter semantics.', 'deprecate_nonmatching_rows')
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
    RAISE EXCEPTION 'PG272 Brainstone package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('brainstone', 'Brainstone', '3c13a2b77d527812c94eae8a9c6f9615', 'battle_rule_v1:6aab083c9a25b2af50c2069683da5131', '{"ability_kind":"activated","activation_cost_generic":2,"activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"brainstone_draw_three_put_two_back_for_first_draw_miracle_v1","can_setup_lorehold_miracle_draw":true,"cmc":1.0,"draw_count":3,"effect":"topdeck_manipulation","hand_to_top_exchange":true,"put_from_hand_on_top_count":2,"requires_sacrifice_artifact":true}'::jsonb, '{"category":"draw","effect":"topdeck_manipulation","subtype":"activated_draw_topdeck_filter","timing":"activated_opponent_upkeep_first_draw_setup"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG272: Brainstone exact executable topdeck/miracle setup scope from local XMage Brainstone.java and focused ManaLoom runtime test; activated {2}, tap, sacrifice: draw three, then put two cards from hand on top. Replaces stale unexecuted scope label while preserving activated-filter semantics.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG272: deprecated stale Brainstone shadow/unexecuted scope before curated executable topdeck rule upsert.')
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
    ('brainstone', 'Brainstone', '3c13a2b77d527812c94eae8a9c6f9615', 'battle_rule_v1:6aab083c9a25b2af50c2069683da5131', '{"ability_kind":"activated","activation_cost_generic":2,"activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"brainstone_draw_three_put_two_back_for_first_draw_miracle_v1","can_setup_lorehold_miracle_draw":true,"cmc":1.0,"draw_count":3,"effect":"topdeck_manipulation","hand_to_top_exchange":true,"put_from_hand_on_top_count":2,"requires_sacrifice_artifact":true}'::jsonb, '{"category":"draw","effect":"topdeck_manipulation","subtype":"activated_draw_topdeck_filter","timing":"activated_opponent_upkeep_first_draw_setup"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG272: Brainstone exact executable topdeck/miracle setup scope from local XMage Brainstone.java and focused ManaLoom runtime test; activated {2}, tap, sacrifice: draw three, then put two cards from hand on top. Replaces stale unexecuted scope label while preserving activated-filter semantics.', 'deprecate_nonmatching_rows')
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
    'codex-pg272-brainstone',
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
