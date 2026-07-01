BEGIN;

DELETE FROM public.card_battle_rules
WHERE normalized_name IN ('back to nature', 'blazing volley', 'cleanfall', 'creeping corrosion', 'damnation', 'day of judgment', 'desert sandstorm', 'devastation', 'purify', 'pyroclasm', 'storm''s wrath', 'tempest of light', 'tranquility')
   OR normalized_name LIKE 'back to nature // %'
   OR normalized_name LIKE 'blazing volley // %'
   OR normalized_name LIKE 'cleanfall // %'
   OR normalized_name LIKE 'creeping corrosion // %'
   OR normalized_name LIKE 'damnation // %'
   OR normalized_name LIKE 'day of judgment // %'
   OR normalized_name LIKE 'desert sandstorm // %'
   OR normalized_name LIKE 'devastation // %'
   OR normalized_name LIKE 'purify // %'
   OR normalized_name LIKE 'pyroclasm // %'
   OR normalized_name LIKE 'storm''s wrath // %'
   OR normalized_name LIKE 'tempest of light // %'
   OR normalized_name LIKE 'tranquility // %';

INSERT INTO public.card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg289_xmage_board_wipe_spell_wave_20260701_084207;

COMMIT;
