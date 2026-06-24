WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('fact or fiction', 'Fact or Fiction', 'da85cd126972897c37373ad25ec5f867', 'battle_rule_v1:b5c5def7cc8d30af6e2c293ea0854a5c', '{"ability_kind":"one_shot","battle_model_scope":"reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1","chooser":"controller","effect":"pile_selection_draw","instant":true,"look_count":5,"pile_count":2,"remainder_destination":"graveyard","selection_destination":"hand","splitter":"opponent"}'::jsonb, '{"category":"draw","effect":"pile_selection_draw","subtype":"two_pile_reveal","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FactOrFiction mapped to family pile_selection_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('steam augury', 'Steam Augury', '9be664a6ecce936cc53df5993a90cdcb', 'battle_rule_v1:e076e7cef34d9f0593c00df3e15059a7', '{"ability_kind":"one_shot","battle_model_scope":"reveal_top_n_split_two_piles_choose_one_hand_rest_graveyard_v1","chooser":"opponent","effect":"pile_selection_draw","instant":true,"look_count":5,"pile_count":2,"remainder_destination":"graveyard","selection_destination":"hand","splitter":"controller"}'::jsonb, '{"category":"draw","effect":"pile_selection_draw","subtype":"two_pile_reveal","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class SteamAugury mapped to family pile_selection_spell; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
