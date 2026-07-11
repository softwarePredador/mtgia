WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('zaxara, the exemplary', 'Zaxara, the Exemplary', 'bdb261d7904dbecf9ddaa6ddb01f9b40', 'battle_rule_v1:58a25a96c5e3a7c34298ed75986ed05a', '{"ability_kind":"activated_mana","activation_requires_tap":true,"battle_model_scope":"xmage_simple_tap_mana_source_with_x_spell_token_counter_trigger_v1","e2e_x_value":2,"effect":"ramp_permanent","is_mana_source":true,"keywords":["deathtouch"],"mana_activation_requires_tap":true,"mana_produced":2,"permanent_type":"creature","produces":"WUBRG","source_mana_cost":"{1}{B}{G}{U}","source_type_line":"Legendary Creature \u2014 Nightmare Hydra","spell_cast_token_count_source":"fixed","spell_cast_token_maker":true,"spell_cast_token_requires_x_mana_cost":true,"token_colors":["G"],"token_count":1,"token_enters_with_counter_type":"+1/+1","token_enters_with_counters_source":"x_value","token_enters_with_plus_one_counters_from_x":true,"token_name":"Hydra Token","token_power":0,"token_subtype":"Hydra","token_toughness":0,"trigger":"spell_cast","trigger_effect":"token_maker","trigger_token_count":1,"xmage_ability_classes":["DeathtouchAbility","SimpleManaAbility","ZaxaraTheExemplaryHydraTokenAbility"],"xmage_auxiliary_ability_classes":["DeathtouchAbility","ZaxaraTheExemplaryHydraTokenAbility"],"xmage_effect_classes":["AddManaOfAnyColorEffect","OneShotEffect","ZaxaraTheExemplaryHydraTokenEffect"],"xmage_mana_ability_classes":["SimpleManaAbility"]}'::jsonb, '{"category":"ramp","effect":"ramp_permanent"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ZaxaraTheExemplary translated into ManaLoom runtime scope xmage_simple_tap_mana_source_with_x_spell_token_counter_trigger_v1. This row is package-ready only because the source signature is a narrow activated mana-source permanent with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
