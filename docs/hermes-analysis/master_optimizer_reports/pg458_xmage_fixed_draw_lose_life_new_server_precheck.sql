WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('ambition''s cost', 'Ambition''s Cost', '2a807c1035d7b1ce49ba9281a02e946e', 'battle_rule_v1:3b2afd0214c6776da9b668598d824795', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AmbitionsCost translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ancient craving', 'Ancient Craving', '2a807c1035d7b1ce49ba9281a02e946e', 'battle_rule_v1:3b2afd0214c6776da9b668598d824795', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AncientCraving translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood pact', 'Blood Pact', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:e849896e6ab7822b604314a9842236f5', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":true,"life_loss":2,"sorcery":false,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodPact translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('harrowing journey', 'Harrowing Journey', '1fee8ed9c8875ba33f2972741b6a3e25', 'battle_rule_v1:e42886e5607833d64538053de3d5de82', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":3,"draw_count":3,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":3,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class HarrowingJourney translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('night''s whisper', 'Night''s Whisper', '99f77dc3d03da6660ecb413593fe23e7', 'battle_rule_v1:4149f6570b19de0fc58fef7eb6736e40', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class NightsWhisper translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('painful lesson', 'Painful Lesson', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:3b5e4090931830427bc375568e4786ed', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PainfulLesson translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('sign in blood', 'Sign in Blood', '0e1cca8ed574f916efa7634f28cd7de4', 'battle_rule_v1:3b5e4090931830427bc375568e4786ed', '{"battle_model_scope":"xmage_fixed_target_player_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":false,"life_loss":2,"sorcery":true,"target":"player","target_constraints":{"players":["any"]},"target_controller":"target_player","target_preference":"self","xmage_effect_classes":["DrawCardTargetEffect","LoseLifeTargetEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","target":"player"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SignInBlood translated into ManaLoom runtime scope xmage_fixed_target_player_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('succumb to temptation', 'Succumb to Temptation', 'c0b258f641e17da5b9ffc3ea28cd6a10', 'battle_rule_v1:96b2d3623c4036f44092a07cd0feebbd', '{"battle_model_scope":"xmage_fixed_controller_draw_lose_life_spell_v1","count":2,"draw_count":2,"draw_lose_life_spell":true,"effect":"draw_cards","instant":true,"life_loss":2,"sorcery":false,"target_controller":"self","xmage_effect_classes":["DrawCardSourceControllerEffect","LoseLifeSourceControllerEffect"]}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SuccumbToTemptation translated into ManaLoom runtime scope xmage_fixed_controller_draw_lose_life_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
