WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('blessed spirits', 'Blessed Spirits', 'ebd3b3b2b92b4e98dc35209599aeccae', 'battle_rule_v1:469302a80b5f9cb07d8e7c4685a084b7', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"keywords":["flying"],"spell_cast_add_counters":true,"spell_cast_add_counters_card_types":["enchantment"],"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_target":"self","trigger":"spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BlessedSpirits translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('boar-q-pine', 'Boar-q-pine', '00710965d61dcb88af09147413c870a9', 'battle_rule_v1:238cedcb64a3ea5843c8e6b1697a55be', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"spell_cast_add_counters":true,"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_target":"self","trigger":"noncreature_spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BoarQPine translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('deeproot champion', 'Deeproot Champion', '00710965d61dcb88af09147413c870a9', 'battle_rule_v1:238cedcb64a3ea5843c8e6b1697a55be', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"spell_cast_add_counters":true,"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_target":"self","trigger":"noncreature_spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeeprootChampion translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('electrostatic infantry', 'Electrostatic Infantry', 'e823ba6dc5925c88a5dc5b0db9a2212a', 'battle_rule_v1:c38a040c3c33c3babb5e2b59547c3b09', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"keywords":["trample"],"spell_cast_add_counters":true,"spell_cast_add_counters_card_types":["instant","sorcery"],"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_target":"self","trigger":"spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElectrostaticInfantry translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('kurgadon', 'Kurgadon', 'db70bff8138e6b150eed34530a8e8e66', 'battle_rule_v1:273ba37a7e0ec3ab4baf381c811ecbd3', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":3,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"spell_cast_add_counters":true,"spell_cast_add_counters_card_types":["creature"],"spell_cast_add_counters_count":3,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_mana_value_min":6,"spell_cast_add_counters_target":"self","trigger":"spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Kurgadon translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lurking lizards', 'Lurking Lizards', '76bddd11dfa133e3780d2fbcbb77d23d', 'battle_rule_v1:7aa55787014ba5b5a3cb13b4e735401c', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"keywords":["trample"],"spell_cast_add_counters":true,"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_mana_value_min":4,"spell_cast_add_counters_target":"self","trigger":"spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LurkingLizards translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('mage tower referee', 'Mage Tower Referee', '3baba1cf8dabe30c1de8d556731bf92e', 'battle_rule_v1:0d02fdb8575fdbf54c6272c635d986db', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"spell_cast_add_counters":true,"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_requires_multicolored":true,"spell_cast_add_counters_target":"self","trigger":"spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MageTowerReferee translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyre hound', 'Pyre Hound', 'e823ba6dc5925c88a5dc5b0db9a2212a', 'battle_rule_v1:c38a040c3c33c3babb5e2b59547c3b09', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"keywords":["trample"],"spell_cast_add_counters":true,"spell_cast_add_counters_card_types":["instant","sorcery"],"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_target":"self","trigger":"spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PyreHound translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pyroceratops', 'Pyroceratops', 'ce93962b6f3e46e6cd910cf3aeb8ff81', 'battle_rule_v1:dd21c7311af121b25fc6bde40c4af5b0', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"keywords":["trample"],"spell_cast_add_counters":true,"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_target":"self","trigger":"noncreature_spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Pyroceratops translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('quirion dryad', 'Quirion Dryad', '62f7f70992d5d80c365670c5dbb81823', 'battle_rule_v1:dbf0c6d6391a46d2cfbfa977e26900e5', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"spell_cast_add_counters":true,"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_required_colors":["W","U","B","R"],"spell_cast_add_counters_target":"self","trigger":"spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class QuirionDryad translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spellgorger weird', 'Spellgorger Weird', '00710965d61dcb88af09147413c870a9', 'battle_rule_v1:238cedcb64a3ea5843c8e6b1697a55be', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"spell_cast_add_counters":true,"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_target":"self","trigger":"noncreature_spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpellgorgerWeird translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sprite dragon', 'Sprite Dragon', 'e570475608537595066a06bdea290f3a', 'battle_rule_v1:8f7117ada06b523b5625123accd43ed4', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"keywords":["flying","haste"],"spell_cast_add_counters":true,"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_target":"self","trigger":"noncreature_spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpriteDragon translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stormkeld prowler', 'Stormkeld Prowler', '042cf0569eb69b7a38aad5dacccff56c', 'battle_rule_v1:d00757460f6000145d9726ccd740eeac', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":2,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"spell_cast_add_counters":true,"spell_cast_add_counters_count":2,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_mana_value_min":5,"spell_cast_add_counters_target":"self","trigger":"spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StormkeldProwler translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tempest angler', 'Tempest Angler', '00710965d61dcb88af09147413c870a9', 'battle_rule_v1:238cedcb64a3ea5843c8e6b1697a55be', '{"ability_kind":"triggered","battle_model_scope":"xmage_spell_cast_add_counters_source_v1","counter_count":1,"counter_type":"+1/+1","effect":"creature","is_creature_permanent":true,"spell_cast_add_counters":true,"spell_cast_add_counters_count":1,"spell_cast_add_counters_counter_type":"+1/+1","spell_cast_add_counters_target":"self","trigger":"noncreature_spell_cast","trigger_effect":"add_counters","xmage_ability_class":"SpellCastControllerTriggeredAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TempestAngler translated into ManaLoom runtime scope xmage_spell_cast_add_counters_source_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
