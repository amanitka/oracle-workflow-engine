--UTF8-BOM: ceské znaky: ešcržýáíé a ruské znaky: ???????? a cínské znaky: ??????????????
--nemazat

-----------------------------------------------------------------
--- VIEW:: v_etl_report_robot_log
-----------------------------------------------------------------
CREATE OR REPLACE FORCE VIEW owner_wfm.v_etl_report_robot_log AS
SELECT 
   name_report, 
   name_step, 
   dtime_start, 
   dtime_end, 
   code_status, 
   num_rows, 
   text_message, 
   date_inserted, 
   dtime_inserted, 
   user_inserted, 
   dtime_updated, 
   user_updated
FROM owner_dwh.dwh_report_robot_log;

-----------------------------------------------------------------
--- COMMENTS FOR VIEW:: v_etl_report_robot_log
-----------------------------------------------------------------
COMMENT ON TABLE owner_wfm.v_etl_report_robot_log IS 'Log table for report robot module';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.name_report IS 'Report name';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.name_step IS 'Report step name';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.dtime_start IS 'Date and time when the report step started';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.dtime_end IS 'Date and time when the report step ended';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.code_status IS 'Status of the the report step';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.num_rows IS 'Number of processed rows';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.text_message IS 'Message of report step';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.date_inserted IS 'Date when the record was inserted';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.dtime_inserted IS 'Date and time when the record was inserted';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.user_inserted IS 'User who inserted the record';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.dtime_updated IS 'Date and time when the record was updated';
COMMENT ON COLUMN owner_wfm.v_etl_report_robot_log.user_updated IS 'User who updated the record';
