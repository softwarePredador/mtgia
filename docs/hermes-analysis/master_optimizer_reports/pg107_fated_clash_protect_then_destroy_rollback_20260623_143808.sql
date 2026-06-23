BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'fated clash';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg107_fated_clash_protect_then_destroy_20260623_143808;

COMMIT;
