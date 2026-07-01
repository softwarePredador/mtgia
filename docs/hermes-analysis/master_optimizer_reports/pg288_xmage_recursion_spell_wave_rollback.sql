BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('argivian find', 'auroral procession', 'call to mind', 'disentomb', 'dutiful return', 'déjà vu', 'elven cache', 'fight on!', 'march of the returned', 'morbid plunder', 'nature''s spiral', 'raise dead', 'recollect', 'reconstruction', 'regenesis', 'regrowth', 'relearn', 'return to battle', 'ritual of restoration', 'sage''s knowledge', 'soul salvage', 'wildwood rebirth')
   OR normalized_name LIKE 'argivian find // %'
   OR normalized_name LIKE 'auroral procession // %'
   OR normalized_name LIKE 'call to mind // %'
   OR normalized_name LIKE 'disentomb // %'
   OR normalized_name LIKE 'dutiful return // %'
   OR normalized_name LIKE 'déjà vu // %'
   OR normalized_name LIKE 'elven cache // %'
   OR normalized_name LIKE 'fight on! // %'
   OR normalized_name LIKE 'march of the returned // %'
   OR normalized_name LIKE 'morbid plunder // %'
   OR normalized_name LIKE 'nature''s spiral // %'
   OR normalized_name LIKE 'raise dead // %'
   OR normalized_name LIKE 'recollect // %'
   OR normalized_name LIKE 'reconstruction // %'
   OR normalized_name LIKE 'regenesis // %'
   OR normalized_name LIKE 'regrowth // %'
   OR normalized_name LIKE 'relearn // %'
   OR normalized_name LIKE 'return to battle // %'
   OR normalized_name LIKE 'ritual of restoration // %'
   OR normalized_name LIKE 'sage''s knowledge // %'
   OR normalized_name LIKE 'soul salvage // %'
   OR normalized_name LIKE 'wildwood rebirth // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg288_xmage_recursion_spell_wave_20260701_083526;

COMMIT;
