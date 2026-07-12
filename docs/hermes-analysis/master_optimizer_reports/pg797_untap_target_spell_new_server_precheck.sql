WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('burst of energy', 'Burst of Energy', '88069268f224445e059a0a0aba2f5a82', 'battle_rule_v1:5233e85f30c26d13a9da6a9d2117387d', '{"battle_model_scope":"xmage_untap_target_spell_v1","duration":"immediate","effect":"stat_modifier_until_eot_untap_target","instant":true,"modifies_stats":false,"power_boost":0,"power_delta":0,"sorcery":false,"target":"permanent","target_constraints":{"card_types":["permanent"]},"target_controller":"any","target_count":1,"target_count_max":1,"target_count_min":1,"toughness_boost":0,"toughness_delta":0,"untap_target":true,"up_to_count":false,"xmage_effect_class":"UntapTargetEffect"}'::jsonb, '{"category":"support","effect":"stat_modifier_until_eot_untap_target","subtype":"temporary_pump_untap","target":"permanent","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class BurstOfEnergy translated into ManaLoom runtime scope xmage_untap_target_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that untaps exact target permanents with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
