BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('burst of strength', 'dragonscale boon')
   OR normalized_name LIKE 'burst of strength // %'
   OR normalized_name LIKE 'dragonscale boon // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg697_add_counters_untap_target_new_serv_20260709_065617;

COMMIT;
