WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('altar''s reap', 'Altar''s Reap', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class AltarsReap translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('blood divination', 'Blood Divination', '673d2e5b32cae23064c95c517a0027eb', 'battle_rule_v1:a6eaaf5e281f76100c9bffdc779e9608', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BloodDivination translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('corrupted conviction', 'Corrupted Conviction', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CorruptedConviction translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('magmatic insight', 'Magmatic Insight', '473bae0f7df2ba37e68718cd5ccc7f2f', 'battle_rule_v1:675d4fcd2437904067cdc1f4b111a5c2', '{"additional_cost":"discard_land","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_land":true,"sorcery":true,"xmage_additional_cost_class":"DiscardTargetCost","xmage_additional_cost_target":"land","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MagmaticInsight translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('skulltap', 'Skulltap', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:0581d3a32ff3d5c6aab372ecc4732b66', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Skulltap translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('tormenting voice', 'Tormenting Voice', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:ea8f354cc237e842e7ffa5a03390d09f', '{"additional_cost":"discard_card","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_card":true,"sorcery":true,"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class TormentingVoice translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('village rites', 'Village Rites', '4ae4120d3d74dc3a1b72f930e1d4fdb0', 'battle_rule_v1:4cd51293e000d79e1389268f7a442ea2', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":true,"requires_sacrifice_creature":true,"sorcery":false,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class VillageRites translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('vivisection', 'Vivisection', '673d2e5b32cae23064c95c517a0027eb', 'battle_rule_v1:a6eaaf5e281f76100c9bffdc779e9608', '{"additional_cost":"sacrifice_creature","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":3,"effect":"draw_cards","instant":false,"requires_sacrifice_creature":true,"sorcery":true,"xmage_additional_cost_class":"SacrificeTargetCost","xmage_additional_cost_target":"creature","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Vivisection translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('wild guess', 'Wild Guess', '82c625909b3e6d29d4fa95e933cfc80e', 'battle_rule_v1:ea8f354cc237e842e7ffa5a03390d09f', '{"additional_cost":"discard_card","battle_model_scope":"xmage_fixed_source_controller_draw_spell_v1","count":2,"effect":"draw_cards","instant":false,"requires_discard_card":true,"sorcery":true,"xmage_additional_cost_class":"DiscardCardCost","xmage_additional_cost_target":"card","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_cards"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class WildGuess translated into ManaLoom runtime scope xmage_fixed_source_controller_draw_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
