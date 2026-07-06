BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg559_spell_cast_gain_life_new_server_sp_20260706_100650 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('contemplation', 'dawnhart geist', 'god-pharaoh''s faithful', 'student of ojutai')
   OR normalized_name LIKE 'contemplation // %'
   OR normalized_name LIKE 'dawnhart geist // %'
   OR normalized_name LIKE 'god-pharaoh''s faithful // %'
   OR normalized_name LIKE 'student of ojutai // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('contemplation', 'Contemplation', 'd55138f0e38ce89501241de5118b997a', 'battle_rule_v1:63c245df679aa19fe5b18d2e9918493c', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Contemplation translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dawnhart geist', 'Dawnhart Geist', '39601a26e7cf06160f3dc44a7a719c47', 'battle_rule_v1:bd9635bdd9fdd90b5cf30c626862d4cb', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":2,"spell_cast_gain_life_card_types":["enchantment"],"spell_cast_gain_life_optional":false,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DawnhartGeist translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('god-pharaoh''s faithful', 'God-Pharaoh''s Faithful', 'ef011c7c90c65d91e901cd0fee8838ee', 'battle_rule_v1:95ab090f9dbca17d324bda0a4506f2da', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["U","B","R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GodPharaohsFaithful translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('student of ojutai', 'Student of Ojutai', '0e76bf14b5b22dd719205302193597cf', 'battle_rule_v1:f23e82b45102a808ec3347df3b9e20db', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":2,"spell_cast_gain_life_optional":false,"trigger":"noncreature_spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StudentOfOjutai translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('contemplation', 'Contemplation', 'd55138f0e38ce89501241de5118b997a', 'battle_rule_v1:63c245df679aa19fe5b18d2e9918493c', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Contemplation translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dawnhart geist', 'Dawnhart Geist', '39601a26e7cf06160f3dc44a7a719c47', 'battle_rule_v1:bd9635bdd9fdd90b5cf30c626862d4cb', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":2,"spell_cast_gain_life_card_types":["enchantment"],"spell_cast_gain_life_optional":false,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DawnhartGeist translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('god-pharaoh''s faithful', 'God-Pharaoh''s Faithful', 'ef011c7c90c65d91e901cd0fee8838ee', 'battle_rule_v1:95ab090f9dbca17d324bda0a4506f2da', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["U","B","R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GodPharaohsFaithful translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('student of ojutai', 'Student of Ojutai', '0e76bf14b5b22dd719205302193597cf', 'battle_rule_v1:f23e82b45102a808ec3347df3b9e20db', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":2,"spell_cast_gain_life_optional":false,"trigger":"noncreature_spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StudentOfOjutai translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('contemplation', 'Contemplation', 'd55138f0e38ce89501241de5118b997a', 'battle_rule_v1:63c245df679aa19fe5b18d2e9918493c', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"life_gain_engine","spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"life_gain_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Contemplation translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dawnhart geist', 'Dawnhart Geist', '39601a26e7cf06160f3dc44a7a719c47', 'battle_rule_v1:bd9635bdd9fdd90b5cf30c626862d4cb', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":2,"spell_cast_gain_life_card_types":["enchantment"],"spell_cast_gain_life_optional":false,"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DawnhartGeist translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('god-pharaoh''s faithful', 'God-Pharaoh''s Faithful', 'ef011c7c90c65d91e901cd0fee8838ee', 'battle_rule_v1:95ab090f9dbca17d324bda0a4506f2da', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":1,"spell_cast_gain_life_optional":false,"spell_cast_gain_life_required_colors":["U","B","R"],"trigger":"spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GodPharaohsFaithful translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('student of ojutai', 'Student of Ojutai', '0e76bf14b5b22dd719205302193597cf', 'battle_rule_v1:f23e82b45102a808ec3347df3b9e20db', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_gain_life_v1","effect":"creature","is_creature_permanent":true,"spell_cast_gain_life":true,"spell_cast_gain_life_amount":2,"spell_cast_gain_life_optional":false,"trigger":"noncreature_spell_cast","trigger_effect":"gain_life","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StudentOfOjutai translated into ManaLoom runtime scope xmage_spell_cast_gain_life_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
