BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('annul', 'artifact blast', 'cancel', 'dispel', 'envelop', 'essence scatter', 'extinguish', 'false summoning', 'flash counter', 'gainsay', 'preemptive strike', 'remove soul')
   OR normalized_name LIKE 'annul // %'
   OR normalized_name LIKE 'artifact blast // %'
   OR normalized_name LIKE 'cancel // %'
   OR normalized_name LIKE 'dispel // %'
   OR normalized_name LIKE 'envelop // %'
   OR normalized_name LIKE 'essence scatter // %'
   OR normalized_name LIKE 'extinguish // %'
   OR normalized_name LIKE 'false summoning // %'
   OR normalized_name LIKE 'flash counter // %'
   OR normalized_name LIKE 'gainsay // %'
   OR normalized_name LIKE 'preemptive strike // %'
   OR normalized_name LIKE 'remove soul // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg286_xmage_counter_spell_wave_20260701_081305;

COMMIT;
