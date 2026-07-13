BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg863_destroy_mana_ritual_new_server_20260713_043302 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('deconstruct', 'liturgy of blood', 'seismic spike', 'turn to dust')
   OR normalized_name LIKE 'deconstruct // %'
   OR normalized_name LIKE 'liturgy of blood // %'
   OR normalized_name LIKE 'seismic spike // %'
   OR normalized_name LIKE 'turn to dust // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deconstruct', 'Deconstruct', '08f659e0e917ed1ddb367a9c86897b45', 'battle_rule_v1:3c02c24a2346797911c20945d2f1a9f0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["G","G","G"],"produces":"G","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["G","G","G"],"produces":"G","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deconstruct translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('liturgy of blood', 'Liturgy of Blood', '793a1d6947010edec6e943eef9da9139', 'battle_rule_v1:7f91b8beaa5f42a0d97e520e388ab01a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["B","B","B"],"produces":"B","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["B","B","B"],"produces":"B","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LiturgyOfBlood translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('seismic spike', 'Seismic Spike', '6ed975bb71da90e04ccbff411312aa15', 'battle_rule_v1:dd8dce7535424809092d8737ac86ce3f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":2,"produced_mana_symbols":["R","R"],"produces":"R","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":2,"produced_mana_symbols":["R","R"],"produces":"R","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SeismicSpike translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('turn to dust', 'Turn to Dust', '32481b22834ca33b610c00906439c510', 'battle_rule_v1:f4a9e330eee70bed3982dcb7d586e238', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":1,"produced_mana_symbols":["G"],"produces":"G","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":1,"produced_mana_symbols":["G"],"produces":"G","resolution_order":"destroy_then_add_mana","sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TurnToDust translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('deconstruct', 'Deconstruct', '08f659e0e917ed1ddb367a9c86897b45', 'battle_rule_v1:3c02c24a2346797911c20945d2f1a9f0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["G","G","G"],"produces":"G","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["G","G","G"],"produces":"G","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deconstruct translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('liturgy of blood', 'Liturgy of Blood', '793a1d6947010edec6e943eef9da9139', 'battle_rule_v1:7f91b8beaa5f42a0d97e520e388ab01a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["B","B","B"],"produces":"B","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["B","B","B"],"produces":"B","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LiturgyOfBlood translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('seismic spike', 'Seismic Spike', '6ed975bb71da90e04ccbff411312aa15', 'battle_rule_v1:dd8dce7535424809092d8737ac86ce3f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":2,"produced_mana_symbols":["R","R"],"produces":"R","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":2,"produced_mana_symbols":["R","R"],"produces":"R","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SeismicSpike translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('turn to dust', 'Turn to Dust', '32481b22834ca33b610c00906439c510', 'battle_rule_v1:f4a9e330eee70bed3982dcb7d586e238', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":1,"produced_mana_symbols":["G"],"produces":"G","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":1,"produced_mana_symbols":["G"],"produces":"G","resolution_order":"destroy_then_add_mana","sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TurnToDust translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('deconstruct', 'Deconstruct', '08f659e0e917ed1ddb367a9c86897b45', 'battle_rule_v1:3c02c24a2346797911c20945d2f1a9f0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["G","G","G"],"produces":"G","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["G","G","G"],"produces":"G","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"artifact"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Deconstruct translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('liturgy of blood', 'Liturgy of Blood', '793a1d6947010edec6e943eef9da9139', 'battle_rule_v1:7f91b8beaa5f42a0d97e520e388ab01a', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["B","B","B"],"produces":"B","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":3,"produced_mana_symbols":["B","B","B"],"produces":"B","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LiturgyOfBlood translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('seismic spike', 'Seismic Spike', '6ed975bb71da90e04ccbff411312aa15', 'battle_rule_v1:dd8dce7535424809092d8737ac86ce3f', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":2,"produced_mana_symbols":["R","R"],"produces":"R","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":2,"produced_mana_symbols":["R","R"],"produces":"R","resolution_order":"destroy_then_add_mana","sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SeismicSpike translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('turn to dust', 'Turn to Dust', '32481b22834ca33b610c00906439c510', 'battle_rule_v1:f4a9e330eee70bed3982dcb7d586e238', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"xmage_effect_class":"DestroyTargetEffect"},{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","compose_on_resolution":true,"effect":"ramp_ritual","mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":1,"produced_mana_symbols":["G"],"produces":"G","xmage_effect_class":"BasicManaEffect"}],"battle_model_scope":"xmage_destroy_target_and_fixed_mana_ritual_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":1,"produced_mana_symbols":["G"],"produces":"G","resolution_order":"destroy_then_add_mana","sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"xmage_effect_classes":["DestroyTargetEffect","BasicManaEffect"]}'::jsonb, '{"category":"removal","effect":"composite_resolution","subtype":"removal_mana_ritual","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TurnToDust translated into ManaLoom runtime scope xmage_destroy_target_and_fixed_mana_ritual_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
