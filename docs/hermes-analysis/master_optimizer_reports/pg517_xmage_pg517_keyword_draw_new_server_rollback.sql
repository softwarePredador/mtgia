BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('accelerate', 'bladebrand', 'cloak of feathers', 'lace with moonglove', 'leap')
   OR normalized_name LIKE 'accelerate // %'
   OR normalized_name LIKE 'bladebrand // %'
   OR normalized_name LIKE 'cloak of feathers // %'
   OR normalized_name LIKE 'lace with moonglove // %'
   OR normalized_name LIKE 'leap // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.xmage_pg517_keyword_draw_new_server_pg51_20260705_163407;

COMMIT;
