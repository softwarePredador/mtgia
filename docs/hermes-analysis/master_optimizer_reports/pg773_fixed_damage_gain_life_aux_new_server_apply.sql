BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg773_fixed_damage_gain_life_aux_new_ser_20260711_163104 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('covenant of blood', 'morbid hunger', 'sacred fire', 'smiting helix')
   OR normalized_name LIKE 'covenant of blood // %'
   OR normalized_name LIKE 'morbid hunger // %'
   OR normalized_name LIKE 'sacred fire // %'
   OR normalized_name LIKE 'smiting helix // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('covenant of blood', 'Covenant of Blood', '3078c7de0c521cf7eac1c270c9dca14d', 'battle_rule_v1:1d56c7af6c995b8069895ee5a393b1b5', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CovenantOfBlood translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('morbid hunger', 'Morbid Hunger', '7fd13135e141b86b8bedb5e8514c84ea', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MorbidHunger translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sacred fire', 'Sacred Fire', '01744899f441b865255babb401800d03', 'battle_rule_v1:a418fd54ddc848bbd76a905f5c9b1932', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SacredFire translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('smiting helix', 'Smiting Helix', 'dbacf397ee08702c65c9991ecf169643', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SmitingHelix translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('covenant of blood', 'Covenant of Blood', '3078c7de0c521cf7eac1c270c9dca14d', 'battle_rule_v1:1d56c7af6c995b8069895ee5a393b1b5', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CovenantOfBlood translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('morbid hunger', 'Morbid Hunger', '7fd13135e141b86b8bedb5e8514c84ea', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MorbidHunger translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sacred fire', 'Sacred Fire', '01744899f441b865255babb401800d03', 'battle_rule_v1:a418fd54ddc848bbd76a905f5c9b1932', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SacredFire translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('smiting helix', 'Smiting Helix', 'dbacf397ee08702c65c9991ecf169643', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SmitingHelix translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('covenant of blood', 'Covenant of Blood', '3078c7de0c521cf7eac1c270c9dca14d', 'battle_rule_v1:1d56c7af6c995b8069895ee5a393b1b5', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":4,"damage":4,"effect":"direct_damage","gain_life":4,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CovenantOfBlood translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('morbid hunger', 'Morbid Hunger', '7fd13135e141b86b8bedb5e8514c84ea', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MorbidHunger translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sacred fire', 'Sacred Fire', '01744899f441b865255babb401800d03', 'battle_rule_v1:a418fd54ddc848bbd76a905f5c9b1932', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":2,"damage":2,"effect":"direct_damage","gain_life":2,"instant":true,"sorcery":false,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SacredFire translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('smiting helix', 'Smiting Helix', 'dbacf397ee08702c65c9991ecf169643', 'battle_rule_v1:c1efa9874143362f23fce5bed164f104', '{"amount":3,"battle_model_scope":"xmage_fixed_damage_target_and_controller_gain_life_spell_v1","controller_gain_life":3,"damage":3,"effect":"direct_damage","gain_life":3,"instant":false,"sorcery":true,"target":"any_target","target_constraints":{"scope":"any_target"},"xmage_effect_classes":["DamageTargetEffect","GainLifeEffect"]}'::jsonb, '{"category":"unknown","effect":"direct_damage","target":"any_target"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SmitingHelix translated into ManaLoom runtime scope xmage_fixed_damage_target_and_controller_gain_life_spell_v1. This row is package-ready only because the source signature is a narrow fixed damage plus controller life-gain spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
