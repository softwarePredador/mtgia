BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg509_xmage_pg509_etb_fixed_damage_targe_20260705_134357 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('geistcatcher''s rig', 'goretusk firebeast', 'unsparing boltcaster', 'viashino pyromancer', 'whiptail moloch')
   OR normalized_name LIKE 'geistcatcher''s rig // %'
   OR normalized_name LIKE 'goretusk firebeast // %'
   OR normalized_name LIKE 'unsparing boltcaster // %'
   OR normalized_name LIKE 'viashino pyromancer // %'
   OR normalized_name LIKE 'whiptail moloch // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('geistcatcher''s rig', 'Geistcatcher''s Rig', 'db3e02163c294694a172feeaf45d88ea', 'battle_rule_v1:9c5990d7e2bffaaa3f9c312f0f11781c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"flying_creature","target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"flying_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GeistcatchersRig translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goretusk firebeast', 'Goretusk Firebeast', '3b2c41e97bcd2e61e7b16ba8797227ad', 'battle_rule_v1:0b3bbe5604fd9bf374462e470c31d1d4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoretuskFirebeast translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unsparing boltcaster', 'Unsparing Boltcaster', '9a46e09738ecdb690d12258849179c96', 'battle_rule_v1:050b3a24d030eff42eae7a9910ac3ce6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":5,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnsparingBoltcaster translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viashino pyromancer', 'Viashino Pyromancer', '0b7677080966557d281ce2381e6ba675', 'battle_rule_v1:60d41dd048c092bca317332544334052', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViashinoPyromancer translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whiptail moloch', 'Whiptail Moloch', 'de709bf2a4de7400cb14e793e6eb0357', 'battle_rule_v1:6d3c745c30c6578b608c0e39feadd8c5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":3,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhiptailMoloch translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('geistcatcher''s rig', 'Geistcatcher''s Rig', 'db3e02163c294694a172feeaf45d88ea', 'battle_rule_v1:9c5990d7e2bffaaa3f9c312f0f11781c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"flying_creature","target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"flying_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GeistcatchersRig translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goretusk firebeast', 'Goretusk Firebeast', '3b2c41e97bcd2e61e7b16ba8797227ad', 'battle_rule_v1:0b3bbe5604fd9bf374462e470c31d1d4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoretuskFirebeast translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unsparing boltcaster', 'Unsparing Boltcaster', '9a46e09738ecdb690d12258849179c96', 'battle_rule_v1:050b3a24d030eff42eae7a9910ac3ce6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":5,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnsparingBoltcaster translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viashino pyromancer', 'Viashino Pyromancer', '0b7677080966557d281ce2381e6ba675', 'battle_rule_v1:60d41dd048c092bca317332544334052', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViashinoPyromancer translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whiptail moloch', 'Whiptail Moloch', 'de709bf2a4de7400cb14e793e6eb0357', 'battle_rule_v1:6d3c745c30c6578b608c0e39feadd8c5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":3,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhiptailMoloch translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('geistcatcher''s rig', 'Geistcatcher''s Rig', 'db3e02163c294694a172feeaf45d88ea', 'battle_rule_v1:9c5990d7e2bffaaa3f9c312f0f11781c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"flying_creature","target":"flying_creature","target_constraints":{"card_types":["creature"],"required_keywords":["flying"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"flying_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GeistcatchersRig translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goretusk firebeast', 'Goretusk Firebeast', '3b2c41e97bcd2e61e7b16ba8797227ad', 'battle_rule_v1:0b3bbe5604fd9bf374462e470c31d1d4', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":4,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoretuskFirebeast translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unsparing boltcaster', 'Unsparing Boltcaster', '9a46e09738ecdb690d12258849179c96', 'battle_rule_v1:050b3a24d030eff42eae7a9910ac3ce6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":5,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnsparingBoltcaster translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('viashino pyromancer', 'Viashino Pyromancer', '0b7677080966557d281ce2381e6ba675', 'battle_rule_v1:60d41dd048c092bca317332544334052', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":2,"etb_damage_target":"player_or_planeswalker","target":"player_or_planeswalker","target_constraints":{"scope":"player_or_planeswalker"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"player_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ViashinoPyromancer translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('whiptail moloch', 'Whiptail Moloch', 'de709bf2a4de7400cb14e793e6eb0357', 'battle_rule_v1:6d3c745c30c6578b608c0e39feadd8c5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_fixed_damage_target_v1","effect":"creature","etb_damage_amount":3,"etb_damage_target":"creature","target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DamageTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WhiptailMoloch translated into ManaLoom runtime scope xmage_creature_etb_fixed_damage_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
