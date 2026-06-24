BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dark ritual', 'pyretic ritual')
   OR normalized_name LIKE 'dark ritual // %'
   OR normalized_name LIKE 'pyretic ritual // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg156_simple_rituals_20260624_083409;

COMMIT;
