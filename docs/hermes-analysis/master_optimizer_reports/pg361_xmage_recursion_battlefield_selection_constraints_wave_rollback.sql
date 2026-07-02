BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('behold the sinister six!', 'brought back', 'continue?', 'grim return', 'march from the tomb', 'patch up')
   OR normalized_name LIKE 'behold the sinister six! // %'
   OR normalized_name LIKE 'brought back // %'
   OR normalized_name LIKE 'continue? // %'
   OR normalized_name LIKE 'grim return // %'
   OR normalized_name LIKE 'march from the tomb // %'
   OR normalized_name LIKE 'patch up // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg361_xmage_recursion_battlefield_selection_constraints_;

COMMIT;
