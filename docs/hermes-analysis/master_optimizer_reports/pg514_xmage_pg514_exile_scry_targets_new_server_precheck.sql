WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('devout decree', 'Devout Decree', '2ffef40b32de279e5d069ebdd05a631d', 'battle_rule_v1:77c2ca923d2c6b62ff46fc58b27e27fb', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"card_types":["creature","planeswalker"],"target_colors":["B","R"]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class DevoutDecree translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('ray of ruin', 'Ray of Ruin', '2c30c4034ace17cd7c4d01f9cb32d74c', 'battle_rule_v1:3ba725d656340693d4c616116bb305ef', '{"_composite_rule_components":[{"battle_model_scope":"xmage_exile_target_spell_v1","compose_on_resolution":true,"destination":"exile","effect":"remove_permanent","target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_class":"ExileTargetEffect"},{"battle_model_scope":"xmage_fixed_scry_spell_v1","compose_on_resolution":true,"count":1,"effect":"scry","scry_count":1,"xmage_effect_class":"ScryEffect"}],"battle_model_scope":"xmage_exile_target_and_scry_spell_v1","destination":"exile","effect":"composite_resolution","instant":false,"resolution_order":"exile_then_scry","scry_count":1,"sorcery":true,"target":"permanent","target_constraints":{"any_of":[{"card_types":["creature"]},{"card_types":["artifact"],"required_subtypes":["vehicle"]},{"card_types":["land"],"exclude_supertypes":["basic"]}]},"xmage_effect_classes":["ExileTargetEffect","ScryEffect"]}'::jsonb, '{"category":"draw","effect":"composite_resolution","target":"permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class RayOfRuin translated into ManaLoom runtime scope xmage_exile_target_and_scry_spell_v1. This row is package-ready only because the source signature is a narrow runtime-backed exact-scope adapter with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
