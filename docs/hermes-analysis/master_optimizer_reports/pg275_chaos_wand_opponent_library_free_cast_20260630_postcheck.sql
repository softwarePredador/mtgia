WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('chaos wand', 'Chaos Wand', '7b77d47629eb006df4e9754fee988c51', 'battle_rule_v1:cb5acba44191c9c6711c017b4c3590d0', '{"ability_kind":"activated","activated_effect":"opponent_library_free_cast","activated_opponent_library_exile_until_card_types":["instant","sorcery"],"activation_cost_generic":4,"activation_requires_tap":true,"artifact":true,"battle_model_scope":"pay_four_tap_target_opponent_exile_until_instant_sorcery_may_cast_free_bottom_rest_v1","cmc":3.0,"effect":"passive","mana_cost":"{3}","opponent_library_bottom_uncast_exiled_random":true,"opponent_library_exile_until_cast_without_paying_mana":true,"target":"opponent"}'::jsonb, '{"category":"value","effect":"passive","subtype":"activated_opponent_library_free_cast_artifact","timing":"activated_main_phase"}'::jsonb, 'curated', 0.91, 'verified', 'auto', 'PG275: Chaos Wand exact activated artifact scope from local XMage ChaosWand.java and focused ManaLoom runtime test; pay four and tap target opponent, exile until instant or sorcery, cast that card without paying mana, bottom the rest in random order.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg275_chaos_wand_opponent_library_free_cast_20260630_202) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
