WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cobbled lancer', 'Cobbled Lancer', '965eb892d89598dcd8397d1c3a72e0a0', 'battle_rule_v1:fd90e2f58196771de6296762a5978d7b', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_cost_colors":["U"],"activation_cost_generic":3,"activation_cost_mana":"{3}{U}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CobbledLancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maestros initiate', 'Maestros Initiate', 'd0d9bfb862fb4711bc005520811ded79', 'battle_rule_v1:0e3c9c3f262ff70d066ffde1d9c555df', '{"ability_kind":"activated","activated_discard_count":1,"activated_draw_count":2,"activated_draw_discard":true,"activated_effect":"draw_discard","activation_cost_colors":["U/R"],"activation_cost_generic":4,"activation_cost_mana":"{4}{U/R}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_discard_v1","count":2,"discard_count":1,"draw_count":2,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaestrosInitiate translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_discard_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw-then-discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg730_graveyard_self_exile_draw_new_serv_20260711_002716) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
