BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('black market connections', 'smuggler''s share', 'davros, dalek creator')
   OR normalized_name LIKE 'black market connections // %'
   OR normalized_name LIKE 'smuggler''s share // %'
   OR normalized_name LIKE 'davros, dalek creator // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg216_phase_watchers_20260625_104702;

COMMIT;
