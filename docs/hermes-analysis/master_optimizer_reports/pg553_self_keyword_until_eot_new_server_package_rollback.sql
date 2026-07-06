BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('bastion mastodon', 'bladed sentinel', 'cabaretti initiate', 'cobalt golem', 'disciple of the old ways', 'dukhara peafowl', 'fallaji chaindancer', 'goblin balloon brigade', 'gruul nodorog', 'gust-skimmer', 'henge guardian', 'igneous golem', 'kessig wolf', 'killer whale', 'kor sky climber', 'leaping master', 'llanowar cavalry', 'malachite golem', 'manta riders', 'mardu hateblade', 'moorland inquisitor', 'narnam cobra', 'noble panther', 'patagia golem', 'pestilent wolf', 'prakhata pillar-bug', 'riveteers initiate', 'roofstalker wight', 'saberclaw golem', 'serpentine kavu', 'skittering heartstopper', 'steeple creeper', 'stonefare crocodile', 'stream hopper', 'titanium golem', 'towering thunderfist', 'twilight panther', 'unyielding krumar', 'vectis silencers', 'viashino grappler', 'weldfast monitor', 'whiptongue frog', 'wily bandar')
   OR normalized_name LIKE 'bastion mastodon // %'
   OR normalized_name LIKE 'bladed sentinel // %'
   OR normalized_name LIKE 'cabaretti initiate // %'
   OR normalized_name LIKE 'cobalt golem // %'
   OR normalized_name LIKE 'disciple of the old ways // %'
   OR normalized_name LIKE 'dukhara peafowl // %'
   OR normalized_name LIKE 'fallaji chaindancer // %'
   OR normalized_name LIKE 'goblin balloon brigade // %'
   OR normalized_name LIKE 'gruul nodorog // %'
   OR normalized_name LIKE 'gust-skimmer // %'
   OR normalized_name LIKE 'henge guardian // %'
   OR normalized_name LIKE 'igneous golem // %'
   OR normalized_name LIKE 'kessig wolf // %'
   OR normalized_name LIKE 'killer whale // %'
   OR normalized_name LIKE 'kor sky climber // %'
   OR normalized_name LIKE 'leaping master // %'
   OR normalized_name LIKE 'llanowar cavalry // %'
   OR normalized_name LIKE 'malachite golem // %'
   OR normalized_name LIKE 'manta riders // %'
   OR normalized_name LIKE 'mardu hateblade // %'
   OR normalized_name LIKE 'moorland inquisitor // %'
   OR normalized_name LIKE 'narnam cobra // %'
   OR normalized_name LIKE 'noble panther // %'
   OR normalized_name LIKE 'patagia golem // %'
   OR normalized_name LIKE 'pestilent wolf // %'
   OR normalized_name LIKE 'prakhata pillar-bug // %'
   OR normalized_name LIKE 'riveteers initiate // %'
   OR normalized_name LIKE 'roofstalker wight // %'
   OR normalized_name LIKE 'saberclaw golem // %'
   OR normalized_name LIKE 'serpentine kavu // %'
   OR normalized_name LIKE 'skittering heartstopper // %'
   OR normalized_name LIKE 'steeple creeper // %'
   OR normalized_name LIKE 'stonefare crocodile // %'
   OR normalized_name LIKE 'stream hopper // %'
   OR normalized_name LIKE 'titanium golem // %'
   OR normalized_name LIKE 'towering thunderfist // %'
   OR normalized_name LIKE 'twilight panther // %'
   OR normalized_name LIKE 'unyielding krumar // %'
   OR normalized_name LIKE 'vectis silencers // %'
   OR normalized_name LIKE 'viashino grappler // %'
   OR normalized_name LIKE 'weldfast monitor // %'
   OR normalized_name LIKE 'whiptongue frog // %'
   OR normalized_name LIKE 'wily bandar // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg553_self_keyword_until_eot_new_server_20260706_054704;

COMMIT;
