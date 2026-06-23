-- PG063 deck608 tutor/search package precheck.
-- Scope: Enlightened Tutor, Idyllic Tutor, Goblin Engineer, Imperial Recruiter.

WITH target_names(normalized_name) AS (
  VALUES
    ('enlightened tutor'),
    ('idyllic tutor'),
    ('goblin engineer'),
    ('imperial recruiter')
),
target_cards AS (
  SELECT lower(c.name) AS normalized_name, c.name, c.id, md5(coalesce(c.oracle_text, '')) AS live_hash
  FROM cards c
  JOIN target_names tn ON tn.normalized_name = lower(c.name)
),
new_rule_keys(normalized_name, logical_rule_key) AS (
  VALUES
    ('enlightened tutor', 'battle_rule_v1:ed0d4316c416061742e6eea0e4bade8a'),
    ('idyllic tutor', 'battle_rule_v1:b516a3f8059b43f049f156445eeeaf21'),
    ('goblin engineer', 'battle_rule_v1:bbff8bfe05ccbe03f94fcbadd749be18'),
    ('imperial recruiter', 'battle_rule_v1:3323c3883679f1a92af90fbb39918840')
),
target_rules AS (
  SELECT cbr.*
  FROM card_battle_rules cbr
  JOIN target_names tn ON tn.normalized_name = cbr.normalized_name
)
SELECT 'target_cards' AS metric, count(*)::text AS value FROM target_cards
UNION ALL
SELECT 'target_rule_rows', count(*)::text FROM target_rules
UNION ALL
SELECT 'current_curated_runtime_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('active', 'verified')
  AND execution_status IN ('auto', 'executable')
UNION ALL
SELECT 'current_generated_review_only_rows', count(*)::text
FROM target_rules
WHERE source = 'generated'
  AND review_status = 'needs_review'
  AND execution_status = 'review_only'
UNION ALL
SELECT 'current_trusted_missing_hash_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('active', 'verified')
  AND execution_status IN ('auto', 'executable')
  AND coalesce(oracle_hash, '') = ''
UNION ALL
SELECT 'new_rule_key_rows_already_present', count(*)::text
FROM target_rules tr
JOIN new_rule_keys nrk
  ON nrk.normalized_name = tr.normalized_name
 AND nrk.logical_rule_key = tr.logical_rule_key
UNION ALL
SELECT 'target_names_missing_cards', count(*)::text
FROM target_names tn
LEFT JOIN target_cards tc ON tc.normalized_name = tn.normalized_name
WHERE tc.id IS NULL;
