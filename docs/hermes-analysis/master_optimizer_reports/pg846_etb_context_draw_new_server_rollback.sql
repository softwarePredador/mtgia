BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('clockwork servant', 'orator of ojutai', 'silkweaver elite', 'skyship buccaneer', 'storm fleet spy')
   OR normalized_name LIKE 'clockwork servant // %'
   OR normalized_name LIKE 'orator of ojutai // %'
   OR normalized_name LIKE 'silkweaver elite // %'
   OR normalized_name LIKE 'skyship buccaneer // %'
   OR normalized_name LIKE 'storm fleet spy // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg846_etb_context_draw_new_server_20260712_213929;

COMMIT;
