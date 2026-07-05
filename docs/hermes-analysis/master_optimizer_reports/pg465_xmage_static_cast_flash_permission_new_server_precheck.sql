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
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
