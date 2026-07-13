BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bind', 'bind // liberate', 'squelch')
   OR normalized_name LIKE 'bind // %'
   OR normalized_name LIKE 'bind // liberate // %'
   OR normalized_name LIKE 'squelch // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg864_counter_activated_draw_new_server_20260713_051122;

COMMIT;
