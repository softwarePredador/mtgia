WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('deadly visit', 'Deadly Visit', 'e79fa6604f9bb48390a6eb47dc93465e', 'battle_rule_v1:8401f578a890f94339112252f3df8e51', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_creature","target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_surveil_spell_v1","compose_on_resolution":true,"count":2,"effect":"surveil","surveil_count":2,"xmage_effect_class":"SurveilEffect"}],"battle_model_scope":"xmage_destroy_target_and_surveil_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_surveil","sorcery":true,"surveil_count":2,"target":"creature","target_constraints":{"card_types":["creature"]},"xmage_effect_classes":["DestroyTargetEffect","SurveilEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DeadlyVisit translated into ManaLoom runtime scope xmage_destroy_target_and_surveil_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('pile on', 'Pile On', 'd7cee896f072258bf3ffc01f35db1455', 'battle_rule_v1:eac4cda4892f93a03f1ee70150b79554', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_surveil_spell_v1","compose_on_resolution":true,"count":2,"effect":"surveil","surveil_count":2,"xmage_effect_class":"SurveilEffect"}],"battle_model_scope":"xmage_destroy_target_and_surveil_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":true,"resolution_order":"destroy_then_surveil","sorcery":false,"surveil_count":2,"target":"creature_or_planeswalker","target_constraints":{"card_types":["creature","planeswalker"]},"xmage_effect_classes":["DestroyTargetEffect","SurveilEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"creature_or_planeswalker","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class PileOn translated into ManaLoom runtime scope xmage_destroy_target_and_surveil_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('shattered wings', 'Shattered Wings', '1403ae9ff7f78a14e19ef7c4d6fbb3d9', 'battle_rule_v1:88df4325c9b9a46eac29e3040c908ab5', '{"_composite_rule_components":[{"battle_model_scope":"xmage_destroy_target_spell_v1","compose_on_resolution":true,"destination":"graveyard","effect":"remove_permanent","target":"permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["enchantment"]},{"card_types":["creature"],"required_keywords":["flying"]}]},"xmage_effect_class":"DestroyTargetEffect"},{"battle_model_scope":"xmage_fixed_surveil_spell_v1","compose_on_resolution":true,"count":1,"effect":"surveil","surveil_count":1,"xmage_effect_class":"SurveilEffect"}],"battle_model_scope":"xmage_destroy_target_and_surveil_spell_v1","destination":"graveyard","effect":"composite_resolution","instant":false,"resolution_order":"destroy_then_surveil","sorcery":true,"surveil_count":1,"target":"permanent","target_constraints":{"any_of":[{"card_types":["artifact"]},{"card_types":["enchantment"]},{"card_types":["creature"],"required_keywords":["flying"]}]},"xmage_effect_classes":["DestroyTargetEffect","SurveilEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ShatteredWings translated into ManaLoom runtime scope xmage_destroy_target_and_surveil_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
