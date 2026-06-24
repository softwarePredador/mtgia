BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('double vision', 'swarm intelligence')
   OR normalized_name LIKE 'double vision // %'
   OR normalized_name LIKE 'swarm intelligence // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg174_copy_spell_engines_20260624_124529;

COMMIT;
