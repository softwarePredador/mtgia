WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('codie, vociferous codex', 'Codie, Vociferous Codex', '445ec79cadbe4b40f691f1ae29915e0a', 'battle_rule_v1:81d37f81103c71bab684ac77e4e52ad2', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The independent activated mana ability is fully modeled and covered by the simple mana-source runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_mana_cost":"{4}","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":5,"modeled_ability_subset":"mana_source_only","permanent_type":"creature","produced_mana_symbols":["W","U","B","R","G"],"produces":"WUBRG","xmage_ability_classes":["CodieVociferousCodexDelayedTriggeredAbility","DelayedTriggeredAbility","SimpleManaAbility","SimpleStaticAbility"],"xmage_auxiliary_ability_classes":["CodieVociferousCodexDelayedTriggeredAbility","DelayedTriggeredAbility","SimpleStaticAbility"],"xmage_effect_classes":["CodieVociferousCodexCantCastEffect","CodieVociferousCodexEffect","CreateDelayedTriggeredAbilityEffect","OneShotEffect","PlayFromNotOwnHandZoneTargetEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["CodieVociferousCodexDelayedTriggeredAbility","DelayedTriggeredAbility","SimpleStaticAbility"],"xmage_unmodeled_effect_classes":["CodieVociferousCodexCantCastEffect","CodieVociferousCodexEffect","CreateDelayedTriggeredAbilityEffect","OneShotEffect","PlayFromNotOwnHandZoneTargetEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CodieVociferousCodex translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('strixhaven stadium', 'Strixhaven Stadium', 'f7eb994071b89b6633b3800563919e1f', 'battle_rule_v1:57ea1b4e976e9c3091d50326c3cbe545', '{"_runtime_partial":true,"_runtime_partial_batch_safe":true,"_runtime_partial_batch_safe_reason":"The independent activated mana ability is fully modeled and covered by the simple mana-source runtime/E2E scenario; auxiliary non-mana abilities remain explicitly unmodeled.","_runtime_partial_reason":"Only the XMage mana ability is executable in this rule; listed auxiliary ability/effect classes remain unmodeled.","ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_permanent_v1","effect":"ramp_permanent","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"modeled_ability_subset":"mana_source_only","permanent_type":"artifact","produced_mana_symbols":["C"],"produces":"C","xmage_ability_classes":["ColorlessManaAbility","DealsDamageToAPlayerAllTriggeredAbility","DealsDamageToYouAllTriggeredAbility"],"xmage_auxiliary_ability_classes":["DealsDamageToAPlayerAllTriggeredAbility","DealsDamageToYouAllTriggeredAbility"],"xmage_effect_classes":["AddCountersSourceEffect","OneShotEffect","RemoveCounterSourceEffect","StrixhavenStadiumEffect"],"xmage_mana_ability_classes":["ColorlessManaAbility"],"xmage_unmodeled_auxiliary_ability_classes":["DealsDamageToAPlayerAllTriggeredAbility","DealsDamageToYouAllTriggeredAbility"],"xmage_unmodeled_effect_classes":["AddCountersSourceEffect","OneShotEffect","RemoveCounterSourceEffect","StrixhavenStadiumEffect"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StrixhavenStadium translated into ManaLoom runtime scope xmage_simple_tap_mana_source_permanent_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg831_simple_mana_source_partial_safe_ne_20260712_124708) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
