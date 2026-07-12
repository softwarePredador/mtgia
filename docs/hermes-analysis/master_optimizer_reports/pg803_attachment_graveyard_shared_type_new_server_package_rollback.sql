BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('alpha status', 'death''s approach', 'exoskeletal armor', 'stoneforge masterwork', 'wreath of geists')
   OR normalized_name LIKE 'alpha status // %'
   OR normalized_name LIKE 'death''s approach // %'
   OR normalized_name LIKE 'exoskeletal armor // %'
   OR normalized_name LIKE 'stoneforge masterwork // %'
   OR normalized_name LIKE 'wreath of geists // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg803_attachment_graveyard_shared_type_n_20260712_031823;

COMMIT;
