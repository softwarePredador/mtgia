BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.xmage_pg500_etb_destroy_static_keywords_20260705_103310 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('acid web spider', 'acidic slime', 'aven cloudchaser', 'cloudchaser eagle', 'manticore', 'rooftop assassin', 'stingblade assassin')
   OR normalized_name LIKE 'acid web spider // %'
   OR normalized_name LIKE 'acidic slime // %'
   OR normalized_name LIKE 'aven cloudchaser // %'
   OR normalized_name LIKE 'cloudchaser eagle // %'
   OR normalized_name LIKE 'manticore // %'
   OR normalized_name LIKE 'rooftop assassin // %'
   OR normalized_name LIKE 'stingblade assassin // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('acid web spider', 'Acid Web Spider', '39c8fb38e89d455204408edef83f8cfe', 'battle_rule_v1:1aa0efe2e139b1b4cfd98f1a96d15f09', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact","keywords":["reach"],"reach":true,"target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcidWebSpider translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('acidic slime', 'Acidic Slime', 'fc9545050669ca9a69c3363f5d092608', 'battle_rule_v1:d6f7486e4c786b9fb3a3ff228eba900f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","deathtouch":true,"destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact_or_enchantment_or_land","keywords":["deathtouch"],"target_constraints":{"card_types":["artifact","enchantment","land"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcidicSlime translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('aven cloudchaser', 'Aven Cloudchaser', '04d4881b78fb84ff7000719294d6782b', 'battle_rule_v1:e2339aebf333937d9a130bfc466caf48', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvenCloudchaser translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloudchaser eagle', 'Cloudchaser Eagle', 'c028fe58460036334805bfbc6fd85e30', 'battle_rule_v1:e2339aebf333937d9a130bfc466caf48', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloudchaserEagle translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('manticore', 'Manticore', '9cf40f4b22d7ed7f3e88f5b646851e39', 'battle_rule_v1:1052f1ae2599cc97def59d1a4409e475', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"flying":true,"keywords":["flash","flying"],"target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Manticore translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rooftop assassin', 'Rooftop Assassin', '6d29498729639e31d73587e9f7aefa7b', 'battle_rule_v1:b6a4b99b720989841de8c334981cce1f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"flying":true,"keywords":["flash","flying","lifelink"],"lifelink":true,"target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RooftopAssassin translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stingblade assassin', 'Stingblade Assassin', '6da93c21140da2ebc0a1386d19fb70b8', 'battle_rule_v1:1052f1ae2599cc97def59d1a4409e475', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"flying":true,"keywords":["flash","flying"],"target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StingbladeAssassin translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('acid web spider', 'Acid Web Spider', '39c8fb38e89d455204408edef83f8cfe', 'battle_rule_v1:1aa0efe2e139b1b4cfd98f1a96d15f09', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact","keywords":["reach"],"reach":true,"target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcidWebSpider translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('acidic slime', 'Acidic Slime', 'fc9545050669ca9a69c3363f5d092608', 'battle_rule_v1:d6f7486e4c786b9fb3a3ff228eba900f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","deathtouch":true,"destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact_or_enchantment_or_land","keywords":["deathtouch"],"target_constraints":{"card_types":["artifact","enchantment","land"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcidicSlime translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('aven cloudchaser', 'Aven Cloudchaser', '04d4881b78fb84ff7000719294d6782b', 'battle_rule_v1:e2339aebf333937d9a130bfc466caf48', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvenCloudchaser translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloudchaser eagle', 'Cloudchaser Eagle', 'c028fe58460036334805bfbc6fd85e30', 'battle_rule_v1:e2339aebf333937d9a130bfc466caf48', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloudchaserEagle translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('manticore', 'Manticore', '9cf40f4b22d7ed7f3e88f5b646851e39', 'battle_rule_v1:1052f1ae2599cc97def59d1a4409e475', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"flying":true,"keywords":["flash","flying"],"target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Manticore translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rooftop assassin', 'Rooftop Assassin', '6d29498729639e31d73587e9f7aefa7b', 'battle_rule_v1:b6a4b99b720989841de8c334981cce1f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"flying":true,"keywords":["flash","flying","lifelink"],"lifelink":true,"target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RooftopAssassin translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stingblade assassin', 'Stingblade Assassin', '6da93c21140da2ebc0a1386d19fb70b8', 'battle_rule_v1:1052f1ae2599cc97def59d1a4409e475', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"flying":true,"keywords":["flash","flying"],"target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StingbladeAssassin translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('acid web spider', 'Acid Web Spider', '39c8fb38e89d455204408edef83f8cfe', 'battle_rule_v1:1aa0efe2e139b1b4cfd98f1a96d15f09', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact","keywords":["reach"],"reach":true,"target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcidWebSpider translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('acidic slime', 'Acidic Slime', 'fc9545050669ca9a69c3363f5d092608', 'battle_rule_v1:d6f7486e4c786b9fb3a3ff228eba900f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","deathtouch":true,"destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact_or_enchantment_or_land","keywords":["deathtouch"],"target_constraints":{"card_types":["artifact","enchantment","land"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AcidicSlime translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('aven cloudchaser', 'Aven Cloudchaser', '04d4881b78fb84ff7000719294d6782b', 'battle_rule_v1:e2339aebf333937d9a130bfc466caf48', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvenCloudchaser translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cloudchaser eagle', 'Cloudchaser Eagle', 'c028fe58460036334805bfbc6fd85e30', 'battle_rule_v1:e2339aebf333937d9a130bfc466caf48', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"enchantment","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["enchantment"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CloudchaserEagle translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('manticore', 'Manticore', '9cf40f4b22d7ed7f3e88f5b646851e39', 'battle_rule_v1:1052f1ae2599cc97def59d1a4409e475', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"flying":true,"keywords":["flash","flying"],"target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Manticore translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rooftop assassin', 'Rooftop Assassin', '6d29498729639e31d73587e9f7aefa7b', 'battle_rule_v1:b6a4b99b720989841de8c334981cce1f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"flying":true,"keywords":["flash","flying","lifelink"],"lifelink":true,"target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RooftopAssassin translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stingblade assassin', 'Stingblade Assassin', '6da93c21140da2ebc0a1386d19fb70b8', 'battle_rule_v1:1052f1ae2599cc97def59d1a4409e475', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","flash":true,"flying":true,"keywords":["flash","flying"],"target_constraints":{"card_types":["creature"],"controller_scope":"opponent","damaged_this_turn":true},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StingbladeAssassin translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
