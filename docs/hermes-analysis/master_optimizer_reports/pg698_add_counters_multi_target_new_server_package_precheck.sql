WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes, shadow_handling) AS (
  VALUES
    ('gird for battle', 'Gird for Battle', '3ec3205f9c7582e0e521c48d34632663', 'battle_rule_v1:370f47a81ed9d92f11b41968a8cbe6cf', '{"battle_model_scope":"xmage_fixed_add_counters_target_creatures_spell_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":false,"sorcery":true,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":2,"target_count_max":2,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"support","effect":"add_counters","subtype":"plus_one_counters","target":"creature"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class GirdForBattle translated into ManaLoom runtime scope xmage_fixed_add_counters_target_creatures_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds fixed counters to exact target creatures with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('leo''s guidance', 'Leo''s Guidance', 'f38609e8728ba9dc858053e333269d1d', 'battle_rule_v1:1a72396e764ce4abd22f1d1d569031f8', '{"battle_model_scope":"xmage_fixed_add_counters_and_untap_target_creatures_spell_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":3,"target_count_max":3,"target_count_min":0,"untap_target":true,"up_to_count":true,"xmage_effect_classes":["AddCountersTargetEffect","UntapTargetEffect"]}'::jsonb, '{"category":"support","effect":"add_counters","subtype":"plus_one_counters","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class LeosGuidance translated into ManaLoom runtime scope xmage_fixed_add_counters_and_untap_target_creatures_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds fixed counters to exact target creatures and untaps them with focused runtime coverage.', 'deprecate_nonmatching_rows'),
    ('reap what is sown', 'Reap What Is Sown', 'f3e88f23e30bfabb3b2da14d43b3a47e', 'battle_rule_v1:34ad232119cc27683aabda01ee0aaecf', '{"battle_model_scope":"xmage_fixed_add_counters_target_creatures_spell_v1","count":1,"counter_count":1,"counter_type":"+1/+1","effect":"add_counters","instant":true,"sorcery":false,"target":"creature","target_constraints":{"card_types":["creature"]},"target_controller":"any","target_count":3,"target_count_max":3,"target_count_min":0,"up_to_count":true,"xmage_effect_class":"AddCountersTargetEffect"}'::jsonb, '{"category":"support","effect":"add_counters","subtype":"plus_one_counters","target":"creature","timing":"instant"}'::jsonb, 'curated', 0.96, 'verified', 'auto', 'XMage authoritative exact-scope split: local class ReapWhatIsSown translated into ManaLoom runtime scope xmage_fixed_add_counters_target_creatures_spell_v1. This row is package-ready only because the source signature is a narrow instant or sorcery spell that adds fixed counters to exact target creatures with focused runtime coverage.', 'deprecate_nonmatching_rows')
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
