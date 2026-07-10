WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('abyssal gorestalker', 'Abyssal Gorestalker', 'da8eee9a8cf82be79c910cdeb6f27c64', 'battle_rule_v1:762091a72ba68a7cbe04537ddfe81772', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1","effect":"creature","etb_each_player_sacrifice":true,"instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":2,"sacrifice_scope":"each_player","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"each_player_sacrifice","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AbyssalGorestalker translated into ManaLoom runtime scope xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fleshbag marauder', 'Fleshbag Marauder', '64df51b439e4ec65e06004d68d2c4f8f', 'battle_rule_v1:3f79521e9885d159a5022d34ada61d98', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1","effect":"creature","etb_each_player_sacrifice":true,"instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"each_player_sacrifice","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FleshbagMarauder translated into ManaLoom runtime scope xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('merciless executioner', 'Merciless Executioner', '64df51b439e4ec65e06004d68d2c4f8f', 'battle_rule_v1:3f79521e9885d159a5022d34ada61d98', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1","effect":"creature","etb_each_player_sacrifice":true,"instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"each_player_sacrifice","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MercilessExecutioner translated into ManaLoom runtime scope xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('slum reaper', 'Slum Reaper', '64df51b439e4ec65e06004d68d2c4f8f', 'battle_rule_v1:3f79521e9885d159a5022d34ada61d98', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1","effect":"creature","etb_each_player_sacrifice":true,"instant":false,"sacrifice_card_types":["creature"],"sacrifice_choice":"controller_choice_lowest_value","sacrifice_count":1,"sacrifice_scope":"each_player","sorcery":false,"trigger":"enters_battlefield","trigger_effect":"each_player_sacrifice","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"SacrificeAllEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SlumReaper translated into ManaLoom runtime scope xmage_creature_etb_each_player_sacrifice_fixed_permanents_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg707_etb_each_player_sacrifice_new_serv_20260710_153453) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
