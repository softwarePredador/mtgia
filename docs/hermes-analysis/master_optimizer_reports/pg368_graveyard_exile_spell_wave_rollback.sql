BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('coffin purge', 'decompose', 'fade from memory', 'purify the grave', 'rapid decay', 'rats'' feast', 'scarab feast')
   OR normalized_name LIKE 'coffin purge // %'
   OR normalized_name LIKE 'decompose // %'
   OR normalized_name LIKE 'fade from memory // %'
   OR normalized_name LIKE 'purify the grave // %'
   OR normalized_name LIKE 'rapid decay // %'
   OR normalized_name LIKE 'rats'' feast // %'
   OR normalized_name LIKE 'scarab feast // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg368_graveyard_exile_spell_wave_20260702_094901;

COMMIT;
