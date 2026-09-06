--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_process_log
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_process_log AS
SELECT 
   prlog_key                AS id, 
   etlproc_process_key      AS id_process_instance, 
   prlog_log_type           AS name_log_type,
   prlog_log_name           AS name_log, 
   prlog_cnt_sel            AS cnt_select, 
   prlog_cnt_ins            AS cnt_insert, 
   prlog_cnt_upd            AS cnt_update, 
   prlog_cnt_del            AS cnt_delete, 
   prlog_cnt_mrg            AS cnt_merge, 
   prlog_cnt_err            AS cnt_error, 
   CASE WHEN prlog_info IN ('N/A ', 'N/A') THEN NULL
        ELSE prlog_info
   END                      AS text_message, 
   prlog_inserted_by        AS user_inserted,
   prlog_inserted_datetime  AS dtime_start, 
   prlog_updated_datetime   AS dtime_end, 
   CASE prlog_status WHEN 'BEGIN'  THEN 'RUNNING' 
                     WHEN 'FAILED' THEN 'ERROR' 
                     ELSE prlog_status 
   END                      AS code_status, 
   owner_wfm.lib_etl_support_util.get_duration(p_dtime_start => prlog_inserted_datetime,
                                               p_dtime_end   => CASE WHEN prlog_status = 'BEGIN' THEN SYSDATE ELSE prlog_updated_datetime END)
                            AS duration
FROM owner_core.etl_process_logs;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_process_log
-----------------------------------------------------------------
-- Add comments to the table 
COMMENT ON TABLE owner_wfm.v_etl_process_log IS 'Process log for console';

-- Add comments to the columns 
COMMENT ON COLUMN owner_wfm.v_etl_process_log.id IS 'Primary key';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.id_process_instance IS 'Process instance id';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.name_log_type IS 'Log type name';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.name_log IS 'Log name';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.cnt_select IS 'Count of selected records';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.cnt_insert IS 'Count of inserted records';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.cnt_update IS 'Count of updated records';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.cnt_delete IS 'Count of deleted records';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.cnt_merge IS 'Count of merged records';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.cnt_error IS 'Count of errors';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.text_message IS 'Text message. In case of error, there is an error message';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.user_inserted IS 'User who inserted the record';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.dtime_start IS 'Date and time when the process started';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.dtime_end IS 'Date and time when the process ended';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.code_status IS 'Status of the the process';
COMMENT ON COLUMN owner_wfm.v_etl_process_log.duration IS 'Duration of the process';
