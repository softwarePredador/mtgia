BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('arcane flight', 'armored ascension', 'aspect of gorgon', 'candlelight vigil', 'claws of valakut', 'epic proportions', 'ethereal armor', 'flaming sword', 'frantic strength', 'frenzied rage', 'giant spectacle', 'gift of orzhova', 'goblin war paint', 'immolation', 'madcap skills', 'magefire wings', 'mantle of webs', 'mark of the vampire', 'marked by honor', 'mythic proportions', 'nimbus wings', 'one with the wind', 'primal visitation', 'prodigious growth', 'sangrite backlash', 'serra''s embrace', 'spectral flight', 'spiteful motives', 'swashbuckling', 'tiger claws', 'unflinching courage', 'untamed hunger', 'web', 'wings of aesthir', 'wings of hope', 'zephid''s embrace')
   OR normalized_name LIKE 'arcane flight // %'
   OR normalized_name LIKE 'armored ascension // %'
   OR normalized_name LIKE 'aspect of gorgon // %'
   OR normalized_name LIKE 'candlelight vigil // %'
   OR normalized_name LIKE 'claws of valakut // %'
   OR normalized_name LIKE 'epic proportions // %'
   OR normalized_name LIKE 'ethereal armor // %'
   OR normalized_name LIKE 'flaming sword // %'
   OR normalized_name LIKE 'frantic strength // %'
   OR normalized_name LIKE 'frenzied rage // %'
   OR normalized_name LIKE 'giant spectacle // %'
   OR normalized_name LIKE 'gift of orzhova // %'
   OR normalized_name LIKE 'goblin war paint // %'
   OR normalized_name LIKE 'immolation // %'
   OR normalized_name LIKE 'madcap skills // %'
   OR normalized_name LIKE 'magefire wings // %'
   OR normalized_name LIKE 'mantle of webs // %'
   OR normalized_name LIKE 'mark of the vampire // %'
   OR normalized_name LIKE 'marked by honor // %'
   OR normalized_name LIKE 'mythic proportions // %'
   OR normalized_name LIKE 'nimbus wings // %'
   OR normalized_name LIKE 'one with the wind // %'
   OR normalized_name LIKE 'primal visitation // %'
   OR normalized_name LIKE 'prodigious growth // %'
   OR normalized_name LIKE 'sangrite backlash // %'
   OR normalized_name LIKE 'serra''s embrace // %'
   OR normalized_name LIKE 'spectral flight // %'
   OR normalized_name LIKE 'spiteful motives // %'
   OR normalized_name LIKE 'swashbuckling // %'
   OR normalized_name LIKE 'tiger claws // %'
   OR normalized_name LIKE 'unflinching courage // %'
   OR normalized_name LIKE 'untamed hunger // %'
   OR normalized_name LIKE 'web // %'
   OR normalized_name LIKE 'wings of aesthir // %'
   OR normalized_name LIKE 'wings of hope // %'
   OR normalized_name LIKE 'zephid''s embrace // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg804_aura_static_attached_keywords_new_20260712_034253;

COMMIT;
