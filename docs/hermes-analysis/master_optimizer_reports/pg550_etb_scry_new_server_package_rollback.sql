BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('automatic librarian', 'chrome cat', 'galadhrim guide', 'lost legion', 'octoprophet', 'omenspeaker', 'prophet of the peak', 'rumbling sentry', 'sage''s row savant')
   OR normalized_name LIKE 'automatic librarian // %'
   OR normalized_name LIKE 'chrome cat // %'
   OR normalized_name LIKE 'galadhrim guide // %'
   OR normalized_name LIKE 'lost legion // %'
   OR normalized_name LIKE 'octoprophet // %'
   OR normalized_name LIKE 'omenspeaker // %'
   OR normalized_name LIKE 'prophet of the peak // %'
   OR normalized_name LIKE 'rumbling sentry // %'
   OR normalized_name LIKE 'sage''s row savant // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg550_etb_scry_new_server_etb_scry_new_s_20260706_044550;

COMMIT;
