BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg273_codex_shredder_mill_recursion_20260630 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('codex shredder')
   OR normalized_name LIKE 'codex shredder // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('codex shredder', 'Codex Shredder', '48dd2cf11a80189f548581507ab88df9', 'battle_rule_v1:3417000adca740f0c5036e7232221df4', '{"ability_kind":"activated","activated_target_player_mill_count":1,"artifact":true,"battle_model_scope":"tap_target_player_mill_one_or_five_tap_sacrifice_return_target_card_from_your_graveyard_to_hand_v1","cmc":1.0,"effect":"passive","graveyard_to_hand_activation_cost_generic":5,"graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"any_card","graveyard_to_hand_target_count":1,"mana_cost":"{1}","target_player_mill_activation_requires_tap":true}'::jsonb, '{"category":"recursion","effect":"passive","subtype":"activated_graveyard_card_return_artifact","timing":"activated_main_phase"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG273: Codex Shredder exact activated artifact scope from local XMage CodexShredder.java and focused ManaLoom runtime test; tap target-player mill one, or pay five, tap, sacrifice this artifact to return target card from your graveyard to your hand.', 'deprecate_nonmatching_rows')
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
    RAISE EXCEPTION 'PG273 Codex Shredder package abort: expected at least one Oracle-hash-matched card row for every proposed card: %', v_missing;
  END IF;
END $$;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('codex shredder', 'Codex Shredder', '48dd2cf11a80189f548581507ab88df9', 'battle_rule_v1:3417000adca740f0c5036e7232221df4', '{"ability_kind":"activated","activated_target_player_mill_count":1,"artifact":true,"battle_model_scope":"tap_target_player_mill_one_or_five_tap_sacrifice_return_target_card_from_your_graveyard_to_hand_v1","cmc":1.0,"effect":"passive","graveyard_to_hand_activation_cost_generic":5,"graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"any_card","graveyard_to_hand_target_count":1,"mana_cost":"{1}","target_player_mill_activation_requires_tap":true}'::jsonb, '{"category":"recursion","effect":"passive","subtype":"activated_graveyard_card_return_artifact","timing":"activated_main_phase"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG273: Codex Shredder exact activated artifact scope from local XMage CodexShredder.java and focused ManaLoom runtime test; tap target-player mill one, or pay five, tap, sacrifice this artifact to return target card from your graveyard to your hand.', 'deprecate_nonmatching_rows')
),
deprecated AS (
  UPDATE public.card_battle_rules r
  SET
    review_status = 'deprecated',
    execution_status = 'disabled',
    updated_at = now(),
    notes = concat_ws(E'\n', nullif(r.notes, ''), 'PG273: deprecated stale Codex Shredder shadow/review scope before curated executable activated artifact rule upsert.')
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
    ('codex shredder', 'Codex Shredder', '48dd2cf11a80189f548581507ab88df9', 'battle_rule_v1:3417000adca740f0c5036e7232221df4', '{"ability_kind":"activated","activated_target_player_mill_count":1,"artifact":true,"battle_model_scope":"tap_target_player_mill_one_or_five_tap_sacrifice_return_target_card_from_your_graveyard_to_hand_v1","cmc":1.0,"effect":"passive","graveyard_to_hand_activation_cost_generic":5,"graveyard_to_hand_activation_requires_sacrifice":true,"graveyard_to_hand_activation_requires_tap":true,"graveyard_to_hand_destination":"hand","graveyard_to_hand_target":"any_card","graveyard_to_hand_target_count":1,"mana_cost":"{1}","target_player_mill_activation_requires_tap":true}'::jsonb, '{"category":"recursion","effect":"passive","subtype":"activated_graveyard_card_return_artifact","timing":"activated_main_phase"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG273: Codex Shredder exact activated artifact scope from local XMage CodexShredder.java and focused ManaLoom runtime test; tap target-player mill one, or pay five, tap, sacrifice this artifact to return target card from your graveyard to your hand.', 'deprecate_nonmatching_rows')
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
    'codex-pg273-codex-shredder',
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
