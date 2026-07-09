BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg692_damage_each_opponent_permanents_20260709_051144 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('end the festivities', 'tectonic hazard')
   OR normalized_name LIKE 'end the festivities // %'
   OR normalized_name LIKE 'tectonic hazard // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('end the festivities', 'End the Festivities', 'f123365122f5b951c3e2711b234f326f', 'battle_rule_v1:409676e1f7059572e6cdf142e6089094', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EndTheFestivities translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tectonic hazard', 'Tectonic Hazard', '1ed517ee6d21d82c06be6f7f8d90a46f', 'battle_rule_v1:2c92b9d4398bfccba9c71a4263a1542a', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TectonicHazard translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('end the festivities', 'End the Festivities', 'f123365122f5b951c3e2711b234f326f', 'battle_rule_v1:409676e1f7059572e6cdf142e6089094', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EndTheFestivities translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tectonic hazard', 'Tectonic Hazard', '1ed517ee6d21d82c06be6f7f8d90a46f', 'battle_rule_v1:2c92b9d4398bfccba9c71a4263a1542a', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TectonicHazard translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('end the festivities', 'End the Festivities', 'f123365122f5b951c3e2711b234f326f', 'battle_rule_v1:409676e1f7059572e6cdf142e6089094', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_and_planeswalker_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EndTheFestivities translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tectonic hazard', 'Tectonic Hazard', '1ed517ee6d21d82c06be6f7f8d90a46f', 'battle_rule_v1:2c92b9d4398bfccba9c71a4263a1542a', '{"_composite_rule_components":[{"ability_kind":"one_shot","amount":1,"battle_model_scope":"spell_damage_each_opponent_v1","compose_on_resolution":true,"damage":1,"effect":"damage_each_opponent","target_controller":"opponents","xmage_effect_class":"DamagePlayersEffect"},{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","compose_on_resolution":true,"damage":1,"damage_scope":"each_creature_opponents_control","effect":"damage_wipe","target_controller":"opponents","xmage_effect_class":"DamageAllEffect"}],"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_damage_each_opponent_and_their_permanents_spell_v1","damage":1,"damage_scope":"each_creature_opponents_control","effect":"composite_resolution","instant":false,"resolution_order":"damage_opponents_then_their_permanents","sorcery":true,"target_controller":"opponents","xmage_effect_classes":["DamagePlayersEffect","DamageAllEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TectonicHazard translated into ManaLoom runtime scope xmage_damage_each_opponent_and_their_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
