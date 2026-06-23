WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('hedron archive', 'Hedron Archive', '0b901e920cec79011b3c835d55d3c859', 'battle_rule_v1:699a8966e4ddb5d8b8a54f57e243bf7f', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_self_sacrifice_draw_two_v1","draw_on_self_sacrifice":2,"effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class HedronArchive mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('mind stone', 'Mind Stone', '8d1c9b62d7e5642df44a61a63de5e240', 'battle_rule_v1:3818b990dbad7de33216aee39fbb14c8', '{"activated_self_sacrifice_draw":true,"activation_cost_generic":1,"activation_requires_tap":true,"battle_model_scope":"mana_rock_self_sacrifice_draw_v1","effect":"ramp_permanent","mana_produced":1,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class MindStone mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('stonespeaker crystal', 'Stonespeaker Crystal', '28a979e8676f38d3fa18b199d3f7802b', 'battle_rule_v1:3b749c5de073394f1c912fa43d8e7c02', '{"activated_exile_target_player_graveyards":true,"activated_self_sacrifice_draw":true,"activation_cost_generic":2,"activation_requires_tap":true,"battle_model_scope":"two_mana_rock_graveyard_hate_cantrip_v1","effect":"ramp_permanent","mana_produced":2,"produces":"C"}'::jsonb, '{"category":"ramp","effect":"ramp_permanent","subtype":"modal_mana_rock","timing":"activated"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class StonespeakerCrystal mapped to family modal_mana_rock; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
    ON lower(c.name) = p.normalized_name
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
    ON r.normalized_name = p.normalized_name
  GROUP BY p.normalized_name
),
expected_rows AS (
  SELECT p.normalized_name, count(r.*) AS expected_rule_rows_before
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
  GROUP BY p.normalized_name
),
shadow_rows AS (
  SELECT p.normalized_name, count(r.*) AS would_deprecate_shadow_rows
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
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
