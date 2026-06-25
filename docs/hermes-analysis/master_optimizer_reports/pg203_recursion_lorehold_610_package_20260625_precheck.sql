WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('brilliant restoration', 'Brilliant Restoration', '011870a867ab737e17010e1be798f66e', 'battle_rule_v1:3e7a0ab3e5871010c9751a9090adbaaf', '{"ability_kind":"one_shot","battle_model_scope":"return_all_artifact_enchantment_cards_from_graveyard_to_battlefield_v1","destination":"battlefield","effect":"recursion","return_all_matching":true,"target":"artifact_or_enchantment","target_card_types":["artifact","enchantment"],"target_controller":"self","target_zone":"graveyard"}'::jsonb, '{"category":"recursion","effect":"recursion","subtype":"graveyard_to_battlefield_or_hand","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BrilliantRestoration mapped to family recursion; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('wake the past', 'Wake the Past', 'a87b4ec70e2653c38cea3b3176068457', 'battle_rule_v1:d7e0d3daac42a4774a437fce19f6a2bc', '{"ability_kind":"one_shot","battle_model_scope":"return_all_artifact_cards_from_graveyard_to_battlefield_haste_eot_v1","destination":"battlefield","effect":"recursion","grants_haste_until_eot":true,"return_all_matching":true,"target":"artifact","target_card_types":["artifact"],"target_controller":"self","target_zone":"graveyard"}'::jsonb, '{"category":"recursion","effect":"recursion","subtype":"graveyard_to_battlefield_or_hand","timing":"resolution"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class WakeThePast mapped to family recursion; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
