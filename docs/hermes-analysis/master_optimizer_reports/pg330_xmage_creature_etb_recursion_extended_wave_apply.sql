BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg330_xmage_creature_etb_recursion_extended_wave_2026070 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('barrow witches', 'disciple of the sun', 'leonin squire', 'pillardrop rescuer', 'ragamuffin raptor', 'scholar of the ages', 'strongarm thug')
   OR normalized_name LIKE 'barrow witches // %'
   OR normalized_name LIKE 'disciple of the sun // %'
   OR normalized_name LIKE 'leonin squire // %'
   OR normalized_name LIKE 'pillardrop rescuer // %'
   OR normalized_name LIKE 'ragamuffin raptor // %'
   OR normalized_name LIKE 'scholar of the ages // %'
   OR normalized_name LIKE 'strongarm thug // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('barrow witches', 'Barrow Witches', '03af5cf8599d458694ed320773b1eb7f', 'battle_rule_v1:4034cd73665465654057f3c53931944c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"knight_card","target_constraints":{"controller":"self","subtypes":["knight"],"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarrowWitches translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('disciple of the sun', 'Disciple of the Sun', 'ae730f1553235bf86c19b2f5a2a0d9eb', 'battle_rule_v1:ffdf833d17e0bd16f63882d13bbc3e2e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":3,"etb_recursion_target":"permanent","keywords":["lifelink"],"lifelink":true,"target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DiscipleOfTheSun translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leonin squire', 'Leonin Squire', '2b39f6f71e298b5b3d7f3958183b2fec', 'battle_rule_v1:a357028acccc67acecfe58b809750fb2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":1,"etb_recursion_target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","mana_value_max":1,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeoninSquire translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pillardrop rescuer', 'Pillardrop Rescuer', '8856c25207818ab8189baf9fd3421354', 'battle_rule_v1:95e527e379975372965a66647a9a3378', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":3,"etb_recursion_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PillardropRescuer translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ragamuffin raptor', 'Ragamuffin Raptor', 'd1562c3e3fda218dcb8826c953cf91af', 'battle_rule_v1:e6a9f76c33f0301dab3bc1f741d19657', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"creature_or_food","etb_recursion_up_to_count":true,"target_constraints":{"any_of":[{"card_types":["creature"]},{"subtypes":["food"]}],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RagamuffinRaptor translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scholar of the ages', 'Scholar of the Ages', 'be6352a59faefe53242ea84fe3104b52', 'battle_rule_v1:69611c1df9c53b61f286a860e1008758', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":2,"etb_recursion_destination":"hand","etb_recursion_target":"instant_or_sorcery","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScholarOfTheAges translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('strongarm thug', 'Strongarm Thug', 'b14be76cbbac1d5a404dda8205132377', 'battle_rule_v1:f46d50601f25d4153e9c7fa2c460ebcd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"mercenary_card","target_constraints":{"controller":"self","subtypes":["mercenary"],"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StrongarmThug translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('barrow witches', 'Barrow Witches', '03af5cf8599d458694ed320773b1eb7f', 'battle_rule_v1:4034cd73665465654057f3c53931944c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"knight_card","target_constraints":{"controller":"self","subtypes":["knight"],"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarrowWitches translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('disciple of the sun', 'Disciple of the Sun', 'ae730f1553235bf86c19b2f5a2a0d9eb', 'battle_rule_v1:ffdf833d17e0bd16f63882d13bbc3e2e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":3,"etb_recursion_target":"permanent","keywords":["lifelink"],"lifelink":true,"target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DiscipleOfTheSun translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leonin squire', 'Leonin Squire', '2b39f6f71e298b5b3d7f3958183b2fec', 'battle_rule_v1:a357028acccc67acecfe58b809750fb2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":1,"etb_recursion_target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","mana_value_max":1,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeoninSquire translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pillardrop rescuer', 'Pillardrop Rescuer', '8856c25207818ab8189baf9fd3421354', 'battle_rule_v1:95e527e379975372965a66647a9a3378', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":3,"etb_recursion_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PillardropRescuer translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ragamuffin raptor', 'Ragamuffin Raptor', 'd1562c3e3fda218dcb8826c953cf91af', 'battle_rule_v1:e6a9f76c33f0301dab3bc1f741d19657', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"creature_or_food","etb_recursion_up_to_count":true,"target_constraints":{"any_of":[{"card_types":["creature"]},{"subtypes":["food"]}],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RagamuffinRaptor translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scholar of the ages', 'Scholar of the Ages', 'be6352a59faefe53242ea84fe3104b52', 'battle_rule_v1:69611c1df9c53b61f286a860e1008758', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":2,"etb_recursion_destination":"hand","etb_recursion_target":"instant_or_sorcery","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScholarOfTheAges translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('strongarm thug', 'Strongarm Thug', 'b14be76cbbac1d5a404dda8205132377', 'battle_rule_v1:f46d50601f25d4153e9c7fa2c460ebcd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"mercenary_card","target_constraints":{"controller":"self","subtypes":["mercenary"],"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StrongarmThug translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('barrow witches', 'Barrow Witches', '03af5cf8599d458694ed320773b1eb7f', 'battle_rule_v1:4034cd73665465654057f3c53931944c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"knight_card","target_constraints":{"controller":"self","subtypes":["knight"],"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BarrowWitches translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('disciple of the sun', 'Disciple of the Sun', 'ae730f1553235bf86c19b2f5a2a0d9eb', 'battle_rule_v1:ffdf833d17e0bd16f63882d13bbc3e2e', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":3,"etb_recursion_target":"permanent","keywords":["lifelink"],"lifelink":true,"target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DiscipleOfTheSun translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leonin squire', 'Leonin Squire', '2b39f6f71e298b5b3d7f3958183b2fec', 'battle_rule_v1:a357028acccc67acecfe58b809750fb2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":1,"etb_recursion_target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","mana_value_max":1,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeoninSquire translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pillardrop rescuer', 'Pillardrop Rescuer', '8856c25207818ab8189baf9fd3421354', 'battle_rule_v1:95e527e379975372965a66647a9a3378', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_mana_value_max":3,"etb_recursion_target":"creature","flying":true,"keywords":["flying"],"target_constraints":{"card_types":["creature"],"controller":"self","mana_value_max":3,"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PillardropRescuer translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ragamuffin raptor', 'Ragamuffin Raptor', 'd1562c3e3fda218dcb8826c953cf91af', 'battle_rule_v1:e6a9f76c33f0301dab3bc1f741d19657', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"creature_or_food","etb_recursion_up_to_count":true,"target_constraints":{"any_of":[{"card_types":["creature"]},{"subtypes":["food"]}],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RagamuffinRaptor translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scholar of the ages', 'Scholar of the Ages', 'be6352a59faefe53242ea84fe3104b52', 'battle_rule_v1:69611c1df9c53b61f286a860e1008758', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":2,"etb_recursion_destination":"hand","etb_recursion_target":"instant_or_sorcery","etb_recursion_up_to_count":true,"target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScholarOfTheAges translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('strongarm thug', 'Strongarm Thug', 'b14be76cbbac1d5a404dda8205132377', 'battle_rule_v1:f46d50601f25d4153e9c7fa2c460ebcd', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"mercenary_card","target_constraints":{"controller":"self","subtypes":["mercenary"],"zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StrongarmThug translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
