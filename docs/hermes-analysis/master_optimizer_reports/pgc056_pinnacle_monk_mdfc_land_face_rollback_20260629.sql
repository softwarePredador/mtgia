BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name = 'pinnacle monk // mystic peak'
  AND logical_rule_key = 'battle_rule_v1:bcde63b5e56f2b9f20af6384bc70ad5d';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pgc056_pinnacle_monk_mdfc_land_face_20260629;

COMMIT;
