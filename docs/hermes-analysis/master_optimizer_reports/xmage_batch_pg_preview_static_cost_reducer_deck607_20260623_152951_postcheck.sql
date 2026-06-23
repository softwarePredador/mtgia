WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pearl medallion', 'Pearl Medallion', '77f7f449ee56143d6b63814fecd37176', 'battle_rule_v1:0d857d5b176cc91065a4754f5824ebf2', '{"ability_kind":"static","applies_to_controller":"source_controller","applies_to_spell_colors":["W"],"battle_model_scope":"static_cost_reduction_for_matching_spells_v1","cmc":2.0,"cost_reduction_applies_to":"spells_you_cast","cost_reduction_generic":1,"effect":"static_cost_reduction"}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PearlMedallion mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.'),
    ('the scarlet witch', 'The Scarlet Witch', '6129fda2f5ae1f8edad5a2f2e77d05c2', 'battle_rule_v1:0b23c5f26d2bc884b7f506cdd9d422fc', '{"ability_kind":"static","applies_to_card_types":["instant","sorcery"],"applies_to_controller":"source_controller","battle_model_scope":"static_power_based_cost_reduction_for_instant_sorcery_mv4_plus_v1","cmc":3.0,"cost_reduction_amount_source":"source_power","cost_reduction_applies_to":"instant_sorcery_spells_you_cast","effect":"static_cost_reduction","minimum_mana_value":4}'::jsonb, '{"category":"support","effect":"static_cost_reduction","subtype":"cost_reducer","timing":"static"}'::jsonb, 'curated_xmage_batch_candidate', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class TheScarletWitch mapped to family static_cost_reducer; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
rule_rows AS (
  SELECT p.normalized_name, p.card_name, p.logical_rule_key, p.oracle_hash, r.*
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON r.normalized_name = p.normalized_name
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.preview_static_cost_deck607_static_cost_reducer_preview_) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r USING (normalized_name, card_name, logical_rule_key, oracle_hash)
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
