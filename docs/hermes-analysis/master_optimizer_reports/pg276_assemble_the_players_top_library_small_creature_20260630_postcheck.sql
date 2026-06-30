WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('assemble the players', 'Assemble the Players', 'ffdf411200b723c016fe9df0d85dd8e4', 'battle_rule_v1:692dcb8d1b5149bfef05a32ceb217882', '{"ability_kind":"static","battle_model_scope":"top_library_look_any_time_cast_creature_power_2_or_less_once_each_turn_pay_cost_v1","cmc":2.0,"effect":"topdeck_play","enchantment":true,"look_top_library_any_time":true,"mana_cost":"{1}{W}","top_library_cast_card_types":["creature"],"top_library_cast_once_each_turn":true,"top_library_cast_power_max":2,"top_library_cast_requires_pay_mana_cost":true}'::jsonb, '{"category":"engine","effect":"topdeck_play","subtype":"static_top_library_small_creature_cast_permission","timing":"main_phase_normal_timing"}'::jsonb, 'curated', 0.9, 'verified', 'auto', 'Oracle-reviewed on 2026-06-30 against local XMage AssembleThePlayers.java and PostgreSQL text: look at top card any time; once each turn, cast a creature spell with power 2 or less from top of library. Runtime focused test proves main-phase normal-cost cast from library top, power check, once-per-turn source tracking, replay, and decision trace.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg276_assemble_the_players_top_library_small_creature_20) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
