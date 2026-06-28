WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('balefire liege', 'Balefire Liege', '467dd11263f2854e2d9fc487a127ced6', 'battle_rule_v1:0d0c24a976d267410f08eb69efa9d3d7', '{"ability_kind":"triggered","battle_model_scope":"red_spell_damage_white_spell_lifegain_static_creature_boost_v1","cmc":5.0,"effect":"creature","power":2,"red_spell_trigger_damage":3,"red_spell_trigger_damage_target":"player_or_planeswalker","static_boost_other_red_creatures_you_control":{"power":1,"toughness":1},"static_boost_other_white_creatures_you_control":{"power":1,"toughness":1},"toughness":4,"trigger":"spell_cast","trigger_effect":"spell_color_damage_life","white_spell_trigger_gain_life":3}'::jsonb, '{"category":"burn_lifegain_engine","effect":"spell_color_damage_life","subtype":"red_spell_damage_white_spell_lifegain","timing":"static_and_triggered"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BalefireLiege mapped to family targeted_interaction; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg_balefire_runtime_20260628_balefire_runtime_20260628_1) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
