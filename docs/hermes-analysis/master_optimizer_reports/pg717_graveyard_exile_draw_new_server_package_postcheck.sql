WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cremate', 'Cremate', 'bf045694be19a16c26c769b9538ae960', 'battle_rule_v1:c00a862b95d740110dab3702b7538b66', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","compose_on_resolution":true,"count":1,"destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"target":"any_card","target_constraints":{"card_types":["card"],"controller":"any","zone":"graveyard"},"target_controller":"any","xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","compose_on_resolution":true,"count":1,"effect":"draw_cards","xmage_effect_class":"DrawCardSourceControllerEffect"}],"battle_model_scope":"xmage_exile_target_and_draw_card_spell_v1","count":1,"destination":"exile","draw_count":1,"effect":"composite_resolution","instant":true,"sorcery":false,"target":"any_card","target_constraints":{"card_types":["card"],"controller":"any","zone":"graveyard"},"xmage_effect_classes":["ExileTargetEffect","DrawCardSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Cremate translated into ManaLoom runtime scope xmage_exile_target_and_draw_card_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg717_graveyard_exile_draw_new_server_gr_20260710_194318) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
