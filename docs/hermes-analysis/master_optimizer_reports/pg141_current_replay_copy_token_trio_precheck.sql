WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('flash photography', 'Flash Photography', 'c3fb29c6ec7bd40a4d59959e9abe9ee8', 'battle_rule_v1:e5ea20bd49a563c1256183af42e86c71', '{"ability_kind":"one_shot","battle_model_scope":"copy_target_permanent_v1","copy_target_types":["permanent"],"effect":"copy_creature_token","target_controller":"any","token_haste":false}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FlashPhotography mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('astral dragon', 'Astral Dragon', '5efa9ecc8bca6d341f1dc4dea3e51c49', 'battle_rule_v1:7f8364137188a184510b1cfc4ebeac33', '{"ability_kind":"triggered","battle_model_scope":"etb_copy_target_noncreature_permanent_twice_as_3_3_flying_dragon_v1","effect":"creature","etb_copy_force_creature":true,"etb_copy_target_types":["noncreature_permanent"],"etb_copy_token_count":2,"etb_copy_token_flying":true,"etb_copy_token_power":3,"etb_copy_token_subtype":"Dragon","etb_copy_token_toughness":3,"flying":true,"power":4,"toughness":4}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AstralDragon mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('clone legion', 'Clone Legion', 'd5300831d3df4276f01145ddeca85521', 'battle_rule_v1:391956936dfadf0b7bd0f0123226279f', '{"ability_kind":"one_shot","battle_model_scope":"copy_each_creature_target_player_controls_v1","copy_all_matching_targets":true,"copy_target_types":["creature"],"effect":"copy_creature_token","target_controller":"opponent"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class CloneLegion mapped to family copy_creature_token; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
