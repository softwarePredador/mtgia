BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aysen crusader')
   OR normalized_name LIKE 'aysen crusader // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg800_static_count_base_subtypes_new_ser_20260712_015848;

COMMIT;
