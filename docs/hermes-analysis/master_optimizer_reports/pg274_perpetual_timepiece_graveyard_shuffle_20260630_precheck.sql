WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('perpetual timepiece', 'Perpetual Timepiece', '4af52424df5fb9a51bff3fddb1c5c1ff', 'battle_rule_v1:26cffda59616c27dd2e137e165dc2d5d', '{"ability_kind":"activated","activated_self_mill_count":2,"artifact":true,"battle_model_scope":"tap_self_mill_two_or_exile_self_shuffle_any_number_graveyard_cards_into_library_v1","cmc":2.0,"effect":"passive","graveyard_shuffle_activation_cost_generic":2,"graveyard_shuffle_activation_requires_tap":false,"graveyard_shuffle_destination":"library","graveyard_shuffle_exiles_self":true,"graveyard_shuffle_low_library_threshold":8,"graveyard_shuffle_min_targets":1,"graveyard_shuffle_target_controller":"self","graveyard_shuffle_target_count":99,"mana_cost":"{2}","self_mill_activation_requires_tap":true,"self_mill_min_library_after":2}'::jsonb, '{"category":"recursion","effect":"passive","subtype":"activated_self_mill_graveyard_shuffle_artifact","timing":"activated_main_phase"}'::jsonb, 'curated', 0.92, 'verified', 'auto', 'PG274: Perpetual Timepiece exact activated artifact scope from local XMage PerpetualTimepiece.java and focused ManaLoom runtime test; tap self-mill two, or pay two and exile this artifact to shuffle selected graveyard cards into library.', 'deprecate_nonmatching_rows')
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
active_review_rows AS (
  SELECT p.normalized_name, count(r.*) AS active_review_scope_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.review_status IN ('verified', 'active')
   AND r.execution_status IN ('auto', 'executable')
   AND coalesce(r.effect_json->>'battle_model_scope', '') LIKE 'xmage_%_review_v1'
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
  p.effect_json->>'battle_model_scope' AS proposed_scope,
  p.shadow_handling,
  tc.target_card_rows,
  tc.canonical_card_id,
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  ar.active_review_scope_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name, card_name, oracle_hash)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN active_review_rows ar USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
