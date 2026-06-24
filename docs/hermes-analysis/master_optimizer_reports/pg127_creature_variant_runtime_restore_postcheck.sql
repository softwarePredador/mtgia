WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('colossal skyturtle', 'Colossal Skyturtle', '05180c03fc1bcfd31ff9d6fc65edfaad', 'battle_rule_v1:d4e643cbd0c20a5a58ca11b06c217a5e', '{"ability_kind":"one_shot","battle_model_scope":"flying_ward_channel_regrowth_or_bounce_creature_v1","channel_return_graveyard_card_to_hand":"{2}{G}","channel_return_target_creature_to_hand":"{1}{U}","effect":"creature","flying":true,"power":6,"toughness":5,"ward_cost":"{2}"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ColossalSkyturtle mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('abigale, eloquent first-year', 'Abigale, Eloquent First-Year', 'daac542cd4b7cf8f12bb55ffac868d1a', 'battle_rule_v1:212147ed06811dba5af5e2c58100c716', '{"ability_kind":"triggered","battle_model_scope":"etb_strip_other_creature_abilities_and_grant_keyword_counters_v1","effect":"creature","etb_grants_keyword_counters":["flying","first_strike","lifelink"],"etb_other_target_creature_loses_all_abilities":true,"first_strike":true,"flying":true,"lifelink":true,"power":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AbigaleEloquentFirstYear mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('glen elendra archmage', 'Glen Elendra Archmage', 'f05e697db3bcfb65a827970c08d1446a', 'battle_rule_v1:180387d5d5fc0c2417eb7372ed7a5909', '{"ability_kind":"activated","activated_counter_noncreature_spell_cost":"{U}","activation_cost":"sacrifice_self","battle_model_scope":"flying_persist_sacrifice_self_counter_noncreature_spell_v1","effect":"creature","flying":true,"persist":true,"power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GlenElendraArchmage mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg127_creature_variant_runtime_restore_20260624_001336) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
