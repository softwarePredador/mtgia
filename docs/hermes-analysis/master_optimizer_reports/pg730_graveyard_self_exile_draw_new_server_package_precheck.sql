WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('cobbled lancer', 'Cobbled Lancer', '965eb892d89598dcd8397d1c3a72e0a0', 'battle_rule_v1:fd90e2f58196771de6296762a5978d7b', '{"ability_kind":"activated","activated_draw":true,"activated_draw_count":1,"activated_effect":"draw_cards","activation_cost_colors":["U"],"activation_cost_generic":3,"activation_cost_mana":"{3}{U}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_v1","count":1,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawCardSourceControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class CobbledLancer translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw ability with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('maestros initiate', 'Maestros Initiate', 'd0d9bfb862fb4711bc005520811ded79', 'battle_rule_v1:0e3c9c3f262ff70d066ffde1d9c555df', '{"ability_kind":"activated","activated_discard_count":1,"activated_draw_count":2,"activated_draw_discard":true,"activated_effect":"draw_discard","activation_cost_colors":["U/R"],"activation_cost_generic":4,"activation_cost_mana":"{4}{U/R}","activation_requires_exile_source_from_graveyard":true,"activation_requires_sacrifice":false,"activation_requires_tap":false,"activation_zone":"graveyard","battle_model_scope":"xmage_permanent_simple_activated_draw_discard_v1","count":2,"discard_count":1,"draw_count":2,"effect":"draw_engine","permanent_type":"creature","xmage_ability_class":"SimpleActivatedAbility","xmage_effect_class":"DrawDiscardControllerEffect"}'::jsonb, '{"category":"draw","effect":"draw_engine"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class MaestrosInitiate translated into ManaLoom runtime scope xmage_permanent_simple_activated_draw_discard_v1. This row is package-ready only because the source signature is a narrow permanent with a simple activated draw-then-discard ability with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
