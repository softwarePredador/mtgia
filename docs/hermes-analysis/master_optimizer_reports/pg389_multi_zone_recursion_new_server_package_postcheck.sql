WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('badlands revival', 'Badlands Revival', '6c4a338d9da9a4035afc7786d92d8cfa', 'battle_rule_v1:cad5ffc686cc6c1e970b5fb45aa6eb1b', '{"battle_model_scope":"xmage_return_multi_zone_graveyard_cards_spell_v1","destination":"mixed_zones","effect":"recursion","instant":false,"mode_selection":"all_components","recursion_components":[{"battlefield_controller":"self","count":1,"destination":"battlefield","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true},{"count":1,"destination":"hand","target":"permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle","land"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true}],"sorcery":true,"target":"multi_zone_graveyard_cards","target_controller":"self","target_graveyard_controller":"self","xmage_effect_classes":["ReturnFromGraveyardToBattlefieldTargetEffect","ReturnFromGraveyardToHandTargetEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"multi_zone_graveyard_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BadlandsRevival translated into ManaLoom runtime scope xmage_return_multi_zone_graveyard_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pull through the weft', 'Pull Through the Weft', 'e0c0356a12d42dc554b125ae70234895', 'battle_rule_v1:1c4754386a55d72baa2366482ab859a3', '{"battle_model_scope":"xmage_return_multi_zone_graveyard_cards_spell_v1","destination":"mixed_zones","effect":"recursion","instant":false,"mode_selection":"all_components","recursion_components":[{"count":2,"destination":"hand","target":"nonland_permanent","target_constraints":{"card_types":["artifact","creature","enchantment","planeswalker","battle"],"controller":"self","exclude_card_types":["land"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true},{"battlefield_controller":"self","count":2,"destination":"battlefield","enters_tapped":true,"target":"land","target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","up_to_count":true}],"sorcery":true,"target":"multi_zone_graveyard_cards","target_controller":"self","target_graveyard_controller":"self","xmage_effect_classes":["ReturnFromGraveyardToBattlefieldTargetEffect","ReturnFromGraveyardToHandTargetEffect"]}'::jsonb, '{"category":"engine","effect":"recursion","target":"multi_zone_graveyard_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PullThroughTheWeft translated into ManaLoom runtime scope xmage_return_multi_zone_graveyard_cards_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg389_multi_zone_recursion_new_server_20260704_pg389_mul) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
