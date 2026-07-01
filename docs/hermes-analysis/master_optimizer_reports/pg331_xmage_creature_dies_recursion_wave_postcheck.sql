WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('dutiful attendant', 'Dutiful Attendant', '1577a7542791cf72d3e107b851620556', 'battle_rule_v1:ac4691be75a5b00ae0e0be9a325705da', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"creature","effect":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DutifulAttendant translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('elderfang ritualist', 'Elderfang Ritualist', '4bbafbe06b30d21e09a9a41d7c4a2bf0', 'battle_rule_v1:3306f4d5219e782160daf1385d92f499', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"elf_card","effect":"creature","target_constraints":{"controller":"self","subtypes":["elf"],"zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ElderfangRitualist translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('living lightning', 'Living Lightning', '49cf6ad10d1f7f69263bd280ce851120', 'battle_rule_v1:28eac3740a610b2b39f04e52527943c0', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_target":"instant_or_sorcery","effect":"creature","target_constraints":{"card_types":["instant","sorcery"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LivingLightning translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('myr retriever', 'Myr Retriever', '29d416587cbec9bf97bdd4d20b730802', 'battle_rule_v1:4437ef138e8d93691f9e19eac9dc08f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"artifact","effect":"creature","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MyrRetriever translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('workshop assistant', 'Workshop Assistant', '29d416587cbec9bf97bdd4d20b730802', 'battle_rule_v1:4437ef138e8d93691f9e19eac9dc08f5', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_dies_return_graveyard_card_to_hand_v1","dies_recursion_count":1,"dies_recursion_destination":"hand","dies_recursion_exclude_self":true,"dies_recursion_target":"artifact","effect":"creature","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"trigger":"dies","xmage_ability_class":"DiesSourceTriggeredAbility","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"unknown","effect":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WorkshopAssistant translated into ManaLoom runtime scope xmage_creature_dies_return_graveyard_card_to_hand_v1. This row is package-ready only because the source signature is a narrow creature dies triggered graveyard-to-hand ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
  (SELECT count(*) FROM manaloom_deploy_audit.pg331_xmage_creature_dies_recursion_wave_20260701_210836) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
