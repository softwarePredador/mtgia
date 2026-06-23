BEGIN;

CREATE TEMP TABLE pg089_l6_removal_compensation_target AS
SELECT 'generous gift'::text AS normalized_name
UNION ALL
SELECT 'stroke of midnight';

DELETE FROM card_battle_rules r
USING pg089_l6_removal_compensation_target t
WHERE r.normalized_name = t.normalized_name;

INSERT INTO card_battle_rules
SELECT *
FROM manaloom_deploy_audit.pg089_deck607_l6_removal_compensation_20260623_061026;

COMMIT;
