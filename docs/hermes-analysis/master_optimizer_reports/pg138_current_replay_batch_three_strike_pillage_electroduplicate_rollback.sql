BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('electroduplicate', 'pirate''s pillage', 'strike it rich')
   OR normalized_name LIKE 'electroduplicate // %'
   OR normalized_name LIKE 'pirate''s pillage // %'
   OR normalized_name LIKE 'strike it rich // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg138_current_replay_batch_three_strike_pillage_electrod;

COMMIT;
