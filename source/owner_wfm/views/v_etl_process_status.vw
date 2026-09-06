--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_process_status
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_process_status AS
SELECT 
   p.id_process                       AS id_process,
   ps.id_process_instance             AS id_process_instance,
   ps.id_workflow_instance            AS id_workflow_instance,
   p.code_process_category            AS code_process_category,
   p.name_process                     AS name_process,
   pg.flag_active                     AS flag_active,
   ps.date_effective                  AS date_effective,
   ps.dtime_start                     AS dtime_start,
   ps.dtime_end                       AS dtime_end,
   NVL(ps.code_status, 'UNKNOWN')     AS code_status,
   owner_wfm.lib_etl_support_util.get_duration(p_dtime_start => ps.dtime_start,
                                               p_dtime_end   => ps.dtime_end)
                                      AS duration,
   p.text_description                 AS text_description,
   p.code_responsible_group           AS code_responsible_group,
   NVL(pp.flag_start_process, 'N')    AS flag_start_process_priv,
   NVL(pp.flag_cancel_process, 'N')   AS flag_cancel_process_priv,
   NVL(pp.flag_restart_process, 'N')  AS flag_restart_process_priv,
   NVL(pp.flag_suspend_process, 'N')  AS flag_suspend_process_priv,
   NVL(pp.flag_resume_process, 'N')   AS flag_resume_process_priv,
   NVL(pp.flag_skip_activity, 'N')    AS flag_skip_activity_priv,
   NVL(pp.flag_kill_activity, 'N')    AS flag_kill_activity_priv,
   NVL(pp.flag_unstuck_activity, 'N') AS flag_unstuck_activity_priv
FROM owner_wfm.etl_process p
LEFT JOIN owner_wfm.etl_process_status ps ON ps.id_process = p.id_process
LEFT JOIN owner_wfm.etl_process_group pg ON pg.code_process_group = p.code_process_group
                                        AND pg.flag_deleted != 'Y'    
LEFT JOIN owner_wfm.tmp_personal_privilege pp ON pp.code_responsible_group = p.code_responsible_group
WHERE p.flag_deleted != 'Y'
ORDER BY p.code_process_category,
         p.name_process
WITH READ ONLY;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_process_status
-----------------------------------------------------------------
COMMENT ON TABLE owner_wfm.v_etl_process_status IS 'Process status for console';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.id_process IS 'Process id';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.id_process_instance IS 'Process instance id';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.id_workflow_instance IS 'Workflow instance id';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.code_process_category IS 'Code of process category';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.name_process IS 'Process name';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.flag_active IS 'Flag marking the process as active';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.date_effective IS 'Effective date of the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.dtime_start IS 'Date and time when the process started';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.dtime_end IS 'Date and time when the process finished';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.code_status IS 'Status of the the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.duration IS 'Duration of the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.text_description IS 'Process description';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.code_responsible_group IS 'Code of responsible group of giving process';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.flag_start_process_priv IS 'Flag saying whether user has right to start the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.flag_cancel_process_priv IS 'Flag saying whether user has right to cancel the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.flag_restart_process_priv IS 'Flag saying whether user has right to restart the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.flag_suspend_process_priv IS 'Flag saying whether user has right to suspend the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.flag_resume_process_priv IS 'Flag saying whether user has right to resume the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.flag_skip_activity_priv IS 'Flag saying whether user has right to skip the process activity';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.flag_kill_activity_priv IS 'Flag saying whether user has right to kill the process activity';
COMMENT ON COLUMN owner_wfm.v_etl_process_status.flag_unstuck_activity_priv IS 'Flag saying whether user has right to unstuck the process activity';