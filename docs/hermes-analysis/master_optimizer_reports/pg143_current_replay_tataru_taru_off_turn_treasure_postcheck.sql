WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('tataru taru', 'Tataru Taru', '313b5afad418df592c6011b08c80d972', 'battle_rule_v1:78e8097d6f3437e339ab729d87e5099a', '{"ability_kind":"triggered","battle_model_scope":"etb_draw_target_opponent_may_draw_off_turn_once_each_turn_tapped_treasure_v1","effect":"ramp_engine","etb_draw_count":1,"etb_target_opponent_may_draw_choice_model":"compact_assume_yes_single_card_v1","etb_target_opponent_may_draw_count":1,"is_creature_permanent":true,"power":0,"toughness":3,"treasure_count":1,"treasure_tokens_tapped":true,"trigger":"opponent_draw","trigger_limit_each_turn":1,"trigger_only_off_turn_opponent_draw":true}'::jsonb, '{"category":"ramp","effect":"ramp_engine","timing":"triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TataruTaru mapped to family ramp_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg143_current_replay_tataru_taru_off_turn_treasure_20260) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
