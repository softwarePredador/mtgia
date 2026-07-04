WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('basal thrull', 'Basal Thrull', '6cde21b2f4ce73144008f302c2dc65f5', 'battle_rule_v1:d69eb95d509e5b2fec24a34ae88604f5', '{"ability_kind":"activated_mana","activation_requires_sacrifice":true,"activation_requires_tap":true,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":true,"mana_produced":2,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["B","B"],"produces":"B","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BasalThrull translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood pet', 'Blood Pet', 'ac212076f211191deac254a55b9e4efa', 'battle_rule_v1:ae1ea7dbc6e05e2d7b58a956a76436a4', '{"ability_kind":"activated_mana","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":1,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["B"],"produces":"B","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodPet translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood vassal', 'Blood Vassal', '1f0d84d040066bc4b65f9180aeb988b6', 'battle_rule_v1:986b9a375a4fa1053952e158a7960f77', '{"ability_kind":"activated_mana","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":2,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["B","B"],"produces":"B","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodVassal translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('catalyst elemental', 'Catalyst Elemental', '2624a42fe38948a6225a247ba102d11d', 'battle_rule_v1:bf5beac6b4c97d8fa4b70d0abf648fa1', '{"ability_kind":"activated_mana","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":2,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["R","R"],"produces":"R","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CatalystElemental translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('coal golem', 'Coal Golem', '6264558f562814b786de6f70b27ab302', 'battle_rule_v1:1baab616b093b614441a897eb9c90aff', '{"ability_kind":"activated_mana","activation_mana_cost":"{3}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":3,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["R","R","R"],"produces":"R","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CoalGolem translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('composite golem', 'Composite Golem', '47bfdc582372221ae2df2b205fc9915e', 'battle_rule_v1:ccbe6b5ec18a31f45f2f6dc22c798cce', '{"ability_kind":"activated_mana","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":5,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CompositeGolem translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crosis''s attendant', 'Crosis''s Attendant', '4854a7b1f3411876f75702a095fa0e68', 'battle_rule_v1:e43e3146992b940b3e12e14c74fabcc6', '{"ability_kind":"activated_mana","activation_mana_cost":"{1}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":3,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["U","B","R"],"produces":"UBR","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrosissAttendant translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('darigaaz''s attendant', 'Darigaaz''s Attendant', 'dbe0025036fa2c70556d0e7e4da0aa4b', 'battle_rule_v1:165a08267c0d88bed3c2121070dd3ca6', '{"ability_kind":"activated_mana","activation_mana_cost":"{1}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":3,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["B","R","G"],"produces":"BRG","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DarigaazsAttendant translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('dromar''s attendant', 'Dromar''s Attendant', 'c9662cc22adc7299ec1263bb09852eb3', 'battle_rule_v1:913f2628280c75f83623b274394c78ab', '{"ability_kind":"activated_mana","activation_mana_cost":"{1}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":3,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["W","U","B"],"produces":"WUB","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DromarsAttendant translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('morgue toad', 'Morgue Toad', '026d2deece1ad85cf38951b86dca35eb', 'battle_rule_v1:d7bd10f259751a844ba56293ab501501', '{"ability_kind":"activated_mana","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":2,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["U","R"],"produces":"UR","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MorgueToad translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rith''s attendant', 'Rith''s Attendant', 'c71c0b720143aa4459ace2161bf240a8', 'battle_rule_v1:e6eb30b02a5e82a34a0af6a85631696c', '{"ability_kind":"activated_mana","activation_mana_cost":"{1}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":3,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["R","G","W"],"produces":"RGW","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RithsAttendant translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('satyr hedonist', 'Satyr Hedonist', 'f7172fdc53573436376e238e0fc92c2c', 'battle_rule_v1:af510c5e5b789c3ad56b26271af0c3df', '{"ability_kind":"activated_mana","activation_mana_cost":"{R}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":3,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["R","R","R"],"produces":"R","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SatyrHedonist translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('treva''s attendant', 'Treva''s Attendant', '3c623b378945ea9372f8515717483778', 'battle_rule_v1:9d409157b20663ee285ca20a1fafd18c', '{"ability_kind":"activated_mana","activation_mana_cost":"{1}","activation_requires_sacrifice":true,"activation_requires_tap":false,"battle_model_scope":"xmage_self_sacrifice_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_sacrifice":true,"mana_activation_requires_tap":false,"mana_produced":3,"mana_source_contextual_only":true,"permanent_type":"creature","produced_mana_symbols":["G","W","U"],"produces":"GWU","xmage_ability_class":"SimpleManaAbility","xmage_cost_class":"SacrificeSourceCost","xmage_effect_classes":[],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TrevasAttendant translated into ManaLoom runtime scope xmage_self_sacrifice_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
