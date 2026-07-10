WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('bile-vial boggart', 'Bile-Vial Boggart', '765f9a0c55872371d4e69b2dea91632d', 'battle_rule_v1:d99ef6cb26e7f6879ee8558b6b1f24c6', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"-1/-1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count_max":1,"target_count_min":0,"trigger":"dies","trigger_effect":"add_counters","up_to_count":true,"xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BileVialBoggart translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('festering mummy', 'Festering Mummy', '9e47de100c190411c8e30156312a120c', 'battle_rule_v1:500f0abd244b5b94191c9b4ff1243b01', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"-1/-1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"-1/-1","dies_add_counters_optional":true,"dies_add_counters_target":"creature","effect":"creature","instant":false,"optional":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FesteringMummy translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('goblin assault team', 'Goblin Assault Team', '599e24538eeab1caa1dea482843a1802', 'battle_rule_v1:fdc0ed4e42df19e95b8f2b81f30c3963', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"keywords":["haste"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GoblinAssaultTeam translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('guul draz mucklord', 'Guul Draz Mucklord', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GuulDrazMucklord translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('lawless broker', 'Lawless Broker', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LawlessBroker translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sparring construct', 'Sparring Construct', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SparringConstruct translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('spinal centipede', 'Spinal Centipede', 'b2cf73bf78e0e5a7cd750ad498f2773e', 'battle_rule_v1:dc6d9eeb7537ceb1ad4b8351b1af12d8', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SpinalCentipede translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('steadfast sentry', 'Steadfast Sentry', '5bd444489d885eeb73b0aec7c7f0609f', 'battle_rule_v1:741a080f18b880224c645da9fc305da1', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"keywords":["vigilance"],"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self"},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SteadfastSentry translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('venerable knight', 'Venerable Knight', '27c7ab08136b9ceb9eca7963462af6c6', 'battle_rule_v1:44c3f8f7e38bf65029e832f0b8195111', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_add_counters_target_creature_v1","count":1,"counter_count":1,"counter_type":"+1/+1","dies_add_counters":true,"dies_add_counters_count":1,"dies_add_counters_counter_type":"+1/+1","dies_add_counters_target":"creature","effect":"creature","instant":false,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller_scope":"self","required_subtypes":["knight"]},"target_controller":"self","trigger":"dies","trigger_effect":"add_counters","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VenerableKnight translated into ManaLoom runtime scope xmage_creature_dies_add_counters_target_creature_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
