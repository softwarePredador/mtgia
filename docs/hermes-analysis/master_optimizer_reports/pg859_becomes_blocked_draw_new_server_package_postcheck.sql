WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('chambered nautilus', 'Chambered Nautilus', '9721a3b0315e6346ff56d0055dbb58cb', 'battle_rule_v1:d30bc9023761d3c0035872b663eb35fa', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_becomes_blocked_draw_cards_v1","becomes_blocked_draw_count":1,"becomes_blocked_draw_optional":true,"becomes_blocked_trigger_draw":true,"draw_count":1,"effect":"creature","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","trigger":"becomes_blocked","trigger_effect":"draw_cards","xmage_ability_class":"BecomesBlockedSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChamberedNautilus translated into ManaLoom runtime scope xmage_creature_becomes_blocked_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drelnoch', 'Drelnoch', 'c46a683852501275cfd935cbcf2e04e7', 'battle_rule_v1:126fa55e5b5560ecd24a49d3e4c7a884', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_becomes_blocked_draw_cards_v1","becomes_blocked_draw_count":2,"becomes_blocked_draw_optional":true,"becomes_blocked_trigger_draw":true,"draw_count":2,"effect":"creature","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","trigger":"becomes_blocked","trigger_effect":"draw_cards","xmage_ability_class":"BecomesBlockedSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Drelnoch translated into ManaLoom runtime scope xmage_creature_becomes_blocked_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('saprazzan heir', 'Saprazzan Heir', '8f2dd0efdd8b14e6813362e6a8a5ddfa', 'battle_rule_v1:5330887d250e84d9e2b7bd8628695f19', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_becomes_blocked_draw_cards_v1","becomes_blocked_draw_count":3,"becomes_blocked_draw_optional":true,"becomes_blocked_trigger_draw":true,"draw_count":3,"effect":"creature","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","trigger":"becomes_blocked","trigger_effect":"draw_cards","xmage_ability_class":"BecomesBlockedSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SaprazzanHeir translated into ManaLoom runtime scope xmage_creature_becomes_blocked_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg859_becomes_blocked_draw_new_server_be_20260713_030532) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
