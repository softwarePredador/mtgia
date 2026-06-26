BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bolt bend')
   OR normalized_name LIKE 'bolt bend // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg240_bolt_bend_redirect_20260626_104058;

COMMIT;
