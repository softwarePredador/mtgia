BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('burst of energy')
   OR normalized_name LIKE 'burst of energy // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg797_untap_target_spell_new_server_20260712_010534;

COMMIT;
