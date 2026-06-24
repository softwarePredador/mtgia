WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('birds of paradise', 'Birds of Paradise', '2119fc1976cfab2480a9d86c57f1859b', 'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba', '{"ability_kind":"activated","battle_model_scope":"one_mana_zero_one_flying_any_color_mana_dork_v1","effect":"creature","flying":true,"is_mana_source":true,"mana_produced":1,"power":0,"produces":"WUBRG","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class BirdsOfParadise mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('llanowar elves', 'Llanowar Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class LlanowarElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('elvish mystic', 'Elvish Mystic', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class ElvishMystic mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('avacyn''s pilgrim', 'Avacyn''s Pilgrim', 'c7264c311c98ff99b293a96ad9ab2daf', 'battle_rule_v1:123fb4f1873cbd3debade4877e0b6788', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_white_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"W","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class AvacynsPilgrim mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('fyndhorn elves', 'Fyndhorn Elves', 'fa07d150550fe544837233efd56086ac', 'battle_rule_v1:b4d210018767f5b0a4740adc889beb85', '{"ability_kind":"activated","battle_model_scope":"one_mana_one_one_green_mana_dork_v1","effect":"creature","is_mana_source":true,"mana_produced":1,"power":1,"produces":"G","toughness":1}'::jsonb, '{"category":"board_presence","effect":"creature","timing":"battlefield"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class FyndhornElves mapped to family creature; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
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
