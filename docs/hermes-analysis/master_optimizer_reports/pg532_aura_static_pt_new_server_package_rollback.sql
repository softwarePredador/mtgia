BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('boon of emrakul', 'chant of the skifsang', 'clinging darkness', 'dead weight', 'debilitating injury', 'defensive stance', 'divine transformation', 'enfeeblement', 'feast of the unicorn', 'feebleness', 'feral invocation', 'giant strength', 'gift of granite', 'greel''s caress', 'hardened-scale armor', 'hero''s resolve', 'holy strength', 'indomitable will', 'knight''s pledge', 'mageta''s boon', 'maggot therapy', 'mire''s grasp', 'oakenform', 'pin to the earth', 'riot spikes', 'sensory deprivation', 'siegecraft', 'slimebind', 'stoneskin', 'torment', 'torpor dust', 'twisted experiment', 'unholy strength', 'weakness', 'weight of the underworld')
   OR normalized_name LIKE 'boon of emrakul // %'
   OR normalized_name LIKE 'chant of the skifsang // %'
   OR normalized_name LIKE 'clinging darkness // %'
   OR normalized_name LIKE 'dead weight // %'
   OR normalized_name LIKE 'debilitating injury // %'
   OR normalized_name LIKE 'defensive stance // %'
   OR normalized_name LIKE 'divine transformation // %'
   OR normalized_name LIKE 'enfeeblement // %'
   OR normalized_name LIKE 'feast of the unicorn // %'
   OR normalized_name LIKE 'feebleness // %'
   OR normalized_name LIKE 'feral invocation // %'
   OR normalized_name LIKE 'giant strength // %'
   OR normalized_name LIKE 'gift of granite // %'
   OR normalized_name LIKE 'greel''s caress // %'
   OR normalized_name LIKE 'hardened-scale armor // %'
   OR normalized_name LIKE 'hero''s resolve // %'
   OR normalized_name LIKE 'holy strength // %'
   OR normalized_name LIKE 'indomitable will // %'
   OR normalized_name LIKE 'knight''s pledge // %'
   OR normalized_name LIKE 'mageta''s boon // %'
   OR normalized_name LIKE 'maggot therapy // %'
   OR normalized_name LIKE 'mire''s grasp // %'
   OR normalized_name LIKE 'oakenform // %'
   OR normalized_name LIKE 'pin to the earth // %'
   OR normalized_name LIKE 'riot spikes // %'
   OR normalized_name LIKE 'sensory deprivation // %'
   OR normalized_name LIKE 'siegecraft // %'
   OR normalized_name LIKE 'slimebind // %'
   OR normalized_name LIKE 'stoneskin // %'
   OR normalized_name LIKE 'torment // %'
   OR normalized_name LIKE 'torpor dust // %'
   OR normalized_name LIKE 'twisted experiment // %'
   OR normalized_name LIKE 'unholy strength // %'
   OR normalized_name LIKE 'weakness // %'
   OR normalized_name LIKE 'weight of the underworld // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg532_aura_static_pt_new_server_20260705_215533;

COMMIT;
