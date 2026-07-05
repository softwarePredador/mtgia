WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('neurok commando', 'Neurok Commando', '5513aef42481c662aaeeee3a98d5227a', 'battle_rule_v1:cd5f769f19b180ce4a560d21eb27f76b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_draw_optional":true,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","keywords":["shroud"],"shroud":true,"trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NeurokCommando translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nine-tail white fox', 'Nine-Tail White Fox', '627f15bab58135bb3d3fb2e93631ab18', 'battle_rule_v1:c56d68f4a4065978a7e96cac35abd44e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NineTailWhiteFox translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scroll thief', 'Scroll Thief', '627f15bab58135bb3d3fb2e93631ab18', 'battle_rule_v1:c56d68f4a4065978a7e96cac35abd44e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrollThief translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soulknife spy', 'Soulknife Spy', '627f15bab58135bb3d3fb2e93631ab18', 'battle_rule_v1:c56d68f4a4065978a7e96cac35abd44e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulknifeSpy translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stealer of secrets', 'Stealer of Secrets', '627f15bab58135bb3d3fb2e93631ab18', 'battle_rule_v1:c56d68f4a4065978a7e96cac35abd44e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StealerOfSecrets translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg480_combat_damage_draw_20260705_040440) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
