WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('chambered nautilus', 'Chambered Nautilus', '9721a3b0315e6346ff56d0055dbb58cb', 'battle_rule_v1:d30bc9023761d3c0035872b663eb35fa', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_becomes_blocked_draw_cards_v1","becomes_blocked_draw_count":1,"becomes_blocked_draw_optional":true,"becomes_blocked_trigger_draw":true,"draw_count":1,"effect":"creature","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","trigger":"becomes_blocked","trigger_effect":"draw_cards","xmage_ability_class":"BecomesBlockedSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ChamberedNautilus translated into ManaLoom runtime scope xmage_creature_becomes_blocked_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('drelnoch', 'Drelnoch', 'c46a683852501275cfd935cbcf2e04e7', 'battle_rule_v1:126fa55e5b5560ecd24a49d3e4c7a884', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_becomes_blocked_draw_cards_v1","becomes_blocked_draw_count":2,"becomes_blocked_draw_optional":true,"becomes_blocked_trigger_draw":true,"draw_count":2,"effect":"creature","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","trigger":"becomes_blocked","trigger_effect":"draw_cards","xmage_ability_class":"BecomesBlockedSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class Drelnoch translated into ManaLoom runtime scope xmage_creature_becomes_blocked_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('saprazzan heir', 'Saprazzan Heir', '8f2dd0efdd8b14e6813362e6a8a5ddfa', 'battle_rule_v1:5330887d250e84d9e2b7bd8628695f19', '{"ability_kind":"triggered","battle_model_scope":"xmage_creature_becomes_blocked_draw_cards_v1","becomes_blocked_draw_count":3,"becomes_blocked_draw_optional":true,"becomes_blocked_trigger_draw":true,"draw_count":3,"effect":"creature","target":"self","target_constraints":{"card_types":["creature"],"source":"self"},"target_controller":"self","trigger":"becomes_blocked","trigger_effect":"draw_cards","xmage_ability_class":"BecomesBlockedSourceTriggeredAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"unknown","effect":"creature","target":"self"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class SaprazzanHeir translated into ManaLoom runtime scope xmage_creature_becomes_blocked_draw_cards_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
