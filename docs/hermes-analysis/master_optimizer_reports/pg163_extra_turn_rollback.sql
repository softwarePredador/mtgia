BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('final fortune', 'last chance')
   OR normalized_name LIKE 'final fortune // %'
   OR normalized_name LIKE 'last chance // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg163_extra_turn_20260624_102023;

COMMIT;
