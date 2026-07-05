BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('air-cult elemental', 'guardians of koilos', 'roaming ghostlight', 'winter eladrin')
   OR normalized_name LIKE 'air-cult elemental // %'
   OR normalized_name LIKE 'guardians of koilos // %'
   OR normalized_name LIKE 'roaming ghostlight // %'
   OR normalized_name LIKE 'winter eladrin // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg492_etb_bounce_target_vocabulary_new_s_20260705_080218;

COMMIT;
