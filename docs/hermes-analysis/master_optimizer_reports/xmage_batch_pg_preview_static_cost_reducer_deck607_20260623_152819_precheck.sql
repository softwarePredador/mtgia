WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pearl medallion', 'Pearl Medallion', '77f7f449ee56143d6b63814fecd37176', 'battle_rule_v1:09662427b256781a39f50dd00ba9735b', '{"ability_kind":"static","applies_to_controller":"source_controller","battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PearlMedallion mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('the scarlet witch', 'The Scarlet Witch', '6129fda2f5ae1f8edad5a2f2e77d05c2', 'battle_rule_v1:083a0ef0848582b5941faaa56850f439', '{"ability_kind":"static","applies_to_card_types":["instant","sorcery"],"applies_to_controller":"source_controller","battle_model_scope":"static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1","cost_reduction_amount_source":"source_power","cost_reduction_applies_to":"instant_sorcery_spells_you_cast","effect":"static_cost_reduction","minimum_mana_value":4}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheScarletWitch mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
target_cards AS (
  SELECT p.normalized_name, count(c.id) AS target_card_rows
  FROM proposed p
  LEFT JOIN public.cards c
    ON lower(c.name) = p.normalized_name
   AND md5(coalesce(c.oracle_text, '')) = p.oracle_hash
  GROUP BY p.normalized_name
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
  rr.existing_rule_rows,
  er.expected_rule_rows_before,
  sr.would_deprecate_shadow_rows
FROM proposed p
JOIN target_cards tc USING (normalized_name)
JOIN rule_rows rr USING (normalized_name)
JOIN expected_rows er USING (normalized_name)
JOIN shadow_rows sr USING (normalized_name)
ORDER BY p.card_name;
