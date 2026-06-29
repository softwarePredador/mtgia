BEGIN;

WITH proposed(normalized_name, logical_rule_key) AS (
  VALUES
    ('ancient copper dragon', 'battle_rule_v1:e2ac43c9f6e03e11e9fab994a5c15258'), ('beacon of immortality', 'battle_rule_v1:655c7da1b9d381d24b94b64487226598'), ('invincible hymn', 'battle_rule_v1:de6504fa068c924a1bad5f1ada35a026'), ('planetarium of wan shi tong', 'battle_rule_v1:a2082ebdf6e7e169b97eccecbb22b36a'), ('radiant performer', 'battle_rule_v1:fa12ce53b0a0c4b963f4071b4fde2c9b'), ('rem karolus, stalwart slayer', 'battle_rule_v1:1a987670b594e446e4b1a122214e549e'), ('rune-tail, kitsune ascendant // rune-tail''s essence', 'battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e'), ('sawhorn nemesis', 'battle_rule_v1:93e3f5684069bf77d7219e17f3e04a6c:sawhorn_nemesis_runtime_v1'), ('screaming nemesis', 'battle_rule_v1:77190ec2e1e1dcb8b15429e5d53e68bd:screaming_nemesis_runtime_v1'), ('semblance anvil', 'battle_rule_v1:ac1ab7b07d9e4a4cb5ce455bc50ccb7e'), ('serra ascendant', 'battle_rule_v1:c3124030acfa1668606aca59dbbb7e2e'), ('slickshot show-off', 'battle_rule_v1:9fd2ff72170533330fc8ba9165bd99b4'), ('stuffy doll', 'battle_rule_v1:e7b60d9805dbf2701195f627c6ca1600'), ('taunt from the rampart', 'battle_rule_v1:16e15ea414a18410acd151d43276651c'), ('the walls of ba sing se', 'battle_rule_v1:1e5bcf3b45fcae347879976d74d2ef84'), ('zirda, the dawnwaker', 'battle_rule_v1:45c3e1db1be4f2f97a3337ce3de8f767')
), deleted AS (
  DELETE FROM public.card_battle_rules r
  USING proposed p
  WHERE r.normalized_name = p.normalized_name
    AND r.logical_rule_key = p.logical_rule_key
    AND NOT EXISTS (
      SELECT 1 FROM public.pg252_manual_runtime_waiver_promotions_backup b
      WHERE b.normalized_name = r.normalized_name
        AND b.logical_rule_key = r.logical_rule_key
    )
  RETURNING r.*
), restored AS (
  INSERT INTO public.card_battle_rules (
    normalized_name, logical_rule_key, card_id, card_name, effect_json, deck_role_json,
    source, confidence, review_status, execution_status, rule_version, oracle_hash,
    notes, reviewed_by, reviewed_at, created_at, updated_at, last_seen_at
  )
  SELECT b.normalized_name, b.logical_rule_key, b.card_id, b.card_name, b.effect_json, b.deck_role_json,
         b.source, b.confidence, b.review_status, b.execution_status, b.rule_version, b.oracle_hash,
         b.notes, b.reviewed_by, b.reviewed_at, b.created_at, now(), b.last_seen_at
  FROM public.pg252_manual_runtime_waiver_promotions_backup b
  JOIN proposed p ON p.normalized_name = b.normalized_name AND p.logical_rule_key = b.logical_rule_key
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET card_id = EXCLUDED.card_id, card_name = EXCLUDED.card_name, effect_json = EXCLUDED.effect_json,
      deck_role_json = EXCLUDED.deck_role_json, source = EXCLUDED.source, confidence = EXCLUDED.confidence,
      review_status = EXCLUDED.review_status, execution_status = EXCLUDED.execution_status,
      rule_version = EXCLUDED.rule_version, oracle_hash = EXCLUDED.oracle_hash, notes = EXCLUDED.notes,
      reviewed_by = EXCLUDED.reviewed_by, reviewed_at = EXCLUDED.reviewed_at, updated_at = now(),
      last_seen_at = EXCLUDED.last_seen_at
  RETURNING *
)
SELECT (SELECT count(*) FROM deleted) AS deleted_inserted_rows,
       (SELECT count(*) FROM restored) AS restored_rows;

COMMIT;
