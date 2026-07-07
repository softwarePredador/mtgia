BEGIN;

UPDATE public.card_battle_rules r
SET
  oracle_hash = md5(COALESCE(c.oracle_text, '')),
  updated_at = CURRENT_TIMESTAMP,
  notes = CASE
    WHEN COALESCE(r.notes, '') LIKE '%Oracle hash backfilled on 2026-07-07%'
      THEN r.notes
    ELSE trim(COALESCE(r.notes, '') || ' Oracle hash backfilled on 2026-07-07 from card_id-linked cards.oracle_text for trusted executable rule integrity.')
  END
FROM public.cards c
WHERE r.card_id = c.id
  AND r.source IN ('manual', 'curated')
  AND r.review_status IN ('verified', 'active')
  AND r.execution_status IN ('auto', 'executable')
  AND COALESCE(r.oracle_hash, '') = '';

COMMIT;
