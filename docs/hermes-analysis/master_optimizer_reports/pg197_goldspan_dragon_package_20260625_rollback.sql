BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('goldspan dragon')
   OR normalized_name LIKE 'goldspan dragon // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg197_goldspan_dragon_20260625_013356;

COMMIT;
