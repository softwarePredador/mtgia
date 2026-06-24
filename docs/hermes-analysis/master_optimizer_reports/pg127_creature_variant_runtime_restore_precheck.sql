WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('colossal skyturtle', 'Colossal Skyturtle', '05180c03fc1bcfd31ff9d6fc65edfaad', 'battle_rule_v1:d4e643cbd0c20a5a58ca11b06c217a5e', '{"ability_kind":"one_shot","battle_model_scope":"flying_ward_channel_regrowth_or_bounce_creature_v1","channel_return_graveyard_card_to_hand":"{2}{G}","channel_return_target_creature_to_hand":"{1}{U}","effect":"creature","flying":true,"power":6,"toughness":5,"ward_cost":"{2}"}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ColossalSkyturtle mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('abigale, eloquent first-year', 'Abigale, Eloquent First-Year', 'daac542cd4b7cf8f12bb55ffac868d1a', 'battle_rule_v1:212147ed06811dba5af5e2c58100c716', '{"ability_kind":"triggered","battle_model_scope":"etb_strip_other_creature_abilities_and_grant_keyword_counters_v1","effect":"creature","etb_grants_keyword_counters":["flying","first_strike","lifelink"],"etb_other_target_creature_loses_all_abilities":true,"first_strike":true,"flying":true,"lifelink":true,"power":1,"toughness":1}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AbigaleEloquentFirstYear mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('glen elendra archmage', 'Glen Elendra Archmage', 'f05e697db3bcfb65a827970c08d1446a', 'battle_rule_v1:180387d5d5fc0c2417eb7372ed7a5909', '{"ability_kind":"activated","activated_counter_noncreature_spell_cost":"{U}","activation_cost":"sacrifice_self","battle_model_scope":"flying_persist_sacrifice_self_counter_noncreature_spell_v1","effect":"creature","flying":true,"persist":true,"power":2,"toughness":2}'::jsonb, '{"category":"manual_review","effect":"external_reference_required_manual_model"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class GlenElendraArchmage mapped to family manual_model; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
