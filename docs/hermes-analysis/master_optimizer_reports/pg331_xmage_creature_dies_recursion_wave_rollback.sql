BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dutiful attendant', 'elderfang ritualist', 'living lightning', 'myr retriever', 'workshop assistant')
   OR normalized_name LIKE 'dutiful attendant // %'
   OR normalized_name LIKE 'elderfang ritualist // %'
   OR normalized_name LIKE 'living lightning // %'
   OR normalized_name LIKE 'myr retriever // %'
   OR normalized_name LIKE 'workshop assistant // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg331_xmage_creature_dies_recursion_wave_20260701_210836;

COMMIT;
