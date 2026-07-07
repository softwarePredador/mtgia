BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('battlewise valor', 'chain to memory', 'cruel finality', 'ferocious charge', 'inordinate rage', 'lose hope', 'lost in a labyrinth', 'stand firm', 'titan''s strength')
   OR normalized_name LIKE 'battlewise valor // %'
   OR normalized_name LIKE 'chain to memory // %'
   OR normalized_name LIKE 'cruel finality // %'
   OR normalized_name LIKE 'ferocious charge // %'
   OR normalized_name LIKE 'inordinate rage // %'
   OR normalized_name LIKE 'lose hope // %'
   OR normalized_name LIKE 'lost in a labyrinth // %'
   OR normalized_name LIKE 'stand firm // %'
   OR normalized_name LIKE 'titan''s strength // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg606_boost_scry_target_creature_new_ser_20260707_091910;

COMMIT;
