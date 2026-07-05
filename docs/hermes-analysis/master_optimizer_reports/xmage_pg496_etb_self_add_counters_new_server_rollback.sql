BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('baleful ammit', 'crocodile of the crossing', 'kujar seedsculptor', 'ornery kudu', 'teyo''s lightshield')
   OR normalized_name LIKE 'baleful ammit // %'
   OR normalized_name LIKE 'crocodile of the crossing // %'
   OR normalized_name LIKE 'kujar seedsculptor // %'
   OR normalized_name LIKE 'ornery kudu // %'
   OR normalized_name LIKE 'teyo''s lightshield // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg496_etb_self_add_counters_new_se_20260705_090433;

COMMIT;
