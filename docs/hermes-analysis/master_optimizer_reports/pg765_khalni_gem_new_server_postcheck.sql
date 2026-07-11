WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('khalni gem', 'Khalni Gem', 'd39f34a51eb4e49360a228042c1eb2d9', 'battle_rule_v1:06060ff363b50cf932d825d4a4937fac', '{"ability_kind":"mana_and_triggered","activation_requires_tap":true,"battle_model_scope":"xmage_simple_mana_source_with_etb_return_lands_to_hand_v1","effect":"ramp_permanent","etb_return_controlled_lands_to_hand_count":2,"etb_return_controlled_lands_to_hand_min_available":true,"etb_return_lands_targeting":"not_target","is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"artifact","produces":"WUBRG","trigger":"enters_battlefield","trigger_effect":"return_lands_to_hand","xmage_ability_classes":["EntersBattlefieldTriggeredAbility","SimpleManaAbility"],"xmage_auxiliary_ability_classes":["EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","KhalniGemReturnToHandTargetEffect","OneShotEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class KhalniGem translated into ManaLoom runtime scope xmage_simple_mana_source_with_etb_return_lands_to_hand_v1. This row is package-ready only because the source signature is a narrow mana-source permanent with enter-the-battlefield return controlled lands trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg765_khalni_gem_new_server_khalni_gem_e_20260711_134814) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
