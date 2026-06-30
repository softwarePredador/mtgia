WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('currency converter', 'Currency Converter', '61871a4bb30c2b48607cee649e2812aa', 'battle_rule_v1:f1e1192b52ed56e41a07b33e311bd313', '{"ability_kind":"triggered","activated_discard_count":1,"activated_draw_count":1,"activated_draw_discard":true,"activated_put_exiled_card_into_graveyard_create_token":true,"battle_model_scope":"currency_converter_discard_exile_draw_discard_token_v1","controller_discard_may_exile_discarded_card_from_graveyard":true,"draw_discard_activation_cost_generic":2,"draw_discard_activation_requires_tap":true,"effect":"draw_engine","permanent_type":"artifact","token_activation_requires_tap":true,"token_colors":["B"],"token_count":1,"token_from_exiled_land":"treasure","token_from_exiled_nonland":"rogue","token_name":"Rogue Token","token_power":2,"token_subtype":"Rogue","token_toughness":2,"treasure_count":1,"trigger":"controller_discard"}'::jsonb, '{"category":"draw","effect":"draw_engine","subtype":"discard_exile_token_conversion","timing":"triggered_and_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CurrencyConverter mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg270_currency_converter_draw_engine_20260630_currency_c) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
