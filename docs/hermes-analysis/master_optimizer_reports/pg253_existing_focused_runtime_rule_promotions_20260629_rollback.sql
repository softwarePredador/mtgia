BEGIN;
WITH proposed(normalized_name, logical_rule_key) AS (VALUES ('heroes remembered', 'battle_rule_v1:4978416393dc912bc2d6d090afde8dc8'), ('single combat', 'battle_rule_v1:45c2a4f6d6d4930fb4cb54b8fa886bc2'), ('the warring triad', 'battle_rule_v1:1b92340f98d8dd60da33dbd03e915d23'), ('toralf, god of fury // toralf''s hammer', 'battle_rule_v1:733e913423b3c4471520195c8a814097'), ('unstable glyphbridge // sandswirl wanderglyph', 'battle_rule_v1:f4168e92445f0a9b9b2de0ef32f4b78d'), ('vedalken orrery', 'battle_rule_v1:9e2c7c96d5b2a117731924d511bb0e2a'), ('wand of vertebrae', 'battle_rule_v1:ab583f78c19a22031bb99e0ac2d0d131'), ('whispersilk cloak', 'battle_rule_v1:776e69f786c18a8398012554b8e22907'), ('wild ricochet', 'battle_rule_v1:bb9ee6595d8b30aa87f1a15879e2703a')), deleted AS (
  DELETE FROM public.card_battle_rules r USING proposed p
  WHERE r.normalized_name=p.normalized_name AND r.logical_rule_key=p.logical_rule_key
    AND NOT EXISTS (SELECT 1 FROM public.pg253_existing_focused_runtime_rule_promotions_backup b WHERE b.normalized_name=r.normalized_name AND b.logical_rule_key=r.logical_rule_key)
  RETURNING r.*
), restored AS (
  INSERT INTO public.card_battle_rules (normalized_name, logical_rule_key, card_id, card_name, effect_json, deck_role_json, source, confidence, review_status, execution_status, rule_version, oracle_hash, notes, reviewed_by, reviewed_at, created_at, updated_at, last_seen_at)
  SELECT b.normalized_name,b.logical_rule_key,b.card_id,b.card_name,b.effect_json,b.deck_role_json,b.source,b.confidence,b.review_status,b.execution_status,b.rule_version,b.oracle_hash,b.notes,b.reviewed_by,b.reviewed_at,b.created_at,now(),b.last_seen_at
  FROM public.pg253_existing_focused_runtime_rule_promotions_backup b JOIN proposed p ON p.normalized_name=b.normalized_name AND p.logical_rule_key=b.logical_rule_key
  ON CONFLICT (normalized_name, logical_rule_key) DO UPDATE
  SET card_id=EXCLUDED.card_id, card_name=EXCLUDED.card_name, effect_json=EXCLUDED.effect_json, deck_role_json=EXCLUDED.deck_role_json, source=EXCLUDED.source, confidence=EXCLUDED.confidence, review_status=EXCLUDED.review_status, execution_status=EXCLUDED.execution_status, rule_version=EXCLUDED.rule_version, oracle_hash=EXCLUDED.oracle_hash, notes=EXCLUDED.notes, reviewed_by=EXCLUDED.reviewed_by, reviewed_at=EXCLUDED.reviewed_at, updated_at=now(), last_seen_at=EXCLUDED.last_seen_at
  RETURNING *
)
SELECT (SELECT count(*) FROM deleted) AS deleted_inserted_rows, (SELECT count(*) FROM restored) AS restored_rows;
COMMIT;
