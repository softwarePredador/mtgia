WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('mystic meditation', 'Mystic Meditation', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:c678f64df56cf307c5d9c3a15cad897a', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":false,"sorcery":true,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MysticMeditation translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for discovery', 'Thirst for Discovery', '9de9e1308d1010387496685c78374e66', 'battle_rule_v1:aefeda576530cf9ef2de5aed32c96bac', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_basic_land":true,"discard_unless_card_types":["land"],"discard_unless_count":1,"discard_unless_filter":"basic_land_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForDiscovery translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for identity', 'Thirst for Identity', '01d3b4c57212f046fe7fc11df5443477', 'battle_rule_v1:236da04cc9f3583da4986ec711e3148b', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["creature"],"discard_unless_count":1,"discard_unless_filter":"creature_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForIdentity translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for knowledge', 'Thirst for Knowledge', '0f757e71e8213ba2a660219d9262cecb', 'battle_rule_v1:02810d99f1cb96bec4b8d39623ba0751', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["artifact"],"discard_unless_count":1,"discard_unless_filter":"artifact_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForKnowledge translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('thirst for meaning', 'Thirst for Meaning', '7433d8f7f2b705ff1783ccf16c296b2f', 'battle_rule_v1:e9b8c97c26e35decce39a5544d12253f', '{"battle_model_scope":"xmage_fixed_draw_discard_spell_v1","count":3,"discard_count":2,"discard_random":false,"discard_unless_card_types":["enchantment"],"discard_unless_count":1,"discard_unless_filter":"enchantment_card","discard_unless_status":"runtime_executor_v1","draw_count":3,"draw_discard_order":"draw_then_discard","draw_discard_spell":true,"effect":"draw_cards","instant":true,"sorcery":false,"xmage_effect_classes":["DrawCardSourceControllerEffect","DiscardControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ThirstForMeaning translated into ManaLoom runtime scope xmage_fixed_draw_discard_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg739_draw_discard_unless_new_server_20260711_034911) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
