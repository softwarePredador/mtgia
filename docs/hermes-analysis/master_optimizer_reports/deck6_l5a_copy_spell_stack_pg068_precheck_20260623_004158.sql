\pset pager off

CREATE TEMP TABLE pg068_target_cards AS
SELECT
  c.id,
  c.name,
  c.type_line,
  c.mana_cost,
  c.cmc,
  md5(coalesce(c.oracle_text, '')) AS oracle_hash,
  c.oracle_text
FROM cards c
WHERE lower(c.name) IN ('dualcaster mage', 'reiterate');

CREATE TEMP TABLE pg068_target_rules AS
SELECT
  c.name,
  cbr.normalized_name,
  cbr.logical_rule_key,
  cbr.source,
  cbr.review_status,
  cbr.execution_status,
  cbr.confidence,
  cbr.oracle_hash,
  cbr.effect_json,
  cbr.deck_role_json
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE cbr.normalized_name IN ('dualcaster mage', 'reiterate');

SELECT
  count(*) FILTER (
    WHERE (name = 'Dualcaster Mage' AND oracle_hash = 'e26f613394b72e9724d299512983218a')
       OR (name = 'Reiterate' AND oracle_hash = '996fb5f02f16605ff7f1c899f2c50f60')
  ) AS target_cards_with_expected_oracle_hash,
  (SELECT count(*) FROM pg068_target_rules) AS existing_rule_rows,
  (
    SELECT count(*)
    FROM pg068_target_rules
    WHERE logical_rule_key IN (
      'battle_rule_v1:e176019b87d68d22e2388e08a4efbf55',
      'battle_rule_v1:18eeabc2a2fa631d99caf65a43a8c405'
    )
  ) AS new_rule_key_rows_already_present,
  (
    SELECT count(*)
    FROM pg068_target_rules
    WHERE review_status IN ('verified', 'active', 'needs_review')
      AND execution_status IN ('auto', 'executable', 'review_only')
  ) AS current_active_or_review_rows,
  (
    SELECT count(*)
    FROM pg068_target_rules
    WHERE oracle_hash IS NULL
       OR effect_json->>'battle_model_scope' IS NULL
       OR (
         normalized_name = 'dualcaster mage'
         AND coalesce((effect_json->>'etb_copy_spell')::boolean, false) IS false
       )
  ) AS rows_missing_pg068_runtime_metadata,
  to_regclass('manaloom_deploy_audit.pg068_deck6_l5a_copy_spell_stack_20260623_004158') IS NOT NULL AS backup_table_already_exists
FROM pg068_target_cards;

SELECT
  name,
  type_line,
  mana_cost,
  cmc,
  oracle_hash,
  oracle_text
FROM pg068_target_cards
ORDER BY name;

SELECT
  name,
  normalized_name,
  logical_rule_key,
  source,
  review_status,
  execution_status,
  confidence,
  oracle_hash,
  effect_json,
  deck_role_json
FROM pg068_target_rules
ORDER BY name, source, logical_rule_key;
