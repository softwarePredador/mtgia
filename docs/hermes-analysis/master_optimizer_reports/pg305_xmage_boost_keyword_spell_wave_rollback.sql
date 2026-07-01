BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('awaken the bear', 'bestow greatness', 'colossal might', 'crash the ramparts', 'fanatical fever', 'fanatical strength', 'fit of rage', 'flowstone strike', 'gift of strength', 'give in to violence', 'interjection', 'larger than life', 'lash of thorns', 'mighty leap', 'precise strike', 'rise to the challenge', 'rush of adrenaline', 'sangrite surge', 'screaming fury', 'seize the initiative', 'skillful lunge', 'staggering size', 'tread upon', 'uncaged fury', 'uncanny speed', 'unnatural predation', 'zealous strike')
   OR normalized_name LIKE 'awaken the bear // %'
   OR normalized_name LIKE 'bestow greatness // %'
   OR normalized_name LIKE 'colossal might // %'
   OR normalized_name LIKE 'crash the ramparts // %'
   OR normalized_name LIKE 'fanatical fever // %'
   OR normalized_name LIKE 'fanatical strength // %'
   OR normalized_name LIKE 'fit of rage // %'
   OR normalized_name LIKE 'flowstone strike // %'
   OR normalized_name LIKE 'gift of strength // %'
   OR normalized_name LIKE 'give in to violence // %'
   OR normalized_name LIKE 'interjection // %'
   OR normalized_name LIKE 'larger than life // %'
   OR normalized_name LIKE 'lash of thorns // %'
   OR normalized_name LIKE 'mighty leap // %'
   OR normalized_name LIKE 'precise strike // %'
   OR normalized_name LIKE 'rise to the challenge // %'
   OR normalized_name LIKE 'rush of adrenaline // %'
   OR normalized_name LIKE 'sangrite surge // %'
   OR normalized_name LIKE 'screaming fury // %'
   OR normalized_name LIKE 'seize the initiative // %'
   OR normalized_name LIKE 'skillful lunge // %'
   OR normalized_name LIKE 'staggering size // %'
   OR normalized_name LIKE 'tread upon // %'
   OR normalized_name LIKE 'uncaged fury // %'
   OR normalized_name LIKE 'uncanny speed // %'
   OR normalized_name LIKE 'unnatural predation // %'
   OR normalized_name LIKE 'zealous strike // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg305_xmage_boost_keyword_spell_wave_20260701_124529;

COMMIT;
