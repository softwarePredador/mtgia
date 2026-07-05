WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('contract killing', 'Contract Killing', 'f1cbc4d4cc19b2e1822644e3a6aa7d73', 'battle_rule_v1:ff1e6910d13613aa0f6c0970dce15189', '{"battle_model_scope":"xmage_destroy_target_create_treasure_spell_v1","controller_treasure_tokens":2,"destination":"graveyard","effect":"remove_creature","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"treasure_count":2,"treasure_recipient":"controller","treasure_trigger":"on_resolution_after_destroy","xmage_effect_classes":["DestroyTargetEffect","CreateTokenEffect"]}'::jsonb, '{"category":"removal","effect":"remove_creature","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ContractKilling translated into ManaLoom runtime scope xmage_destroy_target_create_treasure_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller Treasure creation spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('crack open', 'Crack Open', 'b0dab9c2113f397762b4a4cef17538cf', 'battle_rule_v1:1e40acd2dc6d17116ccdca7014df3b6e', '{"battle_model_scope":"xmage_destroy_target_create_treasure_spell_v1","controller_treasure_tokens":1,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"artifact_or_enchantment","target_constraints":{"card_types":["artifact","enchantment"]},"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"on_resolution_after_destroy","xmage_effect_classes":["DestroyTargetEffect","CreateTokenEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"artifact_or_enchantment"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CrackOpen translated into ManaLoom runtime scope xmage_destroy_target_create_treasure_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller Treasure creation spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('grim bounty', 'Grim Bounty', '898ad01083f20b024fe8b0bafeb32ee1', 'battle_rule_v1:40e2945395e3e9538c8d101258c37603', '{"battle_model_scope":"xmage_destroy_target_create_treasure_spell_v1","controller_treasure_tokens":1,"destination":"graveyard","effect":"remove_permanent","instant":false,"sorcery":true,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"treasure_count":1,"treasure_recipient":"controller","treasure_trigger":"on_resolution_after_destroy","xmage_effect_classes":["DestroyTargetEffect","CreateTokenEffect"]}'::jsonb, '{"category":"removal","effect":"remove_permanent","target":"creature_or_planeswalker"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GrimBounty translated into ManaLoom runtime scope xmage_destroy_target_create_treasure_spell_v1. This row is package-ready only because the source signature is a narrow fixed destroy-target plus controller Treasure creation spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
