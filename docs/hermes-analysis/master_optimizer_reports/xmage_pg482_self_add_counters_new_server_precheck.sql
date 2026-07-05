WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('carnivorous moss-beast', 'Carnivorous Moss-Beast', '49068d66e409b3ed3d3a4f7ca7fd4929', 'battle_rule_v1:8a782138d8d63502af38d50b5968c239', '{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":["G","G"],"activation_cost_generic":5,"activation_cost_mana":"{5}{G}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CarnivorousMossBeast translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('chronomaton', 'Chronomaton', 'c36a67be5df8f853c60f592d49b5a615', 'battle_rule_v1:88916f73f73e2df515bbef6919805dc5', '{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":1,"activation_cost_mana":"{1}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Chronomaton translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('energizer', 'Energizer', '5a1a86ec889efb431814a500926fab3d', 'battle_rule_v1:2c56305f71d41d557570b6ee424d7bc1', '{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Energizer translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hungry megasloth', 'Hungry Megasloth', '9dacf6afa99ff17f48850d4d29834bd6', 'battle_rule_v1:5c70a79648cdeb0e669a29f1c875f1db', '{"_keywords_are_self":true,"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":2,"activation_cost_mana":"{2}","activation_requires_sacrifice":false,"activation_requires_tap":true,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"keywords":["reach"],"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HungryMegasloth translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jenara, asura of war', 'Jenara, Asura of War', '385de3d6d2637476db28317157b5c511', 'battle_rule_v1:d1c39ea5aafb1d002bc9cf60583c4388', '{"_keywords_are_self":true,"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":["W"],"activation_cost_generic":1,"activation_cost_mana":"{1}{W}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"keywords":["flying"],"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JenaraAsuraOfWar translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('jungle delver', 'Jungle Delver', '4a2663cf4c2703fd61427c875548ce01', 'battle_rule_v1:233eac8995e59d158cd014a90e5f3a95', '{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":["G"],"activation_cost_generic":3,"activation_cost_mana":"{3}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class JungleDelver translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ruins recluse', 'Ruins Recluse', '50b63a239462d9429bc682b0d99e6a5a', 'battle_rule_v1:6fcbbccfc5cacd668296e1e1b787d82b', '{"_keywords_are_self":true,"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":["G"],"activation_cost_generic":3,"activation_cost_mana":"{3}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"keywords":["deathtouch","reach"],"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RuinsRecluse translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sledding otter-penguin', 'Sledding Otter-Penguin', '5d51caebfd5fb3e38af00985b8024ea9', 'battle_rule_v1:7f62f3608687b28a16eeadafe7efa4c4', '{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":[],"activation_cost_generic":3,"activation_cost_mana":"{3}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SleddingOtterPenguin translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('unholy officiant', 'Unholy Officiant', '748031dc4868a157d229f5d2d746e0b8', 'battle_rule_v1:314d02cb0db136b0a71adaaffd76e30e', '{"_keywords_are_self":true,"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":["W"],"activation_cost_generic":4,"activation_cost_mana":"{4}{W}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"keywords":["vigilance"],"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class UnholyOfficiant translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('verdant automaton', 'Verdant Automaton', '4a2663cf4c2703fd61427c875548ce01', 'battle_rule_v1:233eac8995e59d158cd014a90e5f3a95', '{"ability_kind":"activated","activated_add_counters":true,"activated_add_counters_count":1,"activated_add_counters_counter_type":"+1/+1","activated_add_counters_target":"self","activated_battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","activated_effect":"add_counters","activation_cost_colors":["G"],"activation_cost_generic":3,"activation_cost_mana":"{3}{G}","activation_requires_sacrifice":false,"activation_requires_tap":false,"battle_model_scope":"xmage_permanent_simple_activated_self_add_counters_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"creature","instant":false,"sorcery":false,"target":"self","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"AddCountersSourceEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VerdantAutomaton translated into ManaLoom runtime scope xmage_permanent_simple_activated_self_add_counters_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
