BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('avoid fate', 'double negative', 'outwit', 'second guess')
   OR normalized_name LIKE 'avoid fate // %'
   OR normalized_name LIKE 'double negative // %'
   OR normalized_name LIKE 'outwit // %'
   OR normalized_name LIKE 'second guess // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg663_counter_special_stack_constraints_20260708_151831;

COMMIT;
