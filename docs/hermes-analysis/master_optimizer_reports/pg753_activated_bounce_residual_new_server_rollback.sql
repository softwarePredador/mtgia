BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('hallowed ground', 'razorfin abolisher', 'waterfront bouncer')
   OR normalized_name LIKE 'hallowed ground // %'
   OR normalized_name LIKE 'razorfin abolisher // %'
   OR normalized_name LIKE 'waterfront bouncer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg753_activated_bounce_residual_new_serv_20260711_100042;

COMMIT;
