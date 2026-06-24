WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('carrion feeder', 'Carrion Feeder', 'aa7a8c93f13391b97e99e8ab170090b2', 'battle_rule_v1:98705567ca9c39c0389d04fd0f5d9c98', '{"ability_kind":"triggered","activation_cost":"sacrifice_creature","battle_model_scope":"sacrifice_creature_put_plus_one_counter_on_self_cant_block_v1","cant_block":true,"effect":"creature","power":1,"self_add_plus_one_counter":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CarrionFeeder mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('icatian moneychanger', 'Icatian Moneychanger', '40b1aa102ad1d51470f23051be0ceca9', 'battle_rule_v1:52cac2abd4e1ea92330cfc12ba51ec5a', '{"ability_kind":"triggered","activation_cost":"sacrifice_self","activation_only_your_upkeep":true,"battle_model_scope":"credit_counter_upkeep_growth_sacrifice_for_life_v1","effect":"creature","enters_with_credit_counters":3,"etb_damage_controller":3,"gain_life_per_credit_counter":true,"power":0,"toughness":2,"upkeep_add_credit_counter":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class IcatianMoneychanger mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('warden of the grove', 'Warden of the Grove', 'ceb13a31308fc0f6e25631a6266a257a', 'battle_rule_v1:ccfa4a6a8d4e8d3b93cbef43611c3694', '{"ability_kind":"triggered","battle_model_scope":"end_step_plus_one_counter_and_other_nontoken_creature_endures_x_v1","effect":"creature","end_step_add_plus_one_counter":1,"other_nontoken_creature_endures_equal_to_source_counters":true,"power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WardenOfTheGrove mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wildborn preserver', 'Wildborn Preserver', 'ef7f70900e5cc27e77031ae20d6b3770', 'battle_rule_v1:5695544e75290878fdfdfa602648642d', '{"ability_kind":"triggered","another_nonhuman_etb_optional_pay_x_for_x_plus_one_counters_on_self":true,"battle_model_scope":"flash_reach_nonhuman_etb_pay_x_put_x_plus_one_counters_on_self_v1","effect":"creature","flash":true,"power":2,"reach":true,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WildbornPreserver mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg126_add_counters_creature_runtime_restore_20260624_000) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
