BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg681_extended_destroy_board_wipe_new_se_20260709_010121 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('damning verdict', 'fight to the death', 'forced march', 'iridian maelstrom', 'retaliate', 'ruinous ultimatum', 'serene heart', 'slash the ranks', 'tivadar''s crusade', 'tranquil domain', 'winds of rath')
   OR normalized_name LIKE 'damning verdict // %'
   OR normalized_name LIKE 'fight to the death // %'
   OR normalized_name LIKE 'forced march // %'
   OR normalized_name LIKE 'iridian maelstrom // %'
   OR normalized_name LIKE 'retaliate // %'
   OR normalized_name LIKE 'ruinous ultimatum // %'
   OR normalized_name LIKE 'serene heart // %'
   OR normalized_name LIKE 'slash the ranks // %'
   OR normalized_name LIKE 'tivadar''s crusade // %'
   OR normalized_name LIKE 'tranquil domain // %'
   OR normalized_name LIKE 'winds of rath // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('damning verdict', 'Damning Verdict', '33f0171bc14c8f1984348bf7768e9dd2', 'battle_rule_v1:1f18065fc9e05b7382e97bd6e22d84c1', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_counter_state":"none","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DamningVerdict translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fight to the death', 'Fight to the Death', '544386e89921de0d8edccea0f7cf3db2', 'battle_rule_v1:4c3d89a5de268a64585efcfaa5ea8a45', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_combat_state":"blocking_or_blocked","effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FightToTheDeath translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forced march', 'Forced March', '0f27f0e3effac970d62931e180ee9ebe', 'battle_rule_v1:fe2535899e8907daeb65efa6d08625d0', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_mana_value_lte":0,"destroy_mana_value_lte_source":"x_value","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForcedMarch translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iridian maelstrom', 'Iridian Maelstrom', '111aee9fb9a2474072a4997ba67059c3', 'battle_rule_v1:95132cc301dd7fa7d0f202f3931d49ee', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_color_count_lt":5,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IridianMaelstrom translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retaliate', 'Retaliate', '2dc2616abd9d2da1be57ba8cb10eceb9', 'battle_rule_v1:7a3f2be667a7bdef390e594f94ec79af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_dealt_damage_to_you_this_turn":true,"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retaliate translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruinous ultimatum', 'Ruinous Ultimatum', '423f331acf69e0207d6337f18eaad355', 'battle_rule_v1:844a41ecce998ddb47894d50dfebd1c5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["permanent"],"destroy_controller":"opponents_control","destroy_exclude_card_types":["land"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RuinousUltimatum translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serene heart', 'Serene Heart', '132c041ddc763e613cf3f60e1f263479', 'battle_rule_v1:9fdbcabe98a9e71e5b7c7a00c79b1104', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"destroy_required_subtypes":["aura"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SereneHeart translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slash the ranks', 'Slash the Ranks', '301ab432ebc0997382ca787fe76a51af', 'battle_rule_v1:f082db7e1494a74df8a4d5a4d41ae126', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature","planeswalker"],"destroy_exclude_commanders":true,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlashTheRanks translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tivadar''s crusade', 'Tivadar''s Crusade', '181c916db01842331fd5d9145ab75a85', 'battle_rule_v1:4923d48bfef02728a27fd70237fbc5f6', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["permanent"],"destroy_required_subtypes":["goblin"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TivadarsCrusade translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tranquil domain', 'Tranquil Domain', '839dadbbbb938ef2d85872020c666dbc', 'battle_rule_v1:1d8b56017de6edbe969c20209c6ae0a9', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"destroy_excluded_subtypes":["aura"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TranquilDomain translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winds of rath', 'Winds of Rath', 'de9e91433d311fc360b75148bbba6f17', 'battle_rule_v1:e0d89211c65d375ab79b6c021718b55b', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_enchanted_state":"not_enchanted","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WindsOfRath translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('damning verdict', 'Damning Verdict', '33f0171bc14c8f1984348bf7768e9dd2', 'battle_rule_v1:1f18065fc9e05b7382e97bd6e22d84c1', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_counter_state":"none","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DamningVerdict translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fight to the death', 'Fight to the Death', '544386e89921de0d8edccea0f7cf3db2', 'battle_rule_v1:4c3d89a5de268a64585efcfaa5ea8a45', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_combat_state":"blocking_or_blocked","effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FightToTheDeath translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forced march', 'Forced March', '0f27f0e3effac970d62931e180ee9ebe', 'battle_rule_v1:fe2535899e8907daeb65efa6d08625d0', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_mana_value_lte":0,"destroy_mana_value_lte_source":"x_value","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForcedMarch translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iridian maelstrom', 'Iridian Maelstrom', '111aee9fb9a2474072a4997ba67059c3', 'battle_rule_v1:95132cc301dd7fa7d0f202f3931d49ee', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_color_count_lt":5,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IridianMaelstrom translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retaliate', 'Retaliate', '2dc2616abd9d2da1be57ba8cb10eceb9', 'battle_rule_v1:7a3f2be667a7bdef390e594f94ec79af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_dealt_damage_to_you_this_turn":true,"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retaliate translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruinous ultimatum', 'Ruinous Ultimatum', '423f331acf69e0207d6337f18eaad355', 'battle_rule_v1:844a41ecce998ddb47894d50dfebd1c5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["permanent"],"destroy_controller":"opponents_control","destroy_exclude_card_types":["land"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RuinousUltimatum translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serene heart', 'Serene Heart', '132c041ddc763e613cf3f60e1f263479', 'battle_rule_v1:9fdbcabe98a9e71e5b7c7a00c79b1104', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"destroy_required_subtypes":["aura"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SereneHeart translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slash the ranks', 'Slash the Ranks', '301ab432ebc0997382ca787fe76a51af', 'battle_rule_v1:f082db7e1494a74df8a4d5a4d41ae126', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature","planeswalker"],"destroy_exclude_commanders":true,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlashTheRanks translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tivadar''s crusade', 'Tivadar''s Crusade', '181c916db01842331fd5d9145ab75a85', 'battle_rule_v1:4923d48bfef02728a27fd70237fbc5f6', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["permanent"],"destroy_required_subtypes":["goblin"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TivadarsCrusade translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tranquil domain', 'Tranquil Domain', '839dadbbbb938ef2d85872020c666dbc', 'battle_rule_v1:1d8b56017de6edbe969c20209c6ae0a9', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"destroy_excluded_subtypes":["aura"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TranquilDomain translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winds of rath', 'Winds of Rath', 'de9e91433d311fc360b75148bbba6f17', 'battle_rule_v1:e0d89211c65d375ab79b6c021718b55b', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_enchanted_state":"not_enchanted","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WindsOfRath translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('damning verdict', 'Damning Verdict', '33f0171bc14c8f1984348bf7768e9dd2', 'battle_rule_v1:1f18065fc9e05b7382e97bd6e22d84c1', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_counter_state":"none","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DamningVerdict translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fight to the death', 'Fight to the Death', '544386e89921de0d8edccea0f7cf3db2', 'battle_rule_v1:4c3d89a5de268a64585efcfaa5ea8a45', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_combat_state":"blocking_or_blocked","effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FightToTheDeath translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('forced march', 'Forced March', '0f27f0e3effac970d62931e180ee9ebe', 'battle_rule_v1:fe2535899e8907daeb65efa6d08625d0', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_mana_value_lte":0,"destroy_mana_value_lte_source":"x_value","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ForcedMarch translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('iridian maelstrom', 'Iridian Maelstrom', '111aee9fb9a2474072a4997ba67059c3', 'battle_rule_v1:95132cc301dd7fa7d0f202f3931d49ee', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_color_count_lt":5,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class IridianMaelstrom translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('retaliate', 'Retaliate', '2dc2616abd9d2da1be57ba8cb10eceb9', 'battle_rule_v1:7a3f2be667a7bdef390e594f94ec79af', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_dealt_damage_to_you_this_turn":true,"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Retaliate translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruinous ultimatum', 'Ruinous Ultimatum', '423f331acf69e0207d6337f18eaad355', 'battle_rule_v1:844a41ecce998ddb47894d50dfebd1c5', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["permanent"],"destroy_controller":"opponents_control","destroy_exclude_card_types":["land"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RuinousUltimatum translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('serene heart', 'Serene Heart', '132c041ddc763e613cf3f60e1f263479', 'battle_rule_v1:9fdbcabe98a9e71e5b7c7a00c79b1104', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"destroy_required_subtypes":["aura"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SereneHeart translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slash the ranks', 'Slash the Ranks', '301ab432ebc0997382ca787fe76a51af', 'battle_rule_v1:f082db7e1494a74df8a4d5a4d41ae126', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature","planeswalker"],"destroy_exclude_commanders":true,"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlashTheRanks translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tivadar''s crusade', 'Tivadar''s Crusade', '181c916db01842331fd5d9145ab75a85', 'battle_rule_v1:4923d48bfef02728a27fd70237fbc5f6', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["permanent"],"destroy_required_subtypes":["goblin"],"effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TivadarsCrusade translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tranquil domain', 'Tranquil Domain', '839dadbbbb938ef2d85872020c666dbc', 'battle_rule_v1:1d8b56017de6edbe969c20209c6ae0a9', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["enchantment"],"destroy_excluded_subtypes":["aura"],"effect":"board_wipe","instant":true,"sorcery":false,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TranquilDomain translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('winds of rath', 'Winds of Rath', 'de9e91433d311fc360b75148bbba6f17', 'battle_rule_v1:e0d89211c65d375ab79b6c021718b55b', '{"battle_model_scope":"xmage_destroy_all_matching_permanents_spell_v1","destination":"graveyard","destroy_card_types":["creature"],"destroy_enchanted_state":"not_enchanted","effect":"board_wipe","instant":false,"sorcery":true,"xmage_effect_class":"DestroyAllEffect"}'::jsonb, '{"category":"wipe","effect":"board_wipe"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WindsOfRath translated into ManaLoom runtime scope xmage_destroy_all_matching_permanents_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
