WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('back in town', 'Back in Town', '29486ab65ba91af38683cb407532a6d9', 'battle_rule_v1:4dbb7fab82dc6aa0bee9310921c10add', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":0,"count_from_x":true,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"outlaw_creature","target_constraints":{"card_types":["creature"],"controller":"self","subtype_group":"outlaw","subtypes":["assassin","mercenary","pirate","rogue","warlock"],"zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"outlaw_creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BackInTown translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('death denied', 'Death Denied', '11326914a120abaf48b741c8f9d80034', 'battle_rule_v1:7f2b1cf93136c4e6f40016e5392a7451', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_hand_spell_v1","count":0,"count_from_x":true,"destination":"hand","effect":"recursion","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeathDenied translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('stir the grave', 'Stir the Grave', '705c519d4397f4ebda5ec77a18c33c87', 'battle_rule_v1:d964ccf44fc72f3a06c632b646920e6a', '{"battle_model_scope":"xmage_return_target_graveyard_card_to_battlefield_spell_v1","battlefield_controller":"self","count":1,"destination":"battlefield","effect":"recursion","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","mana_value_max_source":"x_value","zone":"graveyard"},"target_controller":"self","target_graveyard_controller":"self","target_mana_value_max_from_x":true,"xmage_effect_class":"ReturnFromGraveyardToBattlefieldTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class StirTheGrave translated into ManaLoom runtime scope xmage_return_target_graveyard_card_to_battlefield_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg362_xmage_recursion_x_spell_wave_20260702_075031) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
