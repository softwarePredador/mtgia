BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.xmage_pg520_counter_unless_pays_new_serv_20260705_174428 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('convolute', 'force spike', 'it''ll quench ya!', 'mana tithe', 'mindstatic', 'quench', 'revolutionary rebuff')
   OR normalized_name LIKE 'convolute // %'
   OR normalized_name LIKE 'force spike // %'
   OR normalized_name LIKE 'it''ll quench ya! // %'
   OR normalized_name LIKE 'mana tithe // %'
   OR normalized_name LIKE 'mindstatic // %'
   OR normalized_name LIKE 'quench // %'
   OR normalized_name LIKE 'revolutionary rebuff // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('convolute', 'Convolute', '28e054de37811a5a6c69c182c2a8133f', 'battle_rule_v1:f19dd7a4fca383cf6666d63219dfc95e', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":4,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Convolute translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('force spike', 'Force Spike', 'e980b1e22d76bcc7a902a7bd4494f2c2', 'battle_rule_v1:aa6da9f509ac3ac59eedf048d8c4dfa8', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForceSpike translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('it''ll quench ya!', 'It''ll Quench Ya!', 'd541d6d83519c2147cb2c08404e238e3', 'battle_rule_v1:3b33285d9ff753c4c630cd7e0b756cd0', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ItllQuenchYa translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mana tithe', 'Mana Tithe', 'e980b1e22d76bcc7a902a7bd4494f2c2', 'battle_rule_v1:aa6da9f509ac3ac59eedf048d8c4dfa8', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ManaTithe translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mindstatic', 'Mindstatic', '31d9fa82432680ed5ed8472451543989', 'battle_rule_v1:fd343c6b32cba13d335821c7cb12913f', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":6,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Mindstatic translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quench', 'Quench', 'd541d6d83519c2147cb2c08404e238e3', 'battle_rule_v1:3b33285d9ff753c4c630cd7e0b756cd0', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Quench translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revolutionary rebuff', 'Revolutionary Rebuff', '4bde1d5613deab8c0f70b20b7d9ab2e7', 'battle_rule_v1:f5b3fcb5be409ce75e90a5bb9838c13d', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"nonartifact_spell","target_constraints":{"exclude_card_types":["artifact"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"nonartifact_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevolutionaryRebuff translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('convolute', 'Convolute', '28e054de37811a5a6c69c182c2a8133f', 'battle_rule_v1:f19dd7a4fca383cf6666d63219dfc95e', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":4,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Convolute translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('force spike', 'Force Spike', 'e980b1e22d76bcc7a902a7bd4494f2c2', 'battle_rule_v1:aa6da9f509ac3ac59eedf048d8c4dfa8', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForceSpike translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('it''ll quench ya!', 'It''ll Quench Ya!', 'd541d6d83519c2147cb2c08404e238e3', 'battle_rule_v1:3b33285d9ff753c4c630cd7e0b756cd0', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ItllQuenchYa translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mana tithe', 'Mana Tithe', 'e980b1e22d76bcc7a902a7bd4494f2c2', 'battle_rule_v1:aa6da9f509ac3ac59eedf048d8c4dfa8', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ManaTithe translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mindstatic', 'Mindstatic', '31d9fa82432680ed5ed8472451543989', 'battle_rule_v1:fd343c6b32cba13d335821c7cb12913f', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":6,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Mindstatic translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quench', 'Quench', 'd541d6d83519c2147cb2c08404e238e3', 'battle_rule_v1:3b33285d9ff753c4c630cd7e0b756cd0', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Quench translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revolutionary rebuff', 'Revolutionary Rebuff', '4bde1d5613deab8c0f70b20b7d9ab2e7', 'battle_rule_v1:f5b3fcb5be409ce75e90a5bb9838c13d', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"nonartifact_spell","target_constraints":{"exclude_card_types":["artifact"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"nonartifact_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevolutionaryRebuff translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('convolute', 'Convolute', '28e054de37811a5a6c69c182c2a8133f', 'battle_rule_v1:f19dd7a4fca383cf6666d63219dfc95e', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":4,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Convolute translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('force spike', 'Force Spike', 'e980b1e22d76bcc7a902a7bd4494f2c2', 'battle_rule_v1:aa6da9f509ac3ac59eedf048d8c4dfa8', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForceSpike translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('it''ll quench ya!', 'It''ll Quench Ya!', 'd541d6d83519c2147cb2c08404e238e3', 'battle_rule_v1:3b33285d9ff753c4c630cd7e0b756cd0', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ItllQuenchYa translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mana tithe', 'Mana Tithe', 'e980b1e22d76bcc7a902a7bd4494f2c2', 'battle_rule_v1:aa6da9f509ac3ac59eedf048d8c4dfa8', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":1,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ManaTithe translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mindstatic', 'Mindstatic', '31d9fa82432680ed5ed8472451543989', 'battle_rule_v1:fd343c6b32cba13d335821c7cb12913f', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":6,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Mindstatic translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quench', 'Quench', 'd541d6d83519c2147cb2c08404e238e3', 'battle_rule_v1:3b33285d9ff753c4c630cd7e0b756cd0', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"spell","target_constraints":{"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Quench translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('revolutionary rebuff', 'Revolutionary Rebuff', '4bde1d5613deab8c0f70b20b7d9ab2e7', 'battle_rule_v1:f5b3fcb5be409ce75e90a5bb9838c13d', '{"battle_model_scope":"xmage_counter_target_spell_unless_controller_pays_generic_v1","counter_unless_pays_generic":2,"effect":"counter","instant":true,"sorcery":false,"target":"nonartifact_spell","target_constraints":{"exclude_card_types":["artifact"],"stack_object":"spell","zone":"stack"},"xmage_effect_class":"CounterUnlessPaysEffect"}'::jsonb, '{"category":"protection","effect":"counter","target":"nonartifact_spell","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevolutionaryRebuff translated into ManaLoom runtime scope xmage_counter_target_spell_unless_controller_pays_generic_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
