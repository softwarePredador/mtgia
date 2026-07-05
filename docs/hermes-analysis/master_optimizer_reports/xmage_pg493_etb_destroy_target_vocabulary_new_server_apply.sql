BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg493_etb_destroy_target_vocabulary_new_20260705_082234 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('bala ged scorpion', 'dakmor lancer', 'fleshpulper giant', 'marshdrinker giant', 'myconid spore tender', 'ravenous baboons', 'rock soldiers', 'rustspore ram', 'serpent assassin', 'setessan starbreaker', 'slayer of the wicked')
   OR normalized_name LIKE 'bala ged scorpion // %'
   OR normalized_name LIKE 'dakmor lancer // %'
   OR normalized_name LIKE 'fleshpulper giant // %'
   OR normalized_name LIKE 'marshdrinker giant // %'
   OR normalized_name LIKE 'myconid spore tender // %'
   OR normalized_name LIKE 'ravenous baboons // %'
   OR normalized_name LIKE 'rock soldiers // %'
   OR normalized_name LIKE 'rustspore ram // %'
   OR normalized_name LIKE 'serpent assassin // %'
   OR normalized_name LIKE 'setessan starbreaker // %'
   OR normalized_name LIKE 'slayer of the wicked // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bala ged scorpion', 'Bala Ged Scorpion', 'bee7a1e5e6aca5a2a0e4d597ab4562cf', 'battle_rule_v1:163002bd7915bcab4834fd782fd8716a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"power_max":1},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BalaGedScorpion translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dakmor lancer', 'Dakmor Lancer', '9f7cadf6cd9b3f37181b77e6da45d189', 'battle_rule_v1:2ad4e6f6ec0366e22c3da5c31c477882', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DakmorLancer translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fleshpulper giant', 'Fleshpulper Giant', '8662178b88cb0ec7b256a9f0f9382ff7', 'battle_rule_v1:a618a4a5790d05d5ce1ed03e9f943b4c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"toughness_max":2},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FleshpulperGiant translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marshdrinker giant', 'Marshdrinker Giant', '43ca3cf785a420933b916a72c7d4f486', 'battle_rule_v1:e3f21c7f2952a0e3d620000788073ff9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"land","target_constraints":{"card_types":["land"],"required_subtypes":["island","swamp"]},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarshdrinkerGiant translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('myconid spore tender', 'Myconid Spore Tender', '4f752ab676dccfdcdc035ea46db28e86', 'battle_rule_v1:7f6df953eba86870a1d793785e332a20', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MyconidSporeTender translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ravenous baboons', 'Ravenous Baboons', '6973e2542972949d4f36c8d5e5b53cdb', 'battle_rule_v1:b62f77f5b31d6f27e42d060684f3030c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"land","target_constraints":{"card_types":["land"],"exclude_supertypes":["basic"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RavenousBaboons translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rock soldiers', 'Rock Soldiers', '93bfbdf0cfaffd8d220f3bdbd3e8c4ee', 'battle_rule_v1:2bce2fa059694f09637ce5c391853ae8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RockSoldiers translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rustspore ram', 'Rustspore Ram', '01ad533164a532a0ed04fe877603bc5c', 'battle_rule_v1:d126150f90f188306bfe7b1db3f709ce', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RustsporeRam translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serpent assassin', 'Serpent Assassin', 'bbc834da9ce668a06403439485939dcc', 'battle_rule_v1:2ad4e6f6ec0366e22c3da5c31c477882', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SerpentAssassin translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('setessan starbreaker', 'Setessan Starbreaker', '0c28822ce6d1305a497d437b3b626552', 'battle_rule_v1:171ad18614c8ffda05203572c1e26dc2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"enchantment","target_constraints":{"card_types":["enchantment"],"required_subtypes":["aura"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SetessanStarbreaker translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slayer of the wicked', 'Slayer of the Wicked', '2ca4b1124bf0119a6135276c00aad830', 'battle_rule_v1:733cfeedb34f2197d637b51bcb1ba041', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"required_subtypes":["vampire","werewolf","zombie"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlayerOfTheWicked translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bala ged scorpion', 'Bala Ged Scorpion', 'bee7a1e5e6aca5a2a0e4d597ab4562cf', 'battle_rule_v1:163002bd7915bcab4834fd782fd8716a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"power_max":1},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BalaGedScorpion translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dakmor lancer', 'Dakmor Lancer', '9f7cadf6cd9b3f37181b77e6da45d189', 'battle_rule_v1:2ad4e6f6ec0366e22c3da5c31c477882', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DakmorLancer translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fleshpulper giant', 'Fleshpulper Giant', '8662178b88cb0ec7b256a9f0f9382ff7', 'battle_rule_v1:a618a4a5790d05d5ce1ed03e9f943b4c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"toughness_max":2},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FleshpulperGiant translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marshdrinker giant', 'Marshdrinker Giant', '43ca3cf785a420933b916a72c7d4f486', 'battle_rule_v1:e3f21c7f2952a0e3d620000788073ff9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"land","target_constraints":{"card_types":["land"],"required_subtypes":["island","swamp"]},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarshdrinkerGiant translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('myconid spore tender', 'Myconid Spore Tender', '4f752ab676dccfdcdc035ea46db28e86', 'battle_rule_v1:7f6df953eba86870a1d793785e332a20', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MyconidSporeTender translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ravenous baboons', 'Ravenous Baboons', '6973e2542972949d4f36c8d5e5b53cdb', 'battle_rule_v1:b62f77f5b31d6f27e42d060684f3030c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"land","target_constraints":{"card_types":["land"],"exclude_supertypes":["basic"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RavenousBaboons translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rock soldiers', 'Rock Soldiers', '93bfbdf0cfaffd8d220f3bdbd3e8c4ee', 'battle_rule_v1:2bce2fa059694f09637ce5c391853ae8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RockSoldiers translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rustspore ram', 'Rustspore Ram', '01ad533164a532a0ed04fe877603bc5c', 'battle_rule_v1:d126150f90f188306bfe7b1db3f709ce', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RustsporeRam translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serpent assassin', 'Serpent Assassin', 'bbc834da9ce668a06403439485939dcc', 'battle_rule_v1:2ad4e6f6ec0366e22c3da5c31c477882', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SerpentAssassin translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('setessan starbreaker', 'Setessan Starbreaker', '0c28822ce6d1305a497d437b3b626552', 'battle_rule_v1:171ad18614c8ffda05203572c1e26dc2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"enchantment","target_constraints":{"card_types":["enchantment"],"required_subtypes":["aura"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SetessanStarbreaker translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slayer of the wicked', 'Slayer of the Wicked', '2ca4b1124bf0119a6135276c00aad830', 'battle_rule_v1:733cfeedb34f2197d637b51bcb1ba041', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"required_subtypes":["vampire","werewolf","zombie"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlayerOfTheWicked translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('bala ged scorpion', 'Bala Ged Scorpion', 'bee7a1e5e6aca5a2a0e4d597ab4562cf', 'battle_rule_v1:163002bd7915bcab4834fd782fd8716a', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"power_max":1},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BalaGedScorpion translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dakmor lancer', 'Dakmor Lancer', '9f7cadf6cd9b3f37181b77e6da45d189', 'battle_rule_v1:2ad4e6f6ec0366e22c3da5c31c477882', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DakmorLancer translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fleshpulper giant', 'Fleshpulper Giant', '8662178b88cb0ec7b256a9f0f9382ff7', 'battle_rule_v1:a618a4a5790d05d5ce1ed03e9f943b4c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"toughness_max":2},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FleshpulperGiant translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('marshdrinker giant', 'Marshdrinker Giant', '43ca3cf785a420933b916a72c7d4f486', 'battle_rule_v1:e3f21c7f2952a0e3d620000788073ff9', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"land","target_constraints":{"card_types":["land"],"required_subtypes":["island","swamp"]},"target_controller":"opponent","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MarshdrinkerGiant translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('myconid spore tender', 'Myconid Spore Tender', '4f752ab676dccfdcdc035ea46db28e86', 'battle_rule_v1:7f6df953eba86870a1d793785e332a20', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MyconidSporeTender translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ravenous baboons', 'Ravenous Baboons', '6973e2542972949d4f36c8d5e5b53cdb', 'battle_rule_v1:b62f77f5b31d6f27e42d060684f3030c', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"land","target_constraints":{"card_types":["land"],"exclude_supertypes":["basic"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RavenousBaboons translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rock soldiers', 'Rock Soldiers', '93bfbdf0cfaffd8d220f3bdbd3e8c4ee', 'battle_rule_v1:2bce2fa059694f09637ce5c391853ae8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact","target_constraints":{"card_types":["artifact"],"exclude_card_types":["creature"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RockSoldiers translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rustspore ram', 'Rustspore Ram', '01ad533164a532a0ed04fe877603bc5c', 'battle_rule_v1:d126150f90f188306bfe7b1db3f709ce', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"artifact","target_constraints":{"card_types":["artifact"],"required_subtypes":["equipment"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RustsporeRam translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serpent assassin', 'Serpent Assassin', 'bbc834da9ce668a06403439485939dcc', 'battle_rule_v1:2ad4e6f6ec0366e22c3da5c31c477882', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"exclude_colors":["B"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SerpentAssassin translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('setessan starbreaker', 'Setessan Starbreaker', '0c28822ce6d1305a497d437b3b626552', 'battle_rule_v1:171ad18614c8ffda05203572c1e26dc2', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_permanent","etb_remove_target":"enchantment","target_constraints":{"card_types":["enchantment"],"required_subtypes":["aura"]},"target_controller":"any","trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SetessanStarbreaker translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slayer of the wicked', 'Slayer of the Wicked', '2ca4b1124bf0119a6135276c00aad830', 'battle_rule_v1:733cfeedb34f2197d637b51bcb1ba041', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_destroy_target_v1","destination":"graveyard","effect":"creature","etb_remove_effect":"remove_creature","etb_remove_target":"creature","target_constraints":{"card_types":["creature"],"required_subtypes":["vampire","werewolf","zombie"]},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"DestroyTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlayerOfTheWicked translated into ManaLoom runtime scope xmage_creature_etb_destroy_target_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
