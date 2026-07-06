BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('flurry of wings', 'ordered migration', 'rise from the tides', 'spontaneous generation', 'spore burst')
   OR normalized_name LIKE 'flurry of wings // %'
   OR normalized_name LIKE 'ordered migration // %'
   OR normalized_name LIKE 'rise from the tides // %'
   OR normalized_name LIKE 'spontaneous generation // %'
   OR normalized_name LIKE 'spore burst // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg548_dynamic_token_extended_new_server_20260706_040441;

COMMIT;
