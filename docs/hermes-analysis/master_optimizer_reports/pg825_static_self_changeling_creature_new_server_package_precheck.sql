WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('avian changeling', 'Avian Changeling', '68cf84718d6d7a5d009832629b2108ed', 'battle_rule_v1:83542f8d2dae501a3324c53615cf8244', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","flying":true,"keywords":["changeling","flying"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","FlyingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AvianChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('changeling sentinel', 'Changeling Sentinel', 'b5cbbabd9f4ab5f634662ef31d4b146f', 'battle_rule_v1:f2e9ae6238da485ed448793e165b4779', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","vigilance"],"universal_creature_subtypes":true,"vigilance":true,"xmage_ability_classes":["ChangelingAbility","VigilanceAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChangelingSentinel translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chitinous graspling', 'Chitinous Graspling', '2230a4de4d4c3ccca938a5f823b5b7dc', 'battle_rule_v1:660713cce8044d6d0aa51c0bb16531d1', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","reach"],"reach":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","ReachAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChitinousGraspling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('game-trail changeling', 'Game-Trail Changeling', '701a95b442d40f666617eb8c4f4fa527', 'battle_rule_v1:aafbcbb6d1866de262843aaedd5b285c', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","trample"],"trample":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","TrampleAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GameTrailChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('gangly stompling', 'Gangly Stompling', '701a95b442d40f666617eb8c4f4fa527', 'battle_rule_v1:aafbcbb6d1866de262843aaedd5b285c', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","trample"],"trample":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","TrampleAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GanglyStompling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('impostor of the sixth pride', 'Impostor of the Sixth Pride', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ImpostorOfTheSixthPride translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mischievous sneakling', 'Mischievous Sneakling', '857fb2d72f55670ab64f14608ef73080', 'battle_rule_v1:3a1bb6d724952e1dc187befea51f2ccf', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","flash":true,"keywords":["changeling","flash"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","FlashAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MischievousSneakling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mistform ultimus', 'Mistform Ultimus', '60a2a39453aae611561902d11b316135', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MistformUltimus translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prideful feastling', 'Prideful Feastling', '71505afde7f0ea8b73844d02d01b2a5e', 'battle_rule_v1:76c93329a2a18c3003e9739318d46fcb', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling","lifelink"],"lifelink":true,"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","LifelinkAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PridefulFeastling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('universal automaton', 'Universal Automaton', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UniversalAutomaton translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('venomous changeling', 'Venomous Changeling', 'ea03d68af92ddcc34ece55868ad5dfb5', 'battle_rule_v1:d7e8802b9d7894c8d31d749a3b6925fe', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","deathtouch":true,"effect":"creature","keywords":["changeling","deathtouch"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility","DeathtouchAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VenomousChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('woodland changeling', 'Woodland Changeling', '82d610c1441606511006fcc92c4f41c0', 'battle_rule_v1:ca0c2ace39cdb1764a769a653b0bb9db', '{"_keywords_are_self":true,"all_creature_types":true,"battle_model_scope":"xmage_static_self_changeling_creature_v1","changeling":true,"creature_type_marker":"all","effect":"creature","keywords":["changeling"],"universal_creature_subtypes":true,"xmage_ability_classes":["ChangelingAbility"]}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WoodlandChangeling translated into ManaLoom runtime scope xmage_static_self_changeling_creature_v1. This row is package-ready only because the source signature is a narrow creature/card static Changeling all-creature-types identity with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
