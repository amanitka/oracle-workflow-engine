--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_process_start_group
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_process_start_group AS
SELECT 
  pg.code_start_group_category         AS code_start_group_category,
  pg.code_start_group                  AS code_start_group,
  MAX(pg.flag_active)                  AS flag_active,
  NVL(MIN(pp.flag_start_process), 'N') AS flag_start_process_priv 
FROM owner_wfm.etl_process_group pg
JOIN owner_wfm.etl_process p ON p.code_process_group = pg.code_process_group
LEFT JOIN owner_wfm.tmp_personal_privilege pp ON pp.code_responsible_group = p.code_responsible_group
WHERE pg.flag_deleted != 'Y'
  AND pg.flag_active != 'X'
GROUP BY pg.code_start_group_category,
         pg.code_start_group
ORDER BY pg.code_start_group_category,
         pg.code_start_group
WITH READ ONLY;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_process_start_group
-----------------------------------------------------------------
COMMENT ON TABLE owner_wfm.v_etl_process_start_group IS 'Process start group definition for console';
COMMENT ON COLUMN owner_wfm.v_etl_process_start_group.code_start_group_category IS 'Code of start group category';
COMMENT ON COLUMN owner_wfm.v_etl_process_start_group.code_start_group IS 'Code of start group';
COMMENT ON COLUMN owner_wfm.v_etl_process_start_group.flag_active IS 'Flag marking the process start group as active';
COMMENT ON COLUMN owner_wfm.v_etl_process_start_group.flag_start_process_priv IS 'Flag saying whether user has right to start the process';
