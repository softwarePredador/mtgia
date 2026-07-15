WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('amulet of vigor', 'Amulet of Vigor', '0d3c7434ed983edcde555ec98cc71b96', 'battle_rule_v1:743fd8f0de4dfb77da6f173623545b87', '{"ability_kind":"permanent","artifact":true,"battle_model_scope":"xmage_tapped_permanent_entry_untap_v1","cmc":1.0,"effect":"untap_tapped_permanent_etb_engine","trigger":"permanent_enters_battlefield_tapped_under_your_control","trigger_controller":"self","untap_tapped_permanent_on_entry":true,"xmage_ability_class":"AmuletOfVigorTriggeredAbility","xmage_effect_class":"UntapTargetEffect"}'::jsonb, '{"category":"ramp","effect":"untap_tapped_permanent_etb_engine","subtype":"tapped_entry_untap_engine"}'::jsonb, 'curated', 0.99, 'verified', 'auto', 'XMage-authoritative triggered untap family with focused ManaLoom runtime coverage.', 'deprecate_nonmatching_rows'),
    ('exploration', 'Exploration', '575e8137f1155c881728e3c827307870', 'battle_rule_v1:1e7136a8801e5aa8f35435008f736e9d', '{"ability_kind":"static","additional_land_plays_each_turn":1,"battle_model_scope":"xmage_play_additional_lands_controller_v1","cmc":1.0,"duration":"while_on_battlefield","effect":"additional_land_play_static","xmage_ability_class":"SimpleStaticAbility","xmage_effect_class":"PlayAdditionalLandsControllerEffect"}'::jsonb, '{"category":"ramp","effect":"additional_land_play_static","subtype":"additional_land_play"}'::jsonb, 'curated', 0.99, 'verified', 'auto', 'XMage-authoritative static additional-land family with focused ManaLoom runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ghostly flicker', 'Ghostly Flicker', '4725dcda34e923c03bec0d9163d256e0', 'battle_rule_v1:a1a210055dbccd291a81ea82cff2d47a', '{"ability_kind":"spell","battle_model_scope":"xmage_exile_then_return_two_controlled_permanents_v1","cmc":3.0,"destination":"battlefield_under_your_control","effect":"blink_multiple","instant":true,"target":"artifact_creature_or_land_you_control","target_count_max":2,"target_count_min":2,"xmage_effect_class":"ExileThenReturnTargetEffect","xmage_target_class":"TargetPermanent","zone_transition":"exile_then_return_simultaneously"}'::jsonb, '{"category":"engine","effect":"blink_multiple","subtype":"multi_permanent_blink","timing":"instant"}'::jsonb, 'curated', 0.99, 'verified', 'auto', 'XMage-authoritative exact-two controlled permanent blink family with focused ManaLoom runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grasp of fate', 'Grasp of Fate', '0954b51cb2142383eab9d76adc926c4b', 'battle_rule_v1:4a3b11288c4a9b76e69dce2e8c7748f6', '{"ability_kind":"triggered","battle_model_scope":"xmage_exile_each_opponent_nonland_until_source_leaves_v1","cmc":3.0,"effect":"exile_each_opponent_nonland_until_source_leaves","for_each_opponent":true,"return_destination":"battlefield_under_owners_control","return_trigger":"source_leaves_battlefield","target":"up_to_one_nonland_permanent_each_opponent_controls","target_count_max_per_opponent":1,"target_count_min_per_opponent":0,"trigger":"enters_battlefield","xmage_effect_class":"ExileUntilSourceLeavesEffect","xmage_target_adjuster_class":"ForEachPlayerTargetsAdjuster","xmage_target_class":"TargetNonlandPermanent"}'::jsonb, '{"category":"removal","effect":"exile_each_opponent_nonland_until_source_leaves","subtype":"multiplayer_linked_exile"}'::jsonb, 'curated', 0.99, 'verified', 'auto', 'XMage-authoritative multiplayer linked-exile family with focused ManaLoom runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg599_runtime_closure_new_server_package_20260715_150619) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
