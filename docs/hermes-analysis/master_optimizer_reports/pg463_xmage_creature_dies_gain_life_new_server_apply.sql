BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg463_xmage_creature_dies_gain_life_new_server_20260705_ AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('anodet lurker', 'enatu golem', 'grasping longneck', 'guardian automaton', 'highland game', 'onulet', 'tarpan')
   OR normalized_name LIKE 'anodet lurker // %'
   OR normalized_name LIKE 'enatu golem // %'
   OR normalized_name LIKE 'grasping longneck // %'
   OR normalized_name LIKE 'guardian automaton // %'
   OR normalized_name LIKE 'highland game // %'
   OR normalized_name LIKE 'onulet // %'
   OR normalized_name LIKE 'tarpan // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('anodet lurker', 'Anodet Lurker', 'a9c6230631d347882abbe6d015bb06e0', 'battle_rule_v1:758847ca30fb454036cec72854246bb0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":3,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnodetLurker translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('enatu golem', 'Enatu Golem', '8f49e15bfa18c75f0217bc16c17aa6df', 'battle_rule_v1:4a89277d577326cb47ef270db2344cb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":4,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnatuGolem translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grasping longneck', 'Grasping Longneck', '705e45d3be0759b8eaebd4e9f73680fd', 'battle_rule_v1:e7ed4957301a134d003ea8a3c1bc1183', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"keywords":["reach"],"reach":true,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GraspingLongneck translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian automaton', 'Guardian Automaton', 'a9c6230631d347882abbe6d015bb06e0', 'battle_rule_v1:758847ca30fb454036cec72854246bb0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":3,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianAutomaton translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('highland game', 'Highland Game', '796b7be4baaa8b00e7d04b453b468634', 'battle_rule_v1:90ada3943874c40067c8cde4d7e49fdc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HighlandGame translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('onulet', 'Onulet', '796b7be4baaa8b00e7d04b453b468634', 'battle_rule_v1:90ada3943874c40067c8cde4d7e49fdc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Onulet translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tarpan', 'Tarpan', '1fd6a1149d32fb6b4f9ce8e236c1bbc6', 'battle_rule_v1:0f97a1e681aa1afb50c4e774cb9808bd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":1,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tarpan translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('anodet lurker', 'Anodet Lurker', 'a9c6230631d347882abbe6d015bb06e0', 'battle_rule_v1:758847ca30fb454036cec72854246bb0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":3,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnodetLurker translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('enatu golem', 'Enatu Golem', '8f49e15bfa18c75f0217bc16c17aa6df', 'battle_rule_v1:4a89277d577326cb47ef270db2344cb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":4,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnatuGolem translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grasping longneck', 'Grasping Longneck', '705e45d3be0759b8eaebd4e9f73680fd', 'battle_rule_v1:e7ed4957301a134d003ea8a3c1bc1183', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"keywords":["reach"],"reach":true,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GraspingLongneck translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian automaton', 'Guardian Automaton', 'a9c6230631d347882abbe6d015bb06e0', 'battle_rule_v1:758847ca30fb454036cec72854246bb0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":3,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianAutomaton translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('highland game', 'Highland Game', '796b7be4baaa8b00e7d04b453b468634', 'battle_rule_v1:90ada3943874c40067c8cde4d7e49fdc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HighlandGame translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('onulet', 'Onulet', '796b7be4baaa8b00e7d04b453b468634', 'battle_rule_v1:90ada3943874c40067c8cde4d7e49fdc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Onulet translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tarpan', 'Tarpan', '1fd6a1149d32fb6b4f9ce8e236c1bbc6', 'battle_rule_v1:0f97a1e681aa1afb50c4e774cb9808bd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":1,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tarpan translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('anodet lurker', 'Anodet Lurker', 'a9c6230631d347882abbe6d015bb06e0', 'battle_rule_v1:758847ca30fb454036cec72854246bb0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":3,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AnodetLurker translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('enatu golem', 'Enatu Golem', '8f49e15bfa18c75f0217bc16c17aa6df', 'battle_rule_v1:4a89277d577326cb47ef270db2344cb8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":4,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnatuGolem translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grasping longneck', 'Grasping Longneck', '705e45d3be0759b8eaebd4e9f73680fd', 'battle_rule_v1:e7ed4957301a134d003ea8a3c1bc1183', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"keywords":["reach"],"reach":true,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GraspingLongneck translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardian automaton', 'Guardian Automaton', 'a9c6230631d347882abbe6d015bb06e0', 'battle_rule_v1:758847ca30fb454036cec72854246bb0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":3,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardianAutomaton translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('highland game', 'Highland Game', '796b7be4baaa8b00e7d04b453b468634', 'battle_rule_v1:90ada3943874c40067c8cde4d7e49fdc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HighlandGame translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('onulet', 'Onulet', '796b7be4baaa8b00e7d04b453b468634', 'battle_rule_v1:90ada3943874c40067c8cde4d7e49fdc', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":2,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Onulet translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tarpan', 'Tarpan', '1fd6a1149d32fb6b4f9ce8e236c1bbc6', 'battle_rule_v1:0f97a1e681aa1afb50c4e774cb9808bd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_gain_life_v1","effect":"creature","gain_life_when_this_dies":1,"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"GainLifeEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tarpan translated into ManaLoom runtime scope xmage_creature_dies_gain_life_v1. This row is package-ready only because the source signature is a narrow creature dies triggered fixed life-gain ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
