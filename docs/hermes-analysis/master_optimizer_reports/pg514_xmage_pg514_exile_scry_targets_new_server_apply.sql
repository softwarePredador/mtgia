BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg514_xmage_pg514_exile_scry_targets_new_20260705_152330 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('devout decree', 'ray of ruin')
   OR normalized_name LIKE 'devout decree // %'
   OR normalized_name LIKE 'ray of ruin // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('devout decree', 'Devout Decree', '2ffef40b32de279e5d069ebdd05a631d', 'battle_rule_v1:77c2ca923d2c6b62ff46fc58b27e27fb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DevoutDecree translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ray of ruin', 'Ray of Ruin', '2c30c4034ace17cd7c4d01f9cb32d74c', 'battle_rule_v1:3ba725d656340693d4c616116bb305ef', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RayOfRuin translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('devout decree', 'Devout Decree', '2ffef40b32de279e5d069ebdd05a631d', 'battle_rule_v1:77c2ca923d2c6b62ff46fc58b27e27fb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DevoutDecree translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ray of ruin', 'Ray of Ruin', '2c30c4034ace17cd7c4d01f9cb32d74c', 'battle_rule_v1:3ba725d656340693d4c616116bb305ef', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RayOfRuin translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('devout decree', 'Devout Decree', '2ffef40b32de279e5d069ebdd05a631d', 'battle_rule_v1:77c2ca923d2c6b62ff46fc58b27e27fb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DevoutDecree translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ray of ruin', 'Ray of Ruin', '2c30c4034ace17cd7c4d01f9cb32d74c', 'battle_rule_v1:3ba725d656340693d4c616116bb305ef', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RayOfRuin translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
