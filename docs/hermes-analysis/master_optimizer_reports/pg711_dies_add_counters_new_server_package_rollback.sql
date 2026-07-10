BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bile-vial boggart', 'festering mummy', 'goblin assault team', 'guul draz mucklord', 'lawless broker', 'sparring construct', 'spinal centipede', 'steadfast sentry', 'venerable knight')
   OR normalized_name LIKE 'bile-vial boggart // %'
   OR normalized_name LIKE 'festering mummy // %'
   OR normalized_name LIKE 'goblin assault team // %'
   OR normalized_name LIKE 'guul draz mucklord // %'
   OR normalized_name LIKE 'lawless broker // %'
   OR normalized_name LIKE 'sparring construct // %'
   OR normalized_name LIKE 'spinal centipede // %'
   OR normalized_name LIKE 'steadfast sentry // %'
   OR normalized_name LIKE 'venerable knight // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg711_dies_add_counters_new_server_20260710_172518;

COMMIT;
