BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('aegis automaton', 'escape routes', 'galecaster colossus', 'kami of twisted reflection', 'neurok replica', 'obelisk of undoing', 'seal of removal', 'temporal adept', 'vedalken mastermind')
   OR normalized_name LIKE 'aegis automaton // %'
   OR normalized_name LIKE 'escape routes // %'
   OR normalized_name LIKE 'galecaster colossus // %'
   OR normalized_name LIKE 'kami of twisted reflection // %'
   OR normalized_name LIKE 'neurok replica // %'
   OR normalized_name LIKE 'obelisk of undoing // %'
   OR normalized_name LIKE 'seal of removal // %'
   OR normalized_name LIKE 'temporal adept // %'
   OR normalized_name LIKE 'vedalken mastermind // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg752_activated_bounce_new_server_20260711_094637;

COMMIT;
