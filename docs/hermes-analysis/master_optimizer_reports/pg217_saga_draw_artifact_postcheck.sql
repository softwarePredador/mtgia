WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('the locust god', 'The Locust God', '1b1e612bd7ad1564ae4d3ad8619013e2', 'battle_rule_v1:67d30157e4cec4c53fd99294af46a927', '{"ability_kind":"triggered","activated_loot":true,"activation_cost":"{2}{U}{R}","battle_model_scope":"controller_draw_create_1_1_flying_haste_insect_token_loot_death_return_v1","cmc":6.0,"controller_draw_create_token":true,"dies_return_to_owner_hand_next_end_step":true,"effect":"creature","flying":true,"power":4,"token_colors":["U","R"],"token_count_per_card_drawn":1,"token_flying":true,"token_haste":true,"token_name":"Insect Token","token_power":1,"token_subtype":"Insect","token_toughness":1,"toughness":4}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheLocustGod mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('fable of the mirror-breaker // reflection of kiki-jiki', 'Fable of the Mirror-Breaker // Reflection of Kiki-Jiki', '02f9bffe27fcef275a01555f7b6fc16b', 'battle_rule_v1:35f799486c8be66724ba9e6b155490f7', '{"ability_kind":"activated","battle_model_scope":"saga_goblin_rummage_transform_reflection_copy_v1","cmc":3.0,"effect":"token_maker","saga_chapter_effects":{"1":{"effect":"token_maker","token_attack_create_treasure":true,"token_colors":["R"],"token_count":1,"token_name":"Goblin Shaman Token","token_power":2,"token_subtype":"Goblin Shaman","token_toughness":2},"2":{"draw_equal_to_discarded":true,"effect":"discard_draw","max_discard":2},"3":{"effect":"transform"}},"saga_final_chapter":3,"transform_to":{"activated_copy_target_another_nonlegendary_creature_you_control":true,"activation_cost_generic":1,"activation_requires_tap":true,"copy_target_types":["creature"],"effect":"creature","exclude_legendary_copy_targets":true,"exclude_source_from_copy_targets":true,"name":"Reflection of Kiki-Jiki","power":2,"sacrifice_token_at_end_step":true,"target_controller":"own","token_haste":true,"toughness":2,"type_line":"Enchantment Creature - Goblin Shaman"}}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FableOfTheMirrorBreaker mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('biotransference', 'Biotransference', 'db6e884f32d6be76e85eebb3e3dd986c', 'battle_rule_v1:4b017d52015c70dfb33338170767bad8', '{"ability_kind":"triggered","artifact_tokens":true,"battle_model_scope":"controlled_creatures_are_artifacts_artifact_spell_life_loss_necron_token_v1","cmc":4.0,"controlled_creature_cards_owned_are_artifacts":true,"controlled_creatures_and_creature_spells_are_artifacts":true,"controller_loses_life_on_trigger":1,"effect":"token_maker","token_colors":["B"],"token_count":1,"token_name":"Necron Warrior Token","token_power":2,"token_subtype":"Necron Warrior","token_toughness":2,"trigger":"spell_cast","trigger_artifact_spell":true,"trigger_effect":"token_maker"}'::jsonb, '{"category":"board_development","effect":"token_maker","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Biotransference mapped to family token_maker; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg217_saga_draw_artifact_20260625_111141) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
