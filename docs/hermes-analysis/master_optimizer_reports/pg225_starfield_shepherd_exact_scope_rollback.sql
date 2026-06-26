BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('starfield shepherd')
   OR normalized_name LIKE 'starfield shepherd // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg225_starfield_shepherd_exact_scope_20260626_043837;

COMMIT;
