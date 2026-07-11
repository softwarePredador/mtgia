WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('pressure point', 'Pressure Point', '7c6c85b7c5b7c81fb53d9900f1131e9d', 'battle_rule_v1:2d79a8d3c535e40c978c6d6cfea88fea', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"effect":"tap_target","target":"creature","target_constraints":{"card_types":["creature"]},"target_count":1,"target_count_max":1,"up_to_count":false,"xmage_effect_class":"TapTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_tap_target_and_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":1,"target_count_max":1,"up_to_count":false,"xmage_effect_classes":["TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PressurePoint translated into ManaLoom runtime scope xmage_tap_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents and draws a card with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('repel the darkness', 'Repel the Darkness', '4fcd88b3ec68ed702fbf52c83508086f', 'battle_rule_v1:4dab45dedaed04eec5e2d944587c99b0', '{"_composite_rule_components":[{"battle_model_scope":"xmage_tap_target_spell_v1","compose_on_resolution":true,"effect":"tap_target","target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_class":"TapTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_tap_target_and_draw_card_spell_v1","count":1,"draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"tap_target":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_count":2,"target_count_max":2,"up_to_count":true,"xmage_effect_classes":["TapTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RepelTheDarkness translated into ManaLoom runtime scope xmage_tap_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that taps exact target permanents and draws a card with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg761_tap_target_draw_new_server_tap_tar_20260711_124020) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
