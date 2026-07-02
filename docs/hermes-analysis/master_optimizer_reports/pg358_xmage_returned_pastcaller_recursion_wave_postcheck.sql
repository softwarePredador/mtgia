WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('returned pastcaller', 'Returned Pastcaller', 'afafa879627b9008f2161e952b9c905c', 'battle_rule_v1:6675020f7bc86c55e647c5139d39cb1f', '{"_keywords_are_self":true,"ability_kind":"triggered","battle_model_scope":"xmage_creature_etb_return_graveyard_card_to_hand_v1","effect":"creature","etb_recursion_count":1,"etb_recursion_destination":"hand","etb_recursion_target":"spirit_instant_or_sorcery","flying":true,"keywords":["flying"],"target_constraints":{"any_of":[{"subtypes":["spirit"]},{"card_types":["instant"]},{"card_types":["sorcery"]}],"controller":"self","zone":"graveyard"},"trigger":"enters_battlefield","xmage_ability_class":"EntersBattlefieldTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReturnedPastcaller translated into ManaLoom runtime scope xmage_creature_etb_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature enter-the-battlefield triggered ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg358_xmage_returned_pastcaller_recursion_wave_20260702_) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
