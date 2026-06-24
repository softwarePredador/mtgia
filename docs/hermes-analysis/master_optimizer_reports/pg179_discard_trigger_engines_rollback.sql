BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('feast of sanity', 'geth''s grimoire', 'megrim')
   OR normalized_name LIKE 'feast of sanity // %'
   OR normalized_name LIKE 'geth''s grimoire // %'
   OR normalized_name LIKE 'megrim // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg179_discard_trigger_engines_20260624_140220;

COMMIT;
