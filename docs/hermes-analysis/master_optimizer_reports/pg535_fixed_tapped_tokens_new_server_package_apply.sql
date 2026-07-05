BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg535_fixed_tapped_tokens_new_server_pg5_20260705_230150 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('servo exhibition', 'shadow summoning')
   OR normalized_name LIKE 'servo exhibition // %'
   OR normalized_name LIKE 'shadow summoning // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('servo exhibition', 'Servo Exhibition', '986014963b1bb2a9361b04c58130bfca', 'battle_rule_v1:34867bd8005e3b1fb592b3dfb9a585ed', '{"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_count":2,"token_description":"1/1 colorless Servo artifact creature token","token_name":"Servo Token","token_power":1,"token_subtype":"Servo","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ServoToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ServoExhibition translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shadow summoning', 'Shadow Summoning', '86865fd932dbac3129e8d1060691bc0d', 'battle_rule_v1:e4509add508bcaf39e79f2811c958b41', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Spirit creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Spirit Token","token_power":1,"token_subtype":"Spirit","token_tapped":true,"token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiritWhiteToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShadowSummoning translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('servo exhibition', 'Servo Exhibition', '986014963b1bb2a9361b04c58130bfca', 'battle_rule_v1:34867bd8005e3b1fb592b3dfb9a585ed', '{"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_count":2,"token_description":"1/1 colorless Servo artifact creature token","token_name":"Servo Token","token_power":1,"token_subtype":"Servo","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ServoToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ServoExhibition translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shadow summoning', 'Shadow Summoning', '86865fd932dbac3129e8d1060691bc0d', 'battle_rule_v1:e4509add508bcaf39e79f2811c958b41', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Spirit creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Spirit Token","token_power":1,"token_subtype":"Spirit","token_tapped":true,"token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiritWhiteToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShadowSummoning translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('servo exhibition', 'Servo Exhibition', '986014963b1bb2a9361b04c58130bfca', 'battle_rule_v1:34867bd8005e3b1fb592b3dfb9a585ed', '{"ability_kind":"one_shot","artifact_tokens":true,"battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_count":2,"token_description":"1/1 colorless Servo artifact creature token","token_name":"Servo Token","token_power":1,"token_subtype":"Servo","token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"ServoToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ServoExhibition translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shadow summoning', 'Shadow Summoning', '86865fd932dbac3129e8d1060691bc0d', 'battle_rule_v1:e4509add508bcaf39e79f2811c958b41', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_create_creature_tokens_spell_v1","effect":"token_maker","token_colors":["W"],"token_count":2,"token_description":"1/1 white Spirit creature token with flying","token_flying":true,"token_keywords":["flying"],"token_name":"Spirit Token","token_power":1,"token_subtype":"Spirit","token_tapped":true,"token_toughness":1,"xmage_effect_class":"CreateTokenEffect","xmage_token_class":"SpiritWhiteToken"}'::jsonb, '{"category":"wincon","effect":"token_maker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShadowSummoning translated into ManaLoom runtime scope xmage_fixed_create_creature_tokens_spell_v1. This row is package-ready only because the source signature is a narrow fixed spell-resolution creature-token maker with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
