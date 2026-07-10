WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('abyssal gatekeeper', 'Abyssal Gatekeeper', '882b690c3b89b0b0a3de931b3e6e3cc1', 'battle_rule_v1:38dc27ef7f3aaaa64d69ca3af90e8948', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_each_player_sacrifice_fixed_permanents_v1","dies_each_player_sacrifice":true,"effect":"creature","instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":false,"trigger":"dies","trigger_effect":"each_player_sacrifice","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbyssalGatekeeper translated into ManaLoom runtime scope xmage_creature_dies_each_player_sacrifice_fixed_permanents_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('akki blizzard-herder', 'Akki Blizzard-Herder', '76e5249dc8fad55956f9aeeec989f1ea', 'battle_rule_v1:fcbd2830364aa99be41a8cedcbbf6eb7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_each_player_sacrifice_fixed_permanents_v1","dies_each_player_sacrifice":true,"effect":"creature","instant":false,"sacrifice_card_types":["land"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":false,"trigger":"dies","trigger_effect":"each_player_sacrifice","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AkkiBlizzardHerder translated into ManaLoom runtime scope xmage_creature_dies_each_player_sacrifice_fixed_permanents_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('hurloon shaman', 'Hurloon Shaman', '76e5249dc8fad55956f9aeeec989f1ea', 'battle_rule_v1:fcbd2830364aa99be41a8cedcbbf6eb7', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_each_player_sacrifice_fixed_permanents_v1","dies_each_player_sacrifice":true,"effect":"creature","instant":false,"sacrifice_card_types":["land"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":false,"trigger":"dies","trigger_effect":"each_player_sacrifice","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HurloonShaman translated into ManaLoom runtime scope xmage_creature_dies_each_player_sacrifice_fixed_permanents_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg708_dies_each_player_sacrifice_new_ser_20260710_155036) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
