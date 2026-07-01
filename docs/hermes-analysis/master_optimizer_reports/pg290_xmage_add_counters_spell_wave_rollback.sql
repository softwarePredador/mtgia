BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('battlegrowth', 'blight rot', 'scar')
   OR normalized_name LIKE 'battlegrowth // %'
   OR normalized_name LIKE 'blight rot // %'
   OR normalized_name LIKE 'scar // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg290_xmage_add_counters_spell_wave_20260701_090340;

COMMIT;
