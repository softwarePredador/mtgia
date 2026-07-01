BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg319_xmage_graveyard_self_return_wave_20260701_170519 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('clay revenant', 'durable coilbug', 'firewing phoenix', 'jungle creeper', 'merchant of many hats', 'sanitarium skeleton')
   OR normalized_name LIKE 'clay revenant // %'
   OR normalized_name LIKE 'durable coilbug // %'
   OR normalized_name LIKE 'firewing phoenix // %'
   OR normalized_name LIKE 'jungle creeper // %'
   OR normalized_name LIKE 'merchant of many hats // %'
   OR normalized_name LIKE 'sanitarium skeleton // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('clay revenant', 'Clay Revenant', 'eda7a643bd39973b1c503a2911e8075c', 'battle_rule_v1:6db80ae97aed2cb8a0254e51b304e59c', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ClayRevenant translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('durable coilbug', 'Durable Coilbug', '629741079e6af2edd2d1cd2048c5c1f6', 'battle_rule_v1:7d15b0674691123c9fd7f56ef65e7605', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":4,"activation_cost_mana":"{4}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":4,"graveyard_self_return_activation_cost_mana":"{4}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DurableCoilbug translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('firewing phoenix', 'Firewing Phoenix', 'da336e9fec070e0aecf2c8ac03cda88e', 'battle_rule_v1:837aa65ddae8b447d7a49da13bd85c20', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["R","R","R"],"activation_cost_generic":1,"activation_cost_mana":"{1}{R}{R}{R}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["R","R","R"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{R}{R}{R}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirewingPhoenix translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungle creeper', 'Jungle Creeper', '440698b16883b0b3e1f91f066a069aa3', 'battle_rule_v1:5b4aab512c66d50d12086d9209691de3', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B","G"],"activation_cost_generic":3,"activation_cost_mana":"{3}{B}{G}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B","G"],"graveyard_self_return_activation_cost_generic":3,"graveyard_self_return_activation_cost_mana":"{3}{B}{G}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JungleCreeper translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merchant of many hats', 'Merchant of Many Hats', '16b5f4fceeb6939c797f294c16143f4a', 'battle_rule_v1:a919f59932e6c68c16a37187f9e52636', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerchantOfManyHats translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanitarium skeleton', 'Sanitarium Skeleton', '16b5f4fceeb6939c797f294c16143f4a', 'battle_rule_v1:a919f59932e6c68c16a37187f9e52636', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanitariumSkeleton translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('clay revenant', 'Clay Revenant', 'eda7a643bd39973b1c503a2911e8075c', 'battle_rule_v1:6db80ae97aed2cb8a0254e51b304e59c', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ClayRevenant translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('durable coilbug', 'Durable Coilbug', '629741079e6af2edd2d1cd2048c5c1f6', 'battle_rule_v1:7d15b0674691123c9fd7f56ef65e7605', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":4,"activation_cost_mana":"{4}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":4,"graveyard_self_return_activation_cost_mana":"{4}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DurableCoilbug translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('firewing phoenix', 'Firewing Phoenix', 'da336e9fec070e0aecf2c8ac03cda88e', 'battle_rule_v1:837aa65ddae8b447d7a49da13bd85c20', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["R","R","R"],"activation_cost_generic":1,"activation_cost_mana":"{1}{R}{R}{R}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["R","R","R"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{R}{R}{R}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirewingPhoenix translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungle creeper', 'Jungle Creeper', '440698b16883b0b3e1f91f066a069aa3', 'battle_rule_v1:5b4aab512c66d50d12086d9209691de3', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B","G"],"activation_cost_generic":3,"activation_cost_mana":"{3}{B}{G}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B","G"],"graveyard_self_return_activation_cost_generic":3,"graveyard_self_return_activation_cost_mana":"{3}{B}{G}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JungleCreeper translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merchant of many hats', 'Merchant of Many Hats', '16b5f4fceeb6939c797f294c16143f4a', 'battle_rule_v1:a919f59932e6c68c16a37187f9e52636', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerchantOfManyHats translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanitarium skeleton', 'Sanitarium Skeleton', '16b5f4fceeb6939c797f294c16143f4a', 'battle_rule_v1:a919f59932e6c68c16a37187f9e52636', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanitariumSkeleton translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('clay revenant', 'Clay Revenant', 'eda7a643bd39973b1c503a2911e8075c', 'battle_rule_v1:6db80ae97aed2cb8a0254e51b304e59c', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ClayRevenant translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('durable coilbug', 'Durable Coilbug', '629741079e6af2edd2d1cd2048c5c1f6', 'battle_rule_v1:7d15b0674691123c9fd7f56ef65e7605', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":4,"activation_cost_mana":"{4}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":4,"graveyard_self_return_activation_cost_mana":"{4}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DurableCoilbug translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('firewing phoenix', 'Firewing Phoenix', 'da336e9fec070e0aecf2c8ac03cda88e', 'battle_rule_v1:837aa65ddae8b447d7a49da13bd85c20', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["R","R","R"],"activation_cost_generic":1,"activation_cost_mana":"{1}{R}{R}{R}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["R","R","R"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{R}{R}{R}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FirewingPhoenix translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungle creeper', 'Jungle Creeper', '440698b16883b0b3e1f91f066a069aa3', 'battle_rule_v1:5b4aab512c66d50d12086d9209691de3', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B","G"],"activation_cost_generic":3,"activation_cost_mana":"{3}{B}{G}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B","G"],"graveyard_self_return_activation_cost_generic":3,"graveyard_self_return_activation_cost_mana":"{3}{B}{G}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JungleCreeper translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merchant of many hats', 'Merchant of Many Hats', '16b5f4fceeb6939c797f294c16143f4a', 'battle_rule_v1:a919f59932e6c68c16a37187f9e52636', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MerchantOfManyHats translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sanitarium skeleton', 'Sanitarium Skeleton', '16b5f4fceeb6939c797f294c16143f4a', 'battle_rule_v1:a919f59932e6c68c16a37187f9e52636', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","activated_effect":"recursion","activation_cost_colors":["B"],"activation_cost_generic":2,"activation_cost_mana":"{2}{B}","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_hand_v1","destination":"hand","effect":"creature","graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":2,"graveyard_self_return_activation_cost_mana":"{2}{B}","graveyard_self_return_destination":"hand","graveyard_self_return_to_hand":true,"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToHandEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SanitariumSkeleton translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_hand_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
