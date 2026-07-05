BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg492_etb_bounce_target_vocabulary_new_s_20260705_080218 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('air-cult elemental', 'guardians of koilos', 'roaming ghostlight', 'winter eladrin')
   OR normalized_name LIKE 'air-cult elemental // %'
   OR normalized_name LIKE 'guardians of koilos // %'
   OR normalized_name LIKE 'roaming ghostlight // %'
   OR normalized_name LIKE 'winter eladrin // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('air-cult elemental', 'Air-Cult Elemental', '00cefdd464d0c7e0783d11ae42a4ca57', 'battle_rule_v1:add0e0805dd63d69ec22ac0c106dfc08', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flying":true,"keywords":["flying"],"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AirCultElemental translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardians of koilos', 'Guardians of Koilos', 'd98db2233ec18e6c04d492d26d91c045', 'battle_rule_v1:f38b5f7861c20bd8bad36225b02e1919', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"historic_permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"historic_permanent","exclude_source":true,"target":"historic_permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["permanent"],"required_supertypes":["legendary"]},{"card_types":["enchantment"],"required_subtypes":["saga"]}],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"historic_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardiansOfKoilos translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roaming ghostlight', 'Roaming Ghostlight', 'bd14f162bc972d608f87fb6cc5e3c2a5', 'battle_rule_v1:f37702fd67802ff846d310a75da27ded', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"non_spirit_creature","etb_remove_effect":"remove_creature","etb_remove_target":"non_spirit_creature","flying":true,"keywords":["flying"],"target":"non_spirit_creature","target_constraints":{"card_types":["creature"],"exclude_subtypes":["spirit"]},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"non_spirit_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoamingGhostlight translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winter eladrin', 'Winter Eladrin', 'aa12b5b95838062b861c58759881cdd2', 'battle_rule_v1:2f1ca7f8841212e091a523ec4c6d1471', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WinterEladrin translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('air-cult elemental', 'Air-Cult Elemental', '00cefdd464d0c7e0783d11ae42a4ca57', 'battle_rule_v1:add0e0805dd63d69ec22ac0c106dfc08', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flying":true,"keywords":["flying"],"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AirCultElemental translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardians of koilos', 'Guardians of Koilos', 'd98db2233ec18e6c04d492d26d91c045', 'battle_rule_v1:f38b5f7861c20bd8bad36225b02e1919', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"historic_permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"historic_permanent","exclude_source":true,"target":"historic_permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["permanent"],"required_supertypes":["legendary"]},{"card_types":["enchantment"],"required_subtypes":["saga"]}],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"historic_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardiansOfKoilos translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roaming ghostlight', 'Roaming Ghostlight', 'bd14f162bc972d608f87fb6cc5e3c2a5', 'battle_rule_v1:f37702fd67802ff846d310a75da27ded', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"non_spirit_creature","etb_remove_effect":"remove_creature","etb_remove_target":"non_spirit_creature","flying":true,"keywords":["flying"],"target":"non_spirit_creature","target_constraints":{"card_types":["creature"],"exclude_subtypes":["spirit"]},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"non_spirit_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoamingGhostlight translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winter eladrin', 'Winter Eladrin', 'aa12b5b95838062b861c58759881cdd2', 'battle_rule_v1:2f1ca7f8841212e091a523ec4c6d1471', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WinterEladrin translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('air-cult elemental', 'Air-Cult Elemental', '00cefdd464d0c7e0783d11ae42a4ca57', 'battle_rule_v1:add0e0805dd63d69ec22ac0c106dfc08', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"flying":true,"keywords":["flying"],"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AirCultElemental translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guardians of koilos', 'Guardians of Koilos', 'd98db2233ec18e6c04d492d26d91c045', 'battle_rule_v1:f38b5f7861c20bd8bad36225b02e1919', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_optional":true,"etb_bounce_target":"historic_permanent","etb_remove_effect":"remove_permanent","etb_remove_target":"historic_permanent","exclude_source":true,"target":"historic_permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["permanent"],"required_supertypes":["legendary"]},{"card_types":["enchantment"],"required_subtypes":["saga"]}],"controller_scope":"self","exclude_source":true},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"historic_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuardiansOfKoilos translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('roaming ghostlight', 'Roaming Ghostlight', 'bd14f162bc972d608f87fb6cc5e3c2a5', 'battle_rule_v1:f37702fd67802ff846d310a75da27ded', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"non_spirit_creature","etb_remove_effect":"remove_creature","etb_remove_target":"non_spirit_creature","flying":true,"keywords":["flying"],"target":"non_spirit_creature","target_constraints":{"card_types":["creature"],"exclude_subtypes":["spirit"]},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"non_spirit_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RoamingGhostlight translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winter eladrin', 'Winter Eladrin', 'aa12b5b95838062b861c58759881cdd2', 'battle_rule_v1:2f1ca7f8841212e091a523ec4c6d1471', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_target_to_hand_v1","destination":"hand","effect":"creature","etb_bounce_target":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","exclude_source":true,"target":"creature","target_constraints":{"card_types":["creature"],"exclude_source":true},"target_controller":"any","target_count":1,"trigger":"enters_battlefield","up_to_count":true,"xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WinterEladrin translated into ManaLoom runtime scope xmage_creature_etb_return_target_to_hand_v1. This row is package-ready only because the source signature is a narrow creature ETB return target permanent to hand trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
