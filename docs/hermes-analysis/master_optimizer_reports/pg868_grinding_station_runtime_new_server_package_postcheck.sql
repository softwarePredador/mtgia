WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('grinding station', 'Grinding Station', '288857f5e91e9574eff7a561f5d6708e', 'battle_rule_v1:717756665b21129116b06005239d6754', '{"ability_kind":"triggered","activation_requires_sacrifice_permanent":true,"activation_requires_tap":true,"activation_sacrifice_target_type":"artifact","artifact_enters_untap_source":true,"artifact_enters_untap_source_status":"runtime_executor_v1","battle_model_scope":"artifact_tap_sacrifice_permanent_target_player_mill_v1","effect":"mill_engine","mill_count":3,"target":"player"}'::jsonb, '{"category":"combo_value","effect":"mill","subtype":"library_mill","timing":"resolution_or_activation"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage-authoritative Grinding Station: tap and sacrifice an artifact to mill target player for three; another artifact entering untaps the source. Both branches are implemented and focused-tested in the native ManaLoom runtime.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg868_grinding_station_runtime_new_serve_20260715_163640) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
