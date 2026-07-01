BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('batterhorn', 'conclave naturalists', 'enlightened ascetic', 'goblin settler', 'indrik stomphowler', 'manic vandal', 'meteor golem', 'monk realist', 'ogre arsonist', 'oxidda scrapmelter', 'rambunctious mutt', 'ravaging horde', 'ravenous chupacabra', 'reclamation sage', 'uktabi orangutan', 'viridian shaman', 'vithian renegades', 'war priest of thune', 'wild celebrants')
   OR normalized_name LIKE 'batterhorn // %'
   OR normalized_name LIKE 'conclave naturalists // %'
   OR normalized_name LIKE 'enlightened ascetic // %'
   OR normalized_name LIKE 'goblin settler // %'
   OR normalized_name LIKE 'indrik stomphowler // %'
   OR normalized_name LIKE 'manic vandal // %'
   OR normalized_name LIKE 'meteor golem // %'
   OR normalized_name LIKE 'monk realist // %'
   OR normalized_name LIKE 'ogre arsonist // %'
   OR normalized_name LIKE 'oxidda scrapmelter // %'
   OR normalized_name LIKE 'rambunctious mutt // %'
   OR normalized_name LIKE 'ravaging horde // %'
   OR normalized_name LIKE 'ravenous chupacabra // %'
   OR normalized_name LIKE 'reclamation sage // %'
   OR normalized_name LIKE 'uktabi orangutan // %'
   OR normalized_name LIKE 'viridian shaman // %'
   OR normalized_name LIKE 'vithian renegades // %'
   OR normalized_name LIKE 'war priest of thune // %'
   OR normalized_name LIKE 'wild celebrants // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg297_xmage_creature_etb_destroy_wave_20260701_104734;

COMMIT;
