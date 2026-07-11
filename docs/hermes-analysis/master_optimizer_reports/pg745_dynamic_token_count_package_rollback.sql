BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('evangel of heliod', 'fresh meat', 'hallowed spiritkeeper', 'revenge of the rats', 'reverent hoplite', 'spider spawning', 'underworld hermit')
   OR normalized_name LIKE 'evangel of heliod // %'
   OR normalized_name LIKE 'fresh meat // %'
   OR normalized_name LIKE 'hallowed spiritkeeper // %'
   OR normalized_name LIKE 'revenge of the rats // %'
   OR normalized_name LIKE 'reverent hoplite // %'
   OR normalized_name LIKE 'spider spawning // %'
   OR normalized_name LIKE 'underworld hermit // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg745_dynamic_token_count_new_server_dyn_20260711_064113;

COMMIT;
