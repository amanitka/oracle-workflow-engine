--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_report_robot_status
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_report_robot_status AS
SELECT 
   r.name_report                          AS name_report, 
   rs.dtime_start                         AS dtime_start,
   rs.dtime_end                           AS dtime_end,
   rs.code_status                         AS code_status,
   owner_wfm.lib_etl_support_util.get_duration(p_dtime_start => rs.dtime_start,
                                               p_dtime_end   => rs.dtime_end)
                                          AS duration,
   rs.text_message                        AS text_message,
   r.text_description                     AS text_description,
   r.code_responsible_group               AS code_responsible_group,
   NVL(pp.flag_start_report_robot, 'N')   AS flag_start_report_robot_priv,
   NVL(pp.flag_restart_report_robot, 'N') AS flag_restart_report_robot_priv,
   NVL(pp.flag_kill_report_robot, 'N')    AS flag_kill_report_robot_priv
FROM owner_dwh.dwh_report_robot r
JOIN owner_dwh.dwh_report_robot_status rs ON rs.name_report = r.name_report
LEFT JOIN owner_wfm.tmp_personal_privilege pp ON pp.code_responsible_group = r.code_responsible_group
WHERE r.flag_deleted != 'Y'
ORDER BY r.name_report;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_report_robot_status
-----------------------------------------------------------------
COMMENT ON TABLE owner_wfm.v_etl_report_robot_status IS 'Report robot status for console';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.name_report IS 'Name of the report robot';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.dtime_start IS 'Date and time when the report robot started';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.dtime_end IS 'Date and time when the report robot finished';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.code_status IS 'Status of the the report robot';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.duration IS 'Duration of the report robot';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.text_message IS 'Message of the report robot. Mostly error message of the failed report robot is stored there';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.text_description IS 'Description of the report robot';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.code_responsible_group IS 'Code of responsible group of the report robot';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.flag_start_report_robot_priv IS 'Flag saying whether user has right to start the report robot';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.flag_restart_report_robot_priv IS 'Flag saying whether user has right to restart the report robot';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_status.flag_kill_report_robot_priv IS 'Flag saying whether user has right to kill the report robot';
