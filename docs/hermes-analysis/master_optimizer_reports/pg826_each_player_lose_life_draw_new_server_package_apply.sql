BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg826_pg826_each_player_lose_life_draw_n_20260712_104644 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('crushing disappointment', 'risky shortcut')
   OR normalized_name LIKE 'crushing disappointment // %'
   OR normalized_name LIKE 'risky shortcut // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('crushing disappointment', 'Crushing Disappointment', '4067937d3e47b39762d4ee07b0ea41b0', 'battle_rule_v1:76e6899630805fefcf7a76367f997c29', '{"_composite_rule_components":[{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":true,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"lose_life_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrushingDisappointment translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('risky shortcut', 'Risky Shortcut', 'ccb8b3c872f69d157c2bd6c8242efbec', 'battle_rule_v1:60a12a6d1b6fe7954d1f401120e64b2c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":false,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"draw_then_lose_life","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiskyShortcut translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('crushing disappointment', 'Crushing Disappointment', '4067937d3e47b39762d4ee07b0ea41b0', 'battle_rule_v1:76e6899630805fefcf7a76367f997c29', '{"_composite_rule_components":[{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":true,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"lose_life_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrushingDisappointment translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('risky shortcut', 'Risky Shortcut', 'ccb8b3c872f69d157c2bd6c8242efbec', 'battle_rule_v1:60a12a6d1b6fe7954d1f401120e64b2c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":false,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"draw_then_lose_life","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiskyShortcut translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    AND p.shadow_handling <> 'preserve_existing_rows'
    AND r.logical_rule_key <> p.logical_rule_key
  RETURNING r.*
)
SELECT count(*) AS deprecated_shadow_rows FROM deprecated;

WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('crushing disappointment', 'Crushing Disappointment', '4067937d3e47b39762d4ee07b0ea41b0', 'battle_rule_v1:76e6899630805fefcf7a76367f997c29', '{"_composite_rule_components":[{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":true,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"lose_life_then_draw","sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrushingDisappointment translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('risky shortcut', 'Risky Shortcut', 'ccb8b3c872f69d157c2bd6c8242efbec', 'battle_rule_v1:60a12a6d1b6fe7954d1f401120e64b2c', '{"_composite_rule_components":[{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":2,"draw_count":2,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"},{"battle_model_scope":"xmage_each_player_lose_life_component_v1","compose_on_resolution":true,"effect":"life_total_change","life_loss":2,"life_loss_amount":2,"life_total_delta":-2,"target":"all_players","target_controller":"all_players","xmage_effect_class":"LoseLifeAllPlayersEffect"}],"battle_model_scope":"xmage_each_player_lose_life_draw_card_spell_v1","count":2,"draw_count":2,"each_player_life_loss":2,"effect":"composite_resolution","instant":false,"life_loss":2,"life_loss_amount":2,"life_loss_target":"all_players","resolution_order":"draw_then_lose_life","sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeAllPlayersEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RiskyShortcut translated into ManaLoom runtime scope xmage_each_player_lose_life_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
