BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

CREATE TABLE IF NOT EXISTS manaloom_deploy_audit.pg465_xmage_static_cast_flash_permission_new_server_2026 AS
SELECT *
FROM public.card_battle_rules
WHERE normalized_name IN ('high fae trickster', 'hypersonic dragon', 'quick sliver', 'raff capashen, ship''s mage', 'shimmer myr', 'vernal equinox', 'yeva, nature''s herald')
   OR normalized_name LIKE 'high fae trickster // %'
   OR normalized_name LIKE 'hypersonic dragon // %'
   OR normalized_name LIKE 'quick sliver // %'
   OR normalized_name LIKE 'raff capashen, ship''s mage // %'
   OR normalized_name LIKE 'shimmer myr // %'
   OR normalized_name LIKE 'vernal equinox // %'
   OR normalized_name LIKE 'yeva, nature''s herald // %';

DO $$
DECLARE
  v_missing jsonb;
BEGIN
  WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('high fae trickster', 'High Fae Trickster', '572253badba9314cde5c6fdc03511dec', 'battle_rule_v1:6bd10a81f80c7bbd17d666a850c4520c', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":true,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"nonland_spells","flying":true,"keywords":["flash","flying"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HighFaeTrickster translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hypersonic dragon', 'Hypersonic Dragon', '7e47a005dffa0831100f100dfe67f60c', 'battle_rule_v1:fb124a02d6a37bc79aedb10df58ba1d9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"sorcery_spells","flying":true,"haste":true,"keywords":["flying","haste"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HypersonicDragon translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quick sliver', 'Quick Sliver', 'f2c32bf4b04621526ca050501bc253a1', 'battle_rule_v1:b036645e49a5ca7424c4f27d58d25c93', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":true,"flash_permission_controller":"any_player","flash_permission_filter":"sliver_spells","keywords":["flash"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuickSliver translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raff capashen, ship''s mage', 'Raff Capashen, Ship''s Mage', '81f88dd9406c4ef0e8189bc1071c2670', 'battle_rule_v1:bba49e7921dea07b1448fa76e8297475', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"historic_spells","flying":true,"keywords":["flash","flying"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaffCapashenShipsMage translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shimmer myr', 'Shimmer Myr', '3f7693d00f1b35bec96c1dea4118dce3', 'battle_rule_v1:007474402d8a3f7cc66d62b9b3853aba', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"artifact_spells","keywords":["flash"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShimmerMyr translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vernal equinox', 'Vernal Equinox', '526d6d37bf9ebf99f174ac9dc59182d3', 'battle_rule_v1:fa82c1fc528ef736dd325f1c6151aebb', '{"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash_permission_any_player":true,"flash_permission_controller":"any_player","flash_permission_filter":"creature_or_enchantment_spells","permanent_type":"enchantment","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VernalEquinox translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yeva, nature''s herald', 'Yeva, Nature''s Herald', '4ba84a36268272ffdd2e46ff3c4deab3', 'battle_rule_v1:f5d926550a88a536437fbf494284474b', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"green_creature_spells","keywords":["flash"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YevaNaturesHerald translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('high fae trickster', 'High Fae Trickster', '572253badba9314cde5c6fdc03511dec', 'battle_rule_v1:6bd10a81f80c7bbd17d666a850c4520c', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":true,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"nonland_spells","flying":true,"keywords":["flash","flying"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HighFaeTrickster translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hypersonic dragon', 'Hypersonic Dragon', '7e47a005dffa0831100f100dfe67f60c', 'battle_rule_v1:fb124a02d6a37bc79aedb10df58ba1d9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"sorcery_spells","flying":true,"haste":true,"keywords":["flying","haste"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HypersonicDragon translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quick sliver', 'Quick Sliver', 'f2c32bf4b04621526ca050501bc253a1', 'battle_rule_v1:b036645e49a5ca7424c4f27d58d25c93', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":true,"flash_permission_controller":"any_player","flash_permission_filter":"sliver_spells","keywords":["flash"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuickSliver translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raff capashen, ship''s mage', 'Raff Capashen, Ship''s Mage', '81f88dd9406c4ef0e8189bc1071c2670', 'battle_rule_v1:bba49e7921dea07b1448fa76e8297475', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"historic_spells","flying":true,"keywords":["flash","flying"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaffCapashenShipsMage translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shimmer myr', 'Shimmer Myr', '3f7693d00f1b35bec96c1dea4118dce3', 'battle_rule_v1:007474402d8a3f7cc66d62b9b3853aba', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"artifact_spells","keywords":["flash"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShimmerMyr translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vernal equinox', 'Vernal Equinox', '526d6d37bf9ebf99f174ac9dc59182d3', 'battle_rule_v1:fa82c1fc528ef736dd325f1c6151aebb', '{"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash_permission_any_player":true,"flash_permission_controller":"any_player","flash_permission_filter":"creature_or_enchantment_spells","permanent_type":"enchantment","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VernalEquinox translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yeva, nature''s herald', 'Yeva, Nature''s Herald', '4ba84a36268272ffdd2e46ff3c4deab3', 'battle_rule_v1:f5d926550a88a536437fbf494284474b', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"green_creature_spells","keywords":["flash"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YevaNaturesHerald translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
    ('high fae trickster', 'High Fae Trickster', '572253badba9314cde5c6fdc03511dec', 'battle_rule_v1:6bd10a81f80c7bbd17d666a850c4520c', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":true,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"nonland_spells","flying":true,"keywords":["flash","flying"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HighFaeTrickster translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hypersonic dragon', 'Hypersonic Dragon', '7e47a005dffa0831100f100dfe67f60c', 'battle_rule_v1:fb124a02d6a37bc79aedb10df58ba1d9', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"sorcery_spells","flying":true,"haste":true,"keywords":["flying","haste"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HypersonicDragon translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quick sliver', 'Quick Sliver', 'f2c32bf4b04621526ca050501bc253a1', 'battle_rule_v1:b036645e49a5ca7424c4f27d58d25c93', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":true,"flash_permission_controller":"any_player","flash_permission_filter":"sliver_spells","keywords":["flash"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuickSliver translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('raff capashen, ship''s mage', 'Raff Capashen, Ship''s Mage', '81f88dd9406c4ef0e8189bc1071c2670', 'battle_rule_v1:bba49e7921dea07b1448fa76e8297475', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"historic_spells","flying":true,"keywords":["flash","flying"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RaffCapashenShipsMage translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shimmer myr', 'Shimmer Myr', '3f7693d00f1b35bec96c1dea4118dce3', 'battle_rule_v1:007474402d8a3f7cc66d62b9b3853aba', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"artifact_spells","keywords":["flash"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShimmerMyr translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vernal equinox', 'Vernal Equinox', '526d6d37bf9ebf99f174ac9dc59182d3', 'battle_rule_v1:fa82c1fc528ef736dd325f1c6151aebb', '{"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash_permission_any_player":true,"flash_permission_controller":"any_player","flash_permission_filter":"creature_or_enchantment_spells","permanent_type":"enchantment","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VernalEquinox translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('yeva, nature''s herald', 'Yeva, Nature''s Herald', '4ba84a36268272ffdd2e46ff3c4deab3', 'battle_rule_v1:f5d926550a88a536437fbf494284474b', '{"_keywords_are_self":true,"ability_kind":"static","battle_model_scope":"xmage_static_cast_spells_as_flash_permission_v1","cast_nonland_spells_as_flash":false,"cast_spells_as_flash":true,"effect":"flash_permission","flash":true,"flash_permission_any_player":false,"flash_permission_controller":"self","flash_permission_filter":"green_creature_spells","keywords":["flash"],"permanent_type":"creature","static_effect":"cast_as_though_flash","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"CastAsThoughItHadFlashAllEffect"}'::jsonb, '{"category":"unknown","effect":"flash_permission"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class YevaNaturesHerald translated into ManaLoom runtime scope xmage_static_cast_spells_as_flash_permission_v1. This row is package-ready only because the source signature is a narrow static cast-as-though-flash timing permission permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
