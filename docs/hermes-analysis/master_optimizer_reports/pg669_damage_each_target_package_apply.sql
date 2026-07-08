BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg669_damage_each_target_20260708_191811 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('dual shot', 'furious reprisal', 'jagged lightning', 'pinnacle of rage', 'storm of steel', 'swelter')
   OR normalized_name LIKE 'dual shot // %'
   OR normalized_name LIKE 'furious reprisal // %'
   OR normalized_name LIKE 'jagged lightning // %'
   OR normalized_name LIKE 'pinnacle of rage // %'
   OR normalized_name LIKE 'storm of steel // %'
   OR normalized_name LIKE 'swelter // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dual shot', 'Dual Shot', '6daaff924d8b9f82f1cae620b46fd241', 'battle_rule_v1:842e945d5ea51e4543ecd8893d885a53', '{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":1,"damage_assignment_mode":"each_target","damage_per_target":1,"divided_damage":false,"effect":"multi_target_damage","instant":true,"max_targets":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DualShot translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('furious reprisal', 'Furious Reprisal', '9bd9eb6b5582febd39fe4c14b869e597', 'battle_rule_v1:c1ab7d2e2dd263844aed44f2f2d4957a', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FuriousReprisal translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jagged lightning', 'Jagged Lightning', '56235a14493124e5d85faebf8dcc245b', 'battle_rule_v1:2938db8afb659c7365df1829893a8cbf', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":3,"damage_assignment_mode":"each_target","damage_per_target":3,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JaggedLightning translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pinnacle of rage', 'Pinnacle of Rage', '4ad4ecca3d73471d2abe17e9dabc39bc', 'battle_rule_v1:c8f0c970e5627709918c66013552a0a1', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":3,"damage_assignment_mode":"each_target","damage_per_target":3,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PinnacleOfRage translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm of steel', 'Storm of Steel', '65b87bdad31235af7321ab50fae324f7', 'battle_rule_v1:7f0eaefa9d0a36848db1f9c2db74f696', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormOfSteel translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('swelter', 'Swelter', '2c133f34be23e41ed746a621695a9664', 'battle_rule_v1:e0d02c8b56b4c56167ea3e2e6ade5866', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Swelter translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dual shot', 'Dual Shot', '6daaff924d8b9f82f1cae620b46fd241', 'battle_rule_v1:842e945d5ea51e4543ecd8893d885a53', '{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":1,"damage_assignment_mode":"each_target","damage_per_target":1,"divided_damage":false,"effect":"multi_target_damage","instant":true,"max_targets":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DualShot translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('furious reprisal', 'Furious Reprisal', '9bd9eb6b5582febd39fe4c14b869e597', 'battle_rule_v1:c1ab7d2e2dd263844aed44f2f2d4957a', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FuriousReprisal translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jagged lightning', 'Jagged Lightning', '56235a14493124e5d85faebf8dcc245b', 'battle_rule_v1:2938db8afb659c7365df1829893a8cbf', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":3,"damage_assignment_mode":"each_target","damage_per_target":3,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JaggedLightning translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pinnacle of rage', 'Pinnacle of Rage', '4ad4ecca3d73471d2abe17e9dabc39bc', 'battle_rule_v1:c8f0c970e5627709918c66013552a0a1', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":3,"damage_assignment_mode":"each_target","damage_per_target":3,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PinnacleOfRage translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm of steel', 'Storm of Steel', '65b87bdad31235af7321ab50fae324f7', 'battle_rule_v1:7f0eaefa9d0a36848db1f9c2db74f696', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormOfSteel translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('swelter', 'Swelter', '2c133f34be23e41ed746a621695a9664', 'battle_rule_v1:e0d02c8b56b4c56167ea3e2e6ade5866', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Swelter translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('dual shot', 'Dual Shot', '6daaff924d8b9f82f1cae620b46fd241', 'battle_rule_v1:842e945d5ea51e4543ecd8893d885a53', '{"ability_kind":"one_shot","amount":1,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":1,"damage_assignment_mode":"each_target","damage_per_target":1,"divided_damage":false,"effect":"multi_target_damage","instant":true,"max_targets":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DualShot translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('furious reprisal', 'Furious Reprisal', '9bd9eb6b5582febd39fe4c14b869e597', 'battle_rule_v1:c1ab7d2e2dd263844aed44f2f2d4957a', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FuriousReprisal translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jagged lightning', 'Jagged Lightning', '56235a14493124e5d85faebf8dcc245b', 'battle_rule_v1:2938db8afb659c7365df1829893a8cbf', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":3,"damage_assignment_mode":"each_target","damage_per_target":3,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JaggedLightning translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pinnacle of rage', 'Pinnacle of Rage', '4ad4ecca3d73471d2abe17e9dabc39bc', 'battle_rule_v1:c8f0c970e5627709918c66013552a0a1', '{"ability_kind":"one_shot","amount":3,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":3,"damage_assignment_mode":"each_target","damage_per_target":3,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PinnacleOfRage translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm of steel', 'Storm of Steel', '65b87bdad31235af7321ab50fae324f7', 'battle_rule_v1:7f0eaefa9d0a36848db1f9c2db74f696', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"target_count":2,"target_count_max":2,"target_count_min":1,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormOfSteel translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('swelter', 'Swelter', '2c133f34be23e41ed746a621695a9664', 'battle_rule_v1:e0d02c8b56b4c56167ea3e2e6ade5866', '{"ability_kind":"one_shot","amount":2,"battle_model_scope":"xmage_fixed_damage_each_target_spell_v1","damage":2,"damage_assignment_mode":"each_target","damage_per_target":2,"divided_damage":false,"effect":"multi_target_damage","instant":false,"max_targets":2,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"target_count_min":2,"up_to_count":false,"xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"multi_target_damage","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Swelter translated into ManaLoom runtime scope xmage_fixed_damage_each_target_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
