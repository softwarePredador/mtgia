BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg339_xmage_etb_library_pick_wave_pg339_xmage_etb_librar AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('organ hoarder', 'sibsig appraiser', 'sultai soothsayer', 'tower geist')
   OR normalized_name LIKE 'organ hoarder // %'
   OR normalized_name LIKE 'sibsig appraiser // %'
   OR normalized_name LIKE 'sultai soothsayer // %'
   OR normalized_name LIKE 'tower geist // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('organ hoarder', 'Organ Hoarder', 'c2f297be9e3d0e06dae49b218bf06dc4', 'battle_rule_v1:c78db6f977f2c197ed392b09b6b27854', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":3,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrganHoarder translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sibsig appraiser', 'Sibsig Appraiser', '9d408a209761378f0e6775b2bc1ecaa8', 'battle_rule_v1:b9536bcbbd85f20b8378e7de12d75f0a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":2,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SibsigAppraiser translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sultai soothsayer', 'Sultai Soothsayer', 'bb52caa787d5f836bd84a6ba9d3417ca', 'battle_rule_v1:5527f31e2c1daa1ee88e56c071123e92', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":4,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SultaiSoothsayer translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tower geist', 'Tower Geist', '9522ce486df1ae011dc33de1955e5094', 'battle_rule_v1:ce47d20396337f2e63bd4298947f9873', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":2,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","flying":true,"keywords":["flying"],"rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TowerGeist translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('organ hoarder', 'Organ Hoarder', 'c2f297be9e3d0e06dae49b218bf06dc4', 'battle_rule_v1:c78db6f977f2c197ed392b09b6b27854', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":3,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrganHoarder translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sibsig appraiser', 'Sibsig Appraiser', '9d408a209761378f0e6775b2bc1ecaa8', 'battle_rule_v1:b9536bcbbd85f20b8378e7de12d75f0a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":2,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SibsigAppraiser translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sultai soothsayer', 'Sultai Soothsayer', 'bb52caa787d5f836bd84a6ba9d3417ca', 'battle_rule_v1:5527f31e2c1daa1ee88e56c071123e92', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":4,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SultaiSoothsayer translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tower geist', 'Tower Geist', '9522ce486df1ae011dc33de1955e5094', 'battle_rule_v1:ce47d20396337f2e63bd4298947f9873', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":2,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","flying":true,"keywords":["flying"],"rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TowerGeist translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('organ hoarder', 'Organ Hoarder', 'c2f297be9e3d0e06dae49b218bf06dc4', 'battle_rule_v1:c78db6f977f2c197ed392b09b6b27854', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":3,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class OrganHoarder translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sibsig appraiser', 'Sibsig Appraiser', '9d408a209761378f0e6775b2bc1ecaa8', 'battle_rule_v1:b9536bcbbd85f20b8378e7de12d75f0a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":2,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SibsigAppraiser translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sultai soothsayer', 'Sultai Soothsayer', 'bb52caa787d5f836bd84a6ba9d3417ca', 'battle_rule_v1:5527f31e2c1daa1ee88e56c071123e92', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":4,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SultaiSoothsayer translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tower geist', 'Tower Geist', '9522ce486df1ae011dc33de1955e5094', 'battle_rule_v1:ce47d20396337f2e63bd4298947f9873', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1","destination":"hand","effect":"creature","etb_library_look_count":2,"etb_library_pick_count":1,"etb_library_pick_target":"any_card","etb_library_rest_destination":"graveyard","flying":true,"keywords":["flying"],"rest_destination":"graveyard","target":"any_card","target_constraints":{"controller":"self","scope":"any_card","zone":"library"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"LookLibraryAndPickControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TowerGeist translated into ManaLoom runtime scope xmage_creature_etb_look_library_pick_to_hand_rest_graveyard_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
