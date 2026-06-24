BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('cool but rude')
   OR normalized_name LIKE 'cool but rude // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg190_cool_but_rude_class_rummage_20260624_213939;

COMMIT;
