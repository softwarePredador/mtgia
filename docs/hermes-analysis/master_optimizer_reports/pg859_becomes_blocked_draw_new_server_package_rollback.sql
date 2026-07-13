BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('chambered nautilus', 'drelnoch', 'saprazzan heir')
   OR normalized_name LIKE 'chambered nautilus // %'
   OR normalized_name LIKE 'drelnoch // %'
   OR normalized_name LIKE 'saprazzan heir // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg859_becomes_blocked_draw_new_server_be_20260713_030532;

COMMIT;
