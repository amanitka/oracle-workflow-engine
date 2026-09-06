--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW: v_etl_background_process_log
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_background_process_log AS
SELECT
   log_id                          AS id_log,
   CAST(log_date AS DATE)          AS dtime_log,
   owner                           AS name_job_owner,
   job_name                        AS name_job,   
   status                          AS code_status,
   CAST(actual_start_date AS DATE) AS dtime_start_actual,
   run_duration                    AS duration,
   instance_id                     AS id_instance,
   session_id                      AS id_session,
   additional_info                 AS text_message
FROM sys.dba_scheduler_job_run_details
ORDER BY log_date DESC;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW: v_etl_background_process_log
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfm.v_etl_background_process_log IS 'Background process log for console';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.id_log IS 'Log ID';
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.dtime_log IS 'Date and time of log';
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.name_job_owner IS 'Name of the job owner';
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.name_job IS 'Name of the job';
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.code_status IS 'Code of the the status';
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.dtime_start_actual IS 'Date and time of the actual job start';
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.duration IS 'Duration of the job';
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.id_instance IS 'Database instance id';
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.id_session IS 'Session id and serial';
COMMENT ON COLUMN owner_wfm.v_etl_background_process_log.text_message IS 'Additional info message';
