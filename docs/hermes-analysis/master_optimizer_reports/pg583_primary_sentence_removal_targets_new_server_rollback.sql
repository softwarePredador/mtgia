BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('assassin''s blade', 'dark withering', 'death rattle', 'eightfold maze', 'expunge', 'just fate', 'murderous compulsion', 'protective response', 'sheer drop', 'shoot down', 'slaughter', 'slingbow trap', 'snuff out', 'thraben exorcism', 'vanishing verse')
   OR normalized_name LIKE 'assassin''s blade // %'
   OR normalized_name LIKE 'dark withering // %'
   OR normalized_name LIKE 'death rattle // %'
   OR normalized_name LIKE 'eightfold maze // %'
   OR normalized_name LIKE 'expunge // %'
   OR normalized_name LIKE 'just fate // %'
   OR normalized_name LIKE 'murderous compulsion // %'
   OR normalized_name LIKE 'protective response // %'
   OR normalized_name LIKE 'sheer drop // %'
   OR normalized_name LIKE 'shoot down // %'
   OR normalized_name LIKE 'slaughter // %'
   OR normalized_name LIKE 'slingbow trap // %'
   OR normalized_name LIKE 'snuff out // %'
   OR normalized_name LIKE 'thraben exorcism // %'
   OR normalized_name LIKE 'vanishing verse // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg583_primary_sentence_removal_targets_n_20260707_004155;

COMMIT;
