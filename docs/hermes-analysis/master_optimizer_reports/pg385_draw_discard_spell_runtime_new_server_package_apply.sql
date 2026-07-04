BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg385_draw_discard_spell_runtime_new_server_20260704_051 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('ancestral reminiscence', 'careful study', 'catalog', 'enhanced awareness', 'prying eyes', 'rain of revelation', 'romantic rendezvous', 'sift', 'thoughtflare')
   OR normalized_name LIKE 'ancestral reminiscence // %'
   OR normalized_name LIKE 'careful study // %'
   OR normalized_name LIKE 'catalog // %'
   OR normalized_name LIKE 'enhanced awareness // %'
   OR normalized_name LIKE 'prying eyes // %'
   OR normalized_name LIKE 'rain of revelation // %'
   OR normalized_name LIKE 'romantic rendezvous // %'
   OR normalized_name LIKE 'sift // %'
   OR normalized_name LIKE 'thoughtflare // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ancestral reminiscence', 'Ancestral Reminiscence', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:73912a4129ba131351a7d72087514070', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncestralReminiscence translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('careful study', 'Careful Study', 'bbc40777c44eb8cca3e6a811ad954178', 'battle_rule_v1:0d2aaf58fe699e4cc5b5c7ebc69a05c1', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":2,"discard_random":false,"draw_count":2,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarefulStudy translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('catalog', 'Catalog', '6948b1421f25b941d769532459028061', 'battle_rule_v1:63b054fc75d44178f8bd4b286a0cbdba', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":1,"discard_random":false,"draw_count":2,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Catalog translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('enhanced awareness', 'Enhanced Awareness', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:23c289099aa3f2dabbfeb727d7d654f2', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnhancedAwareness translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prying eyes', 'Prying Eyes', '6b2ee39107b1b3039a3324c430e6f271', 'battle_rule_v1:7807f21b39fea1cfb17ed8edf4ed891a', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":4,"discard_count":2,"discard_random":false,"draw_count":4,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PryingEyes translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rain of revelation', 'Rain of Revelation', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:23c289099aa3f2dabbfeb727d7d654f2', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainOfRevelation translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('romantic rendezvous', 'Romantic Rendezvous', 'aff53f567af23b5e9fcd03939b26340f', 'battle_rule_v1:2baba243f445a0a2e3e5983394657313', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":1,"discard_random":false,"draw_count":2,"draw_discard_order":"discard_then_draw","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RomanticRendezvous translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sift', 'Sift', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:73912a4129ba131351a7d72087514070', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sift translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thoughtflare', 'Thoughtflare', '6b2ee39107b1b3039a3324c430e6f271', 'battle_rule_v1:ebc0a01d26b567480a2f083009f64ec3', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":4,"discard_count":2,"discard_random":false,"draw_count":4,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Thoughtflare translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ancestral reminiscence', 'Ancestral Reminiscence', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:73912a4129ba131351a7d72087514070', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncestralReminiscence translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('careful study', 'Careful Study', 'bbc40777c44eb8cca3e6a811ad954178', 'battle_rule_v1:0d2aaf58fe699e4cc5b5c7ebc69a05c1', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":2,"discard_random":false,"draw_count":2,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarefulStudy translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('catalog', 'Catalog', '6948b1421f25b941d769532459028061', 'battle_rule_v1:63b054fc75d44178f8bd4b286a0cbdba', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":1,"discard_random":false,"draw_count":2,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Catalog translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('enhanced awareness', 'Enhanced Awareness', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:23c289099aa3f2dabbfeb727d7d654f2', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnhancedAwareness translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prying eyes', 'Prying Eyes', '6b2ee39107b1b3039a3324c430e6f271', 'battle_rule_v1:7807f21b39fea1cfb17ed8edf4ed891a', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":4,"discard_count":2,"discard_random":false,"draw_count":4,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PryingEyes translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rain of revelation', 'Rain of Revelation', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:23c289099aa3f2dabbfeb727d7d654f2', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainOfRevelation translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('romantic rendezvous', 'Romantic Rendezvous', 'aff53f567af23b5e9fcd03939b26340f', 'battle_rule_v1:2baba243f445a0a2e3e5983394657313', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":1,"discard_random":false,"draw_count":2,"draw_discard_order":"discard_then_draw","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RomanticRendezvous translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sift', 'Sift', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:73912a4129ba131351a7d72087514070', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sift translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thoughtflare', 'Thoughtflare', '6b2ee39107b1b3039a3324c430e6f271', 'battle_rule_v1:ebc0a01d26b567480a2f083009f64ec3', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":4,"discard_count":2,"discard_random":false,"draw_count":4,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Thoughtflare translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('ancestral reminiscence', 'Ancestral Reminiscence', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:73912a4129ba131351a7d72087514070', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncestralReminiscence translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('careful study', 'Careful Study', 'bbc40777c44eb8cca3e6a811ad954178', 'battle_rule_v1:0d2aaf58fe699e4cc5b5c7ebc69a05c1', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":2,"discard_random":false,"draw_count":2,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarefulStudy translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('catalog', 'Catalog', '6948b1421f25b941d769532459028061', 'battle_rule_v1:63b054fc75d44178f8bd4b286a0cbdba', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":1,"discard_random":false,"draw_count":2,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Catalog translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('enhanced awareness', 'Enhanced Awareness', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:23c289099aa3f2dabbfeb727d7d654f2', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnhancedAwareness translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prying eyes', 'Prying Eyes', '6b2ee39107b1b3039a3324c430e6f271', 'battle_rule_v1:7807f21b39fea1cfb17ed8edf4ed891a', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":4,"discard_count":2,"discard_random":false,"draw_count":4,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PryingEyes translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rain of revelation', 'Rain of Revelation', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:23c289099aa3f2dabbfeb727d7d654f2', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RainOfRevelation translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('romantic rendezvous', 'Romantic Rendezvous', 'aff53f567af23b5e9fcd03939b26340f', 'battle_rule_v1:2baba243f445a0a2e3e5983394657313', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":2,"discard_count":1,"discard_random":false,"draw_count":2,"draw_discard_order":"discard_then_draw","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RomanticRendezvous translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sift', 'Sift', 'dc9032001a319c70dbf9acdf0b806db0', 'battle_rule_v1:73912a4129ba131351a7d72087514070', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":1,"discard_random":false,"draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Sift translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thoughtflare', 'Thoughtflare', '6b2ee39107b1b3039a3324c430e6f271', 'battle_rule_v1:ebc0a01d26b567480a2f083009f64ec3', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":4,"discard_count":2,"discard_random":false,"draw_count":4,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawDiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Thoughtflare translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
