WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('arcum''s astrolabe', 'Arcum''s Astrolabe', 'b8440b4581f1393b623f598bf31c8341', 'battle_rule_v1:30884a43b3dc66d721472b52a6493f00', '{"ability_kind":"mana_and_triggered","activation_mana_cost":"{1}","activation_requires_tap":true,"battle_model_scope":"xmage_simple_mana_source_with_etb_draw_v1","effect":"ramp_permanent","etb_draw_count":1,"is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_classes":["AnyColorManaAbility","EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ArcumsAstrolabe translated into ManaLoom runtime scope xmage_simple_mana_source_with_etb_draw_v1. This row is package-ready only because the source signature is a narrow mana-source permanent with fixed enter-the-battlefield draw trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('energy refractor', 'Energy Refractor', 'cec4e478a79bc9f7ee003844fb1e3cdc', 'battle_rule_v1:f44443c9021d46c52c2315ad02ff0cd3', '{"ability_kind":"mana_and_triggered","activation_mana_cost":"{2}","activation_requires_tap":false,"battle_model_scope":"xmage_simple_mana_source_with_etb_draw_v1","effect":"ramp_permanent","etb_draw_count":1,"is_mana_source":true,"mana_activation_requires_tap":false,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_classes":["AnyColorManaAbility","EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class EnergyRefractor translated into ManaLoom runtime scope xmage_simple_mana_source_with_etb_draw_v1. This row is package-ready only because the source signature is a narrow mana-source permanent with fixed enter-the-battlefield draw trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('llanowar visionary', 'Llanowar Visionary', 'bb7ee1e889365c1602ebac24e4dbedab', 'battle_rule_v1:cea74fd817022b48dd64801a774cab19', '{"ability_kind":"mana_and_triggered","activation_requires_tap":true,"battle_model_scope":"xmage_simple_mana_source_with_etb_draw_v1","effect":"ramp_permanent","etb_draw_count":1,"is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"creature","produced_mana_symbols":["G"],"produces":"G","trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_classes":["EntersBattlefieldTriggeredAbility","GreenManaAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect"],"xmage_mana_ability_classes":["GreenManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LlanowarVisionary translated into ManaLoom runtime scope xmage_simple_mana_source_with_etb_draw_v1. This row is package-ready only because the source signature is a narrow mana-source permanent with fixed enter-the-battlefield draw trigger with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('prophetic prism', 'Prophetic Prism', 'dbafd52cab67ffc85aa684f524be0c37', 'battle_rule_v1:30884a43b3dc66d721472b52a6493f00', '{"ability_kind":"mana_and_triggered","activation_mana_cost":"{1}","activation_requires_tap":true,"battle_model_scope":"xmage_simple_mana_source_with_etb_draw_v1","effect":"ramp_permanent","etb_draw_count":1,"is_mana_source":true,"mana_activation_requires_tap":true,"mana_produced":1,"permanent_type":"artifact","produces":"WUBRG","trigger":"enters_battlefield","trigger_effect":"draw_cards","xmage_ability_classes":["AnyColorManaAbility","EntersBattlefieldTriggeredAbility"],"xmage_effect_classes":["DrawCardSourceControllerEffect"],"xmage_mana_ability_classes":["AnyColorManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PropheticPrism translated into ManaLoom runtime scope xmage_simple_mana_source_with_etb_draw_v1. This row is package-ready only because the source signature is a narrow mana-source permanent with fixed enter-the-battlefield draw trigger with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg474_xmage_simple_mana_source_with_etb_draw_new_server_) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
