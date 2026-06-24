WITH proposed(normalized_name, card_name, oracle_hash, logical_rule_key, effect_json, deck_role_json, source, confidence, review_status, execution_status, notes) AS (
  VALUES
    ('pyromancer ascension', 'Pyromancer Ascension', '84cc013b799522990904777d7a3e458e', 'battle_rule_v1:ebe94a8e6b11cc83126424b87aecca2b', '{"ability_kind":"triggered","battle_model_scope":"pyromancer_ascension_quest_counter_copy_spell_v1","choose_new_targets_status":"may","effect":"copy_spell","may_choose_new_targets":true,"quest_counter_name_match_zone":"graveyard","quest_counter_on_same_name_in_graveyard":true,"quest_counter_threshold_to_copy":2,"target":"own_instant_or_sorcery_on_stack","trigger":"instant_sorcery_cast","trigger_effect":"pyromancer_ascension"}'::jsonb, '{"category":"combo_value","effect":"copy_spell","subtype":"stack_copy","timing":"resolution_or_trigger"}'::jsonb, 'curated', 0.94, 'verified', 'auto', 'XMage batch proposal: exact local XMage class PyromancerAscension mapped to family copy_spell_engine; requires Oracle/hash precheck, ManaLoom review, and approved PG apply before product use.')
),
rule_rows AS (
  SELECT
    r.normalized_name,
    r.logical_rule_key,
    r.oracle_hash,
    r.review_status,
    r.execution_status
  FROM proposed p
  LEFT JOIN public.card_battle_rules r
    ON (
         r.normalized_name = p.normalized_name
         OR r.normalized_name LIKE p.normalized_name || ' // %'
       )
   AND r.logical_rule_key = p.logical_rule_key
)
SELECT
  p.card_name,
  p.normalized_name,
  p.logical_rule_key,
  count(r.*) FILTER (WHERE r.logical_rule_key = p.logical_rule_key) AS promoted_rule_rows,
  count(r.*) FILTER (WHERE r.review_status = 'verified' AND r.execution_status = 'auto') AS promoted_verified_auto_rows,
  count(r.*) FILTER (WHERE r.oracle_hash = p.oracle_hash) AS promoted_oracle_hash_rows,
  (SELECT count(*) FROM manaloom_deploy_audit.pg188_pyromancer_ascension_quest_copy_20260624_210604) AS backup_rows
FROM proposed p
LEFT JOIN rule_rows r
  ON r.normalized_name = p.normalized_name
 AND r.logical_rule_key = p.logical_rule_key
 AND r.oracle_hash = p.oracle_hash
GROUP BY p.card_name, p.normalized_name, p.logical_rule_key, p.oracle_hash
ORDER BY p.card_name;
