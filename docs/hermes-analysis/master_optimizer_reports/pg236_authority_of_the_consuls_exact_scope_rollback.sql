BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('authority of the consuls')
   OR normalized_name LIKE 'authority of the consuls // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg236_authority_of_the_consuls_exact_scope_20260626_0910;

COMMIT;
