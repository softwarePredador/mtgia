BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('eldrazi confluence')
   OR normalized_name LIKE 'eldrazi confluence // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg147_eldrazi_confluence_20260624_063723;

COMMIT;
