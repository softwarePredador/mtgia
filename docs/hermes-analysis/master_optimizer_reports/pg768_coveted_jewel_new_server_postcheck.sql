WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('coveted jewel', 'Coveted Jewel', '467d89a73301ab599871111e0ceaec6d', 'battle_rule_v1:88dafe15957e9554a2f0bda79cbd27ea', '{"ability_kind":"activated_mana_etb_and_unblocked_attack_trigger","activation_requires_tap":true,"battle_model_scope":"xmage_simple_mana_source_with_etb_draw_unblocked_attack_control_transfer_v1","effect":"ramp_permanent","etb_draw_count":3,"is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":3,"permanent_type":"artifact","produces":"WUBRG","source_mana_cost":"{6}","source_type_line":"Artifact","trigger":"enters_battlefield","trigger_effect":"draw_cards","unblocked_attack_control_transfer":true,"unblocked_attack_draw_count":3,"unblocked_attack_trigger_controller":"opponent","unblocked_attack_untap_on_transfer":true,"xmage_ability_classes":["CovetedJewelTriggeredAbility","EntersBattlefieldTriggeredAbility","SimpleManaAbility"],"xmage_auxiliary_ability_classes":["CovetedJewelTriggeredAbility","EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","DrawCardSourceControllerEffect","DrawCardTargetEffect","TargetPlayerGainControlSourceEffect","UntapSourceEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CovetedJewel translated into ManaLoom runtime scope xmage_simple_mana_source_with_etb_draw_unblocked_attack_control_transfer_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg768_coveted_jewel_new_server_coveted_j_20260711_145658) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
