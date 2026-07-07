WITH identity_copy_plan AS (
  VALUES
    (
      'Birds of Paradise // Birds of Paradise',
      'db2d9112-7066-44cb-beea-29e30ade8fe3'::uuid,
      'Birds of Paradise',
      '037e2cf5-cd46-4d03-975d-fb877e4de51a'::uuid,
      'battle_rule_v1:5d3ec3f1d92cfe2044d0172c4e3765ba',
      '2119fc1976cfab2480a9d86c57f1859b',
      '{"category":"ramp","effect":"creature","subtype":"mana_dork","timing":"battlefield"}'::jsonb
    ),
    (
      'Sol Ring // Sol Ring',
      'c971ff63-79d9-45e4-a7d9-4aec4eecd525'::uuid,
      'Sol Ring',
      '083da955-e31c-4d6b-a0f1-dfdf1569d9d8'::uuid,
      'battle_rule_v1:42621fcae461313f674d46db0da059af',
      '7d286f5619ac8934fb07abf152ffcb60',
      '{"category":"ramp","effect":"ramp_permanent","subtype":"fast_mana_rock"}'::jsonb
    )
),
plan(target_name, target_card_id, donor_name, donor_card_id, donor_logical_rule_key, expected_oracle_hash, repaired_deck_role_json) AS (
  SELECT * FROM identity_copy_plan
),
target_rows AS (
  SELECT
    p.*,
    t.name AS db_target_name,
    t.oracle_id AS target_oracle_id,
    md5(coalesce(t.oracle_text, '')) AS target_oracle_hash,
    d.name AS db_donor_name,
    d.oracle_id AS donor_oracle_id,
    md5(coalesce(d.oracle_text, '')) AS donor_oracle_hash,
    r.normalized_name AS donor_normalized_name,
    r.effect_json AS donor_effect_json,
    r.deck_role_json AS donor_deck_role_json,
    r.review_status AS donor_review_status,
    r.execution_status AS donor_execution_status,
    r.confidence AS donor_confidence
  FROM plan p
  LEFT JOIN public.cards t ON t.id = p.target_card_id
  LEFT JOIN public.cards d ON d.id = p.donor_card_id
  LEFT JOIN public.card_battle_rules r
    ON r.card_id = p.donor_card_id
   AND r.logical_rule_key = p.donor_logical_rule_key
),
existing_target_rules AS (
  SELECT
    p.target_name,
    count(r.*) FILTER (
      WHERE r.logical_rule_key = p.donor_logical_rule_key
        AND r.review_status IN ('verified', 'active')
        AND r.execution_status <> 'disabled'
    ) AS existing_trusted_same_key,
    count(r.*) FILTER (
      WHERE r.review_status IN ('verified', 'active')
        AND r.execution_status <> 'disabled'
    ) AS existing_trusted_any_key,
    count(r.*) AS existing_total_rules
  FROM plan p
  LEFT JOIN public.card_battle_rules r
    ON lower(r.card_name) = lower(p.target_name)
    OR r.normalized_name = lower(p.target_name)
  GROUP BY p.target_name
)
SELECT
  tr.target_name,
  tr.target_card_id,
  tr.db_target_name,
  tr.donor_name,
  tr.donor_card_id,
  tr.db_donor_name,
  tr.donor_logical_rule_key,
  tr.expected_oracle_hash,
  tr.target_oracle_hash,
  tr.donor_oracle_hash,
  (tr.target_oracle_id = tr.donor_oracle_id) AS same_oracle_id,
  (tr.target_oracle_hash = tr.expected_oracle_hash) AS target_hash_ok,
  (tr.donor_oracle_hash = tr.expected_oracle_hash) AS donor_hash_ok,
  tr.donor_review_status,
  tr.donor_execution_status,
  tr.donor_confidence,
  tr.donor_deck_role_json AS donor_role_before,
  tr.repaired_deck_role_json AS donor_role_after,
  et.existing_trusted_same_key,
  et.existing_trusted_any_key,
  et.existing_total_rules
FROM target_rows tr
JOIN existing_target_rules et USING (target_name)
ORDER BY tr.target_name;
