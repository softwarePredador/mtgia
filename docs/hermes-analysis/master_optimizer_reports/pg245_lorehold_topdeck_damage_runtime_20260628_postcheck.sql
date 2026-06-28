WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('twinflame tyrant', 'Twinflame Tyrant', 'e4ca0585f743b1c34c36649bfbb1fff6', 'battle_rule_v1:072370a98c9b332eef021390bfc1694a', '{"ability_kind":"static","battle_model_scope":"controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1","cmc":5.0,"damage_modifier_applies_to":"sources_you_control","damage_modifier_duration":"while_on_battlefield","damage_modifier_targets":["opponents","opponent_permanents"],"damage_multiplier":2,"effect":"damage_modifier","flying":true,"power":3,"toughness":5}'::jsonb, '{"category":"wincon","effect":"damage_modifier","subtype":"damage_doubler","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TwinflameTyrant mapped to family static_damage_modifier; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('verge rangers', 'Verge Rangers', '44aa2eeb2eeb517fb30478aec7cec42f', 'battle_rule_v1:85ae1e46c9ad082e1807ac9e9f5420bd', '{"ability_kind":"static","battle_model_scope":"look_top_library_play_lands_from_top_if_opponent_more_lands_v1","cmc":3.0,"effect":"topdeck_play","keywords":["first_strike"],"look_top_library_any_time":true,"play_from_top_condition":"opponent_controls_more_lands","play_lands_from_top_library":true,"power":3,"toughness":3}'::jsonb, '{"category":"ramp","effect":"topdeck_play","subtype":"play_lands_from_library","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VergeRangers mapped to family topdeck_play; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg245_lorehold_topdeck_damage_runtime_20260628_015359) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
