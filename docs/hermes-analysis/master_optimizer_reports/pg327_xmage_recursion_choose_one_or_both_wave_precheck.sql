WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('aid the fallen', 'Aid the Fallen', '9496532b5e3c5ae695453c3fd062e385', 'battle_rule_v1:9d1eb17d007f244339a3e02c362cf00a', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":1,"destination":"hand","target":"planeswalker","target_constraints":{"card_types":["planeswalker"],"controller":"self","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AidTheFallen translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fortuitous find', 'Fortuitous Find', '23e9a63be8f33cd858a93d55ce59e41a', 'battle_rule_v1:d6ac105b3ca97e86df22cbe8592432e9', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"count":1,"destination":"hand","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FortuitousFind translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grim discovery', 'Grim Discovery', 'ffdc50eb8241cba31a0ba1200c592f7f', 'battle_rule_v1:9bbc6cefcd7b190ac1df9e56a7c715af', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":1,"destination":"hand","target":"land","target_constraints":{"card_types":["land"],"controller":"self","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrimDiscovery translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('remember the fallen', 'Remember the Fallen', 'ff4a45cfcecac5f218642ae2ec20e237', 'battle_rule_v1:bb779f40e2b217f92aee5d47260bd257', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":1,"destination":"hand","target":"artifact","target_constraints":{"card_types":["artifact"],"controller":"self","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RememberTheFallen translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reviving melody', 'Reviving Melody', 'daaf4e7a32130bf0ef21c9e245b9a200', 'battle_rule_v1:4061e3abb8aa410e9f72764cbbf49f5a', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":1,"destination":"hand","target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RevivingMelody translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('season of renewal', 'Season of Renewal', 'daaf4e7a32130bf0ef21c9e245b9a200', 'battle_rule_v1:ad3fe6c520d7ca458e2ff435cef3161d', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":true,"mode_selection":"one_or_both","recursion_components":[{"count":1,"destination":"hand","target":"creature","target_constraints":{"card_types":["creature"],"controller":"self","zone":"graveyard"},"target_controller":"self"},{"count":1,"destination":"hand","target":"enchantment","target_constraints":{"card_types":["enchantment"],"controller":"self","zone":"graveyard"},"target_controller":"self"}],"sorcery":false,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SeasonOfRenewal translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('survivors'' bond', 'Survivors'' Bond', '525cdc44e5da52d3fe4f190cb49a010d', 'battle_rule_v1:f23fb97f6a14327ce3f054e72c7f2e32', '{"battle_model_scope":"xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1","destination":"hand","effect":"recursion","instant":false,"mode_selection":"one_or_both","recursion_components":[{"count":1,"destination":"hand","target":"human_creature","target_constraints":{"card_types":["creature"],"controller":"self","subtypes":["human"],"zone":"graveyard"},"target_controller":"self"},{"count":1,"destination":"hand","target":"non_human_creature","target_constraints":{"card_types":["creature"],"controller":"self","exclude_subtypes":["human"],"zone":"graveyard"},"target_controller":"self"}],"sorcery":true,"target_controller":"self","xmage_effect_class":"ReturnFromGraveyardToHandTargetEffect"}'::jsonb, '{"category":"engine","effect":"recursion"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SurvivorsBond translated into ManaLoom runtime scope xmage_return_one_or_both_graveyard_cards_to_hand_spell_v1. This row is package-ready only because the source signature is a narrow instant/sorcery spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
),
matched_cards AS (
  SELECT
    p.normalized_name,
    p.card_name,
    p.oracle_hash,
    c.id AS card_id,
    c.name AS db_card_name
  FROM proposed p
  LEFT JOIN public.cards c
    ON (
         lower(c.name) = p.normalized_name
         OR split_part(lower(c.name), ' // ', 1) = p.normalized_name
       )
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
),
target_cards AS (
  SELECT
    normalized_name,
    card_name,
    oracle_hash,
    count(card_id) AS target_card_rows,
    min(card_id::text)::uuid AS canonical_card_id,
    min(db_card_name) AS canonical_card_name
  FROM matched_cards
  GROUP BY normalized_name, card_name, oracle_hash
),
rule_rows AS (
  SELECT p.normalized_name, count(r.*) AS existing_rule_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key <> p.logical_rule_key
   AND r.review_status NOT IN ('deprecated', 'rejected')
   AND r.execution_status <> 'disabled'
  GROUP BY p.normalized_name
)
SELECT
  p.card_name,
  p.normalized_name,
  p.oracle_hash,
  p.logical_rule_key,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
