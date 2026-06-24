BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bartolomé del presidio')
   OR normalized_name LIKE 'bartolomé del presidio // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg152_bartolome_del_presidio_20260624_075739;

COMMIT;
