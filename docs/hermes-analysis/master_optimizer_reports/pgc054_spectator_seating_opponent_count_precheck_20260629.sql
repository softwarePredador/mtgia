-- PGC054 Spectator Seating opponent-count ETB runtime precheck.
-- Scope: Spectator Seating only. PostgreSQL is the source of truth; Hermes
-- SQLite/deck snapshots must be synced after apply.

WITH target_card AS (
  SELECT
    c.id,
    c.name,
    c.oracle_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    c.type_line,
    regexp_replace(coalesce(c.oracle_text, ''), E'[\\n\\r]+', ' / ', 'g') AS oracle_text
  FROM cards c
  WHERE lower(c.name) = 'spectator seating'
),
target_rules AS (
  SELECT
    cbr.*,
    tc.id AS target_card_id,
    tc.target_oracle_hash
  FROM card_battle_rules cbr
  CROSS JOIN target_card tc
  WHERE cbr.normalized_name = 'spectator seating'
),
namespace AS (
  SELECT count(*) AS count_rows
  FROM card_battle_rules
  WHERE coalesce(reviewed_by, '') = 'codex-pgc054'
     OR coalesce(notes, '') ILIKE '%PGC054%'
)
SELECT 'target_cards' AS metric, count(*)::text AS value
FROM target_card
UNION ALL
SELECT 'target_rule_rows', count(*)::text
FROM target_rules
UNION ALL
SELECT 'curated_auto_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND review_status IN ('verified', 'active')
  AND execution_status = 'auto'
UNION ALL
SELECT 'generated_disabled_rows', count(*)::text
FROM target_rules
WHERE source = 'generated'
  AND execution_status = 'disabled'
UNION ALL
SELECT 'target_oracle_hash_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND oracle_hash = target_oracle_hash
UNION ALL
SELECT 'current_assumed_commander_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND effect_json->>'multiplayer_enters_untapped_status' = 'assumed_for_commander_table'
UNION ALL
SELECT 'current_annotation_scope_rows', count(*)::text
FROM target_rules
WHERE source = 'curated'
  AND effect_json->>'oracle_runtime_scope' = 'mana_source_runtime_with_annotation_only_clauses'
UNION ALL
SELECT 'pgc054_namespace_rows', count_rows::text
FROM namespace
UNION ALL
SELECT 'backup_table_exists', count(*)::text
FROM information_schema.tables
WHERE table_schema = 'manaloom_deploy_audit'
  AND table_name = 'pgc054_spectator_seating_opponent_count_20260629';

WITH target_card AS (
  SELECT
    c.id,
    c.name,
    c.oracle_id,
    md5(coalesce(c.oracle_text, '')) AS target_oracle_hash,
    c.type_line,
    regexp_replace(coalesce(c.oracle_text, ''), E'[\\n\\r]+', ' / ', 'g') AS oracle_text
  FROM cards c
  WHERE lower(c.name) = 'spectator seating'
)
SELECT
  id,
  name,
  oracle_id,
  target_oracle_hash,
  type_line,
  oracle_text
FROM target_card;

SELECT
  card_name,
  normalized_name,
  source,
  review_status,
  execution_status,
  rule_version,
  logical_rule_key,
  oracle_hash,
  reviewed_by,
  effect_json::text AS effect_json,
  left(coalesce(notes, ''), 260) AS notes
FROM card_battle_rules
WHERE normalized_name = 'spectator seating'
ORDER BY source, review_status, logical_rule_key;
