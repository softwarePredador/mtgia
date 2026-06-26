WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('primal amulet // primal wellspring', 'Primal Amulet // Primal Wellspring', 'e90d3ae05767c87dbd3b02c470af4827', 'battle_rule_v1:d05b887f76ae9cd5cee7c89045dc65cc', '{"ability_kind":"static","applies_to_card_types":["instant","sorcery"],"battle_model_scope":"artifact_instant_sorcery_cost_reduction_charge_transform_to_any_color_spell_copy_land_v1","cost_reduction_applies_to":"instant_sorcery_spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction","transform_counter_threshold":4,"transform_optional":true,"transform_remove_all_named_counters":true,"transform_to":{"battle_model_scope":"artifact_instant_sorcery_cost_reduction_charge_transform_to_any_color_spell_copy_land_v1","choose_new_targets_status":"may","copy_when_mana_spent_card_types":["instant","sorcery"],"copy_when_mana_spent_to_cast_matching_spell":true,"effect":"land","is_mana_source":true,"mana_produced":1,"may_choose_new_targets":true,"name":"Primal Wellspring","produces":"WUBRG","target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"copy_when_mana_spent","type_line":"Land"},"trigger":"instant_sorcery_cast","trigger_counter_count":1,"trigger_counter_type":"charge","trigger_effect":"add_named_counter_then_transform"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PrimalAmulet mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.', 'deprecate_nonmatching_rows')
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
