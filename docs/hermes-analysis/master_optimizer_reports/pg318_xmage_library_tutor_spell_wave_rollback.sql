BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('circuitous route', 'farseek', 'into the north', 'natural connection', 'nature''s lore', 'personal tutor', 'ranger''s path', 'reshape the earth', 'shared roots', 'skyshroud claim', 'spoils of victory', 'three visits', 'untamed wilds')
   OR normalized_name LIKE 'circuitous route // %'
   OR normalized_name LIKE 'farseek // %'
   OR normalized_name LIKE 'into the north // %'
   OR normalized_name LIKE 'natural connection // %'
   OR normalized_name LIKE 'nature''s lore // %'
   OR normalized_name LIKE 'personal tutor // %'
   OR normalized_name LIKE 'ranger''s path // %'
   OR normalized_name LIKE 'reshape the earth // %'
   OR normalized_name LIKE 'shared roots // %'
   OR normalized_name LIKE 'skyshroud claim // %'
   OR normalized_name LIKE 'spoils of victory // %'
   OR normalized_name LIKE 'three visits // %'
   OR normalized_name LIKE 'untamed wilds // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg318_xmage_library_tutor_spell_wave_20260701_164350;

COMMIT;
