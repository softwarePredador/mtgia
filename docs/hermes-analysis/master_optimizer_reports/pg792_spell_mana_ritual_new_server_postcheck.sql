WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('battle hymn', 'Battle Hymn', 'd10736bf0f1c20741e6573e8a0f9756f', 'battle_rule_v1:ecc388cb0b7a7b6053fa356c319a35d0', '{"ability_kind":"one_shot","battle_model_scope":"xmage_controlled_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_battlefield_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_battlefield_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BattleHymn translated into ManaLoom runtime scope xmage_controlled_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('channel the suns', 'Channel the Suns', '00f37ae750187d98c2ee7ef1cefe2d81', 'battle_rule_v1:99bac902f7bd0c57a57d2986e5798b55', '{"ability_kind":"one_shot","battle_model_scope":"xmage_fixed_spell_mana_ritual_v1","effect":"ramp_ritual","instant":false,"mana_amount_model":"fixed","mana_color_status":"colored_pool_runtime","mana_produced":5,"produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","sorcery":true,"xmage_effect_class":"AddManaToManaPoolSourceControllerEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChannelTheSuns translated into ManaLoom runtime scope xmage_fixed_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('inner fire', 'Inner Fire', '8a7377dabd39dd4288983536683a62c2', 'battle_rule_v1:5c3ffd7cf5ad80a9c9334df4e439b863', '{"ability_kind":"one_shot","battle_model_scope":"xmage_hand_size_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_hand_size","effect":"ramp_ritual","instant":false,"mana_amount_model":"controller_hand_size","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"R","sorcery":true,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class InnerFire translated into ManaLoom runtime scope xmage_hand_size_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('songs of the damned', 'Songs of the Damned', 'bd0c43c5486b85ec17a57ad84ebfef68', 'battle_rule_v1:5a7a56cb9e6b6ff52ebe704b292915ba', '{"ability_kind":"one_shot","battle_model_scope":"xmage_graveyard_creature_count_spell_mana_ritual_v1","dynamic_mana_amount":true,"dynamic_mana_amount_source":"controller_graveyard_creature_count","effect":"ramp_ritual","instant":true,"mana_amount_model":"controller_graveyard_creature_count","mana_color_status":"colored_pool_runtime","mana_per_count":1,"mana_produced":1,"produces":"B","sorcery":false,"xmage_effect_class":"DynamicManaEffect"}'::jsonb, '{"category":"ramp","effect":"ramp_ritual","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SongsOfTheDamned translated into ManaLoom runtime scope xmage_graveyard_creature_count_spell_mana_ritual_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds exact fixed or count-based mana with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg792_spell_mana_ritual_20260711_225729) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
