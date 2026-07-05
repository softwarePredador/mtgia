BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg472_xmage_dynamic_graveyard_count_damage_spell_new_ser AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('galvanic bombardment', 'ire of kaminari', 'kindle', 'scrapyard salvo')
   OR normalized_name LIKE 'galvanic bombardment // %'
   OR normalized_name LIKE 'ire of kaminari // %'
   OR normalized_name LIKE 'kindle // %'
   OR normalized_name LIKE 'scrapyard salvo // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('galvanic bombardment', 'Galvanic Bombardment', 'a63030de85a8efbe5d5cfb5812aacad0', 'battle_rule_v1:01661b56bea5a3130cd2584b41e60ad2', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Galvanic Bombardment"],"graveyard_count_scope":"controller_graveyard","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GalvanicBombardment translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ire of kaminari', 'Ire of Kaminari', '7a164fc97eec2cf77b86d03b602ac26c', 'battle_rule_v1:14bbef0a7472d0051f179a1f39198391', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_scope":"controller_graveyard","graveyard_count_subtypes":["arcane"],"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IreOfKaminari translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kindle', 'Kindle', 'daa81fd00aeae9e0b48d50f284a4f46f', 'battle_rule_v1:a9db350295df3f3a11a1a18a541cd671', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Kindle"],"graveyard_count_scope":"all_graveyards","instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kindle translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scrapyard salvo', 'Scrapyard Salvo', '65339ed7621226246a5b84a9f684b333', 'battle_rule_v1:75b7f7990c05194d68d794d77aade7d6', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_types":["artifact"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrapyardSalvo translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('galvanic bombardment', 'Galvanic Bombardment', 'a63030de85a8efbe5d5cfb5812aacad0', 'battle_rule_v1:01661b56bea5a3130cd2584b41e60ad2', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Galvanic Bombardment"],"graveyard_count_scope":"controller_graveyard","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GalvanicBombardment translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ire of kaminari', 'Ire of Kaminari', '7a164fc97eec2cf77b86d03b602ac26c', 'battle_rule_v1:14bbef0a7472d0051f179a1f39198391', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_scope":"controller_graveyard","graveyard_count_subtypes":["arcane"],"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IreOfKaminari translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kindle', 'Kindle', 'daa81fd00aeae9e0b48d50f284a4f46f', 'battle_rule_v1:a9db350295df3f3a11a1a18a541cd671', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Kindle"],"graveyard_count_scope":"all_graveyards","instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kindle translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scrapyard salvo', 'Scrapyard Salvo', '65339ed7621226246a5b84a9f684b333', 'battle_rule_v1:75b7f7990c05194d68d794d77aade7d6', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_types":["artifact"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrapyardSalvo translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('galvanic bombardment', 'Galvanic Bombardment', 'a63030de85a8efbe5d5cfb5812aacad0', 'battle_rule_v1:01661b56bea5a3130cd2584b41e60ad2', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Galvanic Bombardment"],"graveyard_count_scope":"controller_graveyard","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GalvanicBombardment translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ire of kaminari', 'Ire of Kaminari', '7a164fc97eec2cf77b86d03b602ac26c', 'battle_rule_v1:14bbef0a7472d0051f179a1f39198391', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_scope":"controller_graveyard","graveyard_count_subtypes":["arcane"],"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IreOfKaminari translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kindle', 'Kindle', 'daa81fd00aeae9e0b48d50f284a4f46f', 'battle_rule_v1:a9db350295df3f3a11a1a18a541cd671', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":2,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_names":["Kindle"],"graveyard_count_scope":"all_graveyards","instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kindle translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scrapyard salvo', 'Scrapyard Salvo', '65339ed7621226246a5b84a9f684b333', 'battle_rule_v1:75b7f7990c05194d68d794d77aade7d6', '{"amount":0,"battle_model_scope":"xmage_dynamic_graveyard_count_damage_spell_v1","damage":0,"damage_amount_source":"graveyard_card_count","damage_base_amount":0,"damage_per_graveyard_count":1,"effect":"direct_damage","graveyard_count_card_types":["artifact"],"graveyard_count_scope":"controller_graveyard","instant":false,"sorcery":true,"target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrapyardSalvo translated into ManaLoom runtime scope xmage_dynamic_graveyard_count_damage_spell_v1. This row is package-ready only because the source signature is a narrow dynamic graveyard-count damage spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
