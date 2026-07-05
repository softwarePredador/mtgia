BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg460_xmage_destroy_target_scry_new_server_20260705_0047 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('artisan''s sorrow', 'expose to daylight', 'get the point', 'guiding bolt', 'rubble reading', 'skywhaler''s shot', 'tel-jilad justice', 'vanquish the foul')
   OR normalized_name LIKE 'artisan''s sorrow // %'
   OR normalized_name LIKE 'expose to daylight // %'
   OR normalized_name LIKE 'get the point // %'
   OR normalized_name LIKE 'guiding bolt // %'
   OR normalized_name LIKE 'rubble reading // %'
   OR normalized_name LIKE 'skywhaler''s shot // %'
   OR normalized_name LIKE 'tel-jilad justice // %'
   OR normalized_name LIKE 'vanquish the foul // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('artisan''s sorrow', 'Artisan''s Sorrow', 'da43fa4288fbb6986c6ddda5b21db6dd', 'battle_rule_v1:6e9e60bc9fb2ad5c293fdfd311a8c137', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArtisansSorrow translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('expose to daylight', 'Expose to Daylight', '3646dffbed1ee5903335e38f180bdd10', 'battle_rule_v1:e27b12d525b32a09c3664f43b350acc4', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExposeToDaylight translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('get the point', 'Get the Point', '9b713515e0ac5d3787f8022921214828', 'battle_rule_v1:60186100f5114fb616355fbbdbb91778', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GetThePoint translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guiding bolt', 'Guiding Bolt', '379be0891c7170a8b2c7e92b0c961cc8', 'battle_rule_v1:7339a89b2ca7be6d9b801f0fbf7123dc', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuidingBolt translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rubble reading', 'Rubble Reading', 'ed6c32c050392475b0ad695de29d1e80', 'battle_rule_v1:3d1fa3cc048c47b80f9e4ebc21b72931', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubbleReading translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skywhaler''s shot', 'Skywhaler''s Shot', 'b72b7bfe543e290d2e6fd90b617727a3', 'battle_rule_v1:cf50ba8ae8f3f26d42593ffd7c919fa7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":3},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":3},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkywhalersShot translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad justice', 'Tel-Jilad Justice', '771f081071e5dbd2213233334c6a2874', 'battle_rule_v1:549bbd1831243bf6128b853515d740c0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladJustice translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vanquish the foul', 'Vanquish the Foul', 'cde9a7f047448ac2ff5c48179b6cbb80', 'battle_rule_v1:c7411f0db013697c3ba279504bd4dff2', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VanquishTheFoul translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('artisan''s sorrow', 'Artisan''s Sorrow', 'da43fa4288fbb6986c6ddda5b21db6dd', 'battle_rule_v1:6e9e60bc9fb2ad5c293fdfd311a8c137', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArtisansSorrow translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('expose to daylight', 'Expose to Daylight', '3646dffbed1ee5903335e38f180bdd10', 'battle_rule_v1:e27b12d525b32a09c3664f43b350acc4', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExposeToDaylight translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('get the point', 'Get the Point', '9b713515e0ac5d3787f8022921214828', 'battle_rule_v1:60186100f5114fb616355fbbdbb91778', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GetThePoint translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guiding bolt', 'Guiding Bolt', '379be0891c7170a8b2c7e92b0c961cc8', 'battle_rule_v1:7339a89b2ca7be6d9b801f0fbf7123dc', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuidingBolt translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rubble reading', 'Rubble Reading', 'ed6c32c050392475b0ad695de29d1e80', 'battle_rule_v1:3d1fa3cc048c47b80f9e4ebc21b72931', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubbleReading translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skywhaler''s shot', 'Skywhaler''s Shot', 'b72b7bfe543e290d2e6fd90b617727a3', 'battle_rule_v1:cf50ba8ae8f3f26d42593ffd7c919fa7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":3},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":3},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkywhalersShot translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad justice', 'Tel-Jilad Justice', '771f081071e5dbd2213233334c6a2874', 'battle_rule_v1:549bbd1831243bf6128b853515d740c0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladJustice translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vanquish the foul', 'Vanquish the Foul', 'cde9a7f047448ac2ff5c48179b6cbb80', 'battle_rule_v1:c7411f0db013697c3ba279504bd4dff2', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VanquishTheFoul translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('artisan''s sorrow', 'Artisan''s Sorrow', 'da43fa4288fbb6986c6ddda5b21db6dd', 'battle_rule_v1:6e9e60bc9fb2ad5c293fdfd311a8c137', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArtisansSorrow translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('expose to daylight', 'Expose to Daylight', '3646dffbed1ee5903335e38f180bdd10', 'battle_rule_v1:e27b12d525b32a09c3664f43b350acc4', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact_or_enchantment","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ExposeToDaylight translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('get the point', 'Get the Point', '9b713515e0ac5d3787f8022921214828', 'battle_rule_v1:60186100f5114fb616355fbbdbb91778', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GetThePoint translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guiding bolt', 'Guiding Bolt', '379be0891c7170a8b2c7e92b0c961cc8', 'battle_rule_v1:7339a89b2ca7be6d9b801f0fbf7123dc', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuidingBolt translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rubble reading', 'Rubble Reading', 'ed6c32c050392475b0ad695de29d1e80', 'battle_rule_v1:3d1fa3cc048c47b80f9e4ebc21b72931', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":true,"target":"land","target_constraints":{"card_types":["land"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"land"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RubbleReading translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skywhaler''s shot', 'Skywhaler''s Shot', 'b72b7bfe543e290d2e6fd90b617727a3', 'battle_rule_v1:cf50ba8ae8f3f26d42593ffd7c919fa7', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":3},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":3},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SkywhalersShot translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tel-jilad justice', 'Tel-Jilad Justice', '771f081071e5dbd2213233334c6a2874', 'battle_rule_v1:549bbd1831243bf6128b853515d740c0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":2,"effect":"scry","scry_count":2,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_scry","scry_count":2,"sorcery":false,"target":"artifact","target_constraints":{"card_types":["artifact"]},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"artifact","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TelJiladJustice translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vanquish the foul', 'Vanquish the Foul', 'cde9a7f047448ac2ff5c48179b6cbb80', 'battle_rule_v1:c7411f0db013697c3ba279504bd4dff2', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_destroy_target_and_scry_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_scry","scry_count":1,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"power_min":4},"xmage_effect_classes":["DestroyTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VanquishTheFoul translated into ManaLoom runtime scope xmage_destroy_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
