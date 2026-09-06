--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_process_instance
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_process_instance AS
SELECT 
   pi.id_process_instance  AS id_process_instance, 
   pi.id_workflow_instance AS id_workflow_instance,
   p.id_process            AS id_process,
   p.name_process          AS name_process,
   pi.date_effective       AS date_effective,
   pi.flag_restart         AS flag_restart,
   pi.user_inserted        AS user_inserted,
   pi.dtime_start          AS dtime_start,
   pi.dtime_end            AS dtime_end,
   CASE WHEN ps.code_status IS NOT NULL THEN ps.code_status  
        ELSE pi.code_status
   END                     AS code_status,
   owner_wfm.lib_etl_support_util.get_duration(p_dtime_start => pi.dtime_start,
                                               p_dtime_end   => pi.dtime_end)
                           AS duration
FROM owner_wfm.etl_process p
JOIN owner_wfm.etl_process_instance pi ON pi.id_process = p.id_process
LEFT JOIN owner_wfm.etl_process_status ps ON ps.id_process_instance = pi.id_process_instance
ORDER BY pi.date_effective DESC, pi.id_process_instance DESC;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_process_instance
-----------------------------------------------------------------
COMMENT ON TABLE owner_wfm.v_etl_process_instance IS 'Process instance for console';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.id_process_instance IS 'Process instance id';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.id_workflow_instance IS 'Workflow instance id';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.id_process IS 'Process id';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.name_process IS 'Process name';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.date_effective IS 'Effective date of the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.flag_restart IS 'Flag marking process as restarted';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.user_inserted IS 'User who inserted the record';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.dtime_start IS 'Date and time when the process started';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.dtime_end IS 'Date and time when the process ended';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.code_status IS 'Status of the the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_instance.duration IS 'Duration of the process';
