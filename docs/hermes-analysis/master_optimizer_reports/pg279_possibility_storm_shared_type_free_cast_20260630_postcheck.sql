WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('possibility storm', 'Possibility Storm', '5da5211c6ce969ce3b5750e349c2b073', 'battle_rule_v1:160bebb577f9d874ec53bee6f8f3d3b8', '{"ability_kind":"triggered","alternate_zone_permission":true,"battle_model_scope":"spell_from_hand_exile_until_shared_type_free_cast_bottom_rest_random_v1","bottom_exiled_with_source_random":true,"effect":"free_cast","exile_from_top_until_shares_card_type":true,"exile_original_spell":true,"hit_card_may_cast_without_paying_mana_cost":true,"may_cast_without_paying_mana_cost":true,"possibility_storm_replacement":true,"source_zone_required":"hand","trigger":"spell_cast_from_hand","trigger_scope":"any_player"}'::jsonb, '{"category":"combo_value","effect":"free_cast","subtype":"cast_without_paying_mana","timing":"triggered_or_resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PossibilityStorm mapped to family free_cast; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg279_possibility_storm_shared_type_free_cast_20260630_1) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
