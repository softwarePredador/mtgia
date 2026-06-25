BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('young pyromancer')
   OR normalized_name LIKE 'young pyromancer // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg195_young_pyromancer_20260625_001550;

COMMIT;
