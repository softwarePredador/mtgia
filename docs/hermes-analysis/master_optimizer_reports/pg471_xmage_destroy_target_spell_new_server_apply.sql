BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg471_xmage_destroy_target_spell_new_server_20260705_021 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bone splinters', 'embrace oblivion', 'powerstone fracture', 'raze')
   OR normalized_name LIKE 'bone splinters // %'
   OR normalized_name LIKE 'embrace oblivion // %'
   OR normalized_name LIKE 'powerstone fracture // %'
   OR normalized_name LIKE 'raze // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bone splinters', 'Bone Splinters', '5b0fa8f1b681a6327b1ffe89ef0ffbc9', 'battle_rule_v1:f4fb67d9af26b5ed562b437b85d0e3d3', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneSplinters translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('embrace oblivion', 'Embrace Oblivion', '05e8fd4bf8fae8602b5883385f75a6aa', 'battle_rule_v1:1330d6b65c530f0725148ec8f4e16576', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmbraceOblivion translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('powerstone fracture', 'Powerstone Fracture', 'a5c06a971f3a0473c0568aba333cf79a', 'battle_rule_v1:142000d6120e9a04710f8a2cc31524b2', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PowerstoneFracture translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raze', 'Raze', 'e0d0084f1ad04bd705cf38689a523622', 'battle_rule_v1:476f315b753e08d325a53d881500898a', '{"additional_cost":"sacrifice_land","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_land":true,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"land","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Raze translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bone splinters', 'Bone Splinters', '5b0fa8f1b681a6327b1ffe89ef0ffbc9', 'battle_rule_v1:f4fb67d9af26b5ed562b437b85d0e3d3', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneSplinters translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('embrace oblivion', 'Embrace Oblivion', '05e8fd4bf8fae8602b5883385f75a6aa', 'battle_rule_v1:1330d6b65c530f0725148ec8f4e16576', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmbraceOblivion translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('powerstone fracture', 'Powerstone Fracture', 'a5c06a971f3a0473c0568aba333cf79a', 'battle_rule_v1:142000d6120e9a04710f8a2cc31524b2', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PowerstoneFracture translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raze', 'Raze', 'e0d0084f1ad04bd705cf38689a523622', 'battle_rule_v1:476f315b753e08d325a53d881500898a', '{"additional_cost":"sacrifice_land","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_land":true,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"land","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Raze translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bone splinters', 'Bone Splinters', '5b0fa8f1b681a6327b1ffe89ef0ffbc9', 'battle_rule_v1:f4fb67d9af26b5ed562b437b85d0e3d3', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneSplinters translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('embrace oblivion', 'Embrace Oblivion', '05e8fd4bf8fae8602b5883385f75a6aa', 'battle_rule_v1:1330d6b65c530f0725148ec8f4e16576', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_creature","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EmbraceOblivion translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('powerstone fracture', 'Powerstone Fracture', 'a5c06a971f3a0473c0568aba333cf79a', 'battle_rule_v1:142000d6120e9a04710f8a2cc31524b2', '{"additional_cost":"sacrifice_artifact_or_creature","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_artifact_or_creature":true,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"artifact_or_creature","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PowerstoneFracture translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raze', 'Raze', 'e0d0084f1ad04bd705cf38689a523622', 'battle_rule_v1:476f315b753e08d325a53d881500898a', '{"additional_cost":"sacrifice_land","battle_model_scope":"xmage_destroy_target_spell_v1","destination":"graveyard","effect":"remove_permanent","instant":false,"requires_sacrifice_land":true,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"land","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Raze translated into ManaLoom runtime scope xmage_destroy_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
