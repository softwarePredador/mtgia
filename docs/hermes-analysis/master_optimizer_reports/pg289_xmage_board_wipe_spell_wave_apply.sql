BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE manaloom_deploy_audit.pg289_xmage_board_wipe_spell_wave_20260701_084207 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('back to nature', 'blazing volley', 'cleanfall', 'creeping corrosion', 'damnation', 'day of judgment', 'desert sandstorm', 'devastation', 'purify', 'pyroclasm', 'storm''s wrath', 'tempest of light', 'tranquility')
   OR normalized_name LIKE 'back to nature // %'
   OR normalized_name LIKE 'blazing volley // %'
   OR normalized_name LIKE 'cleanfall // %'
   OR normalized_name LIKE 'creeping corrosion // %'
   OR normalized_name LIKE 'damnation // %'
   OR normalized_name LIKE 'day of judgment // %'
   OR normalized_name LIKE 'desert sandstorm // %'
   OR normalized_name LIKE 'devastation // %'
   OR normalized_name LIKE 'purify // %'
   OR normalized_name LIKE 'pyroclasm // %'
   OR normalized_name LIKE 'storm''s wrath // %'
   OR normalized_name LIKE 'tempest of light // %'
   OR normalized_name LIKE 'tranquility // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('back to nature', 'Back to Nature', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:2db82a716fde240884554cf0e1f5e0e8', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BackToNature translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blazing volley', 'Blazing Volley', '0d444f6ad4a3d6586c4786af9ffe8d1f', 'battle_rule_v1:ca558b0667e6b7aace3c654850ad435a', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":1,"damage_scope":"each_creature_opponents_control","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlazingVolley translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cleanfall', 'Cleanfall', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:8cca937904da37d443131e25b0e866a5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cleanfall translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('creeping corrosion', 'Creeping Corrosion', '18445e3303e023a20571b11493748ce1', 'battle_rule_v1:8f5c34e1b9985fb3a0a991f08cad1cda', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["artifact"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CreepingCorrosion translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('damnation', 'Damnation', 'fde8457ed00422f361bae1d0643f9b70', 'battle_rule_v1:acf7a4c6829b305ea62cbdb81430e0af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Damnation translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('day of judgment', 'Day of Judgment', 'fc814de9bcaeed653872d6a95f46d3fd', 'battle_rule_v1:acf7a4c6829b305ea62cbdb81430e0af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DayOfJudgment translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('desert sandstorm', 'Desert Sandstorm', '27a771b4117f5def2f499ddc9171c8e3', 'battle_rule_v1:5f4af83cbc23d0c5fb3930192282aaa8', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DesertSandstorm translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('devastation', 'Devastation', '1a1d1a4093ecfdd6c277826b81b123ac', 'battle_rule_v1:5527e651c7538b95afe5c0f79ab9774a', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature","land"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Devastation translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('purify', 'Purify', 'ef96e1d39749b1410f22cc6e03e6a2e8', 'battle_rule_v1:31ebc4bbef8f5dc49e9cc263f7d391eb', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["artifact","enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Purify translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyroclasm', 'Pyroclasm', 'e38b6c9ea33bbe04ad1e7090d1ec2076', 'battle_rule_v1:32ba91fba4737f3432f05905d2845449', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":2,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Pyroclasm translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm''s wrath', 'Storm''s Wrath', '0e94f546b5088c4eee25463894cbdc26', 'battle_rule_v1:925a5a19163b3817fc87c4d00d111209', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":4,"damage_scope":"each_creature_and_planeswalker","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormsWrath translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tempest of light', 'Tempest of Light', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:2db82a716fde240884554cf0e1f5e0e8', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TempestOfLight translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tranquility', 'Tranquility', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:8cca937904da37d443131e25b0e866a5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tranquility translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('back to nature', 'Back to Nature', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:2db82a716fde240884554cf0e1f5e0e8', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BackToNature translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blazing volley', 'Blazing Volley', '0d444f6ad4a3d6586c4786af9ffe8d1f', 'battle_rule_v1:ca558b0667e6b7aace3c654850ad435a', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":1,"damage_scope":"each_creature_opponents_control","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlazingVolley translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cleanfall', 'Cleanfall', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:8cca937904da37d443131e25b0e866a5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cleanfall translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('creeping corrosion', 'Creeping Corrosion', '18445e3303e023a20571b11493748ce1', 'battle_rule_v1:8f5c34e1b9985fb3a0a991f08cad1cda', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["artifact"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CreepingCorrosion translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('damnation', 'Damnation', 'fde8457ed00422f361bae1d0643f9b70', 'battle_rule_v1:acf7a4c6829b305ea62cbdb81430e0af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Damnation translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('day of judgment', 'Day of Judgment', 'fc814de9bcaeed653872d6a95f46d3fd', 'battle_rule_v1:acf7a4c6829b305ea62cbdb81430e0af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DayOfJudgment translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('desert sandstorm', 'Desert Sandstorm', '27a771b4117f5def2f499ddc9171c8e3', 'battle_rule_v1:5f4af83cbc23d0c5fb3930192282aaa8', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DesertSandstorm translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('devastation', 'Devastation', '1a1d1a4093ecfdd6c277826b81b123ac', 'battle_rule_v1:5527e651c7538b95afe5c0f79ab9774a', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature","land"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Devastation translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('purify', 'Purify', 'ef96e1d39749b1410f22cc6e03e6a2e8', 'battle_rule_v1:31ebc4bbef8f5dc49e9cc263f7d391eb', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["artifact","enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Purify translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyroclasm', 'Pyroclasm', 'e38b6c9ea33bbe04ad1e7090d1ec2076', 'battle_rule_v1:32ba91fba4737f3432f05905d2845449', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":2,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Pyroclasm translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm''s wrath', 'Storm''s Wrath', '0e94f546b5088c4eee25463894cbdc26', 'battle_rule_v1:925a5a19163b3817fc87c4d00d111209', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":4,"damage_scope":"each_creature_and_planeswalker","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormsWrath translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tempest of light', 'Tempest of Light', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:2db82a716fde240884554cf0e1f5e0e8', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TempestOfLight translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tranquility', 'Tranquility', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:8cca937904da37d443131e25b0e866a5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tranquility translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('back to nature', 'Back to Nature', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:2db82a716fde240884554cf0e1f5e0e8', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BackToNature translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blazing volley', 'Blazing Volley', '0d444f6ad4a3d6586c4786af9ffe8d1f', 'battle_rule_v1:ca558b0667e6b7aace3c654850ad435a', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":1,"damage_scope":"each_creature_opponents_control","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlazingVolley translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('cleanfall', 'Cleanfall', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:8cca937904da37d443131e25b0e866a5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cleanfall translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('creeping corrosion', 'Creeping Corrosion', '18445e3303e023a20571b11493748ce1', 'battle_rule_v1:8f5c34e1b9985fb3a0a991f08cad1cda', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["artifact"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CreepingCorrosion translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('damnation', 'Damnation', 'fde8457ed00422f361bae1d0643f9b70', 'battle_rule_v1:acf7a4c6829b305ea62cbdb81430e0af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Damnation translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('day of judgment', 'Day of Judgment', 'fc814de9bcaeed653872d6a95f46d3fd', 'battle_rule_v1:acf7a4c6829b305ea62cbdb81430e0af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DayOfJudgment translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('desert sandstorm', 'Desert Sandstorm', '27a771b4117f5def2f499ddc9171c8e3', 'battle_rule_v1:5f4af83cbc23d0c5fb3930192282aaa8', '{"amount":1,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":1,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DesertSandstorm translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('devastation', 'Devastation', '1a1d1a4093ecfdd6c277826b81b123ac', 'battle_rule_v1:5527e651c7538b95afe5c0f79ab9774a', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature","land"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Devastation translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('purify', 'Purify', 'ef96e1d39749b1410f22cc6e03e6a2e8', 'battle_rule_v1:31ebc4bbef8f5dc49e9cc263f7d391eb', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["artifact","enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Purify translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyroclasm', 'Pyroclasm', 'e38b6c9ea33bbe04ad1e7090d1ec2076', 'battle_rule_v1:32ba91fba4737f3432f05905d2845449', '{"amount":2,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":2,"damage_scope":"each_creature","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Pyroclasm translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('storm''s wrath', 'Storm''s Wrath', '0e94f546b5088c4eee25463894cbdc26', 'battle_rule_v1:925a5a19163b3817fc87c4d00d111209', '{"amount":4,"battle_model_scope":"xmage_fixed_damage_all_matching_permanents_spell_v1","damage":4,"damage_scope":"each_creature_and_planeswalker","effect":"damage_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DamageAllEffect"}'::jsonb, '{"category":"wipe","effect":"damage_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormsWrath translated into ManaLoom runtime scope xmage_fixed_damage_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tempest of light', 'Tempest of Light', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:2db82a716fde240884554cf0e1f5e0e8', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TempestOfLight translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tranquility', 'Tranquility', '971f04b9d5fbb56aa10877faa3cf74a2', 'battle_rule_v1:8cca937904da37d443131e25b0e866a5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Tranquility translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
