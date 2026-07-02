BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('reconstruct history', 'retrieve', 'vivid revival')
   OR normalized_name LIKE 'reconstruct history // %'
   OR normalized_name LIKE 'retrieve // %'
   OR normalized_name LIKE 'vivid revival // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg342_xmage_recursion_exile_self_spell_wave_20260702_010;

COMMIT;
