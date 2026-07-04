BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg428_xmage_static_protection_subtypes_new_server_202607 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('baneslayer angel', 'dragonstalker', 'elite inquisitor', 'grave bramble', 'kitsune riftwalker', 'midnight duelist', 'nath''s buffoon', 'shoreline raider', 'tel-jilad archers')
   OR normalized_name LIKE 'baneslayer angel // %'
   OR normalized_name LIKE 'dragonstalker // %'
   OR normalized_name LIKE 'elite inquisitor // %'
   OR normalized_name LIKE 'grave bramble // %'
   OR normalized_name LIKE 'kitsune riftwalker // %'
   OR normalized_name LIKE 'midnight duelist // %'
   OR normalized_name LIKE 'nath''s buffoon // %'
   OR normalized_name LIKE 'shoreline raider // %'
   OR normalized_name LIKE 'tel-jilad archers // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('baneslayer angel', 'Baneslayer Angel', '6ff8233e60ef21831394c03d584cc90b', 'battle_rule_v1:973bf73edcfe9d86e8844d2171f10962', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","first_strike":true,"flying":true,"keywords":["flying","first_strike","lifelink"],"lifelink":true,"protection_from_subtypes":["demon","dragon"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BaneslayerAngel translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dragonstalker', 'Dragonstalker', '16f20165bc82d6ca26da2052b1820080', 'battle_rule_v1:84f814838cb82adbdbd052401b9ea24d', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_subtypes":["dragon"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Dragonstalker translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite inquisitor', 'Elite Inquisitor', 'af26f954b35928382f87b6428f2080c9', 'battle_rule_v1:2438eab81680409d0c44fd12d28c5ae7', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","first_strike":true,"keywords":["first_strike","vigilance"],"protection_from_subtypes":["vampire","werewolf","zombie"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","vigilance":true,"xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteInquisitor translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grave bramble', 'Grave Bramble', 'fad649d082c01228a4b2cbbdfe3aa747', 'battle_rule_v1:5073a13207eb34682e126dfea00b0fc6', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","defender":true,"effect":"creature","keywords":["defender"],"protection_from_subtypes":["zombie"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GraveBramble translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kitsune riftwalker', 'Kitsune Riftwalker', '1a467785235070a14689341eaa7feae0', 'battle_rule_v1:ed169e07fbc5efe8ca83d222c2c3e0da', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["arcane","spirit"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KitsuneRiftwalker translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('midnight duelist', 'Midnight Duelist', 'c8f30f806e27ed47a11d3a0a7ee1d44e', 'battle_rule_v1:5edf74990c5a9ec0cb78917c0cefbec0', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["vampire"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MidnightDuelist translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nath''s buffoon', 'Nath''s Buffoon', 'a7b9dde1c54d861d6ff1bc885775c22a', 'battle_rule_v1:8f4af176e1c167faade458042f4e8a05', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["elf"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NathsBuffoon translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shoreline raider', 'Shoreline Raider', '6c7c7021f6a9cc09fded6a19d160c31c', 'battle_rule_v1:97a60cbe14d8a270721264c8545213f9', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["kavu"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShorelineRaider translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad archers', 'Tel-Jilad Archers', '12b0bc0b3cc904955ae10eba99c3c985', 'battle_rule_v1:dc27d7f5f035d51b05a72775a1328276', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","keywords":["reach"],"protection_from_card_types":["artifact"],"reach":true,"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladArchers translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('baneslayer angel', 'Baneslayer Angel', '6ff8233e60ef21831394c03d584cc90b', 'battle_rule_v1:973bf73edcfe9d86e8844d2171f10962', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","first_strike":true,"flying":true,"keywords":["flying","first_strike","lifelink"],"lifelink":true,"protection_from_subtypes":["demon","dragon"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BaneslayerAngel translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dragonstalker', 'Dragonstalker', '16f20165bc82d6ca26da2052b1820080', 'battle_rule_v1:84f814838cb82adbdbd052401b9ea24d', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_subtypes":["dragon"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Dragonstalker translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite inquisitor', 'Elite Inquisitor', 'af26f954b35928382f87b6428f2080c9', 'battle_rule_v1:2438eab81680409d0c44fd12d28c5ae7', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","first_strike":true,"keywords":["first_strike","vigilance"],"protection_from_subtypes":["vampire","werewolf","zombie"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","vigilance":true,"xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteInquisitor translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grave bramble', 'Grave Bramble', 'fad649d082c01228a4b2cbbdfe3aa747', 'battle_rule_v1:5073a13207eb34682e126dfea00b0fc6', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","defender":true,"effect":"creature","keywords":["defender"],"protection_from_subtypes":["zombie"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GraveBramble translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kitsune riftwalker', 'Kitsune Riftwalker', '1a467785235070a14689341eaa7feae0', 'battle_rule_v1:ed169e07fbc5efe8ca83d222c2c3e0da', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["arcane","spirit"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KitsuneRiftwalker translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('midnight duelist', 'Midnight Duelist', 'c8f30f806e27ed47a11d3a0a7ee1d44e', 'battle_rule_v1:5edf74990c5a9ec0cb78917c0cefbec0', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["vampire"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MidnightDuelist translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nath''s buffoon', 'Nath''s Buffoon', 'a7b9dde1c54d861d6ff1bc885775c22a', 'battle_rule_v1:8f4af176e1c167faade458042f4e8a05', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["elf"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NathsBuffoon translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shoreline raider', 'Shoreline Raider', '6c7c7021f6a9cc09fded6a19d160c31c', 'battle_rule_v1:97a60cbe14d8a270721264c8545213f9', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["kavu"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShorelineRaider translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad archers', 'Tel-Jilad Archers', '12b0bc0b3cc904955ae10eba99c3c985', 'battle_rule_v1:dc27d7f5f035d51b05a72775a1328276', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","keywords":["reach"],"protection_from_card_types":["artifact"],"reach":true,"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladArchers translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('baneslayer angel', 'Baneslayer Angel', '6ff8233e60ef21831394c03d584cc90b', 'battle_rule_v1:973bf73edcfe9d86e8844d2171f10962', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","first_strike":true,"flying":true,"keywords":["flying","first_strike","lifelink"],"lifelink":true,"protection_from_subtypes":["demon","dragon"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BaneslayerAngel translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dragonstalker', 'Dragonstalker', '16f20165bc82d6ca26da2052b1820080', 'battle_rule_v1:84f814838cb82adbdbd052401b9ea24d', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","flying":true,"keywords":["flying"],"protection_from_subtypes":["dragon"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Dragonstalker translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elite inquisitor', 'Elite Inquisitor', 'af26f954b35928382f87b6428f2080c9', 'battle_rule_v1:2438eab81680409d0c44fd12d28c5ae7', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","first_strike":true,"keywords":["first_strike","vigilance"],"protection_from_subtypes":["vampire","werewolf","zombie"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","vigilance":true,"xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EliteInquisitor translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grave bramble', 'Grave Bramble', 'fad649d082c01228a4b2cbbdfe3aa747', 'battle_rule_v1:5073a13207eb34682e126dfea00b0fc6', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","defender":true,"effect":"creature","keywords":["defender"],"protection_from_subtypes":["zombie"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GraveBramble translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kitsune riftwalker', 'Kitsune Riftwalker', '1a467785235070a14689341eaa7feae0', 'battle_rule_v1:ed169e07fbc5efe8ca83d222c2c3e0da', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["arcane","spirit"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KitsuneRiftwalker translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('midnight duelist', 'Midnight Duelist', 'c8f30f806e27ed47a11d3a0a7ee1d44e', 'battle_rule_v1:5edf74990c5a9ec0cb78917c0cefbec0', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["vampire"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MidnightDuelist translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nath''s buffoon', 'Nath''s Buffoon', 'a7b9dde1c54d861d6ff1bc885775c22a', 'battle_rule_v1:8f4af176e1c167faade458042f4e8a05', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["elf"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NathsBuffoon translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shoreline raider', 'Shoreline Raider', '6c7c7021f6a9cc09fded6a19d160c31c', 'battle_rule_v1:97a60cbe14d8a270721264c8545213f9', '{"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_subtypes_creature_v1","effect":"creature","protection_from_subtypes":["kavu"],"static_effect":"self_protection_from_subtypes","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShorelineRaider translated into ManaLoom runtime scope xmage_static_self_protection_from_subtypes_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad archers', 'Tel-Jilad Archers', '12b0bc0b3cc904955ae10eba99c3c985', 'battle_rule_v1:dc27d7f5f035d51b05a72775a1328276', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_self_protection_from_card_types_creature_v1","effect":"creature","keywords":["reach"],"protection_from_card_types":["artifact"],"reach":true,"static_effect":"self_protection_from_card_types","target":"self","target_controller":"self","xmage_ability_class":"ProtectionAbility"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladArchers translated into ManaLoom runtime scope xmage_static_self_protection_from_card_types_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
