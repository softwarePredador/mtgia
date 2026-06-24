BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('pyromancer ascension')
   OR normalized_name LIKE 'pyromancer ascension // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg188_pyromancer_ascension_quest_copy_20260624_210604;

COMMIT;
