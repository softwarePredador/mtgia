BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('training grounds', 'biomancer''s familiar');

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg121_activated_creature_cost_reducer_restore_20260623_2;

COMMIT;
