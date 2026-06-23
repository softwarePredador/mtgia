BEGIN;

CREATE SCHEMA IF NOT EXISTS manaloom_deploy_audit;

DO $$
BEGIN
  IF to_regclass('manaloom_deploy_audit.pg076_deck6_support_passive_ranger_tutor_20260623_054358') IS NOT NULL THEN
    RAISE EXCEPTION 'Backup table manaloom_deploy_audit.pg076_deck6_support_passive_ranger_tutor_20260623_054358 already exists';
  END IF;
END $$;

CREATE TABLE manaloom_deploy_audit.pg076_deck6_support_passive_ranger_tutor_20260623_054358 AS
SELECT cbr.*
FROM card_battle_rules cbr
JOIN cards c ON c.id = cbr.card_id
WHERE c.name = 'Ranger-Captain of Eos'
  AND cbr.logical_rule_key = 'battle_rule_v1:b05b64c0734daafd9c6f24ea02b39495';

WITH patched AS (
  UPDATE card_battle_rules cbr
  SET
    effect_json = cbr.effect_json || '{
      "etb_tutor_status": "runtime_library_to_hand",
      "etb_tutor_runtime_scope": "creature_mana_value_1_or_less_to_hand",
      "sacrifice_noncreature_silence_status": "annotation_only",
      "library_shuffle_status": "annotation_only"
    }'::jsonb,
    notes = concat_ws(
      E'\n',
      nullif(cbr.notes, ''),
      'PG076 addendum: Ranger-Captain ETB tutor is executable for creature mana value 1 or less; library shuffle and sacrifice noncreature silence remain annotation-only.'
    ),
    reviewed_by = 'codex',
    reviewed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
  FROM cards c
  WHERE cbr.card_id = c.id
    AND c.name = 'Ranger-Captain of Eos'
    AND cbr.logical_rule_key = 'battle_rule_v1:b05b64c0734daafd9c6f24ea02b39495'
  RETURNING cbr.normalized_name, cbr.logical_rule_key
)
SELECT count(*) AS ranger_rows_patched FROM patched;

COMMIT;
