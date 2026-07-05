BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg491_self_etb_bounce_new_server_20260705_075431 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('deputy of acquittals', 'exosuit savior', 'jeskai barricade', 'mischievous pup', 'rimekin recluse', 'stickytongue sentinel')
   OR normalized_name LIKE 'deputy of acquittals // %'
   OR normalized_name LIKE 'exosuit savior // %'
   OR normalized_name LIKE 'jeskai barricade // %'
   OR normalized_name LIKE 'mischievous pup // %'
   OR normalized_name LIKE 'rimekin recluse // %'
   OR normalized_name LIKE 'stickytongue sentinel // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deputy of acquittals', 'Deputy of Acquittals', '8658050003924c8990794806bcf34c88', 'battle_rule_v1:493e0ab5c91fdbd60a0fda3532814452', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flash":true,"keywords":["flash"],"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeputyOfAcquittals translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exosuit savior', 'Exosuit Savior', '4b1f906a2af79e08338a65d5700bc5cd', 'battle_rule_v1:692686d146f19ec536fb0704620e44cd', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"flying":true,"keywords":["flying"],"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExosuitSavior translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jeskai barricade', 'Jeskai Barricade', 'ca71ecc80d1273684e448324fdfd168a', 'battle_rule_v1:661b62cfa162aee53b66adff80c17e78', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","defender":true,"destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flash":true,"keywords":["flash","defender"],"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JeskaiBarricade translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischievous pup', 'Mischievous Pup', 'ea8a2a09c160913a1ad518e6b9d3711b', 'battle_rule_v1:7d59845fceced1b041f0de871f39d129', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"flash":true,"keywords":["flash"],"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischievousPup translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rimekin recluse', 'Rimekin Recluse', '79d7243258226d60ebdf5c3170702002', 'battle_rule_v1:2f1ca7f8841212e091a523ec4c6d1471', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RimekinRecluse translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stickytongue sentinel', 'Stickytongue Sentinel', '4b53aac3ac2fe4a7437abe425ee751f6', 'battle_rule_v1:6768ad939d7a940cece11d406c451774', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"keywords":["reach"],"reach":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StickytongueSentinel translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('deputy of acquittals', 'Deputy of Acquittals', '8658050003924c8990794806bcf34c88', 'battle_rule_v1:493e0ab5c91fdbd60a0fda3532814452', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flash":true,"keywords":["flash"],"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeputyOfAcquittals translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exosuit savior', 'Exosuit Savior', '4b1f906a2af79e08338a65d5700bc5cd', 'battle_rule_v1:692686d146f19ec536fb0704620e44cd', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"flying":true,"keywords":["flying"],"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExosuitSavior translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jeskai barricade', 'Jeskai Barricade', 'ca71ecc80d1273684e448324fdfd168a', 'battle_rule_v1:661b62cfa162aee53b66adff80c17e78', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","defender":true,"destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flash":true,"keywords":["flash","defender"],"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JeskaiBarricade translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischievous pup', 'Mischievous Pup', 'ea8a2a09c160913a1ad518e6b9d3711b', 'battle_rule_v1:7d59845fceced1b041f0de871f39d129', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"flash":true,"keywords":["flash"],"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischievousPup translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rimekin recluse', 'Rimekin Recluse', '79d7243258226d60ebdf5c3170702002', 'battle_rule_v1:2f1ca7f8841212e091a523ec4c6d1471', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RimekinRecluse translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stickytongue sentinel', 'Stickytongue Sentinel', '4b53aac3ac2fe4a7437abe425ee751f6', 'battle_rule_v1:6768ad939d7a940cece11d406c451774', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"keywords":["reach"],"reach":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StickytongueSentinel translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('deputy of acquittals', 'Deputy of Acquittals', '8658050003924c8990794806bcf34c88', 'battle_rule_v1:493e0ab5c91fdbd60a0fda3532814452', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flash":true,"keywords":["flash"],"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeputyOfAcquittals translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exosuit savior', 'Exosuit Savior', '4b1f906a2af79e08338a65d5700bc5cd', 'battle_rule_v1:692686d146f19ec536fb0704620e44cd', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"flying":true,"keywords":["flying"],"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExosuitSavior translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jeskai barricade', 'Jeskai Barricade', 'ca71ecc80d1273684e448324fdfd168a', 'battle_rule_v1:661b62cfa162aee53b66adff80c17e78', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","defender":true,"destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flash":true,"keywords":["flash","defender"],"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JeskaiBarricade translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischievous pup', 'Mischievous Pup', 'ea8a2a09c160913a1ad518e6b9d3711b', 'battle_rule_v1:7d59845fceced1b041f0de871f39d129', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"flash":true,"keywords":["flash"],"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischievousPup translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rimekin recluse', 'Rimekin Recluse', '79d7243258226d60ebdf5c3170702002', 'battle_rule_v1:2f1ca7f8841212e091a523ec4c6d1471', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RimekinRecluse translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stickytongue sentinel', 'Stickytongue Sentinel', '4b53aac3ac2fe4a7437abe425ee751f6', 'battle_rule_v1:6768ad939d7a940cece11d406c451774', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"permanent","exclude_source":true,"keywords":["reach"],"reach":true,"target":"permanent","target_constraints":{"card_types":["permanent"],"controller_scope":"self","exclude_source":true},"target_controller":"self","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StickytongueSentinel translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
