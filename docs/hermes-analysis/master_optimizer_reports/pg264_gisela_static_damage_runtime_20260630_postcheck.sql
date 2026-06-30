WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('gisela, blade of goldnight', 'Gisela, Blade of Goldnight', 'c59105cb2fa02882b4485d6a06ab6187', 'battle_rule_v1:a8b6b99ddc6deb9fe2fdb85033a950a4', '{"ability_kind":"static","battle_model_scope":"opponent_or_opponent_permanent_damage_doubled_self_damage_halved_v1","damage_modifier_applies_to":"any_source","damage_modifier_duration":"while_on_battlefield","damage_modifier_targets":["opponents","opponent_permanents"],"damage_multiplier":2,"effect":"damage_modifier","first_strike":true,"flying":true,"power":5,"prevent_half_damage_to_you_and_permanents_you_control":true,"prevent_half_rounding":"rounded_up","toughness":5}'::jsonb, '{"category":"wincon","effect":"damage_modifier","subtype":"damage_doubler","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GiselaBladeOfGoldnight mapped to family static_damage_modifier; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg264_gisela_static_damage_runtime_20260630_20260630_054) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
