BEGIN;

DELETE FROM public.card_battle_rules r
WHERE r.normalized_name IN (SELECT normalized_name FROM (VALUES ('ashnod''s altar'), ('chrome mox'), ('mox diamond')) AS v(normalized_name))
  AND r.reviewed_by = 'codex-pg255';

UPDATE public.card_battle_rules r
SET card_id = b.card_id,
    card_name = b.card_name,
    effect_json = b.effect_json,
    deck_role_json = b.deck_role_json,
    source = b.source,
    confidence = b.confidence,
    review_status = b.review_status,
    execution_status = b.execution_status,
    rule_version = b.rule_version,
    oracle_hash = b.oracle_hash,
    notes = b.notes,
    reviewed_by = b.reviewed_by,
    reviewed_at = b.reviewed_at,
    updated_at = now(),
    last_seen_at = b.last_seen_at
FROM public.pg255_fast_mana_runtime_promotions_20260629_backup b
WHERE r.normalized_name = b.normalized_name
  AND r.logical_rule_key = b.logical_rule_key;

INSERT INTO public.card_battle_rules (normalized_name, logical_rule_key, card_id, card_name, effect_json, deck_role_json, source, confidence, review_status, execution_status, rule_version, oracle_hash, notes, reviewed_by, reviewed_at, created_at, updated_at, last_seen_at)
SELECT b.normalized_name, b.logical_rule_key, b.card_id, b.card_name, b.effect_json, b.deck_role_json, b.source, b.confidence, b.review_status, b.execution_status, b.rule_version, b.oracle_hash, b.notes, b.reviewed_by, b.reviewed_at, b.created_at, now(), b.last_seen_at
FROM public.pg255_fast_mana_runtime_promotions_20260629_backup b
WHERE NOT EXISTS (
  SELECT 1 FROM public.card_battle_rules r
  WHERE r.normalized_name = b.normalized_name
    AND r.logical_rule_key = b.logical_rule_key
);

COMMIT;
