WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('twinflame tyrant', 'Twinflame Tyrant', 'e4ca0585f743b1c34c36649bfbb1fff6', 'battle_rule_v1:072370a98c9b332eef021390bfc1694a', '{"ability_kind":"static","battle_model_scope":"controlled_source_damage_to_opponent_or_opponent_permanent_doubled_v1","cmc":5.0,"damage_modifier_applies_to":"sources_you_control","damage_modifier_duration":"while_on_battlefield","damage_modifier_targets":["opponents","opponent_permanents"],"damage_multiplier":2,"effect":"damage_modifier","flying":true,"power":3,"toughness":5}'::jsonb, '{"category":"wincon","effect":"damage_modifier","subtype":"damage_doubler","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TwinflameTyrant mapped to family static_damage_modifier; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows'),
    ('verge rangers', 'Verge Rangers', '44aa2eeb2eeb517fb30478aec7cec42f', 'battle_rule_v1:85ae1e46c9ad082e1807ac9e9f5420bd', '{"ability_kind":"static","battle_model_scope":"look_top_library_play_lands_from_top_if_opponent_more_lands_v1","cmc":3.0,"effect":"topdeck_play","keywords":["first_strike"],"look_top_library_any_time":true,"play_from_top_condition":"opponent_controls_more_lands","play_lands_from_top_library":true,"power":3,"toughness":3}'::jsonb, '{"category":"ramp","effect":"topdeck_play","subtype":"play_lands_from_library","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class VergeRangers mapped to family topdeck_play; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
