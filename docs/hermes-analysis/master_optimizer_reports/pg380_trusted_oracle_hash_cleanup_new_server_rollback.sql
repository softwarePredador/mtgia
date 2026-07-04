BEGIN;

UPDATE card_battle_rules
SET
  oracle_hash = NULL,
  notes = NULLIF(
    replace(
      coalesce(notes, ''),
      E'\nPG380 trusted oracle hash cleanup: backfilled from cards.oracle_text on new server.',
      ''
    ),
    ''
  ),
  updated_at = now()
WHERE (
    normalized_name = 'angel''s grace'
    AND logical_rule_key = 'battle_rule_v1:2833836fd4d943d3e02d1cfa2d284227'
  )
  OR (
    normalized_name = 'seething song'
    AND logical_rule_key = 'battle_rule_v1:3eb15dc581c6b913158f9b63c023f3d7'
  )
RETURNING card_name, normalized_name, logical_rule_key, oracle_hash, updated_at;

COMMIT;
