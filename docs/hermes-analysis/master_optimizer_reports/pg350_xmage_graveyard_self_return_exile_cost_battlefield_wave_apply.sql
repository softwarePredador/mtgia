BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg350_xmage_graveyard_self_return_exile_cost_battlefield AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bone dragon', 'despoiler of souls', 'scrapheap scrounger')
   OR normalized_name LIKE 'bone dragon // %'
   OR normalized_name LIKE 'despoiler of souls // %'
   OR normalized_name LIKE 'scrapheap scrounger // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bone dragon', 'Bone Dragon', '9df52a9a4df8a0c3c8fea1ed5067dcba', 'battle_rule_v1:ed192d13af826e2cba9fc1a0193966b9', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B","B"],"activation_cost_generic":3,"activation_cost_mana":"{3}{B}{B}","activation_exile_from_graveyard_count":7,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"any_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["B","B"],"graveyard_self_return_activation_cost_generic":3,"graveyard_self_return_activation_cost_mana":"{3}{B}{B}","graveyard_self_return_activation_exile_from_graveyard_count":7,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"any_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneDragon translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('despoiler of souls', 'Despoiler of Souls', '6da4cbe8dcb147c6ac132e4123adbe80', 'battle_rule_v1:cb987efceb3f6cb411733e0382b5415d', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_exile_from_graveyard_count":2,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"creature_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","cant_block":true,"destination":"battlefield","effect":"creature","enters_tapped":false,"graveyard_self_return_activation_cost_colors":["B","B"],"graveyard_self_return_activation_cost_generic":0,"graveyard_self_return_activation_cost_mana":"{B}{B}","graveyard_self_return_activation_exile_from_graveyard_count":2,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"creature_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"source_zone":"graveyard","static_cant_block":true,"target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DespoilerOfSouls translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scrapheap scrounger', 'Scrapheap Scrounger', 'cec4c3f81a746a934176bc31381355b8', 'battle_rule_v1:b2bcbf2dbafe43780992bc75976967fe', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_exile_from_graveyard_count":1,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"creature_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","cant_block":true,"destination":"battlefield","effect":"creature","enters_tapped":false,"graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{B}","graveyard_self_return_activation_exile_from_graveyard_count":1,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"creature_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"source_zone":"graveyard","static_cant_block":true,"target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrapheapScrounger translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bone dragon', 'Bone Dragon', '9df52a9a4df8a0c3c8fea1ed5067dcba', 'battle_rule_v1:ed192d13af826e2cba9fc1a0193966b9', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B","B"],"activation_cost_generic":3,"activation_cost_mana":"{3}{B}{B}","activation_exile_from_graveyard_count":7,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"any_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["B","B"],"graveyard_self_return_activation_cost_generic":3,"graveyard_self_return_activation_cost_mana":"{3}{B}{B}","graveyard_self_return_activation_exile_from_graveyard_count":7,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"any_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneDragon translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('despoiler of souls', 'Despoiler of Souls', '6da4cbe8dcb147c6ac132e4123adbe80', 'battle_rule_v1:cb987efceb3f6cb411733e0382b5415d', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_exile_from_graveyard_count":2,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"creature_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","cant_block":true,"destination":"battlefield","effect":"creature","enters_tapped":false,"graveyard_self_return_activation_cost_colors":["B","B"],"graveyard_self_return_activation_cost_generic":0,"graveyard_self_return_activation_cost_mana":"{B}{B}","graveyard_self_return_activation_exile_from_graveyard_count":2,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"creature_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"source_zone":"graveyard","static_cant_block":true,"target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DespoilerOfSouls translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scrapheap scrounger', 'Scrapheap Scrounger', 'cec4c3f81a746a934176bc31381355b8', 'battle_rule_v1:b2bcbf2dbafe43780992bc75976967fe', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_exile_from_graveyard_count":1,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"creature_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","cant_block":true,"destination":"battlefield","effect":"creature","enters_tapped":false,"graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{B}","graveyard_self_return_activation_exile_from_graveyard_count":1,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"creature_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"source_zone":"graveyard","static_cant_block":true,"target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrapheapScrounger translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bone dragon', 'Bone Dragon', '9df52a9a4df8a0c3c8fea1ed5067dcba', 'battle_rule_v1:ed192d13af826e2cba9fc1a0193966b9', '{"_keywords_are_self":true,"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B","B"],"activation_cost_generic":3,"activation_cost_mana":"{3}{B}{B}","activation_exile_from_graveyard_count":7,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"any_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","destination":"battlefield","effect":"creature","enters_tapped":true,"graveyard_self_return_activation_cost_colors":["B","B"],"graveyard_self_return_activation_cost_generic":3,"graveyard_self_return_activation_cost_mana":"{3}{B}{B}","graveyard_self_return_activation_exile_from_graveyard_count":7,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"any_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"keywords":["flying"],"source_zone":"graveyard","target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoneDragon translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('despoiler of souls', 'Despoiler of Souls', '6da4cbe8dcb147c6ac132e4123adbe80', 'battle_rule_v1:cb987efceb3f6cb411733e0382b5415d', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B","B"],"activation_cost_generic":0,"activation_cost_mana":"{B}{B}","activation_exile_from_graveyard_count":2,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"creature_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","cant_block":true,"destination":"battlefield","effect":"creature","enters_tapped":false,"graveyard_self_return_activation_cost_colors":["B","B"],"graveyard_self_return_activation_cost_generic":0,"graveyard_self_return_activation_cost_mana":"{B}{B}","graveyard_self_return_activation_exile_from_graveyard_count":2,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"creature_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"source_zone":"graveyard","static_cant_block":true,"target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DespoilerOfSouls translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scrapheap scrounger', 'Scrapheap Scrounger', 'cec4c3f81a746a934176bc31381355b8', 'battle_rule_v1:b2bcbf2dbafe43780992bc75976967fe', '{"ability_kind":"graveyard_activated","activated_battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","activated_effect":"recursion","activation_additional_cost":"exile_from_graveyard","activation_cost_colors":["B"],"activation_cost_generic":1,"activation_cost_mana":"{1}{B}","activation_exile_from_graveyard_count":1,"activation_exile_from_graveyard_other":true,"activation_exile_from_graveyard_target":"creature_card","battle_model_scope":"xmage_graveyard_simple_activated_self_return_to_battlefield_v1","cant_block":true,"destination":"battlefield","effect":"creature","enters_tapped":false,"graveyard_self_return_activation_cost_colors":["B"],"graveyard_self_return_activation_cost_generic":1,"graveyard_self_return_activation_cost_mana":"{1}{B}","graveyard_self_return_activation_exile_from_graveyard_count":1,"graveyard_self_return_activation_exile_from_graveyard_other":true,"graveyard_self_return_activation_exile_from_graveyard_target":"creature_card","graveyard_self_return_destination":"battlefield","graveyard_self_return_to_battlefield":true,"source_zone":"graveyard","static_cant_block":true,"target":"self","target_controller":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"ReturnSourceFromGraveyardToBattlefieldEffect"}'::jsonb, '{"category":"engine","effect":"creature","subtype":"recursive_threat","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrapheapScrounger translated into ManaLoom runtime scope xmage_graveyard_simple_activated_self_return_to_battlefield_v1. This row is package-ready only because the source signature is a narrow graveyard simple activated self-return-to-battlefield ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
