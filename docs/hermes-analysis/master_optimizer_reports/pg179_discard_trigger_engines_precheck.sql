WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('feast of sanity', 'Feast of Sanity', '9d3f44ba9a777ab7510132842a854475', 'battle_rule_v1:8783617a8d44c4f2e0242d17976f8828', '{"ability_kind":"triggered","battle_model_scope":"controller_discards_card_damage_any_target_and_gain_life_v1","cmc":4.0,"controller_discard_damage_any_target":1,"controller_discard_gain_life":1,"effect":"passive","trigger":"controller_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FeastOfSanity mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('geth''s grimoire', 'Geth''s Grimoire', '6f91d335d1e146eb8f4f7e034130fa67', 'battle_rule_v1:293ee48b9a46181e885a4e563ef5868c', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_may_draw_v1","cmc":4.0,"draw_on_enter":false,"effect":"draw_engine","opponent_discard_draw_per_card":1,"trigger":"opponent_discard"}'::jsonb, '{"category":"draw","effect":"draw_engine","timing":"static_or_activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GethsGrimoire mapped to family draw_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('megrim', 'Megrim', '2bb00f8626aef78bae0a72196673b7ec', 'battle_rule_v1:3c0ccb6b440a3128acdd19b58ace0b1e', '{"ability_kind":"triggered","battle_model_scope":"opponent_discards_card_damage_that_player_v1","cmc":3.0,"effect":"passive","opponent_discard_damage_per_card":2,"trigger":"opponent_discard"}'::jsonb, '{"category":"support","effect":"passive","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class Megrim mapped to family passive; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
