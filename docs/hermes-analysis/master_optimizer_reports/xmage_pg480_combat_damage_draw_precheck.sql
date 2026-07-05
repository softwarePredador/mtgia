WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('neurok commando', 'Neurok Commando', '5513aef42481c662aaeeee3a98d5227a', 'battle_rule_v1:cd5f769f19b180ce4a560d21eb27f76b', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_draw_optional":true,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","keywords":["shroud"],"shroud":true,"trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NeurokCommando translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('nine-tail white fox', 'Nine-Tail White Fox', '627f15bab58135bb3d3fb2e93631ab18', 'battle_rule_v1:c56d68f4a4065978a7e96cac35abd44e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NineTailWhiteFox translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scroll thief', 'Scroll Thief', '627f15bab58135bb3d3fb2e93631ab18', 'battle_rule_v1:c56d68f4a4065978a7e96cac35abd44e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScrollThief translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('soulknife spy', 'Soulknife Spy', '627f15bab58135bb3d3fb2e93631ab18', 'battle_rule_v1:c56d68f4a4065978a7e96cac35abd44e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SoulknifeSpy translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stealer of secrets', 'Stealer of Secrets', '627f15bab58135bb3d3fb2e93631ab18', 'battle_rule_v1:c56d68f4a4065978a7e96cac35abd44e', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_combat_damage_draw_cards_v1","combat_damage_draw_count":1,"combat_damage_player_draw":true,"draw_count":1,"effect":"creature","trigger":"combat_damage_to_player","trigger_effect":"draw_cards","xmage_ability_class":"DealsCombatDamageToAPlayerTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StealerOfSecrets translated into ManaLoom runtime scope xmage_creature_combat_damage_draw_cards_v1. This row is package-ready only because the source signature is a narrow creature combat-damage-to-player triggered fixed draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
