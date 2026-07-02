BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('advanced stitchwing', 'ghoulsteed', 'stitchwing skaab')
   OR normalized_name LIKE 'advanced stitchwing // %'
   OR normalized_name LIKE 'ghoulsteed // %'
   OR normalized_name LIKE 'stitchwing skaab // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg349_xmage_graveyard_self_return_discard_battlefield_wa;

COMMIT;
