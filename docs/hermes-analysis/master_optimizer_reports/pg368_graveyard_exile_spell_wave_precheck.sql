WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('coffin purge', 'Coffin Purge', 'b8c13734632e6aa5f94766f94c7b0663', 'battle_rule_v1:329f79a646d66432a7ba41e0c0f4a0f1', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","flashback_cost":"{B}","flashback_status":"runtime_executor_v1","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CoffinPurge translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('decompose', 'Decompose', '574498b9832411fc894cdafd0a1459eb', 'battle_rule_v1:42fb18be92bf3dd4236e16a53e22e7ab', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Decompose translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('fade from memory', 'Fade from Memory', 'd849e131a7d83a356c5a209eacecc9ed', 'battle_rule_v1:615cff671d9dde0bc0af79898851acda', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"cycling_cost":"{B}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class FadeFromMemory translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('purify the grave', 'Purify the Grave', 'e7643d7c704fb3390c6f6cc2cbef811b', 'battle_rule_v1:72dfb24ccd0d65f221c49bbc343f94f8', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","flashback_cost":"{W}","flashback_status":"runtime_executor_v1","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":false,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","xmage_auxiliary_ability_classes":["FlashbackAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PurifyTheGrave translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rapid decay', 'Rapid Decay', '236d5189bf9ad6285f7eeb432514426c', 'battle_rule_v1:b92371161b491e6dacb50588a98be1ad', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"cycling_cost":"{2}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RapidDecay translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('rats'' feast', 'Rats'' Feast', '676bd982b2fdb904153179fd14904fc8', 'battle_rule_v1:a3272655216713a20cc870b7a484c55d', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":1,"destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":1,"graveyard_exile_target_count_from_x":true,"instant":false,"sorcery":true,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","target_count_from_x":true,"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RatsFeast translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('scarab feast', 'Scarab Feast', '5bbe7a0b8d550e9b403c2bf4827aa320', 'battle_rule_v1:cfe9f926e6666c66b6e564d000906d3f', '{"battle_model_scope":"xmage_exile_target_graveyard_card_spell_v1","count":3,"cycling_cost":"{B}","cycling_status":"runtime_executor_v1","destination":"exile","effect":"graveyard_exile","graveyard_exile_destination":"exile","graveyard_exile_single_graveyard":true,"graveyard_exile_target":"any_card","graveyard_exile_target_count":3,"graveyard_exile_up_to_count":true,"instant":true,"sorcery":false,"target":"any_card","target_constraints":{"controller":"any","scope":"any_card","zone":"graveyard"},"target_controller":"any","up_to_count":true,"xmage_auxiliary_ability_classes":["CyclingAbility"],"xmage_effect_class":"ExileTargetEffect"}'::jsonb, '{"category":"removal","effect":"graveyard_exile","subtype":"graveyard_hate","target":"any_card","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ScarabFeast translated into ManaLoom runtime scope xmage_exile_target_graveyard_card_spell_v1. This row is package-ready only because the source signature is a narrow exile target graveyard card spell with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
