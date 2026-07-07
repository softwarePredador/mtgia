BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('dark withering', 'death rattle', 'expunge', 'murderous compulsion', 'protective response', 'shoot down', 'slingbow trap', 'snuff out', 'thraben exorcism', 'vanishing verse')
   OR normalized_name LIKE 'dark withering // %'
   OR normalized_name LIKE 'death rattle // %'
   OR normalized_name LIKE 'expunge // %'
   OR normalized_name LIKE 'murderous compulsion // %'
   OR normalized_name LIKE 'protective response // %'
   OR normalized_name LIKE 'shoot down // %'
   OR normalized_name LIKE 'slingbow trap // %'
   OR normalized_name LIKE 'snuff out // %'
   OR normalized_name LIKE 'thraben exorcism // %'
   OR normalized_name LIKE 'vanishing verse // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg583b_safe_primary_sentence_removal_tar_20260707_005413;

COMMIT;
